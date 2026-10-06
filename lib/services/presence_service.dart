import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseInitialized;
import 'supabase_auth_service.dart';

/// Singleton service managing real-time sub-second WebSocket presence across Web and Mobile.
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  RealtimeChannel? _channel;
  Timer? _pingTimer;
  final Set<String> _onlineUserIds = {};
  final Map<String, DateTime> _lastSeenMap = {};

  final StreamController<int> _countController = StreamController<int>.broadcast();
  int _currentOnlineCount = 1;

  Stream<int> get streamOnlineCount => _countController.stream;
  int get currentOnlineCount => _currentOnlineCount;

  /// Initialize real-time WebSocket Broadcast channel.
  Future<void> initPresence() async {
    if (!supabaseInitialized) return;

    final user = SupabaseAuthService.instance.currentUser;
    if (user == null) return;

    await leavePresence();

    try {
      _channel = Supabase.instance.client.channel('online_presence');

      // Listen for instant broadcast events from other devices (< 50ms)
      _channel?.onBroadcast(
        event: 'presence',
        callback: (payload) {
          final uid = payload['user_id']?.toString();
          final status = payload['status']?.toString();
          if (uid != null && uid.isNotEmpty) {
            final now = DateTime.now().toUtc();
            _lastSeenMap[uid] = now;

            if (status == 'offline') {
              _onlineUserIds.remove(uid);
            } else {
              _onlineUserIds.add(uid);
            }
            _updateCount(myUid: user.id);
          }
        },
      );

      _channel?.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _sendPresencePing(user.id, 'online');

          // Repeat ping every 3 seconds to keep active state live across all connected devices
          _pingTimer?.cancel();
          _pingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
            _sendPresencePing(user.id, 'online');
            _cleanStaleUsers(myUid: user.id);
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing presence broadcast: $e');
    }
  }

  void _sendPresencePing(String uid, String status) {
    try {
      _channel?.sendBroadcast(
        event: 'presence',
        payload: {
          'user_id': uid,
          'status': status,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error sending presence ping: $e');
    }
  }

  void _cleanStaleUsers({required String myUid}) {
    final now = DateTime.now().toUtc();
    final toRemove = <String>[];

    _lastSeenMap.forEach((uid, lastSeen) {
      if (uid != myUid && now.difference(lastSeen).inSeconds.abs() > 10) {
        toRemove.add(uid);
      }
    });

    for (final uid in toRemove) {
      _onlineUserIds.remove(uid);
      _lastSeenMap.remove(uid);
    }

    _updateCount(myUid: myUid);
  }

  void _updateCount({required String myUid}) {
    _onlineUserIds.add(myUid);
    final count = _onlineUserIds.length;
    _currentOnlineCount = count > 0 ? count : 1;

    if (!_countController.isClosed) {
      _countController.add(_currentOnlineCount);
    }
  }

  Future<void> leavePresence() async {
    try {
      _pingTimer?.cancel();
      _pingTimer = null;

      final user = SupabaseAuthService.instance.currentUser;
      if (user != null && _channel != null) {
        _sendPresencePing(user.id, 'offline');
      }

      final ch = _channel;
      if (ch != null) {
        _channel = null;
        await Supabase.instance.client.removeChannel(ch);
      }
    } catch (e) {
      debugPrint('Error leaving presence broadcast: $e');
    }
  }

  void dispose() {
    leavePresence();
    _countController.close();
  }
}
