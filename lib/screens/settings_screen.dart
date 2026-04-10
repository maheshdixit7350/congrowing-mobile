import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart' show firebaseInitialized;
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import '../utils/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _privateAccount = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('notifications') ?? true;
      _privateAccount = prefs.getBool('private_account') ?? false;
    });
  }

  Future<void> _setNotifications(bool v) async {
    setState(() => _notifications = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(_snack(
        v ? 'Notifications enabled' : 'Notifications disabled',
        v ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
      ));
    }
  }

  Future<void> _setPrivateAccount(bool v) async {
    setState(() => _privateAccount = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('private_account', v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(_snack(
        v ? 'Account set to private' : 'Account set to public',
        v ? Icons.lock_rounded : Icons.lock_open_rounded,
      ));
    }
  }

  SnackBar _snack(String msg, IconData icon) => SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      );

  // ── Change Password Dialog ──────────────────────────────────────────────
  void _showChangePasswordDialog(bool isDark) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurr = true, obscureNew = true, obscureConf = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Change Password', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(currentCtrl, 'Current Password', obscureCurr, isDark, () => setD(() => obscureCurr = !obscureCurr)),
                const SizedBox(height: 14),
                _dialogField(newCtrl, 'New Password', obscureNew, isDark, () => setD(() => obscureNew = !obscureNew)),
                const SizedBox(height: 14),
                _dialogField(confirmCtrl, 'Confirm New Password', obscureConf, isDark, () => setD(() => obscureConf = !obscureConf)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white60 : Colors.grey)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (currentCtrl.text.isEmpty || newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(_snack('Please fill all fields', Icons.warning_rounded));
                      return;
                    }
                    if (newCtrl.text != confirmCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(_snack('Passwords do not match', Icons.error_rounded));
                      return;
                    }
                    if (newCtrl.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(_snack('Password must be at least 6 characters', Icons.error_rounded));
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(_snack('Password updated successfully!', Icons.check_circle_rounded));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text('Update', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, bool obscure, bool isDark, VoidCallback toggle) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: GestureDetector(
            onTap: toggle,
            child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
          ),
        ),
      ),
    );
  }

  // ── Privacy Settings Dialog ─────────────────────────────────────────────
  void _showPrivacyDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        bool blockMessages = false;
        bool hideActivity = false;
        bool hideOnline = false;
        return StatefulBuilder(
          builder: (ctx, setBS) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 20),
                Text('Privacy Settings', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                const SizedBox(height: 6),
                Text('Control who can see your information', style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                const SizedBox(height: 20),
                _privacySwitchTile('Block Direct Messages', 'Only friends can message you', Icons.message_outlined, blockMessages, isDark, (v) => setBS(() => blockMessages = v)),
                _privacySwitchTile('Hide Activity Status', 'Others won\'t see your activity', Icons.history_rounded, hideActivity, isDark, (v) => setBS(() => hideActivity = v)),
                _privacySwitchTile('Hide Online Status', 'Appear offline to others', Icons.circle_outlined, hideOnline, isDark, (v) => setBS(() => hideOnline = v)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2DD4BF)]),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(_snack('Privacy settings saved', Icons.shield_rounded));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text('Save Settings', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _privacySwitchTile(String title, String subtitle, IconData icon, bool value, bool isDark, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(activeColor: AppColors.primary, value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  // ── Clear Cache Dialog ──────────────────────────────────────────────────
  void _showClearCacheDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Cache', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('This will clear all temporary data and cached images. Your login and preferences will be kept.',
            style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter())),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(_snack('Cache cleared successfully', Icons.cleaning_services_rounded));
            },
            child: Text('Clear', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Delete Account Dialog ───────────────────────────────────────────────
  void _showDeleteAccountDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text('Delete Account', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.red)),
          ],
        ),
        content: Text(
          'This action is permanent and cannot be undone. All your data, posts, and connections will be deleted forever.',
          style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Keep Account', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: Text('Delete Forever', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Logout Dialog ───────────────────────────────────────────────────────
  void _showLogoutDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter())),
          TextButton(
            onPressed: () async {
              try {
                if (firebaseInitialized) {
                  await FirebaseAuth.instance.signOut();
                }
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                // Even if Firebase fails, still log out locally
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            },
            child: Text('Log Out', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProviderScope.of(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => safeNavigateBack(context)),
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Premium ──────────────────────────────────────────────────
          _SectionHeader('PREMIUM'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F2F44), Color(0xFF1A4A6B)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F2F44).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFF4C430), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Get ConGrowing Premium', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('Voice calls, ad-free & exclusive badges', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              ],
            ),
          ),

          // ── Account ──────────────────────────────────────────────────
          _SectionHeader('ACCOUNT'),
          _SettingsTile(isDark: isDark, icon: Icons.person_outline_rounded, label: 'Edit Profile',
            subtitle: 'Update your name, bio & photo',
            onTap: () => Navigator.pushNamed(context, '/edit-profile')),
          _SettingsTile(isDark: isDark, icon: Icons.lock_outline_rounded, label: 'Change Password',
            subtitle: 'Update your login credentials',
            onTap: () => _showChangePasswordDialog(isDark)),
          _SettingsTile(isDark: isDark, icon: Icons.verified_user_outlined, label: 'Privacy',
            subtitle: 'Control your visibility & data',
            onTap: () => _showPrivacyDialog(isDark)),

          const SizedBox(height: 8),
          // ── Preferences ──────────────────────────────────────────────
          _SectionHeader('PREFERENCES'),
          _SettingsSwitchTile(
            isDark: isDark,
            icon: Icons.notifications_outlined,
            label: 'Push Notifications',
            subtitle: 'Get alerts for messages & calls',
            value: _notifications,
            onChanged: _setNotifications,
          ),
          _SettingsSwitchTile(
            isDark: isDark,
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            subtitle: 'Easier on the eyes at night',
            value: themeProvider.isDark,
            onChanged: (v) => themeProvider.setDarkMode(v),
          ),
          _SettingsSwitchTile(
            isDark: isDark,
            icon: Icons.visibility_off_outlined,
            label: 'Private Account',
            subtitle: 'Only approved followers see you',
            value: _privateAccount,
            onChanged: _setPrivateAccount,
          ),

          const SizedBox(height: 8),
          // ── App ──────────────────────────────────────────────────────
          _SectionHeader('APP'),
          _SettingsTile(isDark: isDark, icon: Icons.cached_rounded, label: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: () => _showClearCacheDialog(isDark)),
          _SettingsTile(isDark: isDark, icon: Icons.language_rounded, label: 'Language',
            subtitle: 'English (US)',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(_snack('More languages coming soon!', Icons.translate_rounded));
            }),
          _SettingsTile(isDark: isDark, icon: Icons.share_rounded, label: 'Share App',
            subtitle: 'Invite friends to ConGrowing',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(_snack('Share link copied to clipboard!', Icons.copy_rounded));
              Clipboard.setData(const ClipboardData(text: 'https://congrowing.app/download'));
            }),

          const SizedBox(height: 8),
          // ── About ────────────────────────────────────────────────────
          _SectionHeader('ABOUT'),
          _SettingsTile(isDark: isDark, icon: Icons.info_outline_rounded, label: 'About ConGrowing',
            subtitle: 'v1.0.0',
            onTap: () => Navigator.pushNamed(context, '/about')),
          _SettingsTile(isDark: isDark, icon: Icons.article_outlined, label: 'Terms of Service',
            onTap: () => Navigator.pushNamed(context, '/terms')),
          _SettingsTile(isDark: isDark, icon: Icons.privacy_tip_outlined, label: 'Privacy Policy',
            onTap: () => Navigator.pushNamed(context, '/privacy-policy')),
          _SettingsTile(isDark: isDark, icon: Icons.bug_report_outlined, label: 'Report a Bug',
            subtitle: 'Help us improve the app',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(_snack('Bug report form opening...', Icons.bug_report_rounded));
            }),

          const SizedBox(height: 16),
          // ── Logout Button ────────────────────────────────────────────
          GestureDetector(
            onTap: () => _showLogoutDialog(isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.red.withOpacity(0.3) : Colors.red.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Log Out', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── Delete Account ───────────────────────────────────────────
          GestureDetector(
            onTap: () => _showDeleteAccountDialog(isDark),
            child: Center(
              child: Text('Delete Account', style: GoogleFonts.inter(color: Colors.red.shade300, fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 24),

          // Version footer
          Center(
            child: Text('ConGrowing v1.0.0 · Made with ♥',
              style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 11)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _SettingsTile({required this.isDark, required this.icon, required this.label, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                      if (subtitle != null)
                        Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppColors.textSecondaryLight, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SettingsSwitchTile({required this.isDark, required this.icon, required this.label, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                  if (subtitle != null)
                    Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500)),
                ],
              ),
            ),
            Switch(
              activeColor: AppColors.primary,
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
