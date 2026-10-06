import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../main.dart' show supabaseInitialized;
import 'supabase_auth_service.dart';
import 'notification_service.dart';
import 'presence_service.dart';

/// Singleton service that manages the current user's data from Supabase.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  String? get _currentUserId => SupabaseAuthService.instance.currentUser?.id;

  UserModel? _currentUser;
  StreamSubscription<List<Map<String, dynamic>>>? _userSub;
  Timer? _heartbeatTimer;
  void Function(UserModel?)? _localListener;


  UserModel? get currentUser => _currentUser;

  /// Load (and keep in sync) the profile for the signed-in user.
  Future<void> loadCurrentUser() async {
    if (!supabaseInitialized) {
      // Load saved overrides from SharedPreferences for prototype mode
      final prefs = await SharedPreferences.getInstance();
      final savedName     = prefs.getString('proto_name');
      final savedUsername  = prefs.getString('proto_username');
      final savedBio       = prefs.getString('proto_bio');
      final savedCollege   = prefs.getString('proto_college');
      final savedAvatar    = prefs.getString('proto_avatarUrl');
      final savedGender    = prefs.getString('proto_gender');
      final savedCountry   = prefs.getString('proto_country');
      final savedState     = prefs.getString('proto_state');
      final onboardingDone = prefs.getBool('proto_onboarding_complete') ?? false;

      _currentUser = UserModel(
        id: 'prototype_uid_123',
        name: savedName ?? 'Username',
        username: savedUsername ?? 'Username',
        email: 'username@example.com',
        bio: savedBio,
        college: savedCollege,
        avatarUrl: savedAvatar,
        gender: savedGender,
        country: savedCountry,
        state: savedState,
        onboardingComplete: onboardingDone,
        createdAt: DateTime.now(),
        postsCount: 5,
        followersCount: 250,
        friendsCount: 154,
        criScore: 820,
        totalCalls: 10,
        avgEmpathy: 7.5,
        listenRate: 85,
        totalReviews: 2,
      );
      return;
    }

    final uid = _currentUserId;
    if (uid == null) return;

    try {
      final data = await Supabase.instance.client.from('users').select().eq('id', uid).maybeSingle();
      if (data != null) {
        _currentUser = UserModel.fromJson(data);

        // Sync avatar_url from auth metadata (Google/OAuth) if database has none
        final authUser = SupabaseAuthService.instance.currentUser;
        if (authUser != null) {
          final dbAvatar = data['avatar_url'] as String?;
          final meta = authUser.userMetadata ?? {};
          final metaAvatar = (meta['avatar_url'] ?? meta['picture']) as String?;

          if ((dbAvatar == null || dbAvatar.isEmpty) && (metaAvatar != null && metaAvatar.isNotEmpty)) {
            try {
              await Supabase.instance.client.from('users').update({
                'avatar_url': metaAvatar,
              }).eq('id', uid);
              _currentUser = _currentUser?.copyWith(avatarUrl: metaAvatar);
              debugPrint('Synced avatar_url from auth metadata to public.users table: $metaAvatar');
            } catch (e) {
              debugPrint('Failed to sync avatar_url to public.users: $e');
            }
          }
        }
      } else {
        // User exists in auth but not in public.users table (e.g., Google Sign-In for the first time)
        final authUser = SupabaseAuthService.instance.currentUser;
        if (authUser != null) {
          final email = authUser.email ?? '';
          final meta = authUser.userMetadata ?? {};
          final name = meta['full_name'] ?? meta['name'] ?? email.split('@')[0];

          // Generate a clean username
          String baseUsername = email.isNotEmpty ? email.split('@')[0] : 'user';
          baseUsername = baseUsername.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '').toLowerCase();
          if (baseUsername.isEmpty) baseUsername = 'user';

          String uniqueUsername = baseUsername;
          try {
            final check = await Supabase.instance.client
                .from('users')
                .select('username')
                .eq('username', uniqueUsername)
                .limit(1);
            if (check.isNotEmpty) {
              final suffix = uid.length >= 4 ? uid.substring(0, 4) : '123';
              uniqueUsername = '${baseUsername}_$suffix';
            }
          } catch (_) {}

          final avatarUrl = (meta['avatar_url'] ?? meta['picture']) as String?;
          final gender = meta['gender'] as String?;

          final newUserMap = {
            'id': uid,
            'name': name,
            'username': uniqueUsername,
            'email': email,
            'avatar_url': avatarUrl,
            'gender': gender,
            'created_at': DateTime.now().toIso8601String(),
            'cri_score': 0,
            'onboarding_complete': false,
            'posts_count': 0,
            'friends_count': 0,
            'followers_count': 0,
            'is_online': true,
            'is_premium': false,
            'voice_call_enabled': true,
            'total_reviews': 0,
            'avg_empathy': 5.0,
            'respect_rate': 0.0,
            'listen_rate': 0.0,
            'total_calls': 0,
            'total_call_duration': 0,
          };

          await Supabase.instance.client.from('users').upsert(newUserMap);

          // Reload the newly created user data
          final freshData = await Supabase.instance.client.from('users').select().eq('id', uid).maybeSingle();
          if (freshData != null) {
            _currentUser = UserModel.fromJson(freshData);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading current user from Supabase: $e');
    }
  }

  /// Listen to real-time updates on the current user's profile.
  void listenToCurrentUser(void Function(UserModel?) onChange) {
    if (!supabaseInitialized) {
      _localListener = onChange;
      onChange(_currentUser);
      return;
    }
    final uid = _currentUserId;
    if (uid == null) return;

    _userSub?.cancel();
    
    // First initial load
    loadCurrentUser().then((_) {
      onChange(_currentUser);
    });

    // Setup realtime subscription
    _userSub = Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .listen((data) {
          if (data.isNotEmpty) {
            _currentUser = UserModel.fromJson(data.first);
            onChange(_currentUser);
          }
        }, onError: (e) {
          debugPrint('Error listening to user changes: $e');
        });
  }

  /// Update the current user's profile fields.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (!supabaseInitialized) {
      // Prototype mode: update in-memory + SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cur = _currentUser;
      if (cur == null) return;

      final newName     = data['name']      as String? ?? cur.name;
      final newUsername  = data['username']  as String? ?? cur.username;
      final newBio      = data['bio']       as String? ?? cur.bio;
      final newCollege  = data['college']   as String? ?? cur.college;
      final newAvatar   = data['avatarUrl'] as String? ?? cur.avatarUrl;

      await prefs.setString('proto_name', newName);
      await prefs.setString('proto_username', newUsername);
      if (newBio != null)     await prefs.setString('proto_bio', newBio);
      if (newCollege != null)  await prefs.setString('proto_college', newCollege);
      if (newAvatar != null)   await prefs.setString('proto_avatarUrl', newAvatar);

      _currentUser = UserModel(
        id: cur.id,
        name: newName,
        username: newUsername,
        email: cur.email,
        bio: newBio,
        college: newCollege,
        avatarUrl: newAvatar,
        createdAt: cur.createdAt,
        postsCount: cur.postsCount,
        followersCount: cur.followersCount,
        friendsCount: cur.friendsCount,
        criScore: cur.criScore,
        isPremium: cur.isPremium,
        isOnline: cur.isOnline,
        totalCalls: cur.totalCalls,
        avgEmpathy: cur.avgEmpathy,
        listenRate: cur.listenRate,
        totalReviews: cur.totalReviews,
        respectRate: cur.respectRate,
        totalCallDuration: cur.totalCallDuration,
        voiceCallEnabled: cur.voiceCallEnabled,
      );

      // Notify local listener
      _localListener?.call(_currentUser);
      return;
    }

    final uid = _currentUserId;
    if (uid == null) return;
    try {
      await Supabase.instance.client.from('users').update(data).eq('id', uid);
    } catch (e) {
      debugPrint('Error updating profile on Supabase: $e');
      rethrow;
    }
  }

  /// Get any user by their UID.
  Future<UserModel?> getUserById(String uid) async {
    if (!supabaseInitialized) return null;
    try {
      final data = await Supabase.instance.client.from('users').select().eq('id', uid).maybeSingle();
      if (data != null) {
        return UserModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Complete the onboarding flow.
  ///
  /// Updates the user's gender, country, state, personality type,
  /// CRI score and sets `onboarding_complete = true`.
  Future<void> completeOnboarding({
    required String gender,
    required String country,
    required String state,
    required String personalityType,
    required int criScore,
  }) async {
    if (!supabaseInitialized) {
      // Prototype mode: update in-memory and SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('proto_gender', gender);
      await prefs.setString('proto_country', country);
      await prefs.setString('proto_state', state);
      await prefs.setBool('proto_onboarding_complete', true);

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          gender: gender,
          country: country,
          state: state,
          personalityType: personalityType,
          criScore: criScore,
          onboardingComplete: true,
        );
        _localListener?.call(_currentUser);
      }
      return;
    }

    final uid = _currentUserId;
    if (uid == null) return;
    try {
      await Supabase.instance.client.from('users').update({
        'gender': gender,
        'country': country,
        'state': state,
        'personality_type': personalityType,
        'cri_score': criScore,
        'onboarding_complete': true,
      }).eq('id', uid);
      // Reload after update
      await loadCurrentUser();
    } catch (e) {
      debugPrint('Error completing onboarding on Supabase: $e');
      rethrow;
    }
  }

  /// Check if the current user has completed onboarding.
  Future<bool> isOnboardingComplete() async {
    if (!supabaseInitialized) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('proto_onboarding_complete') ?? false;
    }

    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('onboarding_complete')
          .eq('id', uid)
          .maybeSingle();
      if (data != null) {
        return data['onboarding_complete'] as bool? ?? false;
      }
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
    }
    return false;
  }

  /// Set user online status and manage heartbeat timer using UTC.
  Future<void> setOnlineStatus(bool online) async {
    if (!supabaseInitialized) return;
    final uid = _currentUserId;
    if (uid == null) return;

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await Supabase.instance.client.from('users').update({
        'is_online': online,
        'last_seen': nowUtc,
      }).eq('id', uid);

      if (online) {
        await PresenceService.instance.initPresence();
        // Active heartbeat ping every 5 seconds for background DB sync
        _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
          final curUid = _currentUserId;
          if (curUid != null && supabaseInitialized) {
            try {
              await Supabase.instance.client.from('users').update({
                'is_online': true,
                'last_seen': DateTime.now().toUtc().toIso8601String(),
              }).eq('id', curUid);
            } catch (_) {}
          }
        });
      } else {
        await PresenceService.instance.leavePresence();
      }

    } catch (e) {
      debugPrint('Error setting online status: $e');
    }
  }



  /// Stream a specific user's online status and last seen in real-time.
  Stream<Map<String, dynamic>> streamUserOnlineStatus(String uid) {
    if (!supabaseInitialized || uid.isEmpty) {
      return Stream.value({'is_online': false, 'last_seen': null});
    }
    return Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((rows) {
          if (rows.isEmpty) return {'is_online': false, 'last_seen': null};
          final row = rows.first;
          return {
            'is_online': row['is_online'] as bool? ?? false,
            'last_seen': row['last_seen'] as String?,
          };
        });
  }

  // ── Follows & Friends ──────────────────────────────────────────────────────

  /// Follow a user.
  Future<void> followUser(String targetUid) async {
    if (!supabaseInitialized || _currentUserId == null) return;
    try {
      await Supabase.instance.client.from('follows').insert({
        'follower_id': _currentUserId,
        'following_id': targetUid,
      });
      // Create a notification for the target user
      await NotificationService.instance.createNotification(
        userId: targetUid,
        actorId: _currentUserId!,
        type: 'follow',
      );
      // Force reload current user stats locally
      await loadCurrentUser();
    } catch (e) {
      debugPrint('Error following user: $e');
    }
  }

  /// Unfollow a user.
  Future<void> unfollowUser(String targetUid) async {
    if (!supabaseInitialized || _currentUserId == null) return;
    try {
      await Supabase.instance.client
          .from('follows')
          .delete()
          .eq('follower_id', _currentUserId!)
          .eq('following_id', targetUid);
      // Force reload current user stats locally
      await loadCurrentUser();
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
    }
  }

  /// Check if the current user is following targetUid.
  Future<bool> isFollowing(String targetUid) async {
    if (!supabaseInitialized || _currentUserId == null) return false;
    try {
      final res = await Supabase.instance.client
          .from('follows')
          .select()
          .eq('follower_id', _currentUserId!)
          .eq('following_id', targetUid)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  /// Get list of mutual friends for a user.
  Future<List<UserModel>> getFriends(String uid) async {
    if (!supabaseInitialized) return [];
    try {
      final res = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', uid);
      
      final followedIds = res.map((row) => row['following_id'] as String).toList();
      if (followedIds.isEmpty) return [];

      // Query which of these follow back
      final backRes = await Supabase.instance.client
          .from('follows')
          .select('follower_id')
          .eq('following_id', uid)
          .inFilter('follower_id', followedIds);

      final friendIds = backRes.map((row) => row['follower_id'] as String).toList();
      if (friendIds.isEmpty) return [];

      final usersRes = await Supabase.instance.client
          .from('users')
          .select()
          .inFilter('id', friendIds);

      return usersRes.map((map) => UserModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Error getting friends: $e');
      return [];
    }
  }

  /// Get list of followers who are not followed back (one-way followers).
  Future<List<UserModel>> getFollowers(String uid) async {
    if (!supabaseInitialized) return [];
    try {
      // 1. Get everyone who follows uid
      final res = await Supabase.instance.client
          .from('follows')
          .select('follower_id')
          .eq('following_id', uid);

      final followerIds = res.map((row) => row['follower_id'] as String).toList();
      if (followerIds.isEmpty) return [];

      // 2. Get everyone whom uid follows
      final followingRes = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', uid);

      final followingIds = followingRes.map((row) => row['following_id'] as String).toSet();

      // 3. One-way followers = followerIds - followingIds
      final oneWayFollowerIds = followerIds.where((id) => !followingIds.contains(id)).toList();
      if (oneWayFollowerIds.isEmpty) return [];

      final usersRes = await Supabase.instance.client
          .from('users')
          .select()
          .inFilter('id', oneWayFollowerIds);

      return usersRes.map((map) => UserModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Error getting followers: $e');
      return [];
    }
  }

  /// Get list of following who do not follow back (one-way following).
  Future<List<UserModel>> getFollowing(String uid) async {
    if (!supabaseInitialized) return [];
    try {
      // 1. Get everyone whom uid follows
      final res = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', uid);

      final followingIds = res.map((row) => row['following_id'] as String).toList();
      if (followingIds.isEmpty) return [];

      // 2. Get everyone who follows uid
      final followerRes = await Supabase.instance.client
          .from('follows')
          .select('follower_id')
          .eq('following_id', uid);

      final followerIds = followerRes.map((row) => row['follower_id'] as String).toSet();

      // 3. One-way following = followingIds - followerIds
      final oneWayFollowingIds = followingIds.where((id) => !followerIds.contains(id)).toList();
      if (oneWayFollowingIds.isEmpty) return [];

      final usersRes = await Supabase.instance.client
          .from('users')
          .select()
          .inFilter('id', oneWayFollowingIds);

      return usersRes.map((map) => UserModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Error getting following: $e');
      return [];
    }
  }

  /// Get all active online users (excluding the current user).
  Future<List<UserModel>> getOnlineUsers({int limit = 30}) async {
    if (!supabaseInitialized) return [];
    final uid = _currentUserId;
    try {
      final res = await Supabase.instance.client
          .from('users')
          .select()
          .eq('is_online', true)
          .neq('id', uid ?? '')
          .limit(limit);
      final list = (res as List)
          .where((r) => _isUserRecentlyActive(r as Map<String, dynamic>))
          .map((map) => UserModel.fromJson(map as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugPrint('Error fetching online users: $e');
      return [];
    }
  }


  /// Check if a user row has sent an active heartbeat within 45 seconds in UTC.
  bool _isUserRecentlyActive(Map<String, dynamic> row) {
    final isOnline = row['is_online'] as bool? ?? false;
    if (!isOnline) return false;

    final lastSeenStr = row['last_seen'] as String?;
    if (lastSeenStr == null || lastSeenStr.isEmpty) {
      // Stale rows without recent timestamp are NOT active
      return false;
    }

    try {
      final lastSeen = DateTime.parse(lastSeenStr).toUtc();
      final nowUtc = DateTime.now().toUtc();
      final diffSeconds = nowUtc.difference(lastSeen).inSeconds.abs();
      return diffSeconds <= 45;
    } catch (_) {
      return false;
    }
  }



  /// Stream online users in real-time.
  Stream<List<UserModel>> streamOnlineUsers({int limit = 30}) {
    if (!supabaseInitialized) return Stream.value([]);
    final uid = _currentUserId ?? '';
    return Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .where((r) => r['id'] != uid && _isUserRecentlyActive(r))
            .take(limit)
            .map((r) => UserModel.fromJson(r))
            .toList());
  }

  /// Stream total online users count in real-time via Supabase WebSocket Presence.
  Stream<int> streamOnlineCount() {
    if (!supabaseInitialized) return Stream.value(1);
    return PresenceService.instance.streamOnlineCount;
  }

  /// Helper to query active users with fresh heartbeats (within 12 seconds).
  Future<int> _fetchActiveOnlineCount() async {
    final uid = _currentUserId;
    try {
      final res = await Supabase.instance.client
          .from('users')
          .select('id, is_online, last_seen')
          .eq('is_online', true);

      final now = DateTime.now().toUtc();
      final activeOthers = (res as List).where((r) {
        final rId = r['id'] as String?;
        if (rId == uid || rId == null) return false;
        final lastSeenStr = r['last_seen'] as String?;
        if (lastSeenStr == null || lastSeenStr.trim().isEmpty) return false;
        try {
          final lastSeen = DateTime.parse(lastSeenStr).toUtc();
          final diff = now.difference(lastSeen).inSeconds.abs();
          return diff <= 12;
        } catch (_) {
          return false;
        }
      }).length;

      final total = (uid != null ? 1 : 0) + activeOthers;
      return total > 0 ? total : 1;
    } catch (e) {
      return 1;
    }
  }





  /// Check if a target user is following the current user.
  Future<bool> isFollowedBy(String targetUid) async {
    if (!supabaseInitialized || _currentUserId == null) return false;
    try {
      final res = await Supabase.instance.client
          .from('follows')
          .select()
          .eq('follower_id', targetUid)
          .eq('following_id', _currentUserId!)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _userSub?.cancel();
  }

}
