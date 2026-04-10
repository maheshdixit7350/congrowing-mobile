import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../main.dart' show firebaseInitialized;

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
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                    title: Text('Messages', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
                    actions: [
                      IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => Navigator.pushNamed(context, '/search')),
                    ],
                  ),
                  if (!firebaseInitialized)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('Not connected', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade500)),
                            Text('Firebase is required for messaging', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverFillRemaining(
                      child: StreamBuilder<List<ChatRoom>>(
                        stream: ChatService.instance.getChatRooms(),
                        builder: (ctx, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          }

                          final rooms = snap.data ?? [];

                          if (rooms.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('No conversations yet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                                  const SizedBox(height: 6),
                                  Text('Connect with someone to start chatting!', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: rooms.length,
                            itemBuilder: (ctx, i) => _ChatRoomTile(room: rooms[i], isDark: isDark),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            BottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }
}

/// A single chat room tile that loads the other user's data from Firestore.
class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;
  final bool isDark;
  const _ChatRoomTile({required this.room, required this.isDark});

  String _otherUid(ChatRoom room) {
    final myUid = UserService.instance.currentUser?.id ?? '';
    return room.participants.firstWhere((p) => p != myUid, orElse: () => '');
  }

  @override
  Widget build(BuildContext context) {
    final otherUid = _otherUid(room);
    final myUid = UserService.instance.currentUser?.id ?? '';
    final unread = room.unreadCounts[myUid] ?? 0;

    return FutureBuilder<UserModel?>(
      future: UserService.instance.getUserById(otherUid),
      builder: (ctx, userSnap) {
        final other = userSnap.data;
        final name = other?.name ?? 'User';
        final online = other?.isOnline ?? false;
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withAlpha(40),
                backgroundImage: other?.avatarUrl != null ? NetworkImage(other!.avatarUrl!) : null,
                child: other?.avatarUrl == null
                    ? Text(initial, style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 20))
                    : null,
              ),
              if (online)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.backgroundDark : Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(name, style: GoogleFonts.inter(fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
          subtitle: Text(
            room.lastMessage,
            style: GoogleFonts.inter(fontSize: 12, color: unread > 0 ? (isDark ? Colors.white70 : Colors.black87) : AppColors.textSecondaryLight, fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatTime(room.lastMessageTime), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight)),
              if (unread > 0) ...[
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$unread', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
          onTap: () => Navigator.pushNamed(context, '/chat', arguments: {
            'chatId': room.id,
            'otherUid': otherUid,
            'name': name,
            'avatarUrl': other?.avatarUrl,
            'online': online,
          }),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }
}
