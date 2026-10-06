import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/ad_banner.dart';
import '../utils/ad_manager.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────
class _Person {
  final String name;
  final String imageUrl;
  final int cri;
  final int compatibility;
  final String topic;
  final bool isOnline;
  _Person(
      {required this.name,
      required this.imageUrl,
      required this.cri,
      required this.compatibility,
      required this.topic,
      required this.isOnline});
}

class _Podcast {
  final String title;
  final String category;
  final String imageUrl;
  final String listeners;
  final bool isLive;
  _Podcast(
      {required this.title,
      required this.category,
      required this.imageUrl,
      required this.listeners,
      required this.isLive});
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class CallScreen extends StatefulWidget {
  const CallScreen({super.key});
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Tech',
    'Business',
    'Lifestyle',
    'Language',
    'Science'
  ];

  // Filter state
  String _selectedGender = 'Any';
  String _selectedCountry = 'Any';
  bool _localityEnabled = false;

  final List<_Person> _allPeople = [];

  final List<_Podcast> _podcasts = [];

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    // Listen to profile updates
    UserService.instance.listenToCurrentUser((u) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showConnectDialog(BuildContext context, UserModel person) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
                Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 2)
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: person.avatarUrl != null && person.avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: person.avatarUrl!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: Center(
                            child: Text(
                              person.name.isNotEmpty ? person.name[0].toUpperCase() : 'U',
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
              const SizedBox(height: 16),
              Text('Connect with ${person.name}?',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  '${75 + (person.id.hashCode % 21)}% compatibility · CRI ${person.criScore}',
                  style:
                      GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Topic: ${person.personalityType ?? 'General'}',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF2DD4BF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/user-profile',
                          arguments: {'userId': person.id},
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.2))),
                      ),
                      child: Text('Profile',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(context); // Close the dialog
                            // Show interstitial ad then navigate to video call
                            AdManager.showInterstitialAd(() {
                              Navigator.pushNamed(
                                context,
                                '/video-call',
                                arguments: {
                                  'otherUid': person.id,
                                  'name': person.name,
                                  'avatarUrl': person.avatarUrl,
                                  'isCaller': true,
                                },
                              );
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text('Start Call',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                              ],
                            ),
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
    );
  }

  void _showFilterSheet(BuildContext context, bool isDark) {
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
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                Text('Connection Filters',
                    style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : const Color(0xFF1E293B))),
              ]),
              const SizedBox(height: 24),
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
                                ? const LinearGradient(colors: [
                                    AppColors.primary,
                                    Color(0xFF2DD4BF)
                                  ])
                                : null,
                            color: sel
                                ? null
                                : (isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9)),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3))
                                  ]
                                : []),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
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
                                  : (isDark ? Colors.white60 : Colors.black54)),
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
                        ]),
                      ),
                    );
                  }).toList()),
              const SizedBox(height: 20),
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
                            : Colors.grey.withOpacity(0.15))),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                        value: tempCountry,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color:
                                isDark ? Colors.white54 : Colors.grey.shade600),
                        dropdownColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: countries
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(children: [
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
                                              : FontWeight.w500))
                                ])))
                            .toList(),
                        onChanged: (v) => setBS(() => tempCountry = v!))),
              ),
              const SizedBox(height: 20),
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
                            : Colors.grey.withOpacity(0.15))),
                child: Row(children: [
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
                                color: isDark ? Colors.white : Colors.black87)),
                        Text('Match with the closest person to you',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade500)),
                      ])),
                  Switch(
                      value: tempLocality,
                      onChanged: (v) => setBS(() => tempLocality = v),
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withOpacity(0.3)),
                ]),
              ),
              const SizedBox(height: 28),
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
                        ]),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                    child: Text('Apply Filters',
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16)))))),
                  )),
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
                      AdManager.showInterstitialAd(() => Navigator.pushNamed(
                            context,
                            '/voice-call',
                            arguments: {'isCaller': true},
                          ));
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
                      AdManager.showInterstitialAd(() => Navigator.pushNamed(
                            context,
                            '/video-call',
                            arguments: {'isCaller': true},
                          ));
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

  void _showPodcastSheet(BuildContext context, _Podcast pod, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                  imageUrl: pod.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(pod.title,
                      style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B))),
                  Text(pod.category,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color:
                              isDark ? Colors.white54 : Colors.grey.shade600)),
                ]),
                if (pod.isLive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('● LIVE',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.headphones_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('${pod.listeners} listeners',
                  style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.headphones_rounded),
                  label: Text('Listen',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Joining ${pod.title}…',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600)),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                            child: Text('Join Now',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF4F6FB);
    final cardBg = isDark ? const Color(0xFF1A2540) : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        body: Column(
          children: [
            // ── Premium AppBar ──────────────────────────────────────────
            _buildAppBar(isDark),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── My Profile Card ──────────────────────────────────
                    _buildMyProfileCard(isDark, cardBg),
                    const SizedBox(height: 24),

                    // Search Bar
                    _buildSearchBar(isDark),
                    const SizedBox(height: 20),

                    // Category chips
                    _buildCategoryChips(isDark),
                    const SizedBox(height: 28),

                    // People Online Now
                    _buildSectionTitle('People Online Now', isDark),
                    const SizedBox(height: 14),
                    StreamBuilder<List<UserModel>>(
                      stream: UserService.instance.streamOnlineUsers(),
                      builder: (context, snapshot) {
                        final onlineUsers = snapshot.data ?? [];
                        if (onlineUsers.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                'No one is online right now',
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: onlineUsers
                              .map((u) => _buildPersonTile(context, u, isDark, cardBg))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Trending Podcasts
                    _buildSectionTitle('Trending Podcasts', isDark,
                        action: 'View All'),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _podcasts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (ctx, i) => _buildPodcastCard(
                            ctx, _podcasts[i], isDark, cardBg),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Host CTA
                    _buildHostCTA(isDark, cardBg),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const AdBanner(),
            const BottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar(bool isDark) {
    final hasFilters = _selectedGender != 'Any' ||
        _selectedCountry != 'Any' ||
        _localityEnabled;
    int filterCount = 0;
    if (_selectedGender != 'Any') filterCount++;
    if (_selectedCountry != 'Any') filterCount++;
    if (_localityEnabled) filterCount++;

    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20,
          right: 16,
          bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF4F6FB),
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [AppColors.primary, Color(0xFF2DD4BF)]).createShader(b),
            child: Text('Connect',
                style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5)),
          ),
          const Spacer(),
          // Filter icon
          GestureDetector(
            onTap: () => _showFilterSheet(context, isDark),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasFilters
                        ? const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF2DD4BF)])
                        : null,
                    color: hasFilters
                        ? null
                        : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04)),
                  ),
                  child: Icon(Icons.tune_rounded,
                      color: hasFilters
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      size: 22),
                ),
                if (filterCount > 0)
                  Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                              color: Color(0xFFEF4444), shape: BoxShape.circle),
                          child: Center(
                              child: Text('$filterCount',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800))))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _iconBtn(Icons.person_add_alt_1_rounded, isDark, onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Invite friends coming soon!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            );
          }),
          const SizedBox(width: 8),
          _iconBtn(Icons.notifications_none_rounded, isDark,
              onTap: () => Navigator.pushNamed(context, '/notifications')),
        ],
      ),
    );
  }

  // ── My Profile Card ──────────────────────────────────────────────────────
  Widget _buildMyProfileCard(bool isDark, Color cardBg) {
    final user = UserService.instance.currentUser;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: cardBg,
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          // Gradient header
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEDE9FE), const Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Transform.translate(
                  offset: const Offset(0, 30),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 16,
                            spreadRadius: 2)
                      ],
                    ),
                    child: Container(
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(3),
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: cardBg),
                      child: ClipOval(
                        child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: user.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Container(color: Colors.grey.shade200),
                                errorWidget: (c, u, e) => const Icon(Icons.person, size: 30),
                              )
                            : Container(
                                color: AppColors.primary.withOpacity(0.1),
                                child: Center(
                                  child: Text(
                                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('My Profile',
                                style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B))),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/my-profile'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text('View',
                                    style: GoogleFonts.inter(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11)),
                              ),
                            ),
                          ]),
                          Row(children: [
                            Icon(Icons.workspace_premium_rounded,
                                size: 16, color: Colors.amber.shade500),
                            const SizedBox(width: 4),
                            Text('CRI Score',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54)),
                          ]),
                        ]),
                    // CRI Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(children: [
                        Text('${user?.criScore ?? 0}',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 2),
                            Text('Active',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9)),
                          ]),
                        ),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Connect Now button
                GestureDetector(
                  onTap: () => _showCallTypeSheet(context, isDark),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(colors: [
                        AppColors.primaryGradientStart,
                        AppColors.primaryGradientEnd,
                        Color(0xFF2DD4BF)
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 18,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_alt_rounded,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text('Connect Now',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: 0.3)),
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

  Widget _iconBtn(IconData icon, bool isDark, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
        child: Icon(icon,
            color: isDark ? Colors.white : const Color(0xFF1E293B), size: 22),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2540) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search people, podcasts…',
                hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                    fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black87, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Voice search coming soon!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.mic_rounded,
                  color: AppColors.primary, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Chips ────────────────────────────────────────────────────────
  Widget _buildCategoryChips(bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final sel = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: sel
                    ? const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF2DD4BF)])
                    : null,
                color: sel
                    ? null
                    : (isDark ? const Color(0xFF1A2540) : Colors.white),
                border: Border.all(
                    color: sel
                        ? Colors.transparent
                        : (isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.grey.withOpacity(0.15))),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : [],
              ),
              child: Text(cat,
                  style: GoogleFonts.inter(
                      color: sel
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, bool isDark,
      {String? badge, String? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B))),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(20)),
              child: Text(badge,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5)),
            ),
          ],
        ]),
        if (action != null)
          Text(action,
              style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
      ],
    );
  }

  // ── Top Match Card ────────────────────────────────────────────────────────
  Widget _buildTopMatchCard(UserModel person, bool isDark, Color cardBg) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: cardBg,
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          // Gradient header with avatar
          Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEDE9FE), const Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 0),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Transform.translate(
                    offset: const Offset(0, 30),
                    child: Container(
                      padding:
                          EdgeInsets.all(2.5 + _pulseController.value * 2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.35 * _pulseController.value),
                              blurRadius: 16,
                              spreadRadius: 2)
                        ],
                      ),
                      child: Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: cardBg),
                        child: ClipOval(
                          child: person.avatarUrl != null && person.avatarUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: person.avatarUrl!, fit: BoxFit.cover)
                              : Container(
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: Center(
                                    child: Text(
                                      person.name.isNotEmpty ? person.name[0].toUpperCase() : 'U',
                                      style: GoogleFonts.inter(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 44, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(person.name,
                              style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.workspace_premium_rounded,
                                size: 14, color: Colors.amber.shade500),
                            const SizedBox(width: 4),
                            Text('CRI ${person.criScore}',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54)),
                            const SizedBox(width: 8),
                            Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.grey.shade400)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Row(children: [
                                Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF10B981))),
                                const SizedBox(width: 4),
                                Text('Online',
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFF10B981),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11)),
                              ]),
                            ),
                          ]),
                        ]),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${75 + (person.id.hashCode % 21)}% Match',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.topic_rounded,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(person.personalityType ?? 'General',
                        style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 20),

                // ─── BIG CONNECT BUTTON ─────────────────────────────────
                GestureDetector(
                  onTap: () => _showConnectDialog(context, person),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF2DD4BF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_rounded,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text('Connect Now',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                letterSpacing: 0.3)),
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

  // ── Person Tile ───────────────────────────────────────────────────────────
  Widget _buildPersonTile(
      BuildContext context, UserModel person, bool isDark, Color cardBg) {
    return GestureDetector(
      onTap: () => _showConnectDialog(context, person),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [AppColors.primary, Color(0xFF2DD4BF)])),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: person.avatarUrl != null && person.avatarUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: person.avatarUrl!, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                person.name.isNotEmpty ? person.name[0].toUpperCase() : 'U',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                if (person.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 2)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name,
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(person.personalityType ?? 'General',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color:
                              isDark ? Colors.white54 : Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.workspace_premium_rounded,
                        size: 12, color: Colors.amber.shade500),
                    const SizedBox(width: 3),
                    Text('CRI ${person.criScore}',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black54)),
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${75 + (person.id.hashCode % 21)}%',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1)),
              child: const Icon(Icons.videocam_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Podcast Card ──────────────────────────────────────────────────────────
  Widget _buildPodcastCard(
      BuildContext context, _Podcast pod, bool isDark, Color cardBg) {
    return GestureDetector(
      onTap: () => _showPodcastSheet(context, pod, isDark),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                      imageUrl: pod.imageUrl,
                      height: 95,
                      width: double.infinity,
                      fit: BoxFit.cover),
                ),
                if (pod.isLive)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('LIVE',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10)),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.headphones_rounded,
                          color: Colors.white, size: 10),
                      const SizedBox(width: 3),
                      Text(pod.listeners,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pod.title,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(pod.category,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color:
                              isDark ? Colors.white54 : Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Host CTA ────────────────────────────────────────────────────────────
  Widget _buildHostCTA(bool isDark, Color cardBg) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Podcast creation coming soon!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A2540), const Color(0xFF0B1120)]
                : [const Color(0xFFEDE9FE), const Color(0xFFD1FAE5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12)),
              child: const Icon(Icons.mic_external_on_rounded,
                  color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Your Own Podcast',
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B))),
                  const SizedBox(height: 3),
                  Text('Share your ideas with the world.',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color:
                              isDark ? Colors.white54 : Colors.grey.shade600)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
