import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseInitialized;

/// A notification from the backend.
class AppNotification {
  final String id;
  final String userId;
  final String actorId;
  final String type; // 'like', 'comment', 'follow', 'cri_update', 'achievement'
  final String? thoughtId;
  final String? message;
  final bool isRead;
  final DateTime createdAt;

  // Joined actor data (populated from the query)
  final String? actorName;
  final String? actorAvatarUrl;
  final String? actorUsername;

  AppNotification({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.thoughtId,
    this.message,
    this.isRead = false,
    required this.createdAt,
    this.actorName,
    this.actorAvatarUrl,
    this.actorUsername,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String,
      type: json['type'] as String,
      thoughtId: json['thought_id'] as String?,
      message: json['message'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      actorName: actor?['name'] as String?,
      actorAvatarUrl: actor?['avatar_url'] as String?,
      actorUsername: actor?['username'] as String?,
    );
  }
}

/// Singleton service for managing notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Stream notifications for the current user, joined with actor info.
  Stream<List<AppNotification>> streamNotifications(String userId) {
    if (!supabaseInitialized) return Stream.value([]);
    return Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
          // For each notification, fetch actor data
          if (rows.isEmpty) return <AppNotification>[];

          final actorIds =
              rows.map((r) => r['actor_id'] as String).toSet().toList();
          final actorsRes = await Supabase.instance.client
              .from('users')
              .select('id, name, avatar_url, username')
              .inFilter('id', actorIds);

          final actorMap = <String, Map<String, dynamic>>{};
          for (final a in actorsRes) {
            actorMap[a['id'] as String] = a;
          }

          return rows.map((r) {
            final enriched = Map<String, dynamic>.from(r);
            enriched['actor'] = actorMap[r['actor_id']];
            return AppNotification.fromJson(enriched);
          }).toList();
        });
  }

  /// Fetch notifications as a one-time query (with actor info).
  Future<List<AppNotification>> getNotifications(String userId,
      {int limit = 50}) async {
    if (!supabaseInitialized) return [];
    try {
      final rows = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (rows.isEmpty) return [];

      final actorIds =
          rows.map((r) => r['actor_id'] as String).toSet().toList();
      final actorsRes = await Supabase.instance.client
          .from('users')
          .select('id, name, avatar_url, username')
          .inFilter('id', actorIds);

      final actorMap = <String, Map<String, dynamic>>{};
      for (final a in actorsRes) {
        actorMap[a['id'] as String] = a;
      }

      return rows.map((r) {
        final enriched = Map<String, dynamic>.from(r);
        enriched['actor'] = actorMap[r['actor_id']];
        return AppNotification.fromJson(enriched);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Create a notification.
  Future<void> createNotification({
    required String userId,
    required String actorId,
    required String type,
    String? thoughtId,
    String? message,
  }) async {
    if (!supabaseInitialized) return;
    if (userId == actorId) return; // Don't notify yourself
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': userId,
        'actor_id': actorId,
        'type': type,
        'thought_id': thoughtId,
        'message': message,
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllRead(String userId) async {
    if (!supabaseInitialized) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  /// Get unread count.
  Future<int> getUnreadCount(String userId) async {
    if (!supabaseInitialized) return 0;
    try {
      final res = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);
      return res.length;
    } catch (e) {
      return 0;
    }
  }
}
