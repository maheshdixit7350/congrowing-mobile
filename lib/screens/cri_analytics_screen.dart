import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import '../services/user_service.dart';
import '../services/daily_missions_service.dart';
import '../utils/ad_manager.dart';
import 'iq_challenge_screen.dart';
import 'dart:math' as math;

class CriAnalyticsScreen extends StatefulWidget {
  const CriAnalyticsScreen({super.key});

  @override
  State<CriAnalyticsScreen> createState() => _CriAnalyticsScreenState();
}

class _CriAnalyticsScreenState extends State<CriAnalyticsScreen>
    with TickerProviderStateMixin {
  List<DailyMission> _missions = [];
  int _streak = 0;
  bool _loading = true;
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = CurvedAnimation(
        parent: _scoreAnimController, curve: Curves.easeOutCubic);
    _loadData();
  }

  Future<void> _loadData() async {
    final missions = await DailyMissionsService.instance.getTodayMissions();
    final streak = await DailyMissionsService.instance.getStreak();
    if (mounted) {
      setState(() {
        _missions = missions;
        _streak = streak;
        _loading = false;
      });
      _scoreAnimController.forward();
    }
  }

  void _resetChartData() {
    setState(() {
      _loading = true;
    });
    _scoreAnimController.reset();
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CRI Chart data & metrics refreshed cleanly'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show call-type bottom sheet (Voice / Video).
  void _showCallTypeSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.call,
                                color: Colors.white, size: 28),
                          ),
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
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.videocam,
                                color: Colors.white, size: 28),
                          ),
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

  /// Handle mission tap.
  Future<void> _completeMission(DailyMission mission) async {
    if (mission.isCompleted) return;

    // Talk → open call sheet
    if (mission.type == 'talk') {
      _showCallTypeSheet();
      return;
    }

    // Thought → navigate to thoughts/play page
    if (mission.type == 'thought') {
      await Navigator.pushNamed(context, '/play');
      // Mark as completed after returning (user may have shared a thought)
      await DailyMissionsService.instance.completeMission(mission.id);
      await _loadData();
      return;
    }

    // IQ → open IQ challenge
    if (mission.type == 'iq') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const IQChallengeScreen()),
      );
      await DailyMissionsService.instance.completeMission(mission.id);
      await _loadData();
      return;
    }

    // Others — show confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Complete Mission?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mission.title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(mission.description,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('+${mission.criReward} CRI',
                      style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Complete',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DailyMissionsService.instance.completeMission(mission.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Mission complete! +${mission.criReward} CRI',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = UserService.instance.currentUser;
    final criScore = user?.criScore ?? 0;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // Custom SliverAppBar with gradient
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: Colors.white),
                    ),
                    onPressed: () => safeNavigateBack(context),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Clean & Refresh Chart Data',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cleaning_services_rounded,
                            size: 16, color: Colors.white),
                      ),
                      onPressed: _resetChartData,
                    ),
                    const SizedBox(width: 8),
                  ],
                  backgroundColor: const Color(0xFF4F46E5),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF7C3AED),
                            Color(0xFF4F46E5),
                            Color(0xFF06B6D4)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('CRI Analytics',
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.local_fire_department_rounded,
                                            color: Colors.orangeAccent,
                                            size: 16),
                                        const SizedBox(width: 4),
                                        Text('$_streak day streak',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Big Score Display
                              AnimatedBuilder(
                                animation: _scoreAnim,
                                builder: (context, _) {
                                  final displayScore =
                                      (criScore * _scoreAnim.value).round();
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$displayScore',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 72,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 12, left: 8),
                                        child: Text('/1000',
                                            style: GoogleFonts.inter(
                                                color: Colors.white60,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              // Level indicator
                              Row(
                                children: [
                                  _buildLevelBadge(criScore),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Character Rating Index',
                                    style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // CRI progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: criScore / 1000,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Daily Missions Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _buildDailyMissions(isDark),
                  ),
                ),

                // Dimension Breakdown
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildDimensionBreakdown(isDark, user),
                  ),
                ),

                // Score History
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildScoreHistory(isDark),
                  ),
                ),

                // How CRI Works
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildHowCriWorks(isDark),
                  ),
                ),

                // Improvement Tips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildImprovementTips(isDark),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildLevelBadge(int score) {
    String level;
    Color color;
    if (score >= 900) {
      level = 'Diamond';
      color = const Color(0xFF60A5FA);
    } else if (score >= 700) {
      level = 'Gold';
      color = const Color(0xFFFBBF24);
    } else if (score >= 500) {
      level = 'Silver';
      color = const Color(0xFF9CA3AF);
    } else if (score >= 300) {
      level = 'Bronze';
      color = const Color(0xFFF97316);
    } else {
      level = 'Starter';
      color = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, color: color, size: 14),
          const SizedBox(width: 4),
          Text(level,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDailyMissions(bool isDark) {
    final completed = _missions.where((m) => m.isCompleted).length;
    final total = _missions.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Missions',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    Text('$completed/$total completed',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: 12,
                width: (MediaQuery.of(context).size.width - 80) * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7C3AED),
                      Color(0xFF4F46E5),
                      Color(0xFF06B6D4)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mission list
          ...List.generate(_missions.length, (i) {
            final mission = _missions[i];
            return _buildMissionCard(mission, isDark, i);
          }),

          if (completed == total && total > 0) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('All missions completed! 🎉',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMissionCard(DailyMission mission, bool isDark, int index) {
    IconData iconData;
    Color iconColor;

    switch (mission.type) {
      case 'talk':
        iconData = Icons.call_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case 'quiz':
        iconData = Icons.quiz_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
      case 'grammar':
        iconData = Icons.menu_book_rounded;
        iconColor = const Color(0xFF3B82F6);
        break;
      case 'iq':
        iconData = Icons.psychology_rounded;
        iconColor = const Color(0xFF8B5CF6);
        break;
      case 'puzzle':
        iconData = Icons.extension_rounded;
        iconColor = const Color(0xFFEF4444);
        break;
      case 'thought':
        iconData = Icons.lightbulb_rounded;
        iconColor = const Color(0xFFF97316);
        break;
      default:
        iconData = Icons.star_rounded;
        iconColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => _completeMission(mission),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: mission.isCompleted
              ? (isDark
                  ? AppColors.green.withOpacity(0.1)
                  : const Color(0xFFF0FDF4))
              : (isDark ? Colors.grey.shade900 : const Color(0xFFFAFAFA)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: mission.isCompleted
                ? AppColors.green.withOpacity(0.3)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // Mission icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: mission.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: mission.isCompleted ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mission.description,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Checkbox (auto-checked when completed)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color:
                    mission.isCompleted ? AppColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: mission.isCompleted
                      ? AppColors.green
                      : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  width: 2,
                ),
              ),
              child: mission.isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionBreakdown(bool isDark, dynamic user) {
    final empathy = (user?.avgEmpathy ?? 5.0) / 10.0;
    final respect = (user?.respectRate ?? 0.0) / 100.0;
    final listen = (user?.listenRate ?? 0.0) / 100.0;
    final totalCalls = (user?.totalCalls ?? 0) as int;
    final engagement = math.min(totalCalls / 20.0, 1.0);
    final creativity = _missions.isEmpty
        ? 0.5
        : _missions.where((m) => m.isCompleted).length / _missions.length;

    final dimensions = [
      {
        'label': 'Empathy',
        'score': empathy,
        'color': 0xFF6366F1,
        'icon': Icons.favorite_rounded
      },
      {
        'label': 'Respect',
        'score': respect,
        'color': 0xFF7C3AED,
        'icon': Icons.handshake_rounded
      },
      {
        'label': 'Listening',
        'score': listen,
        'color': 0xFF06B6D4,
        'icon': Icons.hearing_rounded
      },
      {
        'label': 'Engagement',
        'score': engagement,
        'color': 0xFF10B981,
        'icon': Icons.trending_up_rounded
      },
      {
        'label': 'Growth',
        'score': creativity,
        'color': 0xFFF59E0B,
        'icon': Icons.auto_awesome_rounded
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Dimension Breakdown',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radar_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: CustomPaint(
              size: const Size(220, 220),
              painter: _RadarChartPainter(
                scores: dimensions.map((d) => d['score'] as double).toList(),
                labels: dimensions.map((d) => d['label'] as String).toList(),
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...dimensions.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(d['icon'] as IconData,
                            color: Color(d['color'] as int), size: 16),
                        const SizedBox(width: 8),
                        Text(d['label'] as String,
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(
                          '${((d['score'] as double) * 100).toInt()}%',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Color(d['color'] as int),
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDarkElevated
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: d['score'] as double,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(d['color'] as int).withValues(alpha: 0.6),
                                  Color(d['color'] as int),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(d['color'] as int).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildScoreHistory(bool isDark) {
    final uid = UserService.instance.currentUser?.id;
    if (uid == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
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
                  gradient: AppColors.cyanGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Score History',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your CRI score changes based on call feedback and daily activities.',
            style: GoogleFonts.inter(
                fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final user = UserService.instance.currentUser;
              final score = user?.criScore ?? 0;
              final reviews = user?.totalReviews ?? 0;
              final calls = user?.totalCalls ?? 0;

              return Row(
                children: [
                  _buildStatCard('Current\nScore', '$score',
                      const Color(0xFF7C3AED), isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('Total\nReviews', '$reviews',
                      const Color(0xFF06B6D4), isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('Total\nCalls', '$calls',
                      const Color(0xFF10B981), isDark),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 28, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey,
                    height: 1.3),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildHowCriWorks(bool isDark) {
    final items = [
      {
        'icon': Icons.call_rounded,
        'title': 'Make Calls',
        'desc': 'Connect with people to get reviewed',
        'color': const Color(0xFF10B981)
      },
      {
        'icon': Icons.rate_review_rounded,
        'title': 'Get Feedback',
        'desc': 'Other users rate your conversation skills',
        'color': const Color(0xFF3B82F6)
      },
      {
        'icon': Icons.trending_up_rounded,
        'title': 'Score Updates',
        'desc': 'Your CRI recalculates based on reviews',
        'color': const Color(0xFF7C3AED)
      },
      {
        'icon': Icons.people_rounded,
        'title': 'Match Better',
        'desc': 'Higher CRI = better conversation partners',
        'color': const Color(0xFFF59E0B)
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How CRI Works',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'CRI (Character Rating Index) reflects your conversation quality.',
            style: GoogleFonts.inter(
                fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item['icon'] as IconData,
                          color: item['color'] as Color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] as String,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(item['desc'] as String,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white38 : Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildImprovementTips(bool isDark) {
    final tips = [
      {
        'icon': Icons.hearing_rounded,
        'title': 'Active Listening',
        'tip':
            'Focus on understanding before responding. Ask follow-up questions.',
        'color': const Color(0xFF6366F1)
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Show Empathy',
        'tip': 'Acknowledge feelings and share related experiences.',
        'color': const Color(0xFFEF4444)
      },
      {
        'icon': Icons.schedule_rounded,
        'title': 'Be Consistent',
        'tip': 'Regular conversations build trust and improve scores.',
        'color': const Color(0xFF10B981)
      },
      {
        'icon': Icons.lightbulb_rounded,
        'title': 'Daily Missions',
        'tip': 'Complete daily missions to boost your CRI score.',
        'color': const Color(0xFFF59E0B)
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Improvement Tips',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (item['color'] as Color)
                      .withOpacity(isDark ? 0.08 : 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: (item['color'] as Color).withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData,
                        color: item['color'] as Color, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] as String,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(item['tip'] as String,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white38 : Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<double> scores;
  final List<String> labels;
  final bool isDark;

  _RadarChartPainter(
      {required this.scores, required this.labels, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius + 5, bgPaint);

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = const Color(0xFF7C3AED).withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final int sides = scores.length;
    final double angleStep = (2 * math.pi) / sides;
    const double startAngle = -math.pi / 2;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
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

    for (int i = 0; i < sides; i++) {
      final angle = startAngle + i * angleStep;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + i * angleStep;
      final r = radius * scores[i].clamp(0.0, 1.0);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }

      canvas.drawCircle(
          Offset(x, y), 5, Paint()..color = const Color(0xFF6366F1));
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white);
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    for (int i = 0; i < sides; i++) {
      final angle = startAngle + i * angleStep;
      final labelRadius = radius + 20;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
