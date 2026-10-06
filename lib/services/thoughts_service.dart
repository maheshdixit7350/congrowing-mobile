import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseInitialized;
import 'supabase_auth_service.dart';
import 'notification_service.dart';

/// A single ephemeral thought post (text + optional image, expires after 24h).
class Thought {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int likes;
  final List<String> likedBy;

  const Thought({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    this.likes = 0,
    this.likedBy = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'text': text,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'likes': likes,
      'liked_by': likedBy,
    };
  }

  factory Thought.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    DateTime parsedExpiresAt;
    final rawCreated = json['created_at'] ?? json['createdAt'];
    final rawExpires = json['expires_at'] ?? json['expiresAt'];

    if (rawCreated is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    if (rawExpires is String) {
      parsedExpiresAt = DateTime.tryParse(rawExpires) ??
          DateTime.now().add(const Duration(hours: 24));
    } else {
      parsedExpiresAt = DateTime.now().add(const Duration(hours: 24));
    }

    List<String> likedByList = [];
    final rawLiked = json['liked_by'] ?? json['likedBy'];
    if (rawLiked is List) {
      likedByList = rawLiked.map((item) => item.toString()).toList();
    }

    return Thought(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId']) as String? ?? '',
      userName:
          (json['user_name'] ?? json['userName']) as String? ?? 'Anonymous',
      userAvatarUrl:
          (json['user_avatar_url'] ?? json['userAvatarUrl']) as String?,
      text: json['text'] as String? ?? '',
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      createdAt: parsedCreatedAt,
      expiresAt: parsedExpiresAt,
      likes: json['likes'] as int? ?? 0,
      likedBy: likedByList,
    );
  }
}

/// A comment on a thought.
class ThoughtComment {
  final String id;
  final String thoughtId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String text;
  final DateTime createdAt;

  const ThoughtComment({
    required this.id,
    required this.thoughtId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.text,
    required this.createdAt,
  });

  factory ThoughtComment.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final raw = json['created_at'] ?? json['createdAt'];
    if (raw is String) {
      parsedDate = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ThoughtComment(
      id: (json['id'] ?? '').toString(),
      thoughtId: (json['thought_id'] ?? json['thoughtId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId']) as String? ?? '',
      userName:
          (json['user_name'] ?? json['userName']) as String? ?? 'Anonymous',
      userAvatarUrl:
          (json['user_avatar_url'] ?? json['userAvatarUrl']) as String?,
      text: json['text'] as String? ?? '',
      createdAt: parsedDate,
    );
  }
}

/// Service for managing ephemeral thoughts (24h posts) using Supabase.
class ThoughtsService {
  ThoughtsService._();
  static final ThoughtsService instance = ThoughtsService._();

  /// Daily post limits.
  static const int normalDailyLimit = 2;
  static const int premiumDailyLimit = 7;

  String get _myUid => supabaseInitialized
      ? (SupabaseAuthService.instance.currentUser?.id ?? '')
      : '';

  /// Get the number of thoughts the current user has posted today.
  Future<int> getTodayPostCount() async {
    if (!supabaseInitialized || _myUid.isEmpty) return 0;

    try {
      final todayStart = DateTime.now().toUtc();
      final startOfDay =
          DateTime.utc(todayStart.year, todayStart.month, todayStart.day);

      final result = await Supabase.instance.client
          .from('thoughts')
          .select('id')
          .eq('user_id', _myUid)
          .gte('created_at', startOfDay.toIso8601String());

      return (result as List).length;
    } catch (e) {
      debugPrint('Error getting today post count: $e');
      return 0;
    }
  }

  /// Check if the user can post (hasn't exceeded daily limit).
  Future<bool> canPost({required bool isPremium}) async {
    final count = await getTodayPostCount();
    final limit = isPremium ? premiumDailyLimit : normalDailyLimit;
    return count < limit;
  }

  /// Get remaining posts for today.
  Future<int> getRemainingPosts({required bool isPremium}) async {
    final count = await getTodayPostCount();
    final limit = isPremium ? premiumDailyLimit : normalDailyLimit;
    return (limit - count).clamp(0, limit);
  }

