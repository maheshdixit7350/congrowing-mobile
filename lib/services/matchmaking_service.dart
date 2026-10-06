import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';
import '../main.dart' show supabaseInitialized;

class MatchmakingService {
  Future<String?> findRandomMatch(bool isVideo) async {
    if (!supabaseInitialized) return null;

    final type = isVideo ? 'video' : 'voice';
    try {
      final currentUid = SupabaseAuthService.instance.currentUser?.id;
      
      // Look for an open room in the rooms table (exclude own rooms)
      final result = await Supabase.instance.client
          .from('rooms')
          .select()
          .eq('type', type)
          .eq('status', 'waiting');

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
