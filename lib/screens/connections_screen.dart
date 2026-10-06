import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';

class ConnectionsScreen extends StatefulWidget {
  final String? userId;
  final int initialTabIndex; // 0 = Friends, 1 = Followers, 2 = Following

  const ConnectionsScreen({
    super.key,
    this.userId,
    this.initialTabIndex = 0,
  });

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late String _targetUid;

  List<UserModel> _friends = [];
  List<UserModel> _followers = [];
  List<UserModel> _following = [];

  bool _loading = true;
  final Set<String> _myFollowingIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _targetUid = widget.userId ?? UserService.instance.currentUser?.id ?? '';
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_targetUid.isEmpty) return;
    setState(() => _loading = true);

    try {
      final myUid = UserService.instance.currentUser?.id;
      
      // Load target user's connections
      final friendsFuture = UserService.instance.getFriends(_targetUid);
      final followersFuture = UserService.instance.getFollowers(_targetUid);
      final followingFuture = UserService.instance.getFollowing(_targetUid);

      // Load current user's following list (for rendering Follow/Unfollow buttons correctly)
      Future<List<UserModel>> myFollowingFuture;
      if (myUid != null && myUid != _targetUid) {
        myFollowingFuture = UserService.instance.getFollowing(myUid);
      } else {
        myFollowingFuture = Future.value([]);
      }

      final results = await Future.wait([
        friendsFuture,
        followersFuture,
        followingFuture,
        myFollowingFuture,
      ]);

      if (mounted) {
        setState(() {
          _friends = results[0];
          _followers = results[1];
          _following = results[2];

          final myFollowingList = results[3];
          if (myUid == _targetUid) {
            // If viewing own connections, we follow everyone in the "following" list and "friends" list
            _myFollowingIds.addAll(_following.map((u) => u.id));
            _myFollowingIds.addAll(_friends.map((u) => u.id));
          } else {
            _myFollowingIds.addAll(myFollowingList.map((u) => u.id));
          }

          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading connections: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow(UserModel user) async {
    final targetUid = user.id;
    final isFollowing = _myFollowingIds.contains(targetUid);

    setState(() {
      if (isFollowing) {
        _myFollowingIds.remove(targetUid);
      } else {
        _myFollowingIds.add(targetUid);
      }
    });

    if (isFollowing) {
      await UserService.instance.unfollowUser(targetUid);
    } else {
      await UserService.instance.followUser(targetUid);
    }
    
    // Reload lists to keep totals and states accurate
    _loadData();
  }

  Future<void> _startChat(UserModel user) async {
    final chatId = await ChatService.instance.getOrCreateChatRoom(user.id);
    if (chatId.isNotEmpty && mounted) {
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'otherUser': user,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwn = _targetUid == UserService.instance.currentUser?.id;

    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FC);
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final textMain = isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final textSub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => safeNavigateBack(context),
        ),
        title: Text(
          isOwn ? 'My Connections' : 'Connections',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textMain,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: textSub,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(_friends, 'No friends yet', 'Mutual follows will show up here as friends.', Icons.people_outline, textMain, textSub, cardColor, isDark),
                _buildList(_followers, 'No followers', 'People following you will appear here.', Icons.favorite_border_rounded, textMain, textSub, cardColor, isDark),
                _buildList(_following, 'Not following anyone', 'People you follow will show up here.', Icons.person_add_alt_1_outlined, textMain, textSub, cardColor, isDark),
              ],
            ),
    );
  }

  Widget _buildList(
    List<UserModel> list,
    String emptyTitle,
    String emptySubtitle,
    IconData emptyIcon,
    Color textMain,
    Color textSub,
    Color cardColor,
    bool isDark,
  ) {
    if (list.isEmpty) {
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
                child: Icon(emptyIcon, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final u = list[index];
        final isFollowing = _myFollowingIds.contains(u.id);
        final isMe = u.id == UserService.instance.currentUser?.id;
        final initial = u.name.isNotEmpty ? u.name[0].toUpperCase() : '?';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/user-profile',
                      arguments: {'userId': u.id},
                    );
                  },
                  child: Row(
                    children: [
                      // Avatar
                      u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: u.avatarUrl!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(width: 14),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${u.username}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Actions
              if (!isMe) ...[
                // Chat button for Friends
                if (_tabCtrl.index == 0) ...[
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary, size: 22),
                    onPressed: () => _startChat(u),
                  ),
                  const SizedBox(width: 4),
                ],
                // Follow / Unfollow Toggle
                GestureDetector(
                  onTap: () => _toggleFollow(u),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFollowing ? Colors.transparent : AppColors.primary,
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isFollowing
                          ? 'Following'
                          : (_tabCtrl.index == 1 ? 'Follow Back' : 'Follow'),
                      style: GoogleFonts.inter(
                        color: isFollowing ? AppColors.primary : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
