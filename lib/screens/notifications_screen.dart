import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
        title: Text('Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all read', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _sectionHeader('NEW'),
          _NotifItem(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDwUlzZTpEppXDkzGQXTpVsFTIPI-l6L8fBPZbDaXzjVer9-iKxt5aXElMcdxw1KNyU1d3aKUaJ8L0xYVBqdhVgzIZtdUQr6axSah9SlPjCLSZBq9bxEDL5gwFEyNQf9qC-JfSkEOagHbygY7YGqpofmAE2w2FdT_uAeBaUBuYWzeQn9Qs81Jz4RsbUuwz1iqhb5cajpe9GIseqkZ0ZZfp3SnAsnHt2x2k8J3E2Er5-AB-jCZQcuwz1JRPMBd4wTPfRMzLyHnI0ui4',
            badgeIcon: Icons.favorite_rounded,
            badgeColor: Colors.red,
            text: 'Neha liked your post',
            subtext: '"ALWAYS DOWN TO EARTH 🌱"',
            time: '2m ago',
            isNew: true,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _NotifItem(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBNtt_wYgFTJxKDSxoIDe7i6JqU92xxzbjtCGgwtezQZBRakLxLj0PU8b5U9rZcYjB77rhNTOKvgdYVrrcROwDCIb2adTFXXxquIyYKAkIDub7mACH911QYYB6oJhw8yCYE10fFqB89m1dtd0youkatWJrSUmTbcUqj0ssaTSPeUjNy_kbVh-Bn74eVnc1bbUuo7d3yWLzzmE4i_lP10qvxqbQETzg6rpb9llMYYf29taPrR7zMZYJtp-IPQpMSdLcCtKLs0gMHkgw',
            badgeIcon: Icons.person_add_rounded,
            badgeColor: AppColors.primary,
            text: 'Yash started following you',
            time: '15m ago',
            isNew: true,
            isDark: isDark,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
              child: Text('Follow', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          _NotifItem(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCvzpxNzlkNMl4OMTuvqM1f2kxHuWXIhkKNvq_2PhHmotMpL880kJZ69JJZ0d6bsLaMpnoi-LJyBvQ_PI79pO3RDrSPUvCUSsm2-snro_qApZhPPkPUUmfceFh08bLGVVPUXS_k1VY9R-PDH82h6RByM6zMaGTrJHQ_zyicnrtXBk4exltnf4jmRW20cvNs6TV-nLfy_XdmP9YPfnrE_xyfX93uES6-QQ9shV7bJJsvrzZlVU2It1HPapHXLf4eLbisZzq__YGFrss',
            badgeIcon: Icons.chat_bubble_rounded,
            badgeColor: Colors.blue,
            text: 'Jatin commented on your post',
            subtext: '"Bhai ekdum fire hai yeh post! 🔥"',
            time: '1h ago',
            isNew: true,
            isDark: isDark,
          ),
          _sectionHeader('EARLIER'),
          _SystemNotif(
            icon: Icons.trending_up_rounded,
            iconColor: Colors.white,
            bgColor: AppColors.primaryGradient,
            text: 'Your CRI score increased to 850',
            time: '3h ago',
            linkText: 'View Analytics →',
            onLink: () => Navigator.pushNamed(context, '/cri-analytics'),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _SystemNotif(
            icon: Icons.emoji_events_rounded,
            iconColor: Colors.amber.shade500,
            bgColor: null,
            bgSolidColor: Colors.amber.shade50,
            text: 'You entered the Top 20% on the leaderboard!',
            time: 'Yesterday',
            linkText: 'View Leaderboard →',
            onLink: () => Navigator.pushNamed(context, '/leaderboard'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondaryLight, letterSpacing: 1.2),
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final String imageUrl;
  final IconData badgeIcon;
  final Color badgeColor;
  final String text;
  final String? subtext;
  final String time;
  final bool isNew;
  final bool isDark;
  final Widget? trailing;

  const _NotifItem({
    required this.imageUrl,
    required this.badgeIcon,
    required this.badgeColor,
    required this.text,
    this.subtext,
    required this.time,
    required this.isNew,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNew
            ? AppColors.primary.withOpacity(0.05)
            : (isDark ? Colors.transparent : Colors.transparent),
        borderRadius: BorderRadius.circular(16),
        border: isNew ? Border.all(color: AppColors.primary.withOpacity(0.1)) : null,
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(child: CachedNetworkImage(imageUrl: imageUrl, width: 48, height: 48, fit: BoxFit.cover)),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(badgeIcon, color: Colors.white, size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.textMainDark : AppColors.textMainLight),
                    children: [
                      TextSpan(text: text.split(' ').first, style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: ' ${text.split(' ').skip(1).join(' ')} '),
                      TextSpan(text: '• $time', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                    ],
                  ),
                ),
                if (subtext != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtext!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _SystemNotif extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final LinearGradient? bgColor;
  final Color? bgSolidColor;
  final String text;
  final String time;
  final String linkText;
  final VoidCallback onLink;
  final bool isDark;

  const _SystemNotif({
    required this.icon,
    required this.iconColor,
    this.bgColor,
    this.bgSolidColor,
    required this.text,
    required this.time,
    required this.linkText,
    required this.onLink,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: bgColor,
              color: bgSolidColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: bgColor != null ? iconColor : iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$text • $time',
                  style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.textMainDark : AppColors.textMainLight),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onLink,
                  child: Text(linkText, style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
