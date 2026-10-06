import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseInitialized;
import 'supabase_auth_service.dart';

/// Singleton service that manages real-time WebSocket Presence for sub-second online user tracking.
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  RealtimeChannel? _channel;
  final StreamController<int> _countController = StreamController<int>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _usersController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  int _currentOnlineCount = 1;
  List<Map<String, dynamic>> _onlineUsersList = [];

  Stream<int> get streamOnlineCount => _countController.stream;
  Stream<List<Map<String, dynamic>>> get streamOnlineUsers => _usersController.stream;
  int get currentOnlineCount => _currentOnlineCount;
  List<Map<String, dynamic>> get currentOnlineUsersList => _onlineUsersList;

  /// Initialize real-time WebSocket Presence channel.
  Future<void> initPresence() async {
    if (!supabaseInitialized) return;

    final user = SupabaseAuthService.instance.currentUser;
    if (user == null) return;

    await leavePresence();

    try {
      final channel = Supabase.instance.client.channel('online_presence');
      _channel = channel;

      channel.onPresenceSync(() {
        _updatePresenceState();
      });

      channel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          final metadata = user.userMetadata ?? {};
          final rawName = metadata['full_name'] ?? metadata['name'];
          final name = rawName != null
              ? rawName.toString()
              : (user.email?.isNotEmpty == true ? user.email!.split('@')[0] : 'User');
          final rawAvatar = metadata['avatar_url'] ?? metadata['picture'];
          final avatarUrl = rawAvatar != null ? rawAvatar.toString() : '';

          try {
            channel.track({
              'user_id': user.id,
              'email': user.email ?? '',
              'name': name,
              'avatar_url': avatarUrl,
              'online_at': DateTime.now().toUtc().toIso8601String(),
            });
          } catch (e) {
            debugPrint('Error tracking presence payload: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing presence channel: $e');
    }
  }

  void _updatePresenceState() {
    final ch = _channel;
    if (ch == null) return;
    try {
      final state = ch.presenceState();
      final Map<String, Map<String, dynamic>> uniqueUsers = {};

      for (final presences in state.values) {
        for (final p in presences) {
          final payload = p.payload;
          final uid = payload['user_id']?.toString();
          if (uid != null && uid.isNotEmpty) {
            uniqueUsers[uid] = payload;
          }
        }
      }

      final count = uniqueUsers.length;
      _currentOnlineCount = count > 0 ? count : 1;
      _onlineUsersList = uniqueUsers.values.toList();

      if (!_countController.isClosed) {
        _countController.add(_currentOnlineCount);
      }
      if (!_usersController.isClosed) {
        _usersController.add(_onlineUsersList);
      }
    } catch (e) {
      debugPrint('Error updating presence state: $e');
    }
  }

  Future<void> leavePresence() async {
    try {
      final ch = _channel;
      if (ch != null) {
        _channel = null;
        try {
          await ch.untrack();
        } catch (_) {}
        try {
          await Supabase.instance.client.removeChannel(ch);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error leaving presence channel: $e');
    }
  }

  void dispose() {
    leavePresence();
    _countController.close();
    _usersController.close();
  }
}
