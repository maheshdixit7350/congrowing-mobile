import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: Text('Privacy Policy',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy Policy', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
              Text('Last updated: March 2026', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 20),
              _section('1. Information We Collect',
                  'We collect information you provide directly, such as your name, email address, profile information, and content you post. We also automatically collect usage data including device information, log data, and analytics.'),
              _section('2. How We Use Your Information',
                  'We use the information collected to provide, maintain, and improve our services, personalize your experience, communicate with you, and ensure the safety and integrity of our platform.'),
              _section('3. Information Sharing',
                  'We do not sell your personal information. We may share information with service providers who assist in operating our platform, or when required by law.'),
              _section('4. Data Security',
                  'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.'),
              _section('5. Your Rights',
                  'You have the right to access, correct, or delete your personal information. You can update your profile through the app settings or contact us for assistance.'),
              _section('6. Cookies and Tracking',
                  'We use cookies and similar technologies to enhance your experience, analyze usage patterns, and deliver personalized content.'),
              _section('7. Children\'s Privacy',
                  'Our service is not directed to children under 13. We do not knowingly collect personal information from children under 13.'),
              _section('8. Changes to This Policy',
                  'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.'),
              _section('9. Contact Us',
                  'If you have any questions about this Privacy Policy, please contact us at support@congrowing.com.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.5),
          ),
        ],
      ),
    );
  }
}
