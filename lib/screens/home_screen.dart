import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/ad_banner.dart';
import '../utils/ad_manager.dart';
import '../services/user_service.dart';
import '../main.dart' show supabaseInitialized;
import '../services/leaderboard_service.dart';
import '../services/thoughts_service.dart';
import '../models/user_model.dart';
import 'story_viewer_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Filter state
  String _selectedGender = 'Any';
  String _selectedCountry = 'Any';
  bool _localityEnabled = false;

  @override
  void initState() {
    super.initState();
    // Listen to profile updates
    UserService.instance.listenToCurrentUser((user) {
      if (mounted) setState(() {});
    });
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Exit App',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content:
            Text('Are you sure you want to exit?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text('Exit',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showConnectFilterSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String tempGender = _selectedGender;
    String tempCountry = _selectedCountry;
    bool tempLocality = _localityEnabled;

    final genders = ['Any', 'Male', 'Female', 'Other'];
    final countries = [
      'Any',
      'India',
      'USA',
      'UK',
      'Canada',
      'Australia',
      'Germany',
      'Japan',
      'Brazil'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -4))
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                          borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Connection Filters',
                      style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 24),

              // Gender Preference
              Text('GENDER PREFERENCE',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: genders.map((g) {
                  final sel = tempGender == g;
                  return GestureDetector(
                    onTap: () => setBS(() => tempGender = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: sel
                            ? const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF2DD4BF)])
                            : null,
                        color: sel
                            ? null
                            : (isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9)),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            g == 'Male'
                                ? Icons.male_rounded
                                : g == 'Female'
                                    ? Icons.female_rounded
                                    : g == 'Other'
                                        ? Icons.transgender_rounded
                                        : Icons.people_rounded,
                            size: 16,
                            color: sel
                                ? Colors.white
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Text(g,
                              style: GoogleFonts.inter(
                                  color: sel
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white60
                                          : Colors.black87),
                                  fontWeight:
                                      sel ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Country Preference
              Text('COUNTRY PREFERENCE',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.withOpacity(0.15)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tempCountry,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.white54 : Colors.grey.shade600),
                    dropdownColor:
                        isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: countries
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(Icons.public_rounded,
                                      size: 16,
                                      color: c == tempCountry
                                          ? AppColors.primary
                                          : (isDark
                                              ? Colors.white54
                                              : Colors.grey.shade500)),
                                  const SizedBox(width: 10),
                                  Text(c,
                                      style: GoogleFonts.inter(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: c == tempCountry
                                              ? FontWeight.w700
                                              : FontWeight.w500)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setBS(() => tempCountry = v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Locality Preference
              Text('LOCALITY PREFERENCE',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.near_me_rounded,
                        size: 20,
                        color: tempLocality
                            ? AppColors.primary
                            : (isDark ? Colors.white54 : Colors.grey.shade500)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Connect Nearby',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? Colors.white : Colors.black87)),
                          Text('Match with the closest person to you',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Switch(
                      value: tempLocality,
                      onChanged: (v) => setBS(() => tempLocality = v),
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _selectedGender = tempGender;
                          _selectedCountry = tempCountry;
                          _localityEnabled = tempLocality;
                        });
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: Text('Apply Filters',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16))),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCallTypeSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 24),
            Text('Connect with someone',
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('How would you like to connect?',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      AdManager.showInterstitialAd(
                          () => Navigator.pushNamed(context, '/voice-call', arguments: {'isCaller': true}));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3))),
                      child: Column(
                        children: [
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.call,
                                  color: Colors.white, size: 28)),
                          const SizedBox(height: 12),
                          Text('Voice Call',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      AdManager.showInterstitialAd(
                          () => Navigator.pushNamed(context, '/video-call', arguments: {'isCaller': true}));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4))
                          ]),
                      child: Column(
                        children: [
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.videocam,
                                  color: Colors.white, size: 28)),
                          const SizedBox(height: 12),
                          Text('Video Call',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onWillPop(context);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    title: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const SizedBox(width: 32, height: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: Text(
                            'ConGrowing',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add_box_outlined),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/create-post'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border_rounded),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/notifications'),
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(child: _buildStories(context, isDark)),
                  SliverToBoxAdapter(
                      child: Divider(
                          height: 1,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100)),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                      child: _buildConnectSection(context, isDark)),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildLeaderboard(context, isDark)),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                      child: _buildCriAnalytics(context, isDark)),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
            const AdBanner(),
            const BottomNavBar(currentIndex: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildStories(BuildContext context, bool isDark) {
    final user = UserService.instance.currentUser;
    final initial = (user?.name ?? 'U').isNotEmpty
        ? (user?.name ?? 'U').substring(0, 1).toUpperCase()
        : 'U';
    return SizedBox(
      height: 100,
      child: StreamBuilder<List<Thought>>(
        stream: ThoughtsService.instance.streamActiveThoughts(),
        builder: (context, snapshot) {
          final thoughts = snapshot.data ?? [];
          final myThoughts =
              thoughts.where((t) => t.userId == (user?.id ?? '')).toList();
          final otherThoughts =
              thoughts.where((t) => t.userId != (user?.id ?? '')).toList();

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Your Story
              GestureDetector(
                onTap: () {
                  if (myThoughts.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryViewerPage(
                          thoughts: myThoughts,
                          initialIndex: 0,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, '/create-post');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: myThoughts.isNotEmpty
                                  ? const SweepGradient(
                                      colors: [Color(0xFF7C3AED), Color(0xFF06B6D4), Color(0xFF7C3AED)],
                                      startAngle: 0,
                                      endAngle: math.pi * 2,
                                    )
                                  : null,
                              border: myThoughts.isNotEmpty
                                  ? null
                                  : Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                      strokeAlign: BorderSide.strokeAlignOutside,
                                    ),
                              color: myThoughts.isNotEmpty ? null : AppColors.primary.withAlpha(40),
                            ),
                            child: user?.avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(user!.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                            child: Text(initial,
                                                style: GoogleFonts.inter(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 22)))))
                                : Center(
                                    child: Text(initial,
                                        style: GoogleFonts.inter(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 22))),
                          ),
                          if (myThoughts.isEmpty)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Your Story',
                          style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),

              // Other users' active thoughts
              ...List.generate(otherThoughts.length, (index) {
                final thought = otherThoughts[index];
                final startChar = thought.userName.isNotEmpty
                    ? thought.userName.substring(0, 1).toUpperCase()
                    : '?';
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryViewerPage(
                            thoughts: otherThoughts,
                            initialIndex: index,
                          ),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4), Color(0xFFEC4899), Color(0xFF7C3AED)],
                              startAngle: 0,
                              endAngle: math.pi * 2,
                            ),
                          ),
                          child: thought.userAvatarUrl != null
                              ? ClipOval(
                                  child: Image.network(thought.userAvatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                          child: Text(startChar,
                                              style: GoogleFonts.inter(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 22)))))
                              : Center(
                                  child: Text(startChar,
                                      style: GoogleFonts.inter(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 22))),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: Text(
                            thought.userName,
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  String _criLevelLabel(int s) {
    if (s >= 900) return '💎 Diamond';
    if (s >= 700) return '🏆 Gold';
    if (s >= 500) return '🥈 Silver';
    if (s >= 300) return '🥉 Bronze';
    return '🌱 Starter';
  }

  Widget _buildConnectSection(BuildContext context, bool isDark) {
    final user = UserService.instance.currentUser;
    final hasFilters = _selectedGender != 'Any' ||
        _selectedCountry != 'Any' ||
        _localityEnabled;
    int filterCount = 0;
    if (_selectedGender != 'Any') filterCount++;
    if (_selectedCountry != 'Any') filterCount++;
    if (_localityEnabled) filterCount++;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 22,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Connect with People',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('FREE',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5)),
              ),
              const Spacer(),
              // Filter Icon
              GestureDetector(
                onTap: () => _showConnectFilterSheet(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.tune_rounded,
                          size: 16,
                          color: isDark ? Colors.white : Colors.grey.shade700),
                    ),
                    if (filterCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                              child: Text('$filterCount',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800))),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Hero Card
          Container(
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.heroGradientDark : AppColors.heroGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Decorative background circles
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar and User row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: user?.avatarUrl != null
                                    ? Image.network(
                                        user!.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          child: Center(
                                            child: Text(
                                              (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
                                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        child: Center(
                                          child: Text(
                                            ((user?.name ?? 'U').isNotEmpty ? (user?.name ?? 'U')[0] : 'U').toUpperCase(),
                                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@${user?.username ?? 'user'}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                  ),
                                  child: Text(
                                    _criLevelLabel(user?.criScore ?? 0),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // CRI Score display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${user?.criScore ?? 0}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 44,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    'CRI SCORE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white60,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF34D399),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Active',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF6EE7B7),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'STATUS',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white60,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Connect Now Button
                        GestureDetector(
                          onTap: () => _showCallTypeSheet(context, isDark),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (b) => AppColors.heroGradient.createShader(b),
                                  child: const Icon(Icons.people_alt_rounded,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 10),
                                ShaderMask(
                                  shaderCallback: (b) => AppColors.heroGradient.createShader(b),
                                  child: Text(
                                    'Connect Now',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context, bool isDark) {
    final user = UserService.instance.currentUser;
    final myName = user?.name ?? 'You';
    final myCri = user?.criScore ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: AppColors.amberGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Leaderboard',
                    style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A))),
                const Spacer(),
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 22),
              ],
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 16),
            // Your rank
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        myName.isNotEmpty ? myName[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(myName,
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        Text('Score: $myCri • ${_criLevelLabel(myCri)}',
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFFBBF24), size: 28),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Top 3 from Supabase Leaderboard
            if (supabaseInitialized)
              StreamBuilder<List<LeaderboardEntry>>(
                stream: LeaderboardService.instance.streamLeaderboard(limit: 3),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Text('Connect to climb the leaderboard!',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey.shade500),
                          textAlign: TextAlign.center),
                    );
                  }
                  return Column(
                    children: List.generate(list.length, (i) {
                      final entry = list[i];
                      final name = entry.name;
                      final score = entry.criScore;
                      final isMe = entry.isMe;
                      final medalColors = [
                      const Color(0xFFFBBF24), // Gold
                      const Color(0xFFCBD5E1), // Silver
                      const Color(0xFFCD7C3A), // Bronze
                    ];
                    final medalEmoji = ['🥇', '🥈', '🥉'];
                    return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : (isDark
                                  ? AppColors.cardDarkElevated
                                  : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isMe
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : (isDark
                                    ? AppColors.dividerDark
                                    : AppColors.dividerLight),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: i < 3
                                  ? Text(medalEmoji[i],
                                      style: const TextStyle(fontSize: 18))
                                  : Text('${i + 1}',
                                      style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white54 : Colors.grey)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: i < 3
                                    ? LinearGradient(
                                        colors: [
                                          medalColors[i].withValues(alpha: 0.5),
                                          medalColors[i],
                                        ],
                                      )
                                    : AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(isMe ? '$name (You)' : name,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isMe
                                          ? AppColors.primary
                                          : (isDark ? Colors.white : const Color(0xFF1E293B))),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$score',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary)),
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            const SizedBox(height: 12),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/leaderboard'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDarkElevated
                      : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Full Leaderboard',
                          style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.primary, size: 15),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriAnalytics(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('CRI Analytics',
                    style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.insights_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                  child: Text(
                    '${UserService.instance.currentUser?.criScore ?? 0}',
                    style: GoogleFonts.outfit(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppColors.successGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text('Active',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Radar chart
            Center(
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _RadarChartPainter(UserService.instance.currentUser),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/cri-analytics'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDarkElevated
                      : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Full Analytics',
                        style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.primary, size: 15),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final UserModel? user;
  _RadarChartPainter(this.user);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final fillPaint = Paint()
      ..color = const Color(0xFF7C3AED).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const int sides = 5;
    const double angleStep = (2 * math.pi) / sides;
    const double startAngle = -math.pi / 2;

    for (int ring = 1; ring <= 3; ring++) {
      final r = radius * ring / 3;
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = startAngle + i * angleStep;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw data polygon based on real user metrics
    final empathyScore = ((user?.avgEmpathy ?? 5.0) / 10.0).clamp(0.1, 1.0);
    final respectScore = ((user?.respectRate ?? 0.0) / 100.0).clamp(0.1, 1.0);
    final listenScore = ((user?.listenRate ?? 0.0) / 100.0).clamp(0.1, 1.0);
    final criScore = ((user?.criScore ?? 0) / 1000.0).clamp(0.1, 1.0);
    final callsScore = ((user?.totalCalls ?? 0) / 50.0).clamp(0.1, 1.0);

    final scores = [empathyScore, respectScore, listenScore, criScore, callsScore];
    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + i * angleStep;
      final r = radius * scores[i];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
