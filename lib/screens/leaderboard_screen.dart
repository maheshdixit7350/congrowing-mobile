import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const _leaders = [
    {'rank': 1, 'name': 'Neha', 'score': '150 hrs', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDwUlzZTpEppXDkzGQXTpVsFTIPI-l6L8fBPZbDaXzjVer9-iKxt5aXElMcdxw1KNyU1d3aKUaJ8L0xYVBqdhVgzIZtdUQr6axSah9SlPjCLSZBq9bxEDL5gwFEyNQf9qC-JfSkEOagHbygY7YGqpofmAE2w2FdT_uAeBaUBuYWzeQn9Qs81Jz4RsbUuwz1iqhb5cajpe9GIseqkZ0ZZfp3SnAsnHt2x2k8J3E2Er5-AB-jCZQcuwz1JRPMBd4wTPfRMzLyHnI0ui4'},
    {'rank': 2, 'name': 'Jatin', 'score': '133 hrs', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCvzpxNzlkNMl4OMTuvqM1f2kxHuWXIhkKNvq_2PhHmotMpL880kJZ69JJZ0d6bsLaMpnoi-LJyBvQ_PI79pO3RDrSPUvCUSsm2-snro_qApZhPPkPUUmfceFh08bLGVVPUXS_k1VY9R-PDH82h6RByM6zMaGTrJHQ_zyicnrtXBk4exltnf4jmRW20cvNs6TV-nLfy_XdmP9YPfnrE_xyfX93uES6-QQ9shV7bJJsvrzZlVU2It1HPapHXLf4eLbisZzq__YGFrss'},
    {'rank': 3, 'name': 'Yash', 'score': '120 hrs', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNtt_wYgFTJxKDSxoIDe7i6JqU92xxzbjtCGgwtezQZBRakLxLj0PU8b5U9rZcYjB77rhNTOKvgdYVrrcROwDCIb2adTFXXxquIyYKAkIDub7mACH911QYYB6oJhw8yCYE10fFqB89m1dtd0youkatWJrSUmTbcUqj0ssaTSPeUjNy_kbVh-Bn74eVnc1bbUuo7d3yWLzzmE4i_lP10qvxqbQETzg6rpb9llMYYf29taPrR7zMZYJtp-IPQpMSdLcCtKLs0gMHkgw'},
    {'rank': 4, 'name': 'David', 'score': '100 hrs', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAfuha8VGG0BPiBwuldEhiK9YAE0ZJIm3M8NQLRRMrpBGwNbyf7YYtzio6JXwwEC5SKcqFfjg7Aczu0Poy_GmrU4zm7YgZvO4m5vURKmgOtHqYqRKmWvzeO3ElnB_-erPhAy00ddbmEwdiv5Wz66YfB5PvjgK2S390u-8j9MFyWGS6n40kKzw2vCeDkDM6DY_9seyet1uzDAIXG9o12iUI5XSMn7uQ9EAvzJhX9pW6kwZCekMVnS5zMLADilTBQL7Nu3l_cUOtl9bY'},
    {'rank': 5, 'name': 'Maya', 'score': '92 hrs', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAGGnQbm1ehPSo92cYwsOLK23IJyCBQwUDE4faKq-R_5y_o0uvALCRrvZ2dzUqSLPUuzco5VF-ax43xaE8bCJLzu0Fp6XRN-2gjZ1BZ5JImcyudet4ygoZ6I6mN5202iTnbQ4HAqCHh_-7_GbU_mythWdepWp7XpSNpdBTnWKurtRXr6xIoIKxflEb9lqQTHJ67--HtYI5aMI1bia6QGBMagllJYfo37AztM5vCcbGH6lO4G07HkfAwl2D-uxNOng6NLBYb0VsLL_I'},
    {'rank': 6, 'name': 'Sameer Sahu', 'score': '85 hrs', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCCphgPcz225mSJx5UUnQf3LRfEjXZ95vXgbNUEASwrhXMdPjJdc1jIMzYe8ZVAnJrHE9XPJTKaaIC7RL31x-CMLRK1q2j_gXTDwThBkmGWnm6cMkZIvqECe_qkQlMbqDXG39bMZgoxthG5kR4q5GKjFrTJW5QQE14dfrXSzvMaXm483i2bLmBcqEM6eWdf9_EVDjvAox2zd257BJG3v2t9bA41RPKx8tPDN38O7RAjaAFeolU329Idfe3E6MLFxc9rOs20FIOio28'},
  ];

  Color _rankColor(int rank) {
    if (rank == 1) return Colors.amber.shade500;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.orange.shade400;
    return AppColors.textSecondaryLight;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => safeNavigateBack(context)),
        title: Text('Leaderboard', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaders.length,
        itemBuilder: (ctx, i) {
          final l = _leaders[i];
          final rank = l['rank'] as int;
          final isMe = l['name'] == 'Sameer Sahu';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.primary.withOpacity(0.06)
                  : (isDark ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isMe ? AppColors.primary.withOpacity(0.2) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: rank <= 3
                      ? Icon(Icons.emoji_events_rounded, color: _rankColor(rank), size: 24)
                      : Text('$rank', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textSecondaryLight)),
                ),
                const SizedBox(width: 12),
                ClipOval(child: CachedNetworkImage(imageUrl: l['url'] as String, width: 48, height: 48, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l['name'] as String,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: isMe ? AppColors.primary : null),
                      ),
                      if (isMe) Text('You', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)),
                    ],
                  ),
                ),
                Text(
                  l['score'] as String,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: rank <= 3 ? _rankColor(rank) : AppColors.textSecondaryLight),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
