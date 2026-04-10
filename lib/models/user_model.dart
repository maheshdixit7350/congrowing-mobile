import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String? college;
  final String? gender;
  final String? country;
  final String? phone;
  final int criScore;
  final int postsCount;
  final int friendsCount;
  final int followersCount;
  final bool isOnline;
  final bool isPremium;
  final bool voiceCallEnabled;
  final DateTime createdAt;
  
  // CRI metrics (Calculated by CriService)
  final int totalReviews;
  final double avgEmpathy;
  final double respectRate;
  final double listenRate;
  final int totalCalls;
  final int totalCallDuration;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.college,
    this.gender,
    this.country,
    this.phone,
    this.criScore = 0,
    this.postsCount = 0,
    this.friendsCount = 0,
    this.followersCount = 0,
    this.isOnline = false,
    this.isPremium = false,
    this.voiceCallEnabled = true,
    required this.createdAt,
    this.totalReviews = 0,
    this.avgEmpathy = 5.0,
    this.respectRate = 0.0,
    this.listenRate = 0.0,
    this.totalCalls = 0,
    this.totalCallDuration = 0,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    String? college,
    String? gender,
    String? country,
    String? phone,
    int? criScore,
    int? postsCount,
    int? friendsCount,
    int? followersCount,
    bool? isOnline,
    bool? isPremium,
    bool? voiceCallEnabled,
    DateTime? createdAt,
    int? totalReviews,
    double? avgEmpathy,
    double? respectRate,
    double? listenRate,
    int? totalCalls,
    int? totalCallDuration,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      college: college ?? this.college,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      criScore: criScore ?? this.criScore,
      postsCount: postsCount ?? this.postsCount,
      friendsCount: friendsCount ?? this.friendsCount,
      followersCount: followersCount ?? this.followersCount,
      isOnline: isOnline ?? this.isOnline,
      isPremium: isPremium ?? this.isPremium,
      voiceCallEnabled: voiceCallEnabled ?? this.voiceCallEnabled,
      createdAt: createdAt ?? this.createdAt,
      totalReviews: totalReviews ?? this.totalReviews,
      avgEmpathy: avgEmpathy ?? this.avgEmpathy,
      respectRate: respectRate ?? this.respectRate,
      listenRate: listenRate ?? this.listenRate,
      totalCalls: totalCalls ?? this.totalCalls,
      totalCallDuration: totalCallDuration ?? this.totalCallDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'college': college,
      'gender': gender,
      'country': country,
      'phone': phone,
      'criScore': criScore,
      'postsCount': postsCount,
      'friendsCount': friendsCount,
      'followersCount': followersCount,
      'isOnline': isOnline,
      'isPremium': isPremium,
      'voiceCallEnabled': voiceCallEnabled,
      'createdAt': createdAt.toIso8601String(),
      'totalReviews': totalReviews,
      'avgEmpathy': avgEmpathy,
      'respectRate': respectRate,
      'listenRate': listenRate,
      'totalCalls': totalCalls,
      'totalCallDuration': totalCallDuration,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final raw = json['createdAt'];
    if (raw is Timestamp) {
      parsedDate = raw.toDate();
    } else if (raw is String) {
      parsedDate = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      college: json['college'] as String?,
      gender: json['gender'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      criScore: json['criScore'] as int? ?? 0,
      postsCount: json['postsCount'] as int? ?? 0,
      friendsCount: json['friendsCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      voiceCallEnabled: json['voiceCallEnabled'] as bool? ?? true,
      createdAt: parsedDate,
      totalReviews: json['totalReviews'] as int? ?? 0,
      avgEmpathy: (json['avgEmpathy'] as num?)?.toDouble() ?? 5.0,
      respectRate: (json['respectRate'] as num?)?.toDouble() ?? 0.0,
      listenRate: (json['listenRate'] as num?)?.toDouble() ?? 0.0,
      totalCalls: json['totalCalls'] as int? ?? 0,
      totalCallDuration: json['totalCallDuration'] as int? ?? 0,
    );
  }
}
