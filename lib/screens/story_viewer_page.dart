import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/thoughts_service.dart';
import '../services/user_service.dart';
import '../utils/app_colors.dart';
import '../utils/audio_helper.dart';

class StoryViewerPage extends StatefulWidget {
  final List<Thought> thoughts;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.thoughts,
    required this.initialIndex,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  // Progress bar animation
  late AnimationController _animController;

  bool _isPaused = false;
  String _myUid = '';
  final Map<String, List<String>> _localLikedBy = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _myUid = UserService.instance.currentUser?.id ?? '';

    for (var t in widget.thoughts) {
      _localLikedBy[t.id] = List<String>.from(t.likedBy);
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7), // 7 seconds per story
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _startStory();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _startStory() {
    _animController.stop();
    _animController.reset();
    _animController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.thoughts.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    } else {
      // Last story reached, close viewer
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    }
  }

  void _togglePause(bool pause) {
    setState(() {
      _isPaused = pause;
    });
    if (pause) {
      _animController.stop();
    } else {
      _animController.forward();
    }
  }

  void _showCommentSheet(Thought thought, bool isDark) {
    _togglePause(true);
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comments',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
              ),
              Divider(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                thickness: 1,
                height: 1,
              ),
              // Comments List
              Expanded(
                child: StreamBuilder<List<ThoughtComment>>(
                  stream: ThoughtsService.instance.streamComments(thought.id),
                  builder: (ctx, snapshot) {
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to share your thoughts!',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollCtrl,
                      itemCount: comments.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemBuilder: (ctx, i) {
                        final comment = comments[i];
                        final initial = comment.userName.isNotEmpty
                            ? comment.userName[0].toUpperCase()
                            : '?';
                        final timeAgo = ThoughtsService.getTimeAgo(comment.createdAt);
                        final isMe = comment.userId == _myUid;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B).withOpacity(0.6)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800.withOpacity(0.5)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: comment.userAvatarUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            comment.userAvatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Text(
                                              initial,
                                              style: GoogleFonts.inter(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          initial,
                                          style: GoogleFonts.inter(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment.userName,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeAgo,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      comment.text,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: isDark ? Colors.grey.shade300 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMe)
                                GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        title: Text('Delete Comment', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                                        content: Text('Are you sure you want to delete this comment?', style: GoogleFonts.inter()),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ThoughtsService.instance.deleteComment(comment.id);
                                    }
                                  },
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                    color: Colors.redAccent.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Comment Input
              Container(
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, 12 + MediaQuery.of(ctx).viewInsets.bottom),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    )
                  ],
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          ),
                        ),
                        child: TextField(
                          controller: commentCtrl,
                          style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                          onChanged: (val) => AudioHelper.playTyping(),
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts...',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        } catch (_) {}
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
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
    ).then((_) {
      _togglePause(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final thought = widget.thoughts[_currentIndex];
    final likedBy = _localLikedBy[thought.id] ?? thought.likedBy;
    final isLiked = likedBy.contains(_myUid);
    final initial =
        thought.userName.isNotEmpty ? thought.userName[0].toUpperCase() : '?';
    final timeRemaining = ThoughtsService.getTimeRemaining(thought.expiresAt);
    final timeAgo = ThoughtsService.getTimeAgo(thought.createdAt);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onLongPressDown: (_) => _togglePause(true),
          onLongPressUp: () => _togglePause(false),
          onTapUp: (details) {
            final screenHeight = MediaQuery.of(context).size.height;
            if (details.globalPosition.dy > screenHeight - 120) {
              // Ignore tap in the bottom area (like/comment buttons) to avoid gesture conflicts
              return;
            }
            final width = MediaQuery.of(context).size.width;
            final dx = details.globalPosition.dx;
            if (dx < width / 3) {
              _prevStory();
            } else {
              _nextStory();
            }
          },
          child: Stack(
            children: [
              // Post Content
              Positioned.fill(
                child: thought.imageUrl != null
                    ? Image.network(
                        thought.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white));
                        },
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              thought.text,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
              ),

              // If there's an image, overlay the text at the bottom
              if (thought.imageUrl != null && thought.text.isNotEmpty)
                Positioned(
                  bottom: 120,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      thought.text,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),

              // Gradient Overlay Top & Bottom for readability
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Top Indicators & Header
              Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Progress Bars
                    Row(
                      children: List.generate(
                        widget.thoughts.length,
                        (index) {
                          double value = 0.0;
                          if (index < _currentIndex) value = 1.0;
                          if (index == _currentIndex) {
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: AnimatedBuilder(
                                  animation: _animController,
                                  builder: (ctx, _) => LinearProgressIndicator(
                                    value: _animController.value,
                                    backgroundColor: Colors.white30,
                                    valueColor: const AlwaysStoppedAnimation(
                                        Colors.white),
                                    minHeight: 3,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white30,
                                valueColor:
                                    const AlwaysStoppedAnimation(Colors.white),
                                minHeight: 3,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Header Row (Avatar, Name, Countdown, Close)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          child: thought.userAvatarUrl != null
                              ? ClipOval(
                                  child: Image.network(thought.userAvatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Text(
                                          initial,
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700))))
                              : Text(initial,
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thought.userName,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            Text(
                              timeAgo,
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Hourly Countdown tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                timeRemaining,
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Actions (Likes & Comments)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    // Like Action
                    GestureDetector(
                      onTap: () async {
                        await ThoughtsService.instance.toggleLike(thought.id);
                        setState(() {
                          if (likedBy.contains(_myUid)) {
                            likedBy.remove(_myUid);
                          } else {
                            likedBy.add(_myUid);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${likedBy.length}',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Comment Action
                    GestureDetector(
                      onTap: () => _showCommentSheet(thought, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: FutureBuilder<int>(
                          future: ThoughtsService.instance
                              .getCommentCount(thought.id),
                          builder: (ctx, snap) {
                            final count = snap.data ?? 0;
                            return Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '$count',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            );
                          },
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
    );
  }
}
