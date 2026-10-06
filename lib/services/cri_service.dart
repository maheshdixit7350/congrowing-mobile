import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseInitialized;
import 'supabase_auth_service.dart';

/// A single review left by one user about another after a call.
class UserReview {
  final String id;
  final String reviewerId;
  final String reviewedUserId;
  final double empathyScore;       // 0–10
  final bool wasRespectful;
  final bool didListen;
  final String? note;
  final String callType;           // 'voice' or 'video'
  final int callDurationSeconds;
  final DateTime createdAt;

  const UserReview({
    required this.id,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.empathyScore,
    required this.wasRespectful,
    required this.didListen,
    this.note,
    required this.callType,
    required this.callDurationSeconds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'reviewer_id': reviewerId,
    'reviewed_user_id': reviewedUserId,
    'empathy_score': empathyScore,
    'was_respectful': wasRespectful,
    'did_listen': didListen,
    'note': note,
    'call_type': callType,
    'call_duration_seconds': callDurationSeconds,
    'created_at': createdAt.toIso8601String(),
  };

  factory UserReview.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final raw = json['created_at'] ?? json['createdAt'];
    if (raw is String) {
      parsedDate = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return UserReview(
      id: (json['id'] ?? '').toString(),
      reviewerId: (json['reviewer_id'] ?? json['reviewerId']) as String? ?? '',
      reviewedUserId: (json['reviewed_user_id'] ?? json['reviewedUserId'] ?? json['reviewee_id']) as String? ?? '',
      empathyScore: ((json['empathy_score'] ?? json['empathyScore'] ?? json['empathy']) as num?)?.toDouble() ?? 5.0,
      wasRespectful: (json['was_respectful'] ?? json['wasRespectful'] ?? json['respect']) as bool? ?? false,
      didListen: (json['did_listen'] ?? json['didListen']) as bool? ?? false,
      note: (json['note'] ?? json['review_text']) as String?,
      callType: (json['call_type'] ?? json['callType']) as String? ?? 'voice',
      callDurationSeconds: (json['call_duration_seconds'] ?? json['callDurationSeconds']) as int? ?? 0,
      createdAt: parsedDate,
    );
  }
}

/// Service to handle CRI (Character Rating Index) calculations in Supabase.
class CriService {
  CriService._();
  static final CriService instance = CriService._();

  String get _myUid => supabaseInitialized ? (SupabaseAuthService.instance.currentUser?.id ?? '') : '';

  /// Submit a review about a user after a call.
  Future<void> submitReview({
    required String reviewedUserId,
    required double empathyScore,
    required bool wasRespectful,
    required bool didListen,
    String? note,
    required String callType,
    required int callDurationSeconds,
  }) async {
    if (!supabaseInitialized || _myUid.isEmpty) return;

    final review = UserReview(
      id: '',
      reviewerId: _myUid,
      reviewedUserId: reviewedUserId,
      empathyScore: empathyScore,
      wasRespectful: wasRespectful,
      didListen: didListen,
      note: note,
      callType: callType,
      callDurationSeconds: callDurationSeconds,
      createdAt: DateTime.now(),
    );

    // 1. Store the review
    await Supabase.instance.client.from('reviews').insert(review.toJson());

    // 2. Update the reviewed user's aggregate CRI stats
    await _recalculateCRI(reviewedUserId);

    // 3. Track total calls for both users
    try {
      final myUser = await Supabase.instance.client.from('users').select().eq('id', _myUid).maybeSingle();
      if (myUser != null) {
        final myCalls = (myUser['total_calls'] ?? myUser['totalCalls']) as int? ?? 0;
        final myDuration = (myUser['total_call_duration'] ?? myUser['totalCallDuration']) as int? ?? 0;
        await Supabase.instance.client.from('users').update({
          'total_calls': myCalls + 1,
          'total_call_duration': myDuration + callDurationSeconds,
        }).eq('id', _myUid);
      }

      final reviewedUser = await Supabase.instance.client.from('users').select().eq('id', reviewedUserId).maybeSingle();
      if (reviewedUser != null) {
        final otherCalls = (reviewedUser['total_calls'] ?? reviewedUser['totalCalls']) as int? ?? 0;
        final otherDuration = (reviewedUser['total_call_duration'] ?? reviewedUser['totalCallDuration']) as int? ?? 0;
        await Supabase.instance.client.from('users').update({
          'total_calls': otherCalls + 1,
          'total_call_duration': otherDuration + callDurationSeconds,
        }).eq('id', reviewedUserId);
      }
    } catch (_) {}
  }

  /// Recalculate CRI for a user based on all their reviews.
  Future<void> _recalculateCRI(String userId) async {
    try {
      final list = await Supabase.instance.client
          .from('reviews')
          .select()
          .eq('reviewed_user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      if (list.isEmpty) return;

      final reviews = list.map((map) => UserReview.fromJson(map)).toList();
      final count = reviews.length;

      // Empathy average (0-10) → scaled to 0-400
      final empathyAvg = reviews.fold(0.0, (sum, r) => sum + r.empathyScore) / count;
      final empathyPart = (empathyAvg / 10.0) * 400;

      // Respectfulness rate → scaled to 0-300
      final respectCount = reviews.where((r) => r.wasRespectful).length;
      final respectPart = (respectCount / count) * 300;

      // Listening rate → scaled to 0-200
      final listenCount = reviews.where((r) => r.didListen).length;
      final listenPart = (listenCount / count) * 200;

      // Engagement bonus (based on call count) → up to 100
      final engagementPart = (count >= 20 ? 100 : count * 5).toDouble();

      final criScore = (empathyPart + respectPart + listenPart + engagementPart).round().clamp(0, 1000);

      await Supabase.instance.client.from('users').update({
        'cri_score': criScore,
        'total_reviews': count,
        'avg_empathy': double.parse(empathyAvg.toStringAsFixed(1)),
        'respect_rate': double.parse(((respectCount / count) * 100).toStringAsFixed(0)),
        'listen_rate': double.parse(((listenCount / count) * 100).toStringAsFixed(0)),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error recalculating CRI on Supabase: $e');
    }
  }

  /// Get reviews for a specific user.
  Stream<List<UserReview>> getReviewsForUser(String userId) {
    if (!supabaseInitialized) return const Stream.empty();
    return Supabase.instance.client
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('reviewed_user_id', userId)
        .map((list) {
          final mapped = list.map((map) => UserReview.fromJson(map)).toList();
          mapped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return mapped.take(20).toList();
        });
  }
}
