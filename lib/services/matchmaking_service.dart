import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';
import '../main.dart' show supabaseInitialized;

class MatchmakingService {
  Future<String?> findRandomMatch(bool isVideo) async {
    if (!supabaseInitialized) return null;

    final type = isVideo ? 'video' : 'voice';
    try {
      final currentUid = SupabaseAuthService.instance.currentUser?.id;
      final thirtySecsAgo = DateTime.now()
          .subtract(const Duration(seconds: 30))
          .toIso8601String();

      // Clean up old stale waiting rooms
      try {
        await Supabase.instance.client
            .from('rooms')
            .update({
              'status': 'ended',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('status', 'waiting')
            .lt('created_at', thirtySecsAgo);
      } catch (_) {}

      // Look for an open room created in the last 30 seconds
      final result = await Supabase.instance.client
          .from('rooms')
          .select()
          .eq('type', type)
          .eq('status', 'waiting')
          .gte('created_at', thirtySecsAgo);

      final eligibleDocs = result.where((doc) {
        if (currentUid == null) return true;
        return doc['caller_id'] != currentUid;
      }).toList();

      if (eligibleDocs.isNotEmpty) {
        final doc = eligibleDocs.first;
        final roomId = doc['id'].toString();

        // Mark as connecting so others don't join
        await Supabase.instance.client
            .from('rooms')
            .update({
              'status': 'connecting',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', roomId);

        return roomId;
      }
    } catch (_) {}
    return null;
  }
}
