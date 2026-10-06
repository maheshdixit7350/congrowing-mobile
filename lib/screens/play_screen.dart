import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/thoughts_service.dart';
import '../services/user_service.dart';

/// Ephemeral Thoughts screen – users post text + optional images that disappear after 24 hours.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final _textController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isPosting = false;
  int _remainingPosts = 2;
  bool _isPremium = false;

  /// Timer for updating countdown displays every minute.
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadPostLimits();
    // Refresh countdown display every minute
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1080, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
      });
    }
  }

  Future<void> _postThought() async {
    final text = _textController.text.trim();
    if ((text.isEmpty && _selectedImageBytes == null) || _isPosting) return;

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

    setState(() => _isPosting = true);

    try {
      await ThoughtsService.instance.postThought(
        text: text,
        imageBytes: _selectedImageBytes,
        imageName: _selectedImageName,
        isPremium: _isPremium,
      );

      _textController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
        _isPosting = false;
      });

      // Refresh remaining posts
      await _loadPostLimits();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Thought shared! Visible for 24 hours.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isPosting = false);
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

  void _showCommentSheet(BuildContext context, Thought thought, bool isDark) {
    final commentCtrl = TextEditingController();
    final myUid = UserService.instance.currentUser?.id ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Comments',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 18)),
              ),
              Expanded(
                child: StreamBuilder<List<ThoughtComment>>(
                  stream: ThoughtsService.instance.streamComments(thought.id),
                  builder: (ctx, snapshot) {
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No comments yet',
                                style: GoogleFonts.inter(
                                    color: Colors.grey, fontSize: 14)),
                            Text('Be the first to comment!',
                                style: GoogleFonts.inter(
                                    color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollCtrl,
                      itemCount: comments.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (ctx, i) {
                        final comment = comments[i];
                        final initial = comment.userName.isNotEmpty
                            ? comment.userName[0].toUpperCase()
                            : '?';
                        final timeAgo =
                            ThoughtsService.getTimeAgo(comment.createdAt);
                        final isMe = comment.userId == myUid;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withAlpha(40),
                                ),
                                child: comment.userAvatarUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                            comment.userAvatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                                child: Text(initial,
                                                    style: GoogleFonts.inter(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12)))))
                                    : Center(
                                        child: Text(initial,
                                            style: GoogleFonts.inter(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(comment.userName,
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                        const SizedBox(width: 8),
                                        Text(timeAgo,
                                            style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(comment.text,
                                        style: GoogleFonts.inter(
                                            fontSize: 13, height: 1.4)),
                                  ],
                                ),
                              ),
                              if (isMe)
                                GestureDetector(
                                  onTap: () async {
                                    await ThoughtsService.instance
                                        .deleteComment(comment.id);
                                  },
                                  child: Icon(Icons.close,
                                      size: 14, color: Colors.grey.shade400),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Comment input
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 8 + MediaQuery.of(ctx).viewInsets.bottom),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                  border: Border(
                      top: BorderSide(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: GoogleFonts.inter(
                              color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final text = commentCtrl.text.trim();
                        if (text.isEmpty) return;
                        try {
                          await ThoughtsService.instance.addComment(
                            thoughtId: thought.id,
                            text: text,
                          );
                          commentCtrl.clear();
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppColors.red),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = UserService.instance.currentUser;
    final myUid = UserService.instance.currentUser?.id ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          title: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  'Thoughts',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('24h',
                    style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          actions: [
            // Daily limit indicator
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _remainingPosts > 0
                    ? AppColors.green.withOpacity(0.1)
                    : AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _remainingPosts > 0 ? Icons.edit_note_rounded : Icons.block,
                    size: 14,
                    color:
                        _remainingPosts > 0 ? AppColors.green : AppColors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_remainingPosts/${_isPremium ? ThoughtsService.premiumDailyLimit : ThoughtsService.normalDailyLimit}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          _remainingPosts > 0 ? AppColors.green : AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text('About Thoughts',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    content: Text(
                      'Share your thoughts, ideas, and images with the community. '
                      'All thoughts automatically disappear after 24 hours.\n\n'
                      '📝 Normal users: ${ThoughtsService.normalDailyLimit} posts/day\n'
                      '⭐ Premium users: ${ThoughtsService.premiumDailyLimit} posts/day',
                      style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Got it',
                            style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Compose thought card
                  SliverToBoxAdapter(
                    child: _buildComposeCard(isDark, user),
                  ),

                  // Divider
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Live Feed',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Thoughts feed
                  StreamBuilder<List<Thought>>(
                    stream: ThoughtsService.instance.streamRecentThoughts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverFillRemaining(
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)),
                        );
                      }

                      final thoughts = snapshot.data ?? [];

                      if (thoughts.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lightbulb_outline_rounded,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No thoughts yet',
                                  style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to share a thought!',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey.shade400),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) =>
                              _buildThoughtCard(thoughts[i], isDark, myUid),
                          childCount: thoughts.length,
                        ),
                      );
                    },
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
            const BottomNavBar(currentIndex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildComposeCard(bool isDark, dynamic user) {
    final initial = (user?.name ?? 'U').isNotEmpty
        ? (user?.name ?? 'U')[0].toUpperCase()
        : 'U';
    final limitReached = _remainingPosts <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
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
                                          fontWeight: FontWeight.w700)))))
                      : Center(
                          child: Text(initial,
                              style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 12),
                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 3,
                    minLines: 1,
                    enabled: !limitReached,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: limitReached
                          ? 'Daily limit reached. Come back tomorrow!'
                          : "What's on your mind?",
                      hintStyle: GoogleFonts.inter(
                        color: limitReached
                            ? AppColors.red.withOpacity(0.5)
                            : (isDark ? Colors.white30 : Colors.grey.shade400),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),

            // Selected image preview
            if (_selectedImageBytes != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_selectedImageBytes!,
                        height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImageBytes = null;
                        _selectedImageName = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
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

            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: limitReached ? null : _pickImage,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image_rounded,
                            color: limitReached ? Colors.grey : AppColors.green,
                            size: 18),
                        const SizedBox(width: 6),
                        Text('Photo',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded,
                          color: AppColors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('24h',
                          style: GoogleFonts.inter(
                              color: AppColors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Spacer(),
                // Remaining posts indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _remainingPosts > 0
                        ? AppColors.green.withOpacity(0.1)
                        : AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_remainingPosts left today',
                    style: GoogleFonts.inter(
                      color:
                          _remainingPosts > 0 ? AppColors.green : AppColors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: (_isPosting || limitReached) ? null : _postThought,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: limitReached ? null : AppColors.primaryGradient,
                      color: limitReached ? Colors.grey.shade300 : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: limitReached
                          ? []
                          : [
                              BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ],
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Share',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThoughtCard(Thought thought, bool isDark, String myUid) {
    final isLiked = thought.likedBy.contains(myUid);
    final timeAgo = ThoughtsService.getTimeAgo(thought.createdAt);
    final timeRemaining = ThoughtsService.getTimeRemaining(thought.expiresAt);
    final initial =
        thought.userName.isNotEmpty ? thought.userName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3)),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(40),
                  ),
                  child: thought.userAvatarUrl != null
                      ? ClipOval(
                          child: Image.network(thought.userAvatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                  child: Text(initial,
                                      style: GoogleFonts.inter(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700)))))
                      : Center(
                          child: Text(initial,
                              style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(thought.userName,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(timeAgo,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.grey)),
                    ],
                  ),
                ),
                // Expiry timer — live countdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 12, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text(timeRemaining,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (thought.userId == myUid) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: Text('Delete thought?',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child:
                                    Text('Cancel', style: GoogleFonts.inter())),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Delete',
                                  style: GoogleFonts.inter(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ThoughtsService.instance
                            .deleteThought(thought.id);
                        await _loadPostLimits();
                      }
                    },
                    child: Icon(Icons.more_vert,
                        size: 18, color: isDark ? Colors.white38 : Colors.grey),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Text content
            if (thought.text.isNotEmpty)
              Text(thought.text,
                  style: GoogleFonts.inter(fontSize: 15, height: 1.5)),

            // Image
            if (thought.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  thought.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Actions — Like + Comment
            Row(
              children: [
                GestureDetector(
                  onTap: () => ThoughtsService.instance.toggleLike(thought.id),
                  child: Row(
                    children: [
                      Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isLiked
                            ? Colors.red
                            : (isDark ? Colors.white38 : Colors.grey),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${thought.likes}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showCommentSheet(context, thought, isDark),
                  child: FutureBuilder<int>(
                    future:
                        ThoughtsService.instance.getCommentCount(thought.id),
                    builder: (ctx, snap) {
                      final count = snap.data ?? 0;
                      return Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: isDark ? Colors.white38 : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$count',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
