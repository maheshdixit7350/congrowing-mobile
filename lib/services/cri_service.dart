import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart' show firebaseInitialized;

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
    'reviewerId': reviewerId,
    'reviewedUserId': reviewedUserId,
    'empathyScore': empathyScore,
    'wasRespectful': wasRespectful,
    'didListen': didListen,
    'note': note,
    'callType': callType,
    'callDurationSeconds': callDurationSeconds,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory UserReview.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserReview(
      id: doc.id,
      reviewerId: d['reviewerId'] ?? '',
      reviewedUserId: d['reviewedUserId'] ?? '',
      empathyScore: (d['empathyScore'] as num?)?.toDouble() ?? 5.0,
      wasRespectful: d['wasRespectful'] as bool? ?? false,
      didListen: d['didListen'] as bool? ?? false,
      note: d['note'] as String?,
      callType: d['callType'] as String? ?? 'voice',
      callDurationSeconds: d['callDurationSeconds'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Service to handle CRI (Character Rating Index) calculations.
class CriService {
  CriService._();
  static final CriService instance = CriService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

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
    if (!firebaseInitialized || _myUid.isEmpty) return;

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
    await _db.collection('reviews').add(review.toJson());

    // 2. Update the reviewed user's aggregate CRI stats
    await _recalculateCRI(reviewedUserId);

    // 3. Track total calls for both users
    await _db.collection('users').doc(_myUid).update({
      'totalCalls': FieldValue.increment(1),
      'totalCallDuration': FieldValue.increment(callDurationSeconds),
    });
    await _db.collection('users').doc(reviewedUserId).update({
      'totalCalls': FieldValue.increment(1),
      'totalCallDuration': FieldValue.increment(callDurationSeconds),
    });
  }

  /// Recalculate CRI for a user based on all their reviews.
  ///
  /// CRI Formula (0-1000 scale):
  /// - Empathy average (40% weight)  → max 400
  /// - Respectfulness rate (30% weight) → max 300
  /// - Listening rate (20% weight) → max 200
  /// - Engagement bonus (10% weight) → max 100
  Future<void> _recalculateCRI(String userId) async {
    try {
      final reviewsSnap = await _db
          .collection('reviews')
          .where('reviewedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50) // Use last 50 reviews for fairness
          .get();

      if (reviewsSnap.docs.isEmpty) return;

      final reviews = reviewsSnap.docs.map(UserReview.fromFirestore).toList();
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

      await _db.collection('users').doc(userId).update({
        'criScore': criScore,
        'totalReviews': count,
        'avgEmpathy': double.parse(empathyAvg.toStringAsFixed(1)),
        'respectRate': double.parse(((respectCount / count) * 100).toStringAsFixed(0)),
        'listenRate': double.parse(((listenCount / count) * 100).toStringAsFixed(0)),
      });
    } catch (_) {
      // Silently fail
    }
  }

  /// Get reviews for a specific user.
  Stream<List<UserReview>> getReviewsForUser(String userId) {
    if (!firebaseInitialized) return const Stream.empty();
    return _db
        .collection('reviews')
        .where('reviewedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map(UserReview.fromFirestore).toList());
  }
}
