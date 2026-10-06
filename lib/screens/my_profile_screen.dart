import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

// ── 15 built-in gradient themes ───────────────────────────────────────────────
const List<List<Color>> _kBgThemes = [
  [Color(0xFF3D0099), Color(0xFF6B21A8), Color(0xFF1D4ED8)],
  [Color(0xFF0F2F44), Color(0xFF1A4A6B), Color(0xFF06B6D4)],
  [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF59E0B)],
  [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF0284C7)],
  [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
  [Color(0xFF7F1D1D), Color(0xFF991B1B), Color(0xFFDC2626)],
  [Color(0xFF134E4A), Color(0xFF0F766E), Color(0xFF14B8A6)],
  [Color(0xFF1E3A5F), Color(0xFF1D4ED8), Color(0xFF7C3AED)],
  [Color(0xFF3B0764), Color(0xFF7E22CE), Color(0xFFDB2777)],
  [Color(0xFF052E16), Color(0xFF14532D), Color(0xFF16A34A)],
  [Color(0xFF0C4A6E), Color(0xFF075985), Color(0xFF0284C7)],
  [Color(0xFF431407), Color(0xFF9A3412), Color(0xFFEA580C)],
  [Color(0xFF1C1917), Color(0xFF292524), Color(0xFF57534E)],
  [Color(0xFF0D0D1A), Color(0xFF1A0533), Color(0xFF0D1A33)],
  [Color(0xFF4A044E), Color(0xFF86198F), Color(0xFFC026D3)],
];

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _chartAnimCtrl;
  UserModel? _user;
  int _bgThemeIndex = 0;
  bool _hideGraph = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _chartAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..forward();
    _loadUser();
    _loadPrefs();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _chartAnimCtrl.dispose();
    super.dispose();
  }

  void _loadUser() {
    _user = UserService.instance.currentUser;
    UserService.instance.listenToCurrentUser((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _bgThemeIndex = prefs.getInt('profile_bg_theme') ?? 0;
        _hideGraph = prefs.getBool('profile_hide_graph') ?? false;
      });
    }
  }

  Future<void> _saveBgTheme(int i) async =>
      (await SharedPreferences.getInstance()).setInt('profile_bg_theme', i);
  Future<void> _saveHideGraph(bool v) async =>
      (await SharedPreferences.getInstance()).setBool('profile_hide_graph', v);

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
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

  // ── Theme picker bottom sheet ─────────────────────────────────────────────
  void _showThemePicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Background Theme',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 4),
              Text('Choose a gradient for your profile banner',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _kBgThemes.length,
                itemBuilder: (_, i) {
                  final selected = _bgThemeIndex == i;
                  return GestureDetector(
                    onTap: () {
                      setBS(() {});
                      setState(() => _bgThemeIndex = i);
                      _saveBgTheme(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _kBgThemes[i],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: _kBgThemes[i][0].withOpacity(0.6),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              // Privacy toggle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.grey.shade900 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.visibility_off_outlined,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hide CRI Graph',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? Colors.white : Colors.black87)),
                          Text('Only you can see the candlestick chart',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    StatefulBuilder(
                      builder: (_, setSw) => Switch(
                        activeThumbColor: AppColors.primary,
                        value: _hideGraph,
                        onChanged: (v) {
                          setSw(() {});
                          setState(() => _hideGraph = v);
                          _saveHideGraph(v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _user;
    final name = user?.name ?? 'User';
    final uname = user?.username ?? 'user';
    final bio = user?.bio ?? '';
    final college = user?.college ?? '';
    final cri = user?.criScore ?? 0;
    final posts = user?.postsCount ?? 0;
    final friends = user?.friendsCount ?? 0;
    final followers = user?.followersCount ?? 0;
    final following = user?.followingCount ?? 0;
    final isPremium = user?.isPremium ?? false;
    final isActive = (user?.totalCalls ?? 0) > 3;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final criLabel = _criLabel(cri);
    final criColor = _criColor(cri);

    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FC);
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final textMain = isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final textSub =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgColors = _kBgThemes[_bgThemeIndex.clamp(0, _kBgThemes.length - 1)];

    // ── Header height constants ──────────────────────────────────────────
    const double kGradientH = 200.0; // height of gradient/candlestick banner
    const double kAvatarSize = 88.0; // avatar diameter
    const double kOverlap = 44.0; // how much avatar overlaps the gradient

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                // ═══ KEY FIX #1: ClampingScrollPhysics stops overscroll stretching ═══
                physics: const ClampingScrollPhysics(),
                headerSliverBuilder: (ctx, _) => [
                  // ── 1. Slim pinned title bar ─────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    toolbarHeight: 52,
                    backgroundColor: bgColors[0],
                    automaticallyImplyLeading: false,
                    title: Text(
                      '@$uname',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.palette_outlined,
                            color: Colors.white, size: 22),
                        onPressed: () => _showThemePicker(isDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),

                  // ── 2. Profile Header (Banner + Avatar + Info) ─────────────
                  // ═══ FIX: Combined into one SliverToBoxAdapter using Stack ══
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Gradient banner
                            SizedBox(
                              height: kGradientH,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Gradient fill
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: bgColors,
                                      ),
                                    ),
                                  ),
                                  // Decorative bubbles
                                  Positioned(
                                    top: -50,
                                    right: -30,
                                    child: Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -20,
                                    left: -40,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.04),
                                      ),
                                    ),
                                  ),
                                  // Animated Candlestick chart
                                  if (!_hideGraph)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      height: kGradientH * 0.7,
                                      child: AnimatedBuilder(
                                        animation: _chartAnimCtrl,
                                        builder: (context, _) => LayoutBuilder(
                                          builder: (context, constraints) {
                                            final size = Size(
                                                constraints.maxWidth,
                                                constraints.maxHeight);
                                            final endOffset =
                                                _SmoothLineChartPainter
                                                    .getEndOffset(
                                              size,
                                              cri,
                                              isActive,
                                              _chartAnimCtrl.value,
                                            );
                                            return Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Positioned.fill(
                                                  child: CustomPaint(
                                                    painter:
                                                        _SmoothLineChartPainter(
                                                      criScore: cri,
                                                      isActive: isActive,
                                                      animationValue:
                                                          _chartAnimCtrl.value,
                                                    ),
                                                  ),
                                                ),
                                                if (_chartAnimCtrl.value <
                                                        1.0 &&
                                                    endOffset != Offset.zero)
                                                  Positioned(
                                                    left: endOffset.dx - 14,
                                                    top: endOffset.dy - 14,
                                                    child: _buildSmallAvatar(
                                                      initial: initial,
                                                      avatarUrl:
                                                          user?.avatarUrl,
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  // Chart label
                                  if (!_hideGraph)
                                    Positioned(
                                      bottom: 10,
                                      right: 14,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.35),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons
                                                    .candlestick_chart_outlined,
                                                color: Colors.white70,
                                                size: 11),
                                            const SizedBox(width: 4),
                                            Text('10-day CRI',
                                                style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  // Premium badge
                                  if (isPremium)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD700),
                                              Color(0xFFFF8C00)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text('PRO',
                                            style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white)),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Avatar + buttons row
                            Positioned(
                              top: kGradientH - kOverlap,
                              left: 16,
                              right: 16,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildAvatar(
                                    initial: initial,
                                    cri: cri,
                                    avatarUrl: user?.avatarUrl,
                                    isDark: isDark,
                                    criColor: criColor,
                                    size: kAvatarSize,
                                  ),
                                  const Spacer(),
                                  // CRI chip
                                  _chip(
                                    icon: Icons.insights_rounded,
                                    label: 'CRI $cri',
                                    gradient: AppColors.primaryGradient,
                                    textColor: Colors.white,
                                    onTap: () => Navigator.pushNamed(
                                        context, '/cri-analytics'),
                                  ),
                                  const SizedBox(width: 8),
                                  // Edit button
                                  _chip(
                                    icon: Icons.edit_rounded,
                                    label: 'Edit',
                                    background: isDark
                                        ? AppColors.cardDark
                                        : Colors.white,
                                    border: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                    textColor: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade800,
                                    onTap: () => Navigator.pushNamed(
                                        context, '/edit-profile'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Space for the avatar overhang
                        const SizedBox(height: kAvatarSize - kOverlap),

                        // Name / bio / tier
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + verified
                              Row(
                                children: [
                                  Text(name,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                        color: textMain,
                                      )),
                                  if (isPremium) ...[
                                    const SizedBox(width: 6),
                                    ShaderMask(
                                      shaderCallback: (b) =>
                                          const LinearGradient(
                                        colors: [
                                          Color(0xFFFFD700),
                                          Color(0xFFFF8C00)
                                        ],
                                      ).createShader(b),
                                      child: const Icon(Icons.verified_rounded,
                                          size: 20, color: Colors.white),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('@$uname',
                                  style: GoogleFonts.inter(
                                      color: textSub, fontSize: 13)),
                              const SizedBox(height: 8),
                              // CRI tier badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: criColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: criColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shield_rounded,
                                        size: 13, color: criColor),
                                    const SizedBox(width: 4),
                                    Text(criLabel,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: criColor,
                                        )),
                                  ],
                                ),
                              ),
                              if (college.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  Icon(Icons.school_outlined,
                                      size: 13, color: textSub),
                                  const SizedBox(width: 5),
                                  Text(college,
                                      style: GoogleFonts.inter(
                                          fontSize: 13, color: textSub)),
                                ]),
                              ],
                              if (bio.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(bio,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textMain,
                                      height: 1.45,
                                    )),
                              ],
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),

                        // Stats card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 8),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.07),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                              border: isDark
                                  ? Border.all(color: Colors.grey.shade800)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                _StatItem(
                                    count: _fmt(posts),
                                    label: 'Posts',
                                    icon: Icons.grid_view_rounded,
                                    iconColor: AppColors.primary),
                                _VDiv(isDark: isDark),
                                _StatItem(
                                    count: _fmt(friends),
                                    label: 'Friends',
                                    icon: Icons.people_rounded,
                                    iconColor: AppColors.green,
                                    onTap: () => Navigator.pushNamed(context, '/connections', arguments: {'tabIndex': 0, 'userId': user?.id})),
                                _VDiv(isDark: isDark),
                                _StatItem(
                                    count: _fmt(followers),
                                    label: 'Followers',
                                    icon: Icons.favorite_rounded,
                                    iconColor: AppColors.red,
                                    onTap: () => Navigator.pushNamed(context, '/connections', arguments: {'tabIndex': 1, 'userId': user?.id})),
                                _VDiv(isDark: isDark),
                                _StatItem(
                                    count: _fmt(following),
                                    label: 'Following',
                                    icon: Icons.person_add_rounded,
                                    iconColor: Colors.blue,
                                    onTap: () => Navigator.pushNamed(context, '/connections', arguments: {'tabIndex': 2, 'userId': user?.id})),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 3. Pinned tab bar ────────────────────────────────────
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      TabBar(
                        controller: _tabCtrl,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: textSub,
                        labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 13),
                        unselectedLabelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w500, fontSize: 13),
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.grid_view_rounded, size: 16),
                                SizedBox(width: 6),
                                Text('Posts'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tag_rounded, size: 16),
                                SizedBox(width: 6),
                                Text('Tagged'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      isDark: isDark,
                      bgColor: bgColor,
                    ),
                  ),
                ],

                // ── Tab body ─────────────────────────────────────────────
                body: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _emptyTab(
                      isDark: isDark,
                      icon: Icons.grid_view_rounded,
                      title: 'No posts yet',
                      subtitle: 'Your posts will appear here',
                    ),
                    _emptyTab(
                      isDark: isDark,
                      icon: Icons.tag_rounded,
                      title: 'No tagged posts',
                      subtitle: 'Posts you\'re tagged in will appear here',
                    ),
                  ],
                ),
              ),
            ),
            const BottomNavBar(currentIndex: 4),
          ],
        ),
      ),
    );
  }

  // ── Avatar widget ─────────────────────────────────────────────────────────
  Widget _buildAvatar({
    required String initial,
    required int cri,
    required bool isDark,
    required Color criColor,
    required double size,
    String? avatarUrl,
  }) {
    final ringSize = size + 12;
    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // CRI progress ring
          CustomPaint(
            size: Size(ringSize, ringSize),
            painter: _CriRingPainter(
              progress: (cri / 1000.0).clamp(0.0, 1.0),
              color: criColor,
            ),
          ),
          // Avatar circle — solid background, no transparency
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              border: Border.all(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(initial),
                    ),
                  )
                : _initials(initial),
          ),
        ],
      ),
    );
  }

  Widget _initials(String i) => Center(
        child: ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: Text(i,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30)),
        ),
      );

  Widget _buildSmallAvatar({required String initial, String? avatarUrl}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _smallInitials(initial),
              ),
            )
          : _smallInitials(initial),
    );
  }

  Widget _smallInitials(String i) => Center(
        child: Text(
          i,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      );

  // ── Chip helper ───────────────────────────────────────────────────────────
  Widget _chip({
    required IconData icon,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
    LinearGradient? gradient,
    Color? background,
    Color? border,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: gradient,
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: border != null ? Border.all(color: border) : null,
          boxShadow: gradient != null
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
          ],
        ),
      ),
    );
  }

  // ── Empty tab placeholder ─────────────────────────────────────────────────
  Widget _emptyTab({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
              ),
              child: Icon(icon,
                  size: 36, color: AppColors.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Animated Smooth Line Chart Painter ──────────────────────────────────────
class _SmoothLineChartPainter extends CustomPainter {
  final int criScore;
  final bool isActive;
  final double animationValue; // 0.0 → 1.0 (plays once)

  static const int _totalDays = 10; // last 10 days

  // Greater variety of positive feedback
  static const List<String> _peakLabels = [
    'Epic 🤯',
    'Incredible 🤩',
    'Phenomenal 🎆',
    'Superb 🏆',
    'Legendary 👑',
    'Flawless 💎',
    'Iconic 🌟',
    'Exquisite 🤌',
    'Radiant ✨',
    'Brilliant 💡',
    'Unstoppable 🚀',
    'Genius 🧠'
  ];

  static const List<String> _dropLabels = [
    'Tough ☔',
    'Slip ⛸️',
    'Slow 🐌',
    'Ouch 🤕',
    'Dip 📉'
  ];

  const _SmoothLineChartPainter({
    required this.criScore,
    required this.isActive,
    required this.animationValue,
  });

  static Offset getEndOffset(
      Size size, int criScore, bool isActive, double animationValue) {
    if (size.width == 0 || size.height == 0) return Offset.zero;
    final rng = math.Random(criScore * 13 + 7);
    final points = <double>[];
    double score = (criScore * 0.65).clamp(10, 900).toDouble();

    for (int i = 0; i < _totalDays; i++) {
      final drift = isActive ? 0.35 : 0.45;
      final change = (rng.nextDouble() - drift) * score * 0.15;
      score = (score + change).clamp(5, 1000).toDouble();
      points.add(score);
    }

    final maxVal = points.reduce(math.max);
    final minVal = points.reduce(math.min);
    final range = (maxVal - minVal).clamp(1, double.infinity);

    final chartTop = size.height * 0.28;
    final chartH = size.height - chartTop;
    double toY(double v) =>
        chartTop +
        chartH -
        ((v - minVal) / range) * (chartH * 0.85) -
        chartH * 0.05;

    final stepX = size.width / (_totalDays - 1);

    final fullPath = Path();
    fullPath.moveTo(0, toY(points[0]));

    for (int i = 0; i < _totalDays - 1; i++) {
      final x0 = i * stepX;
      final y0 = toY(points[i]);
      final x1 = (i + 1) * stepX;
      final y1 = toY(points[i + 1]);
      final cx0 = x0 + stepX * 0.5;
      final cx1 = x1 - stepX * 0.5;
      fullPath.cubicTo(cx0, y0, cx1, y1, x1, y1);
    }

    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return Offset.zero;

    final metric = metrics.first;
    final drawnLength = metric.length * animationValue;
    final tangent = metric.getTangentForOffset(drawnLength);
    return tangent?.position ?? Offset.zero;
  }

  List<double> _generatePoints() {
    final rng = math.Random(criScore * 13 + 7);
    final list = <double>[];
    double score = (criScore * 0.65).clamp(10, 900).toDouble();

    for (int i = 0; i < _totalDays; i++) {
      final drift = isActive ? 0.35 : 0.45;
      final change = (rng.nextDouble() - drift) * score * 0.15;
      score = (score + change).clamp(5, 1000).toDouble();
      list.add(score);
    }
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final points = _generatePoints();
    if (points.isEmpty) return;

    final maxVal = points.reduce(math.max);
    final minVal = points.reduce(math.min);
    final range = (maxVal - minVal).clamp(1, double.infinity);

    // Reserve top portion for floating labels
    final chartTop = size.height * 0.28;
    final chartH = size.height - chartTop;

    double toY(double v) =>
        chartTop +
        chartH -
        ((v - minVal) / range) * (chartH * 0.85) -
        chartH * 0.05;

    final stepX = size.width / (_totalDays - 1);

    // Build full smooth path
    final fullPath = Path();
    fullPath.moveTo(0, toY(points[0]));

    for (int i = 0; i < _totalDays - 1; i++) {
      final x0 = i * stepX;
      final y0 = toY(points[i]);
      final x1 = (i + 1) * stepX;
      final y1 = toY(points[i + 1]);

      final cx0 = x0 + stepX * 0.5;
      final cx1 = x1 - stepX * 0.5;
      fullPath.cubicTo(cx0, y0, cx1, y1, x1, y1);
    }

    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    // Extract segment up to the animation's current horizontal progress
    final drawnLength = metric.length * animationValue;
    final extractPath = metric.extractPath(0, drawnLength);

    // ── 1. Gradient Fill Under Path ──
    final fillPath = Path.from(extractPath);
    final tangent = metric.getTangentForOffset(drawnLength);
    final endX = tangent?.position.dx ?? 0;

    fillPath.lineTo(endX, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF34D399).withOpacity(0.5),
        const Color(0xFF34D399).withOpacity(0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, Paint()..shader = fillGradient);

    // ── 2. Bright Stroke Line ──
    canvas.drawPath(
      extractPath,
      Paint()
        ..color = const Color(0xFF34D399)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── 3. Scanning Line ──
    if (animationValue < 1.0) {
      canvas.drawLine(
        Offset(endX, 0),
        Offset(endX, size.height),
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..strokeWidth = 1.5,
      );
    }

    // ── 4. Knots (Points) & Labels ──
    // revealPos relates to X coordinate steps
    final revealPos = animationValue * (_totalDays - 1);

    for (int i = 0; i < _totalDays; i++) {
      // Age since this point was crossed by the scanner
      final nodeAge = revealPos - i;
      if (nodeAge < 0.0) continue;

      final x = i * stepX;
      final y = toY(points[i]);

      // Node pops in with an elastic bounce (over 0.4 progress units)
      final growProgress =
          Curves.easeOutBack.transform((nodeAge / 0.4).clamp(0.0, 1.0));

      final isBull = i == 0 || points[i] >= points[i - 1];

      // Draw node rings
      canvas.drawCircle(
        Offset(x, y),
        5.0 * growProgress,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(x, y),
        3.0 * growProgress,
        Paint()
          ..color = isBull ? const Color(0xFF34D399) : const Color(0xFFF87171),
      );

      // Feedback Labels (visible for roughly 1.3 units, then fades)
      final labelOpacity = (nodeAge < 0.3)
          ? (nodeAge / 0.3)
          : (nodeAge > 1.0)
              ? (1.0 - (nodeAge - 1.0) / 0.4).clamp(0.0, 1.0)
              : 1.0;

      if (labelOpacity > 0.01 && i > 0) {
        final rngLabels = math.Random(criScore + i);
        String labelText;
        Color labelColor;

        if (isBull) {
          labelText = _peakLabels[rngLabels.nextInt(_peakLabels.length)];
          labelColor = const Color(0xFF34D399); // Green
        } else {
          labelText = _dropLabels[rngLabels.nextInt(_dropLabels.length)];
          labelColor = const Color(0xFFF87171); // Red
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: TextStyle(
              color: labelColor.withOpacity(labelOpacity),
              fontSize: 10 + (2 * growProgress), // very slight text pop
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                    color: Colors.black.withOpacity(0.5 * labelOpacity),
                    blurRadius: 4),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Float effect offsets the label slowly as it ages
        final floatOffset = (1.0 - growProgress) * 8 + (nodeAge * 4);
        final labelY = isBull ? y - 18 - floatOffset : y + 10 + floatOffset;
        final labelX = (x - textPainter.width / 2)
            .clamp(2.0, size.width - textPainter.width - 2);

        textPainter.paint(canvas, Offset(labelX, labelY));
      }

      // Day label bottom axis
      final tp = TextPainter(
        text: TextSpan(
          text: 'D${i + 1}',
          style: TextStyle(
            color:
                Colors.white.withOpacity(0.35 * growProgress.clamp(0.0, 1.0)),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 12));
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothLineChartPainter old) => true;
}

// ── CRI Ring Painter ──────────────────────────────────────────────────────────
class _CriRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _CriRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;

    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..shader = LinearGradient(colors: [color, color.withOpacity(0.5)])
            .createShader(Rect.fromCircle(center: c, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CriRingPainter o) =>
      o.progress != progress || o.color != color;
}

// ── Stat Item ─────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  const _StatItem(
      {required this.count,
      required this.label,
      required this.icon,
      required this.iconColor,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(count,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color:
                  isDark ? AppColors.textMainDark : AppColors.textMainLight,
            )),
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            )),
      ],
    );

    if (onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      );
    }

    return Expanded(child: content);
  }
}

// ── Vertical Divider ──────────────────────────────────────────────────────────
class _VDiv extends StatelessWidget {
  final bool isDark;
  const _VDiv({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 44,
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      );
}

// ── Tab Bar Delegate ──────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;
  final Color bgColor;
  const _TabBarDelegate(this.tabBar,
      {required this.isDark, required this.bgColor});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    // Always reads live theme so dark/light switches instantly (no glitch)
    final bg = Theme.of(ctx).brightness == Brightness.dark
        ? AppColors.backgroundDark
        : const Color(0xFFF7F8FC);
    return Container(
      color: bg,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) =>
      old.isDark != isDark || old.bgColor != bgColor;
}
