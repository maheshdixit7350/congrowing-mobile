import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _initialized = false;
  bool _sending = false;

  String _chatId = '';
  String _otherUid = '';
  String _contactName = 'User';
  String? _contactAvatarUrl;
  bool _contactOnline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _chatId = args['chatId'] as String? ?? '';
        _otherUid = args['otherUid'] as String? ?? '';
        _contactName = args['name'] as String? ?? 'User';
        _contactAvatarUrl = args['avatarUrl'] as String?;
        _contactOnline = args['online'] as bool? ?? false;
      }
      // Mark messages as read
      if (_chatId.isNotEmpty) {
        ChatService.instance.markAsRead(_chatId);
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _chatId.isEmpty) return;
    _controller.clear();
    await ChatService.instance.sendText(_chatId, text);
    _scrollToBottom();
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null || _chatId.isEmpty) return;
    setState(() => _sending = true);
    await ChatService.instance.sendPhoto(_chatId, File(picked.path));
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked == null || _chatId.isEmpty) return;
    setState(() => _sending = true);
    await ChatService.instance.sendPhoto(_chatId, File(picked.path));
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null || _chatId.isEmpty) return;
    setState(() => _sending = true);
    await ChatService.instance.sendFile(
      _chatId,
      File(result.files.single.path!),
      result.files.single.name,
    );
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _showAttachmentOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 20),
            Text('Share', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachOption(icon: Icons.photo_library_rounded, label: 'Gallery', color: Colors.purple, onTap: () { Navigator.pop(context); _pickImage(); }),
                _AttachOption(icon: Icons.camera_alt_rounded, label: 'Camera', color: Colors.blue, onTap: () { Navigator.pop(context); _takePhoto(); }),
                _AttachOption(icon: Icons.insert_drive_file_rounded, label: 'File', color: Colors.orange, onTap: () { Navigator.pop(context); _pickFile(); }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = _contactName.isNotEmpty ? _contactName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => safeNavigateBack(context)),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withAlpha(40),
                  backgroundImage: _contactAvatarUrl != null ? NetworkImage(_contactAvatarUrl!) : null,
                  child: _contactAvatarUrl == null ? Text(initial, style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700)) : null,
                ),
                if (_contactOnline)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_contactName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(_contactOnline ? 'Online' : 'Offline', style: GoogleFonts.inter(fontSize: 11, color: _contactOnline ? Colors.green : AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), shape: BoxShape.circle),
              child: const Icon(Icons.call_rounded, color: AppColors.primary, size: 18),
            ),
            onPressed: () => Navigator.pushNamed(context, '/call'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _chatId.isEmpty
                ? Center(child: Text('No chat selected', style: GoogleFonts.inter(color: Colors.grey)))
                : StreamBuilder<List<ChatMessage>>(
                    stream: ChatService.instance.getMessages(_chatId),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      final messages = snap.data ?? [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.waving_hand_rounded, size: 48, color: Colors.amber.shade400),
                              const SizedBox(height: 12),
                              Text('Say hello! 👋', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                      return ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = messages[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: msg.isMe
                                ? _SentBubble(msg: msg)
                                : _ReceivedBubble(msg: msg, avatarUrl: _contactAvatarUrl, initial: initial, isDark: isDark),
                          );
                        },
                      );
                    },
                  ),
          ),

          // Sending indicator
          if (_sending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                const SizedBox(width: 8),
                Text('Sending...', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ]),
            ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showAttachmentOptions,
                  child: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.inter(color: AppColors.textSecondaryLight, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(89), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attachment Option ─────────────────────────────────────────────────────────
class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Sent Bubble ───────────────────────────────────────────────────────────────
class _SentBubble extends StatelessWidget {
  final ChatMessage msg;
  const _SentBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20), bottomRight: Radius.circular(4),
                ),
              ),
              child: _buildContent(Colors.white),
            ),
            const SizedBox(height: 2),
            Text('${DateFormat('h:mm a').format(msg.timestamp)} ✓✓', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondaryLight)),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(Color textColor) {
    if (msg.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(imageUrl: msg.imageUrl!, width: 200, fit: BoxFit.cover),
      );
    }
    if (msg.fileUrl != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(msg.fileName ?? 'File', style: GoogleFonts.inter(color: textColor, fontSize: 13, decoration: TextDecoration.underline))),
        ],
      );
    }
    return Text(msg.text, style: GoogleFonts.inter(color: textColor, fontSize: 13));
  }
}

// ── Received Bubble ──────────────────────────────────────────────────────────
class _ReceivedBubble extends StatelessWidget {
  final ChatMessage msg;
  final String? avatarUrl;
  final String initial;
  final bool isDark;
  const _ReceivedBubble({required this.msg, this.avatarUrl, required this.initial, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary.withAlpha(40),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null ? Text(initial, style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)) : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4), bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
              child: _buildContent(),
            ),
            const SizedBox(height: 2),
            Text(DateFormat('h:mm a').format(msg.timestamp), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondaryLight)),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (msg.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(imageUrl: msg.imageUrl!, width: 200, fit: BoxFit.cover),
      );
    }
    if (msg.fileUrl != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(msg.fileName ?? 'File', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, decoration: TextDecoration.underline))),
        ],
      );
    }
    return Text(msg.text, style: GoogleFonts.inter(fontSize: 13));
  }
}
