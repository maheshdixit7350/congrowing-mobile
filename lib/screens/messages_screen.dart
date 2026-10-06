import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../main.dart' show supabaseInitialized;

// Deterministic gradient for a user name
LinearGradient _avatarGradient(String name) {
  final gradients = [
    const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
    const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF06B6D4)]),
    const LinearGradient(colors: [Color(0xFFDB2777), Color(0xFFEC4899)]),
    const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
    const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
    const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
  ];
  final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % gradients.length;
  return gradients[idx];
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.92),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                                child: Text('Messages',
                                    style: GoogleFonts.outfit(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                              ),
                              Text('Your conversations',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight)),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/search'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.search_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Chat List ───────────────────────────────────────────────
            Expanded(
              child: !supabaseInitialized
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.cloud_off_rounded,
                                size: 48,
                                color: isDark
                                    ? Colors.white30
                                    : Colors.grey.shade400),
                          ),
                          const SizedBox(height: 16),
                          Text('Not connected',
                              style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text('Backend is required for messaging',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade400)),
                        ],
                      ),
                    )
                  : StreamBuilder<List<ChatRoom>>(
                      stream: ChatService.instance.getChatRooms(),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2),
                          );
                        }

                        final rooms = snap.data ?? [];

                        if (rooms.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 44,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(height: 24),
                                  Text('No conversations yet',
                                      style: GoogleFonts.outfit(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A))),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Connect with someone to start chatting!',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 32),
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, '/call'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 14),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.heroGradient,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6)),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.people_alt_rounded,
                                              color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text('Find Someone',
                                              style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: rooms.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 84,
                            endIndent: 20,
                            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                          ),
                          itemBuilder: (ctx, i) =>
                              _ChatRoomTile(room: rooms[i], isDark: isDark),
                        );
                      },
                    ),
            ),
            const BottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }
}

/// A single chat room tile.
class _ChatRoomTile extends StatefulWidget {
  final ChatRoom room;
  final bool isDark;
  const _ChatRoomTile({required this.room, required this.isDark});

  @override
  State<_ChatRoomTile> createState() => _ChatRoomTileState();
}

class _ChatRoomTileState extends State<_ChatRoomTile> {
  late final Future<UserModel?> _userFuture;
  late final String _otherUid;

  @override
  void initState() {
    super.initState();
    final myUid = UserService.instance.currentUser?.id ?? '';
    _otherUid = widget.room.participants
        .firstWhere((p) => p != myUid, orElse: () => '');
    _userFuture = UserService.instance.getUserById(_otherUid);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = UserService.instance.currentUser?.id ?? '';
    final unread = widget.room.unreadCounts[myUid] ?? 0;

    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (ctx, userSnap) {
        final other = userSnap.data;
        final name = other?.name ?? 'User';
        final online = other?.isOnline ?? false;
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/chat', arguments: {
              'chatId': widget.room.id,
              'otherUid': _otherUid,
              'name': name,
              'avatarUrl': other?.avatarUrl,
              'online': online,
            }),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: other?.avatarUrl == null
                              ? _avatarGradient(name)
                              : null,
                          border: online
                              ? Border.all(
                                  color: AppColors.green, width: 2.5)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: other?.avatarUrl != null &&
                                  other!.avatarUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: other.avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    decoration: BoxDecoration(
                                      gradient: _avatarGradient(name),
                                    ),
                                    child: Center(
                                      child: Text(initial,
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 20)),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: _avatarGradient(name),
                                  ),
                                  child: Center(
                                    child: Text(initial,
                                        style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20)),
                                  ),
                                ),
                        ),
                      ),
                      if (online)
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isDark
                                    ? const Color(0xFF0E1525)
                                    : const Color(0xFFF6F7FB),
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Name + last message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(name,
                                  style: GoogleFonts.inter(
                                      fontWeight: unread > 0
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 15,
                                      color: widget.isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              _formatTime(widget.room.lastMessageTime),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: unread > 0
                                    ? AppColors.primary
                                    : (widget.isDark
                                        ? Colors.white30
                                        : Colors.grey.shade400),
                                fontWeight: unread > 0
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.room.lastMessage.isEmpty
                                    ? 'Start a conversation'
                                    : widget.room.lastMessage,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: unread > 0
                                      ? (widget.isDark
                                          ? Colors.white70
                                          : const Color(0xFF475569))
                                      : (widget.isDark
                                          ? Colors.white30
                                          : Colors.grey.shade500),
                                  fontWeight: unread > 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                constraints:
                                    const BoxConstraints(minWidth: 22),
                                height: 22,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Center(
                                  child: Text(
                                    unread > 99
                                        ? '99+'
                                        : '$unread',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}
