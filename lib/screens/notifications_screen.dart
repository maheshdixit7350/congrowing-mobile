import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../services/thoughts_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<String> _myFollowingIds = {};
  bool _loadingFollows = false;

  @override
  void initState() {
    super.initState();
    _loadMyFollows();
  }

  Future<void> _loadMyFollows() async {
    final myUid = UserService.instance.currentUser?.id;
    if (myUid == null) return;
    setState(() => _loadingFollows = true);
    try {
      final following = await UserService.instance.getFollowing(myUid);
      if (mounted) {
        setState(() {
          _myFollowingIds.clear();
          _myFollowingIds.addAll(following.map((u) => u.id));
          _loadingFollows = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingFollows = false);
    }
  }

  Future<void> _followBack(String targetUid) async {
    setState(() {
      _myFollowingIds.add(targetUid);
    });
    await UserService.instance.followUser(targetUid);
    _loadMyFollows();
  }

  IconData _getBadgeIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'cri_update':
        return Icons.trending_up_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getBadgeColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return AppColors.primary;
      case 'cri_update':
        return Colors.green;
      case 'achievement':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = UserService.instance.currentUser;

    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FC);
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final textMain = isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final textSub =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => safeNavigateBack(context),
        ),
        title: Text('Notifications',
            style:
                GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (currentUser != null)
            TextButton(
              onPressed: () =>
                  NotificationService.instance.markAllRead(currentUser.id),
              child: Text('Mark all read',
                  style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
        ],
      ),
      body: currentUser == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : StreamBuilder<List<AppNotification>>(
              stream: NotificationService.instance
                  .streamNotifications(currentUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                final notifs = snapshot.data ?? [];
                if (notifs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none_rounded,
                                color: AppColors.primary, size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textMain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Activity like matches, comments and follows will show up here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textSub,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: notifs.length,
                  itemBuilder: (context, index) {
                    final n = notifs[index];
                    final timeStr = ThoughtsService.getTimeAgo(n.createdAt);
                    final isNew = !n.isRead;
                    final isFollowing = _myFollowingIds.contains(n.actorId);

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/user-profile',
                          arguments: {'userId': n.actorId},
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isNew
                                ? AppColors.primary.withOpacity(0.15)
                                : (isDark
                                    ? Colors.grey.shade900
                                    : Colors.grey.shade100),
                            width: isNew ? 1.5 : 1,
                          ),
                          boxShadow: isNew
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            // Actor profile avatar with badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                n.actorAvatarUrl != null &&
                                        n.actorAvatarUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: n.actorAvatarUrl!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                        ),
                                        child: Center(
                                          child: Text(
                                            n.actorName != null &&
                                                    n.actorName!.isNotEmpty
                                                ? n.actorName![0].toUpperCase()
                                                : '?',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                Positioned(
                                  bottom: -4,
                                  right: -4,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _getBadgeColor(n.type),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: cardColor, width: 2),
                                    ),
                                    child: Icon(_getBadgeIcon(n.type),
                                        color: Colors.white, size: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            // User Info and text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(
                                          fontSize: 13, color: textMain),
                                      children: [
                                        TextSpan(
                                          text: n.actorName ?? 'Someone',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                            text:
                                                ' ${n.message ?? "interacted with you"}'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    timeStr,
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: textSub),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Action buttons
                            if (n.type == 'follow' && !isFollowing)
                              GestureDetector(
                                onTap: () => _followBack(n.actorId),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Follow Back',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
