import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/cri_service.dart';
import '../utils/ad_manager.dart';

/// Post-call feedback screen shown after each voice/video call.
/// Matches the reference design with empathy slider, respect & listen toggles.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  double _empathyScore = 5.0;
  bool _wasRespectful = false;
  bool _didListen = false;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  // Passed via arguments
  String _otherName = 'User';
  String _otherUid = '';
  String? _otherAvatarUrl;
  String _callType = 'voice';
  int _callDurationSeconds = 0;

  bool _initialized = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _otherName = args['name'] as String? ?? 'User';
        _otherUid = args['otherUid'] as String? ?? '';
        _otherAvatarUrl = args['avatarUrl'] as String?;
        _callType = args['callType'] as String? ?? 'voice';
        _callDurationSeconds = args['durationSeconds'] as int? ?? 0;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _submit() async {
    if (_otherUid.isEmpty || _submitting) return;
    setState(() => _submitting = true);

    await CriService.instance.submitReview(
      reviewedUserId: _otherUid,
      empathyScore: _empathyScore,
      wasRespectful: _wasRespectful,
      didListen: _didListen,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      callType: _callType,
      callDurationSeconds: _callDurationSeconds,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Review submitted! CRI updated.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

      // Show interstitial ad, then go home
      AdManager.showInterstitialAd(() {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
        }
      });
    }
  }

  String _pronoun() {
    return 'they';
  }

  @override
  Widget build(BuildContext context) {
    final initial = _otherName.isNotEmpty ? _otherName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Feedback',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.black87)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // Title
              Text(
                'Rate your Interaction',
                style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'How was your conversation with $_otherName?',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Avatar & Name
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF8B5CF6).withAlpha(30),
                    backgroundImage: _otherAvatarUrl != null
                        ? NetworkImage(_otherAvatarUrl!)
                        : null,
                    child: _otherAvatarUrl == null
                        ? Text(initial,
                            style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF8B5CF6)))
                        : null,
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_otherName,
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Call Duration: ${_formatDuration(_callDurationSeconds)}',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B5CF6)),
                ),
              ),

              const SizedBox(height: 28),

              // ── Empathy Level ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 20,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Empathy Level',
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _empathyScore.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF8B5CF6)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFF8B5CF6),
                        inactiveTrackColor: const Color(0xFFE0D7F8),
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 14, elevation: 4),
                        overlayColor: const Color(0xFF8B5CF6).withAlpha(30),
                        trackHeight: 8,
                      ),
                      child: Slider(
                        value: _empathyScore,
                        min: 0,
                        max: 10,
                        divisions: 20,
                        onChanged: (v) => setState(() => _empathyScore = v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Not Empathetic',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey.shade500)),
                        Text('Very Empathetic',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Was respectful? ────────────────────────────────────────
              _ToggleCard(
                icon: Icons.favorite_rounded,
                iconBg: const Color(0xFF8B5CF6),
                title: 'Was ${_pronoun()} respectful?',
                subtitle: 'Kindness & tone',
                value: _wasRespectful,
                onChanged: (v) => setState(() => _wasRespectful = v),
              ),

              const SizedBox(height: 12),

              // ── Did they listen? ───────────────────────────────────────
              _ToggleCard(
                icon: Icons.psychology_rounded,
                iconBg: const Color(0xFF8B5CF6),
                title: 'Did ${_pronoun()} listen?',
                subtitle: 'Active listening',
                value: _didListen,
                onChanged: (v) => setState(() => _didListen = v),
              ),

              const SizedBox(height: 16),

              // ── Optional Note ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 20,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'Add a personal note about this interaction...\n(Optional)',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Submit Button ──────────────────────────────────────────
              GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF8B5CF6).withAlpha(100),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_submitting)
                        const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                      else ...[
                        const Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Submit Review & Update Score',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip option
              GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (r) => false),
                child: Text('Skip for now',
                    style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable toggle card for boolean questions.
class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconBg, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF8B5CF6),
            activeTrackColor: const Color(0xFF8B5CF6).withAlpha(80),
          ),
        ],
      ),
    );
  }
}
