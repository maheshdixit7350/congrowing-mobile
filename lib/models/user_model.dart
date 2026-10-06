// UserModel for ConGrowing

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
  final String? state;
  final String? phone;
  final int criScore;
  final String? personalityType;
  final bool onboardingComplete;
  final int postsCount;
  final int friendsCount;
  final int followersCount;
  final int followingCount;
  final bool isOnline;
  final DateTime? lastSeen;
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
    this.state,
    this.phone,
    this.criScore = 0,
    this.personalityType,
    this.onboardingComplete = false,
    this.postsCount = 0,
    this.friendsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isOnline = false,
    this.lastSeen,
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
    String? state,
    String? phone,
    int? criScore,
    String? personalityType,
    bool? onboardingComplete,
    int? postsCount,
    int? friendsCount,
    int? followersCount,
    int? followingCount,
    bool? isOnline,
    DateTime? lastSeen,
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
      state: state ?? this.state,
      phone: phone ?? this.phone,
      criScore: criScore ?? this.criScore,
      personalityType: personalityType ?? this.personalityType,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      postsCount: postsCount ?? this.postsCount,
      friendsCount: friendsCount ?? this.friendsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
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
      'avatar_url': avatarUrl,
      'bio': bio,
      'college': college,
      'gender': gender,
      'country': country,
      'state': state,
      'phone': phone,
      'criScore': criScore,
      'cri_score': criScore,
      'personalityType': personalityType,
      'personality_type': personalityType,
      'onboardingComplete': onboardingComplete,
      'onboarding_complete': onboardingComplete,
      'postsCount': postsCount,
      'posts_count': postsCount,
      'friendsCount': friendsCount,
      'friends_count': friendsCount,
      'followersCount': followersCount,
      'followers_count': followersCount,
      'followingCount': followingCount,
      'following_count': followingCount,
      'isOnline': isOnline,
      'is_online': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'last_seen': lastSeen?.toIso8601String(),
      'isPremium': isPremium,
      'is_premium': isPremium,
      'voiceCallEnabled': voiceCallEnabled,
      'voice_call_enabled': voiceCallEnabled,
      'createdAt': createdAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'totalReviews': totalReviews,
      'total_reviews': totalReviews,
      'avgEmpathy': avgEmpathy,
      'avg_empathy': avgEmpathy,
      'respectRate': respectRate,
      'respect_rate': respectRate,
      'listenRate': listenRate,
      'listen_rate': listenRate,
      'totalCalls': totalCalls,
      'total_calls': totalCalls,
      'totalCallDuration': totalCallDuration,
      'total_call_duration': totalCallDuration,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final raw = json['createdAt'] ?? json['created_at'];
    if (raw is String) {
      parsedDate = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      bio: json['bio'] as String?,
      college: json['college'] as String?,
      gender: json['gender'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      phone: json['phone'] as String?,
      criScore: (json['criScore'] ?? json['cri_score']) as int? ?? 0,
      personalityType: (json['personalityType'] ?? json['personality_type']) as String?,
      onboardingComplete: (json['onboardingComplete'] ?? json['onboarding_complete']) as bool? ?? false,
      postsCount: (json['postsCount'] ?? json['posts_count']) as int? ?? 0,
      friendsCount: (json['friendsCount'] ?? json['friends_count']) as int? ?? 0,
      followersCount: (json['followersCount'] ?? json['followers_count']) as int? ?? 0,
      followingCount: (json['followingCount'] ?? json['following_count']) as int? ?? 0,
      isOnline: (json['isOnline'] ?? json['is_online']) as bool? ?? false,
      lastSeen: _parseDateTime(json['lastSeen'] ?? json['last_seen']),
      isPremium: (json['isPremium'] ?? json['is_premium']) as bool? ?? false,
      voiceCallEnabled: (json['voiceCallEnabled'] ?? json['voice_call_enabled']) as bool? ?? true,
      createdAt: parsedDate,
      totalReviews: (json['totalReviews'] ?? json['total_reviews']) as int? ?? 0,
      avgEmpathy: ((json['avgEmpathy'] ?? json['avg_empathy']) as num?)?.toDouble() ?? 5.0,
      respectRate: ((json['respectRate'] ?? json['respect_rate']) as num?)?.toDouble() ?? 0.0,
      listenRate: ((json['listenRate'] ?? json['listen_rate']) as num?)?.toDouble() ?? 0.0,
      totalCalls: (json['totalCalls'] ?? json['total_calls']) as int? ?? 0,
      totalCallDuration: (json['totalCallDuration'] ?? json['total_call_duration']) as int? ?? 0,
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
