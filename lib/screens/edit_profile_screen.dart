import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _collegeCtrl;
  late AnimationController _saveAnimCtrl;
  late Animation<double> _saveScale;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = UserService.instance.currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _collegeCtrl = TextEditingController(text: user?.college ?? '');

    _nameCtrl.addListener(_onFieldChanged);
    _usernameCtrl.addListener(_onFieldChanged);
    _bioCtrl.addListener(_onFieldChanged);
    _collegeCtrl.addListener(_onFieldChanged);

    _saveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _saveScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _saveAnimCtrl, curve: Curves.easeInOut),
    );
  }

  void _onFieldChanged() {
    final user = UserService.instance.currentUser;
    final changed = _nameCtrl.text.trim() != (user?.name ?? '') ||
        _usernameCtrl.text.trim() != (user?.username ?? '') ||
        _bioCtrl.text.trim() != (user?.bio ?? '') ||
        _collegeCtrl.text.trim() != (user?.college ?? '');
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _collegeCtrl.dispose();
    _saveAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Name cannot be empty', isError: true);
      return;
    }
    if (_usernameCtrl.text.trim().isEmpty) {
      _showSnack('Username cannot be empty', isError: true);
      return;
    }

    _saveAnimCtrl.forward().then((_) => _saveAnimCtrl.reverse());
    setState(() => _isLoading = true);

    try {
      await UserService.instance.updateProfile({
        'name': _nameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'college': _collegeCtrl.text.trim(),
      });

      // Reload user data
      await UserService.instance.loadCurrentUser();

      if (mounted) {
        _showSnack('Profile updated successfully! ✨');
        setState(() => _hasChanges = false);
        // Go back after a brief moment
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to update: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      backgroundColor: isError ? AppColors.red : AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = UserService.instance.currentUser;
    final initial =
        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U';

    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FC);
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final textMain = isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final textSub =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            toolbarHeight: 56,
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: textMain),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Edit Profile',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: textMain)),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ScaleTransition(
                  scale: _saveScale,
                  child: GestureDetector(
                    onTap: (_hasChanges && !_isLoading) ? _saveProfile : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        gradient:
                            _hasChanges ? AppColors.primaryGradient : null,
                        color: _hasChanges
                            ? null
                            : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _hasChanges
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Save',
                              style: GoogleFonts.inter(
                                color: _hasChanges ? Colors.white : textSub,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              )),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                children: [
                  // ── Avatar Section ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            border: Border.all(
                              color:
                                  isDark ? Colors.grey.shade700 : Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            image: user?.avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(user!.avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: user?.avatarUrl == null
                              ? Center(
                                  child: Text(initial,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                      )),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(user?.name ?? 'User',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: textMain)),
                        const SizedBox(height: 2),
                        Text('@${user?.username ?? 'user'}',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: textSub)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Fields Section ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Personal Information',
                            Icons.person_outline_rounded, textMain),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Full Name',
                          ctrl: _nameCtrl,
                          isDark: isDark,
                          icon: Icons.badge_outlined,
                          hint: 'Enter your full name',
                          borderColor: borderColor,
                          cardColor: cardColor,
                          textMain: textMain,
                          textSub: textSub,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Username',
                          ctrl: _usernameCtrl,
                          isDark: isDark,
                          icon: Icons.alternate_email_rounded,
                          hint: 'Choose a unique username',
                          borderColor: borderColor,
                          cardColor: cardColor,
                          textMain: textMain,
                          textSub: textSub,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Bio Section ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                            'About You', Icons.edit_note_rounded, textMain),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Bio',
                          ctrl: _bioCtrl,
                          isDark: isDark,
                          icon: Icons.short_text_rounded,
                          hint: 'Write something about yourself...',
                          maxLines: 3,
                          borderColor: borderColor,
                          cardColor: cardColor,
                          textMain: textMain,
                          textSub: textSub,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'College / Institution',
                          ctrl: _collegeCtrl,
                          isDark: isDark,
                          icon: Icons.school_outlined,
                          hint: 'Your college or institution',
                          borderColor: borderColor,
                          cardColor: cardColor,
                          textMain: textMain,
                          textSub: textSub,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Info Note ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          AppColors.primary.withOpacity(isDark ? 0.08 : 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your profile information is visible to other users on the platform.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textSub,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, IconData icon, Color c) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(t,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 15, color: c)),
        ],
      );

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required bool isDark,
    required IconData icon,
    required String hint,
    required Color borderColor,
    required Color cardColor,
    required Color textMain,
    required Color textSub,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textSub,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: GoogleFonts.inter(fontSize: 14, color: textMain),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(icon, size: 18, color: textSub),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 38, minHeight: 0),
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                  fontSize: 13, color: textSub.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
