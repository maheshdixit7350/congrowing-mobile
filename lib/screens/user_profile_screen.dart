import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  bool _isFollowing = false;
  bool _isFollowedBy = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = await UserService.instance.getUserById(widget.userId);
      if (user != null) {
        final following = await UserService.instance.isFollowing(widget.userId);
        final followedBy = await UserService.instance.isFollowedBy(widget.userId);
        if (mounted) {
          setState(() {
            _user = user;
            _isFollowing = following;
            _isFollowedBy = followedBy;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;
    final originalState = _isFollowing;
    setState(() {
      _isFollowing = !_isFollowing;
    });

    try {
      if (originalState) {
        await UserService.instance.unfollowUser(_user!.id);
      } else {
        await UserService.instance.followUser(_user!.id);
      }
      // Reload stats
      final updatedUser = await UserService.instance.getUserById(_user!.id);
      if (updatedUser != null && mounted) {
        setState(() {
          _user = updatedUser;
        });
      }
    } catch (e) {
      setState(() {
        _isFollowing = originalState;
      });
      debugPrint('Error toggling follow: $e');
    }
  }

  Future<void> _startChat() async {
    if (_user == null) return;
    final chatId = await ChatService.instance.getOrCreateChatRoom(_user!.id);
    if (chatId.isNotEmpty && mounted) {
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'otherUser': _user!,
        },
      );
    }
  }

  String _criLabel(int s) {
    if (s >= 900) return 'Diamond';
    if (s >= 700) return 'Gold';
    if (s >= 500) return 'Silver';
    if (s >= 300) return 'Bronze';
    return 'Starter';
  }

  Color _criColor(int s) {
    if (s >= 900) return const Color(0xFF60A5FA);
    if (s >= 700) return const Color(0xFFFBBF24);
    if (s >= 500) return const Color(0xFFD1D5DB);
    if (s >= 300) return const Color(0xFFF97316);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FC);
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final textMain = isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final textSub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => safeNavigateBack(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'User profile not found',
            style: GoogleFonts.inter(color: textSub, fontSize: 16),
          ),
        ),
      );
    }

    final initial = _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?';
    final criLabel = _criLabel(_user!.criScore);
    final criColor = _criColor(_user!.criScore);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () => safeNavigateBack(context),
            ),
            backgroundColor: const Color(0xFF3D0099),
            title: Text(
              '@${_user!.username}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Top Banner background
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3D0099), Color(0xFF6B21A8), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Profile Avatar positioned overlapping banner
                Positioned(
                  bottom: -40,
                  left: 24,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: _user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _user!.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Container(color: Colors.grey.shade200),
                                errorWidget: (c, u, e) => const Icon(Icons.person, size: 40),
                              )
                            : Container(
                                color: AppColors.primary.withOpacity(0.1),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user!.name,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textMain,
                              ),
                            ),
                            Text(
                              '@${_user!.username}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: textSub,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // CRI score badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: criColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: criColor.withOpacity(0.3), width: 1),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_user!.criScore}',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: criColor,
                              ),
                            ),
                            Text(
                              criLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: criColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                    Text(
                      _user!.bio!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textMain,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_user!.college != null && _user!.college!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.school_outlined, size: 16, color: textSub),
                        const SizedBox(width: 8),
                        Text(
                          _user!.college!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textSub,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Connection stats cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        'Friends',
                        _user!.friendsCount,
                        () => Navigator.pushNamed(context, '/connections', arguments: {
                          'userId': _user!.id,
                          'tabIndex': 0,
                        }),
                        cardColor,
                        textMain,
                        textSub,
                      ),
                      _buildStatCard(
                        'Followers',
                        _user!.followersCount,
                        () => Navigator.pushNamed(context, '/connections', arguments: {
                          'userId': _user!.id,
                          'tabIndex': 1,
                        }),
                        cardColor,
                        textMain,
                        textSub,
                      ),
                      _buildStatCard(
                        'Following',
                        _user!.followingCount,
                        () => Navigator.pushNamed(context, '/connections', arguments: {
                          'userId': _user!.id,
                          'tabIndex': 2,
                        }),
                        cardColor,
                        textMain,
                        textSub,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Call/Chat/Follow action buttons
                  Row(
                    children: [
                      // Chat button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startChat,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardColor,
                            foregroundColor: textMain,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Follow Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: !_isFollowing
                                ? const LinearGradient(
                                    colors: [AppColors.primary, Color(0xFF2DD4BF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            boxShadow: !_isFollowing
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: ElevatedButton(
                            onPressed: _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing ? Colors.transparent : Colors.transparent,
                              foregroundColor: _isFollowing ? AppColors.primary : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: _isFollowing ? const BorderSide(color: AppColors.primary) : BorderSide.none,
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _isFollowing
                                  ? 'Following'
                                  : (_isFollowedBy ? 'Follow Back' : 'Follow'),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    VoidCallback onTap,
    Color cardColor,
    Color textMain,
    Color textSub,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
