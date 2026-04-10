import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
        title: Text('Terms of Service',
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
              Text('Terms of Service', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
              Text('Last updated: March 2026', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 20),
              _section('1. Acceptance of Terms',
                  'By accessing and using ConGrowing, you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.'),
              _section('2. User Accounts',
                  'You are responsible for maintaining the confidentiality of your account credentials. You must provide accurate and complete information when creating your account. You are responsible for all activities that occur under your account.'),
              _section('3. Acceptable Use',
                  'You agree not to use ConGrowing for any unlawful purpose or in any way that could damage, disable, or impair the service. You must not post harmful, offensive, or misleading content.'),
              _section('4. User Content',
                  'You retain ownership of the content you post. By posting content on ConGrowing, you grant us a non-exclusive, royalty-free license to use, display, and distribute your content within the platform.'),
              _section('5. CRI Score',
                  'The Conversational Relationship Index (CRI) score is a metric for engagement and growth. It is calculated based on your interactions and should not be considered a definitive measure of personal worth.'),
              _section('6. Intellectual Property',
                  'ConGrowing and its original content, features, and functionality are owned by ConGrowing and are protected by international copyright, trademark, and other intellectual property laws.'),
              _section('7. Termination',
                  'We may terminate or suspend your account at any time, without prior notice, for conduct that we believe violates these Terms of Service or is harmful to other users.'),
              _section('8. Disclaimer',
                  'ConGrowing is provided "as is" without warranties of any kind, either express or implied. We do not guarantee that the service will be uninterrupted, secure, or error-free.'),
              _section('9. Limitation of Liability',
                  'In no event shall ConGrowing be liable for any indirect, incidental, special, or consequential damages arising out of or in connection with use of the service.'),
              _section('10. Changes to Terms',
                  'We reserve the right to modify or replace these Terms at any time. We will provide notice of significant changes. Your continued use constitutes acceptance of the new Terms.'),
              _section('11. Contact',
                  'For any questions regarding these Terms, please contact us at support@congrowing.com.'),
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
