import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import '../services/user_service.dart';
import '../services/thoughts_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _posting = false;
  int _remainingPosts = 2;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPostLimits();
  }

  Future<void> _loadPostLimits() async {
    final user = UserService.instance.currentUser;
    final isPremium = user?.isPremium ?? false;
    final remaining =
        await ThoughtsService.instance.getRemainingPosts(isPremium: isPremium);
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _remainingPosts = remaining;
      });
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1080, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
      });
    }
  }

  Future<void> _sharePost() async {
    final text = _textCtrl.text.trim();
    if ((text.isEmpty && _imageBytes == null) || _posting) return;

    if (_remainingPosts <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.block, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isPremium
                        ? 'Daily limit reached! Premium users can post up to ${ThoughtsService.premiumDailyLimit} stories per day.'
                        : 'Daily limit reached! Upgrade to Premium for ${ThoughtsService.premiumDailyLimit} stories/day.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    setState(() => _posting = true);

    try {
      await ThoughtsService.instance.postThought(
        text: text,
        imageBytes: _imageBytes,
        imageName: _imageName,
        isPremium: _isPremium,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Thought shared! Visible for 24h.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        safeNavigateBack(context);
      }
    } catch (e) {
      setState(() => _posting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: GoogleFonts.inter()),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = UserService.instance.currentUser;
    final userName = user?.name ?? 'User';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final limitReached = _remainingPosts <= 0;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => safeNavigateBack(context)),
        title: Text('Share a Thought',
            style:
                GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: GestureDetector(
                onTap: (_posting || limitReached) ? null : _sharePost,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: limitReached ? null : AppColors.primaryGradient,
                    color: limitReached ? Colors.grey.shade400 : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: limitReached
                        ? []
                        : [
                            BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ],
                  ),
                  child: _posting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Share',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(40),
                  ),
                  child: user?.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(user!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                  child: Text(initial,
                                      style: GoogleFonts.inter(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)))))
                      : Center(
                          child: Text(initial,
                              style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14))),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_rounded,
                                  size: 12, color: AppColors.amber),
                              const SizedBox(width: 4),
                              Text('Visible for 24h',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.amber,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _remainingPosts > 0
                                ? AppColors.green.withOpacity(0.1)
                                : AppColors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_remainingPosts left today',
                            style: GoogleFonts.inter(
                              color: _remainingPosts > 0
                                  ? AppColors.green
                                  : AppColors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Text input
            TextField(
              controller: _textCtrl,
              maxLines: null,
              minLines: 5,
              enabled: !limitReached,
              style: GoogleFonts.inter(fontSize: 16),
              decoration: InputDecoration(
                hintText: limitReached
                    ? 'Daily limit reached. Come back tomorrow!'
                    : "What's on your mind, $userName?",
                hintStyle: GoogleFonts.inter(
                  color: limitReached
                      ? AppColors.red.withOpacity(0.5)
                      : AppColors.textSecondaryLight,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),

            // Image preview
            if (_imageBytes != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_imageBytes!,
                        width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _imageBytes = null;
                        _imageName = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Media attachment options
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add to your thought',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MediaOption(
                        icon: Icons.image_rounded,
                        label: 'Photo',
                        color: limitReached ? Colors.grey : Colors.green,
                        onTap: limitReached ? () {} : _pickImage,
                      ),
                      _MediaOption(
                        icon: Icons.tag_faces_rounded,
                        label: 'Feeling',
                        color: limitReached ? Colors.grey : Colors.amber,
                        onTap: () {},
                      ),
                      _MediaOption(
                        icon: Icons.location_on_rounded,
                        label: 'Location',
                        color: limitReached ? Colors.grey : Colors.blue,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOption(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}
