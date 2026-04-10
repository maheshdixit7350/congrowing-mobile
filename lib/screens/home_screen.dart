import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/ad_banner.dart';
import '../utils/ad_manager.dart';
import '../services/user_service.dart';

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
        title: Text('Exit App', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to exit?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text('Exit', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
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
    final countries = ['Any', 'India', 'USA', 'UK', 'Canada', 'Australia', 'Germany', 'Japan', 'Brazil'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -4))],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Connection Filters', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 24),

              // Gender Preference
              Text('GENDER PREFERENCE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.grey.shade500, letterSpacing: 1.2)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: sel ? const LinearGradient(colors: [AppColors.primary, Color(0xFF2DD4BF)]) : null,
                        color: sel ? null : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        boxShadow: sel ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            g == 'Male' ? Icons.male_rounded : g == 'Female' ? Icons.female_rounded : g == 'Other' ? Icons.transgender_rounded : Icons.people_rounded,
                            size: 16,
                            color: sel ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Text(g, style: GoogleFonts.inter(color: sel ? Colors.white : (isDark ? Colors.white60 : Colors.black87), fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Country Preference
              Text('COUNTRY PREFERENCE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.grey.shade500, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tempCountry,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white54 : Colors.grey.shade600),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: countries.map((c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(Icons.public_rounded, size: 16, color: c == tempCountry ? AppColors.primary : (isDark ? Colors.white54 : Colors.grey.shade500)),
                          const SizedBox(width: 10),
                          Text(c, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontWeight: c == tempCountry ? FontWeight.w700 : FontWeight.w500)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (v) => setBS(() => tempCountry = v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Locality Preference
              Text('LOCALITY PREFERENCE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.grey.shade500, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.near_me_rounded, size: 20, color: tempLocality ? AppColors.primary : (isDark ? Colors.white54 : Colors.grey.shade500)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Connect Nearby', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                          Text('Match with the closest person to you', style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Switch(
                      value: tempLocality,
                      onChanged: (v) => setBS(() => tempLocality = v),
                      activeColor: AppColors.primary,
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
                    gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
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
                        child: Center(child: Text('Apply Filters', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 24),
            Text('Connect with someone', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('How would you like to connect?', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      AdManager.showInterstitialAd(() => Navigator.pushNamed(context, '/voice-call'));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                      child: Column(
                        children: [
                          Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.call, color: Colors.white, size: 28)),
                          const SizedBox(height: 12),
                          Text('Voice Call', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
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
                      AdManager.showInterstitialAd(() => Navigator.pushNamed(context, '/video-call'));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2DD4BF)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]),
                      child: Column(
                        children: [
                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.videocam, color: Colors.white, size: 28)),
                          const SizedBox(height: 12),
                          Text('Video Call', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
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
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
                              errorBuilder: (c, e, s) => const SizedBox(width: 32, height: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
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
                        onPressed: () => Navigator.pushNamed(context, '/create-post'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border_rounded),
                        onPressed: () => Navigator.pushNamed(context, '/notifications'),
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(child: _buildStories(context, isDark)),
                  SliverToBoxAdapter(child: Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100)),
                  SliverToBoxAdapter(child: const SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildConnectSection(context, isDark)),
                  SliverToBoxAdapter(child: const SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildLeaderboard(context, isDark)),
                  SliverToBoxAdapter(child: const SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _buildCriAnalytics(context, isDark)),
                  SliverToBoxAdapter(child: const SizedBox(height: 24)),
                ],
              ),
            ),
            const AdBanner(),
            BottomNavBar(currentIndex: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildStories(BuildContext context, bool isDark) {
    final user = UserService.instance.currentUser;
    final initial = (user?.name ?? 'U').substring(0, 1).toUpperCase();
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Your Story
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 2, strokeAlign: BorderSide.strokeAlignOutside),
                        color: AppColors.primary.withAlpha(40),
                      ),
                      child: user?.avatarUrl != null
                          ? ClipOval(child: Image.network(user!.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(initial, style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 22)))))
                          : Center(child: Text(initial, style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 22))),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Your Story', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectSection(BuildContext context, bool isDark) {
    final user = UserService.instance.currentUser;
    final hasFilters = _selectedGender != 'Any' || _selectedCountry != 'Any' || _localityEnabled;
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
              Text('Connect with People', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('FREE', style: GoogleFonts.inter(color: Colors.green.shade600, fontWeight: FontWeight.w800, fontSize: 11)),
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
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.tune_rounded, size: 16, color: isDark ? Colors.white : Colors.grey.shade700),
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
                          child: Center(child: Text('$filterCount', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              gradient: isDark ? null : const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.white, width: 2),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar and User
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                            color: AppColors.primary.withAlpha(40),
                          ),
                          child: user?.avatarUrl != null
                              ? ClipOval(child: Image.network(user!.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40)))
                              : const Icon(Icons.person, size: 40),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                            ),
                            child: const Icon(Icons.edit, color: AppColors.primary, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '@${user?.name ?? 'User'}',
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // CURRENT CRI SCORE Label
                Text(
                  'CURRENT CRI SCORE',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),

                // Score + Growth
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${user?.criScore ?? 850}',
                      style: GoogleFonts.inter(fontSize: 64, fontWeight: FontWeight.w800, color: const Color(0xFF6D28D9), height: 1.0),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100.withOpacity(0.8),
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.trending_up_rounded, color: Colors.green.shade700, size: 14),
                              const SizedBox(width: 4),
                              Text('12.5%', style: GoogleFonts.inter(color: Colors.green.shade700, fontWeight: FontWeight.w800, fontSize: 13)),
                            ],
                          ),
                          Text('GROWTH', style: GoogleFonts.inter(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Connect Now Button
                GestureDetector(
                  onTap: () => _showCallTypeSheet(context, isDark),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_alt_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Connect Now',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: 0.5,
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
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leaderboard', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            // Your rank
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withAlpha(50),
                    child: Text(myName.isNotEmpty ? myName[0].toUpperCase() : '?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(myName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('CRI Score: $myCri', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Connect with more people to climb the leaderboard!', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/leaderboard'),
              child: Center(
                child: Text('View Full Leaderboard', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
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
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CRI Analytics', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                const Icon(Icons.insights_rounded, color: AppColors.primary, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'CURRENT CRI SCORE',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondaryLight, letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${UserService.instance.currentUser?.criScore ?? 0}',
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGradientStart,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up_rounded, color: Colors.green.shade600, size: 14),
                      const SizedBox(width: 3),
                      Text('Active', style: GoogleFonts.inter(color: Colors.green.shade600, fontWeight: FontWeight.w700, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Radar chart placeholder
            Center(
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _RadarChartPainter(),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/cri-analytics'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800.withOpacity(0.6) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'View Full Analytics',
                    style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
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
    final double angleStep = (2 * math.pi) / sides;
    const double startAngle = -math.pi / 2;

    for (int ring = 1; ring <= 3; ring++) {
      final r = radius * ring / 3;
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = startAngle + i * angleStep;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw data polygon
    final scores = [0.85, 0.75, 0.70, 0.80, 0.65];
    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + i * angleStep;
      final r = radius * scores[i];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) dataPath.moveTo(x, y);
      else dataPath.lineTo(x, y);
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
