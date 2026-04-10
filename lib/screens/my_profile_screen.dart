import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadUser();
  }

  void _loadUser() {
    _user = UserService.instance.currentUser;
    UserService.instance.listenToCurrentUser((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _user;
    final name = user?.name ?? 'User';
    final username = user?.username ?? 'user';
    final bio = user?.bio ?? '';
    final college = user?.college ?? '';
    final cri = user?.criScore ?? 0;
    final posts = user?.postsCount ?? 0;
    final friends = user?.friendsCount ?? 0;
    final followers = user?.followersCount ?? 0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (ctx, inner) => [
                  SliverAppBar(
                    backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                    leading: null,
                    automaticallyImplyLeading: false,
                    title: GestureDetector(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 18),
                          const SizedBox(width: 4),
                          Text('@$username', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
                          const Icon(Icons.expand_more_rounded, size: 16),
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Cover photo
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF0F2F44), const Color(0xFF1A4A6B)]
                                  : [AppColors.primary.withAlpha(40), AppColors.primary.withAlpha(80)],
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.camera_alt_outlined, color: Colors.white.withAlpha(100), size: 32),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(0, -40),
                                    child: Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                                          width: 4,
                                        ),
                                        color: AppColors.primary.withAlpha(40),
                                      ),
                                      child: user?.avatarUrl != null
                                          ? ClipOval(child: Image.network(user!.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildInitial(initial, 32)))
                                          : _buildInitial(initial, 32),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => Navigator.pushNamed(context, '/cri-analytics'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.cardDark : Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 14),
                                                const SizedBox(width: 4),
                                                ShaderMask(
                                                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                                                  child: Text('CRI: $cri',
                                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                                            ),
                                            child: Text('Edit Profile', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Transform.translate(
                                offset: const Offset(0, -28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
                                    Text('@$username', style: GoogleFonts.inter(color: AppColors.textSecondaryLight, fontSize: 13)),
                                    if (college.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(college, style: GoogleFonts.inter(fontSize: 13)),
                                    ],
                                    if (bio.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(bio, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ],
                                ),
                              ),
                              // Stats
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    _StatItem(count: '$posts', label: 'Posts'),
                                    Container(width: 1, height: 30, color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                                    _StatItem(count: '$friends', label: 'Friends'),
                                    Container(width: 1, height: 30, color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                                    _StatItem(count: '$followers', label: 'Followers'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      TabBar(
                        controller: _tabCtrl,
                        indicatorColor: AppColors.primary,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondaryLight,
                        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                        tabs: const [Tab(text: 'Posts'), Tab(text: 'Videos'), Tab(text: 'Tagged')],
                      ),
                      isDark: isDark,
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildEmptyTab(Icons.photo_library_outlined, 'No posts yet', 'Share your first post!'),
                    _buildEmptyTab(Icons.videocam_outlined, 'No videos yet', 'Upload a video to get started'),
                    _buildEmptyTab(Icons.tag_rounded, 'No tagged posts', 'Posts you\'re tagged in will appear here'),
                  ],
                ),
              ),
            ),
            BottomNavBar(currentIndex: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial(String initial, double fontSize) {
    return Center(
      child: Text(initial, style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: fontSize)),
    );
  }

  Widget _buildEmptyTab(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(count, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;
  const _TabBarDelegate(this.tabBar, {required this.isDark});

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight, child: tabBar);
  }

  @override bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