  /// Post a new thought (text + optional image bytes).
  Future<void> postThought({
    required String text,
    Uint8List? imageBytes,
    String? imageName,
    required bool isPremium,
  }) async {
    if (!supabaseInitialized || _myUid.isEmpty) return;

    // Check daily limit
    final allowed = await canPost(isPremium: isPremium);
    if (!allowed) {
      final limit = isPremium ? premiumDailyLimit : normalDailyLimit;
      throw Exception(
          'Daily limit reached! You can post up to $limit stories per day.');
    }

    try {
      // Get current user info from users table in Supabase
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', _myUid)
          .maybeSingle();
      final userName =
          (userData != null ? userData['name'] as String? : null) ??
              'Anonymous';
      final userAvatar = userData != null
          ? (userData['avatar_url'] ?? userData['avatarUrl']) as String?
          : null;

      String? imageUrl;
      if (imageBytes != null && imageName != null) {
        final path =
            '$_myUid/${DateTime.now().millisecondsSinceEpoch}_$imageName';
        await Supabase.instance.client.storage.from('thoughts').uploadBinary(
              path,
              imageBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        imageUrl = Supabase.instance.client.storage
            .from('thoughts')
            .getPublicUrl(path);
      }

      final now = DateTime.now().toUtc();
      final expiresAt = now.add(const Duration(hours: 24));

      await Supabase.instance.client.from('thoughts').insert({
        'user_id': _myUid,
        'user_name': userName,
        'user_avatar_url': userAvatar,
        'text': text,
        'image_url': imageUrl,
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'likes': 0,
        'liked_by': [],
      });

      // Run storage cleanup for old thoughts asynchronously
      _cleanupExpiredThoughts();
    } catch (e) {
      debugPrint('Error posting thought to Supabase: $e');
      rethrow;
    }
  }

  /// Stream active (non-expired) thoughts, ordered by most recent.
  Stream<List<Thought>> streamActiveThoughts() {
    if (!supabaseInitialized) return const Stream.empty();

    // Trigger cleanup asynchronously
    _cleanupExpiredThoughts();

    return Supabase.instance.client
        .from('thoughts')
        .stream(primaryKey: ['id']).map((list) {
      final now = DateTime.now();
      final activeThoughts = list
          .map((map) => Thought.fromJson(map))
          .where((t) => t.expiresAt.isAfter(now))
          .toList();

      activeThoughts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return activeThoughts;
    });
  }

  /// Stream active thoughts (alias/fallback).
  Stream<List<Thought>> streamRecentThoughts() {
    return streamActiveThoughts();
  }

  /// Like / unlike a thought.
  Future<void> toggleLike(String thoughtId) async {
    if (!supabaseInitialized || _myUid.isEmpty) return;

    try {
      final doc = await Supabase.instance.client
          .from('thoughts')
          .select()
          .eq('id', thoughtId)
          .single();
      final likedBy = List<String>.from(doc['liked_by'] ?? []);

      final wasLiked = likedBy.contains(_myUid);
      if (wasLiked) {
        likedBy.remove(_myUid);
      } else {
        likedBy.add(_myUid);
      }

      await Supabase.instance.client.from('thoughts').update({
        'liked_by': likedBy,
        'likes': likedBy.length,
      }).eq('id', thoughtId);

      // If it's a new like, send a notification to the author of the thought
      if (!wasLiked && doc['user_id'] != _myUid) {
        await NotificationService.instance.createNotification(
          userId: doc['user_id'] as String,
          actorId: _myUid,
          type: 'like',
          thoughtId: thoughtId,
          message: 'liked your story',
        );
      }
    } catch (e) {
      debugPrint('Error toggling like on Supabase: $e');
    }
  }

  /// Delete a thought (only author can delete).
  Future<void> deleteThought(String thoughtId) async {
    if (!supabaseInitialized || _myUid.isEmpty) return;

    try {
      final doc = await Supabase.instance.client
          .from('thoughts')
          .select()
          .eq('id', thoughtId)
          .single();
      if (doc['user_id'] == _myUid) {
        final imageUrl = doc['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final uri = Uri.parse(imageUrl);
            final segments = uri.pathSegments;
            final bucketIndex = segments.indexOf('thoughts');
            if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
              final path = segments.sublist(bucketIndex + 1).join('/');
              await Supabase.instance.client.storage
                  .from('thoughts')
                  .remove([path]);
            }
          } catch (_) {}
        }
        await Supabase.instance.client
            .from('thoughts')
            .delete()
            .eq('id', thoughtId);
      }
    } catch (e) {
      debugPrint('Error deleting thought: $e');
    }
  }

  // ── Comments ────────────────────────────────────────────────────────────

  /// Add a comment to a thought.
  Future<void> addComment({
    required String thoughtId,
    required String text,
  }) async {
    if (!supabaseInitialized || _myUid.isEmpty || text.trim().isEmpty) return;

    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', _myUid)
          .maybeSingle();
      final userName =
          (userData != null ? userData['name'] as String? : null) ??
              'Anonymous';
      final userAvatar = userData != null
          ? (userData['avatar_url'] ?? userData['avatarUrl']) as String?
          : null;

      await Supabase.instance.client.from('thought_comments').insert({
        'thought_id': thoughtId,
        'user_id': _myUid,
        'user_name': userName,
        'user_avatar_url': userAvatar,
        'text': text.trim(),
      });

      // Fetch the thought to find the owner's userId
      final thoughtDoc = await Supabase.instance.client
          .from('thoughts')
          .select('user_id')
          .eq('id', thoughtId)
          .maybeSingle();

      if (thoughtDoc != null && thoughtDoc['user_id'] != _myUid) {
        await NotificationService.instance.createNotification(
          userId: thoughtDoc['user_id'] as String,
          actorId: _myUid,
          type: 'comment',
          thoughtId: thoughtId,
          message: 'commented: "${text.trim()}"',
        );
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Stream comments for a specific thought.
  Stream<List<ThoughtComment>> streamComments(String thoughtId) {
    if (!supabaseInitialized) return const Stream.empty();

    return Supabase.instance.client
        .from('thought_comments')
        .stream(primaryKey: ['id'])
        .eq('thought_id', thoughtId)
        .map((list) {
          final comments =
              list.map((map) => ThoughtComment.fromJson(map)).toList();
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
        });
  }

  /// Get comment count for a thought (one-time fetch).
  Future<int> getCommentCount(String thoughtId) async {
    if (!supabaseInitialized) return 0;
    try {
      final result = await Supabase.instance.client
          .from('thought_comments')
          .select('id')
          .eq('thought_id', thoughtId);
      return (result as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Delete a comment.
  Future<void> deleteComment(String commentId) async {
    if (!supabaseInitialized || _myUid.isEmpty) return;
    try {
      await Supabase.instance.client
          .from('thought_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', _myUid);
    } catch (e) {
      debugPrint('Error deleting comment: $e');
    }
  }

  /// Self-cleaning storage and DB cleanup routine for expired thoughts.
  Future<void> _cleanupExpiredThoughts() async {
    if (!supabaseInitialized || _myUid.isEmpty) return;
    try {
      final nowStr = DateTime.now().toUtc().toIso8601String();
      final expired = await Supabase.instance.client
          .from('thoughts')
          .select()
          .eq('user_id', _myUid)
          .lt('expires_at', nowStr);

      if (expired.isEmpty) return;

      for (final doc in expired) {
        final imageUrl = doc['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final uri = Uri.parse(imageUrl);
            final segments = uri.pathSegments;
            final bucketIndex = segments.indexOf('thoughts');
            if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
              final path = segments.sublist(bucketIndex + 1).join('/');
              await Supabase.instance.client.storage
                  .from('thoughts')
                  .remove([path]);
            }
          } catch (_) {}
        }
        await Supabase.instance.client
            .from('thoughts')
            .delete()
            .eq('id', doc['id']);
      }
      debugPrint(
          'Thoughts self-cleanup completed: deleted ${expired.length} expired entries.');
    } catch (e) {
      debugPrint('Error in thoughts self-cleaning: $e');
    }
  }

  /// Get time remaining for a thought (accurate to minutes).
  static String getTimeRemaining(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m left';
    }
    if (remaining.inMinutes > 0) return '${remaining.inMinutes}m left';
    return 'Expiring soon';
  }

  /// Get relative time string.
  static String getTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
