import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseInitialized;
import 'supabase_auth_service.dart';

/// A leaderboard entry backed by real Supabase data.
class LeaderboardEntry {
  final String uid;
  final String name;
  final String? avatarUrl;
  final int criScore;
  final int rank;
  final bool isMe;

  const LeaderboardEntry({
    required this.uid,
    required this.name,
    this.avatarUrl,
    required this.criScore,
    required this.rank,
    this.isMe = false,
  });
}

/// Service to pull real leaderboard data from Supabase.
class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  String get _myUid => supabaseInitialized ? (SupabaseAuthService.instance.currentUser?.id ?? '') : '';

  /// Get top N users by CRI score.
  Future<List<LeaderboardEntry>> getTopUsers({int limit = 20}) async {
    if (!supabaseInitialized) return [];

    try {
      final list = await Supabase.instance.client
          .from('users')
          .select()
          .order('cri_score', ascending: false)
          .limit(limit);

      final entries = <LeaderboardEntry>[];
      for (int i = 0; i < list.length; i++) {
        final data = list[i];
        final id = data['id'].toString();
        entries.add(LeaderboardEntry(
          uid: id,
          name: data['name'] as String? ?? 'User',
          avatarUrl: (data['avatar_url'] ?? data['avatarUrl']) as String?,
          criScore: (data['cri_score'] ?? data['criScore']) as int? ?? 0,
          rank: i + 1,
          isMe: id == _myUid,
        ));
      }
      return entries;
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      return [];
    }
  }

  /// Stream the leaderboard in real-time.
  Stream<List<LeaderboardEntry>> streamLeaderboard({int limit = 20}) {
    if (!supabaseInitialized) return const Stream.empty();

    return Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .map((list) {
          final entries = <LeaderboardEntry>[];
          final sortedList = List<Map<String, dynamic>>.from(list);
          sortedList.sort((a, b) => ((b['cri_score'] ?? b['criScore']) as int? ?? 0)
              .compareTo((a['cri_score'] ?? a['criScore']) as int? ?? 0));
          
          final limitedList = sortedList.take(limit).toList();
          for (int i = 0; i < limitedList.length; i++) {
            final data = limitedList[i];
            final id = data['id'].toString();
            entries.add(LeaderboardEntry(
              uid: id,
              name: data['name'] as String? ?? 'User',
              avatarUrl: (data['avatar_url'] ?? data['avatarUrl']) as String?,
              criScore: (data['cri_score'] ?? data['criScore']) as int? ?? 0,
              rank: i + 1,
              isMe: id == _myUid,
            ));
          }
          return entries;
        });
  }

  /// Get the current user's rank.
  Future<int> getMyRank() async {
    if (!supabaseInitialized || _myUid.isEmpty) return 0;

    try {
      final doc = await Supabase.instance.client.from('users').select().eq('id', _myUid).maybeSingle();
      if (doc == null) return 0;
      
      final myCri = (doc['cri_score'] ?? doc['criScore']) as int? ?? 0;

      final result = await Supabase.instance.client
          .from('users')
          .select('id')
          .gt('cri_score', myCri);

      return result.length + 1;
    } catch (e) {
      debugPrint('Error getting rank: $e');
      return 0;
    }
  }
}
