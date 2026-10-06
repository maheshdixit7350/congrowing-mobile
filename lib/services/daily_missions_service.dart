import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseInitialized;
import 'supabase_auth_service.dart';

/// Represents a single daily mission/task.
class DailyMission {
  final String id;
  final String title;
  final String description;
  final String icon; // icon name
  final int criReward; 
  final bool isCompleted;
  final String type; // 'talk', 'iq', 'thought'

  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.criReward,
    this.isCompleted = false,
    required this.type,
  });

  DailyMission copyWith({bool? isCompleted}) {
    return DailyMission(
      id: id,
      title: title,
      description: description,
      icon: icon,
      criReward: criReward,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'criReward': criReward,
    'isCompleted': isCompleted,
    'type': type,
  };

  factory DailyMission.fromJson(Map<String, dynamic> json) {
    return DailyMission(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'star',
      criReward: (json['criReward'] ?? json['xpReward'] ?? json['cri_reward']) as int? ?? 5,
      isCompleted: (json['isCompleted'] ?? json['is_completed']) as bool? ?? false,
      type: json['type'] as String? ?? 'talk',
    );
  }
}

/// Service that manages daily missions stored in Supabase.
class DailyMissionsService {
  DailyMissionsService._();
  static final DailyMissionsService instance = DailyMissionsService._();

  String get _myUid => supabaseInitialized ? (SupabaseAuthService.instance.currentUser?.id ?? '') : '';

  /// The 3 daily missions.
  static List<DailyMission> get defaultMissions => [
    const DailyMission(
      id: 'talk_20',
      title: 'Talk for 20 Minutes',
      description: 'Have a meaningful conversation with someone for at least 20 minutes.',
      icon: 'call',
      criReward: 5,
      type: 'talk',
    ),
    const DailyMission(
      id: 'iq_challenge',
      title: 'IQ Challenge',
      description: 'Answer 7 IQ questions — riddles, logic & patterns.',
      icon: 'thought',
      criReward: 8,
      type: 'iq',
    ),
    const DailyMission(
      id: 'share_thought',
      title: 'Share a Thought',
      description: 'Post a thought to inspire others in the community.',
      icon: 'thought',
      criReward: 3,
      type: 'thought',
    ),
  ];

  /// Get today's date key (e.g., '2026-04-16').
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get or initialize today's missions for the current user.
  Future<List<DailyMission>> getTodayMissions() async {
    if (!supabaseInitialized || _myUid.isEmpty) return defaultMissions;

    try {
      final docId = '${_myUid}_$_todayKey';
      final doc = await Supabase.instance.client.from('daily_missions').select().eq('id', docId).maybeSingle();

      if (doc != null) {
        final list = (doc['missions'] as List<dynamic>?) ?? [];
        return list.map((m) => DailyMission.fromJson(Map<String, dynamic>.from(m as Map))).toList();
      } else {
        await _initializeTodayMissions();
        return defaultMissions;
      }
    } catch (e) {
      debugPrint('Error loading daily missions: $e');
      return defaultMissions;
    }
  }

  Future<void> _initializeTodayMissions() async {
    try {
      final docId = '${_myUid}_$_todayKey';
      await Supabase.instance.client.from('daily_missions').upsert({
        'id': docId,
        'user_id': _myUid,
        'date': _todayKey,
        'missions': defaultMissions.map((m) => m.toJson()).toList(),
        'completed_count': 0,
        'total_cri_earned': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error initializing daily missions: $e');
    }
  }

  /// Mark a mission as completed and award CRI points.
  Future<void> completeMission(String missionId) async {
    if (!supabaseInitialized || _myUid.isEmpty) return;

    try {
      final docId = '${_myUid}_$_todayKey';
      final doc = await Supabase.instance.client.from('daily_missions').select().eq('id', docId).maybeSingle();
      if (doc == null) return;

      final missions = (doc['missions'] as List<dynamic>)
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();

      int criEarned = 0;
      for (int i = 0; i < missions.length; i++) {
        if (missions[i]['id'] == missionId && !(missions[i]['isCompleted'] ?? false)) {
          missions[i]['isCompleted'] = true;
          criEarned = missions[i]['criReward'] as int? ?? 0;
          break;
        }
      }

      if (criEarned > 0) {
        final completedCount = missions.where((m) => (m['isCompleted'] ?? false) == true).length;
        
        await Supabase.instance.client.from('daily_missions').update({
          'missions': missions,
          'completed_count': completedCount,
          'total_cri_earned': (doc['total_cri_earned'] as int? ?? 0) + criEarned,
        }).eq('id', docId);

        // Award CRI points directly to the user's score in users table
        final userDoc = await Supabase.instance.client.from('users').select().eq('id', _myUid).maybeSingle();
        if (userDoc != null) {
          final currentCri = (userDoc['cri_score'] ?? userDoc['criScore']) as int? ?? 850;
          await Supabase.instance.client.from('users').update({
            'cri_score': currentCri + criEarned,
          }).eq('id', _myUid);
        }
      }
    } catch (e) {
      debugPrint('Error completing mission: $e');
    }
  }

  Stream<List<DailyMission>> streamTodayMissions() {
    if (!supabaseInitialized || _myUid.isEmpty) {
      return Stream.value(defaultMissions);
    }
    final docId = '${_myUid}_$_todayKey';
    return Supabase.instance.client
        .from('daily_missions')
        .stream(primaryKey: ['id'])
        .eq('id', docId)
        .map((list) {
          if (list.isNotEmpty) {
            final doc = list.first;
            final missionsList = (doc['missions'] as List<dynamic>?) ?? [];
            return missionsList.map((m) => DailyMission.fromJson(Map<String, dynamic>.from(m as Map))).toList();
          } else {
            // Try to initialize in background
            _initializeTodayMissions();
            return defaultMissions;
          }
        });
  }

  Future<int> getStreak() async {
    if (!supabaseInitialized || _myUid.isEmpty) return 0;

    try {
      final list = await Supabase.instance.client
          .from('daily_missions')
          .select()
          .eq('user_id', _myUid)
          .order('date', ascending: false)
          .limit(30);

      if (list.isEmpty) return 0;

      int streak = 0;
      final now = DateTime.now();
      for (int i = 0; i < list.length; i++) {
        final data = list[i];
        final completed = (data['completed_count'] ?? data['completedCount']) as int? ?? 0;
        if (completed > 0) {
          final date = DateTime.tryParse(data['date'] as String? ?? '');
          if (date != null) {
            final expected = now.subtract(Duration(days: i));
            if (date.year == expected.year && date.month == expected.month && date.day == expected.day) {
              streak++;
            } else {
              break;
            }
          }
        } else {
          break;
        }
      }
      return streak;
    } catch (e) {
      debugPrint('Error getting streak: $e');
      return 0;
    }
  }
}
