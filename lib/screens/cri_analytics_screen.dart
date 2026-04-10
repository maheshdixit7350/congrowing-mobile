import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import 'dart:math' as math;

class CriAnalyticsScreen extends StatelessWidget {
  const CriAnalyticsScreen({super.key});

  static const _dimensions = [
    {'label': 'Empathy', 'score': 0.85, 'color': 0xFF6366F1},
    {'label': 'Logic', 'score': 0.75, 'color': 0xFF7C3AED},
    {'label': 'Creativity', 'score': 0.70, 'color': 0xFF4F46E5},
    {'label': 'Reliability', 'score': 0.80, 'color': 0xFF06B6D4},
    {'label': 'Openness', 'score': 0.65, 'color': 0xFF8B5CF6},
  ];

  static const _dimensionDetails = [
    {'title': 'Empathy', 'desc': 'Ability to understand and share the feelings of others.', 'tip': 'Listen actively to others without judgement.', 'color': 0xFF6366F1},
    {'title': 'Logic', 'desc': 'Reasoning conducted or assessed according to strict principles.', 'tip': 'Practice solving puzzles and reading analytical articles.', 'color': 0xFF7C3AED},
    {'title': 'Creativity', 'desc': 'The use of imagination or original ideas.', 'tip': 'Try picking up a new hobby or brainstorming solutions.', 'color': 0xFF4F46E5},
    {'title': 'Reliability', 'desc': 'The quality of being trustworthy or of performing consistently.', 'tip': 'Keep your promises and be punctual for meetings.', 'color': 0xFF06B6D4},
    {'title': 'Openness', 'desc': 'Receptiveness to new ideas and experiences.', 'tip': 'Read books outside your usual genre and travel.', 'color': 0xFF8B5CF6},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => safeNavigateBack(context)),
        title: Text('CRI Analytics', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report downloading...', style: GoogleFonts.inter()),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current CRI Score', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('850', style: GoogleFonts.inter(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 1)),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text('+12.5%', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Top 20% of all users', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn('Current Rank', 'Silver III'),
                      _buildStatColumn('Percentile', '82nd'),
                      _buildStatColumn('Streaks', '14 days'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Radar chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dimension Breakdown', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                      Icon(Icons.pie_chart_outline_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: CustomPaint(
                      size: const Size(200, 200),
                      painter: _RadarChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Dimension bars
                  ..._dimensions.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(d['label'] as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('${((d['score'] as double) * 100).toInt()}%',
                                style: GoogleFonts.inter(fontSize: 12, color: Color(d['color'] as int), fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: d['score'] as double,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(d['color'] as int)),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // History
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Score History', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                      Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _HistoryBar(month: 'Oct', score: 720, max: 1000),
                        _HistoryBar(month: 'Nov', score: 780, max: 1000),
                        _HistoryBar(month: 'Dec', score: 800, max: 1000),
                        _HistoryBar(month: 'Jan', score: 820, max: 1000),
                        _HistoryBar(month: 'Feb', score: 840, max: 1000),
                        _HistoryBar(month: 'Mar', score: 850, max: 1000, isActive: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Peer Comparison
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peer Comparison', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  Text('You are scoring well above the average user on our platform.', style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 24),
                  _buildComparisonRow('Empathy', 85, 60, isDark),
                  const SizedBox(height: 16),
                  _buildComparisonRow('Logic', 75, 50, isDark),
                  const SizedBox(height: 16),
                  _buildComparisonRow('Creativity', 70, 75, isDark),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('You', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
                      const SizedBox(width: 16),
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Average', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text('IMPROVEMENT TIPS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            ..._dimensionDetails.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(item['color'] as int).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.tips_and_updates_rounded, color: Color(item['color'] as int), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'] as String, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(item['desc'] as String, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(item['color'] as int).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Tip: ${item['tip']}', style: GoogleFonts.inter(fontSize: 11, color: Color(item['color'] as int), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }

  Widget _buildComparisonRow(String label, double youScore, double avgScore, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${youScore.toInt()}% vs ${avgScore.toInt()}%', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 12, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))),
            LayoutBuilder(
              builder: (ctx, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth * (youScore / 100),
                      height: 12,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                    ),
                    Positioned(
                      left: constraints.maxWidth * (avgScore / 100),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryBar extends StatelessWidget {
  final String month;
  final int score;
  final int max;
  final bool isActive;

  const _HistoryBar({required this.month, required this.score, required this.max, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final height = 100.0 * score / max;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$score', style: GoogleFonts.inter(fontSize: 10, color: isActive ? AppColors.primary : AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 100,
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            height: height,
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.primaryGradient : null,
              color: isActive ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(month, style: GoogleFonts.inter(fontSize: 11, color: isActive ? AppColors.primary : AppColors.textSecondaryLight, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    final bgPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    
    // Draw background circle
    canvas.drawCircle(center, radius, bgPaint);
    
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final fillPaint = Paint()
      ..color = const Color(0xFF7C3AED).withOpacity(0.3)
      ..style = PaintingStyle.fill;
      
    final strokePaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const int sides = 5;
    final double angleStep = (2 * math.pi) / sides;
    const double startAngle = -math.pi / 2;

    // Draw concentric polygons (web)
    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
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
    
    // Draw spokes
    for(int i = 0; i < sides; i++) {
      final angle = startAngle + i * angleStep;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
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
      
      // Draw points at vertices
      canvas.drawCircle(Offset(x,y), 4, Paint()..color = const Color(0xFF6366F1));
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);
    
    // Draw center point
    canvas.drawCircle(center, 3, Paint()..color = Colors.grey.shade400);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
