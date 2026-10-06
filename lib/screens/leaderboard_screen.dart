import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  Color _rankColor(int rank) {
    if (rank == 1) return Colors.amber.shade500;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.orange.shade400;
    return AppColors.textSecondaryLight;
  }

  IconData _rankIcon(int rank) {
    if (rank == 1) return Icons.emoji_events_rounded;
    if (rank == 2) return Icons.emoji_events_rounded;
    if (rank == 3) return Icons.emoji_events_rounded;
    return Icons.tag;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => safeNavigateBack(context),
        ),
        title: Text('Leaderboard', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      body: StreamBuilder<List<LeaderboardEntry>>(
        stream: LeaderboardService.instance.streamLeaderboard(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final leaders = snapshot.data ?? [];

          if (leaders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No users yet',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start connecting to appear on the leaderboard!',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaders.length,
            itemBuilder: (ctx, i) {
              final entry = leaders[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: entry.isMe
                      ? AppColors.primary.withOpacity(0.06)
                      : (isDark ? AppColors.cardDark : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: entry.isMe
                        ? AppColors.primary.withOpacity(0.2)
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                  ),
                  boxShadow: entry.isMe ? [
                    BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                  ] : [],
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 32,
                      child: entry.rank <= 3
                          ? Icon(Icons.emoji_events_rounded, color: _rankColor(entry.rank), size: 24)
                          : Text(
                              '${entry.rank}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textSecondaryLight),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withAlpha(40),
                        border: entry.isMe
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: entry.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                entry.avatarUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                                    style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                                style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: entry.isMe ? AppColors.primary : null,
                            ),
                          ),
                          if (entry.isMe)
                            Text('You', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: entry.rank <= 3
                            ? _rankColor(entry.rank).withOpacity(0.1)
                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entry.criScore}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: entry.rank <= 3 ? _rankColor(entry.rank) : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
