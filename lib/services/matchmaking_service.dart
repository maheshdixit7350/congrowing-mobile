import 'package:cloud_firestore/cloud_firestore.dart';

class MatchmakingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> findRandomMatch(bool isVideo) async {
    final type = isVideo ? 'video' : 'voice';
    // Look for an open room in the 'rooms' collection
    final query = await _firestore
        .collection('rooms')
        .where('type', isEqualTo: type)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      // Mark as connecting so others don't join
      await doc.reference.update({'status': 'connecting'});
      return doc.id;
    }
    return null;
  }

  // This is now handled by signaling.createRoom() 
  // and then the screen updates the status
}
