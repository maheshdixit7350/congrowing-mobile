import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../utils/audio_helper.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _initialized = false;
  bool _sending = false;
  bool _showScrollDown = false;
  bool _showSearch = false;
  bool _isMuted = false;
  String _searchQuery = '';

  String _chatId = '';
  String _otherUid = '';
  String _contactName = 'User';
  String? _contactAvatarUrl;
  bool _contactOnline = false;
  String? _lastSeenStr;

  int _lastMessageCount = 0;

  late AnimationController _sendBtnController;
  Stream<List<ChatMessage>>? _messageStream;
  StreamSubscription? _onlineStatusSub;

  @override
  void initState() {
    super.initState();
    _sendBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final atBottom = _scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 100;
    if (_showScrollDown == atBottom) {
      setState(() => _showScrollDown = !atBottom);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _chatId = args['chatId'] as String? ?? '';
        _otherUid = args['otherUid'] as String? ?? '';
        _contactName = args['name'] as String? ?? 'User';
        _contactAvatarUrl = args['avatarUrl'] as String?;
        _contactOnline = args['online'] as bool? ?? false;
      }
      if (_chatId.isNotEmpty) {
        ChatService.instance.markAsRead(_chatId);
        _messageStream = ChatService.instance.getMessages(_chatId);
      } else if (_otherUid.isNotEmpty) {
        _initChatRoomAsync();
      }
      if (_otherUid.isNotEmpty) {
        _subscribeToOnlineStatus();
      }
      _initialized = true;
    }
  }

  Future<void> _initChatRoomAsync() async {
    final roomId = await ChatService.instance.getOrCreateChatRoom(_otherUid);
    if (mounted && roomId.isNotEmpty) {
      setState(() {
        _chatId = roomId;
        ChatService.instance.markAsRead(_chatId);
        _messageStream = ChatService.instance.getMessages(_chatId);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollCtrl.dispose();
    _sendBtnController.dispose();
    _onlineStatusSub?.cancel();
    super.dispose();
  }

  void _subscribeToOnlineStatus() {
    _onlineStatusSub?.cancel();
    _onlineStatusSub = UserService.instance
        .streamUserOnlineStatus(_otherUid)
        .listen((data) {
      if (mounted) {
        setState(() {
          _contactOnline = data['is_online'] as bool? ?? false;
          _lastSeenStr = data['last_seen'] as String?;
        });
      }
    });
  }

  String _formatLastSeen(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return 'Offline';
    final dt = DateTime.tryParse(isoStr);
    if (dt == null) return 'Offline';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Last seen yesterday';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
    return 'Last seen ${DateFormat('MMM d').format(dt)}';
  }

  void _confirmClearChat() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2236) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cleaning_services_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text('Clean Chat',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        content: Text(
          'Are you sure you want to clean all messages in this conversation? This action cannot be undone.',
          style: GoogleFonts.inter(
              fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await ChatService.instance.clearChatHistory(_chatId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Chat history cleaned successfully'
                        : 'Failed to clean chat'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text('Clean Chat',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2236) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            if (msg.text.isNotEmpty)
              ListTile(
                leading:
                    const Icon(Icons.copy_rounded, color: AppColors.primary),
                title: Text('Copy Text',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: msg.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            if (msg.isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: Text('Delete Message',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteMessage(msg);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2236) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text('Delete Message',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this message? This cannot be undone.',
          style: GoogleFonts.inter(
              fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ChatService.instance.deleteMessage(_chatId, msg.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Message deleted'
                        : 'Failed to delete message'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _chatId.isEmpty || _sending) return;
    _controller.clear();
    _sendBtnController.reverse();
    setState(() => _sending = true);
    try {
      await ChatService.instance.sendText(_chatId, text);
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _pickImage() async {
    if (_sending || _chatId.isEmpty) return;
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null || _chatId.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ChatService.instance.sendPhoto(_chatId, File(picked.path));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _takePhoto() async {
    if (_sending || _chatId.isEmpty) return;
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked == null || _chatId.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ChatService.instance.sendPhoto(_chatId, File(picked.path));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _pickFile() async {
    if (_sending || _chatId.isEmpty) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null || _chatId.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ChatService.instance.sendFile(
        _chatId,
        File(result.files.single.path!),
        result.files.single.name,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _pickDocument() async {
    if (_sending || _chatId.isEmpty) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
        'csv',
        'zip',
        'rar'
      ],
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null || _chatId.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ChatService.instance.sendFile(
        _chatId,
        File(result.files.single.path!),
        result.files.single.name,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _showAttachmentOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2236) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            Text('Share Something',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Text('Choose what you want to share',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey.shade500)),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _AttachOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _AttachOption(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Document',
                  gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
                  onTap: () {
                    Navigator.pop(context);
                    _pickDocument();
                  },
                ),
                _AttachOption(
                  icon: Icons.folder_rounded,
                  label: 'File',
                  gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCallOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = UserService.instance.currentUser?.id ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2236) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Text('Call $_contactName',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text('Choose how you want to connect',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _CallOptionCard(
                    icon: Icons.call_rounded,
                    label: 'Voice Call',
                    gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/voice-call', arguments: {
                        'otherUid': _otherUid,
                        'name': _contactName,
                        'avatarUrl': _contactAvatarUrl,
                        'isCaller': true,
                        'myUid': myUid,
                      });
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _CallOptionCard(
                    icon: Icons.videocam_rounded,
                    label: 'Video Call',
                    gradient: const [AppColors.primary, Color(0xFF818CF8)],
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/video-call', arguments: {
                        'otherUid': _otherUid,
                        'name': _contactName,
                        'avatarUrl': _contactAvatarUrl,
                        'isCaller': true,
                        'myUid': myUid,
                      });
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Check if a date separator is needed before this message.
  bool _needsDateSeparator(List<ChatMessage> msgs, int index) {
    if (index == 0) return true;
    final prev = msgs[index - 1].timestamp;
    final curr = msgs[index].timestamp;
    return prev.year != curr.year ||
        prev.month != curr.month ||
        prev.day != curr.day;
  }

  String _formatDateSeparator(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(dt);
    return DateFormat('MMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial =
        _contactName.isNotEmpty ? _contactName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFEEF0F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.92),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: isDark ? Colors.white : Colors.black87),
                    onPressed: () => safeNavigateBack(context),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      if (_otherUid.isNotEmpty) {
                        Navigator.pushNamed(context, '/user-profile',
                            arguments: {'userId': _otherUid});
                      }
                    },
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _contactAvatarUrl == null
                                    ? AppColors.primaryGradient
                                    : null,
                                border: Border.all(
                                  color: _contactOnline
                                      ? AppColors.green
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _contactAvatarUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: _contactAvatarUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          child: Center(
                                            child: Text(initial,
                                                style: GoogleFonts.inter(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16)),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(initial,
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16)),
                                      ),
                              ),
                            ),
                            if (_contactOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF1A2236)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_contactName,
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A))),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _contactOnline
                                        ? const Color(0xFF22C55E)
                                        : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _contactOnline ? 'Online' : _formatLastSeen(_lastSeenStr),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _contactOnline
                                        ? const Color(0xFF22C55E)
                                        : (isDark
                                            ? Colors.white38
                                            : Colors.grey.shade500),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Search toggle button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _showSearch
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _showSearch
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color: _showSearch ? Colors.white : AppColors.primary,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchQuery = '';
                            _searchController.clear();
                          }
                        });
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Call button
                  GestureDetector(
                    onTap: _showCallOptions,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.call_rounded,
                          color: Colors.white, size: 17),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Video call button
                  GestureDetector(
                    onTap: () {
                      final myUid =
                          UserService.instance.currentUser?.id ?? '';
                      Navigator.pushNamed(context, '/video-call', arguments: {
                        'otherUid': _otherUid,
                        'name': _contactName,
                        'avatarUrl': _contactAvatarUrl,
                        'isCaller': true,
                        'myUid': myUid,
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.cyanGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.videocam_rounded,
                          color: Colors.white, size: 17),
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Popup Options Menu (Clean Chat, Mute, View Profile)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: isDark ? Colors.white70 : Colors.black87,
                        size: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: isDark ? const Color(0xFF1A2236) : Colors.white,
                    onSelected: (val) {
                      if (val == 'clean') {
                        _confirmClearChat();
                      } else if (val == 'mute') {
                        setState(() => _isMuted = !_isMuted);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isMuted
                                ? 'Notifications muted for $_contactName'
                                : 'Notifications unmuted'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else if (val == 'profile') {
                        if (_otherUid.isNotEmpty) {
                          Navigator.pushNamed(context, '/user-profile',
                              arguments: {'userId': _otherUid});
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'clean',
                        child: Row(
                          children: [
                            const Icon(Icons.cleaning_services_rounded,
                                color: Colors.redAccent, size: 20),
                            const SizedBox(width: 12),
                            Text('Clean Chat',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.redAccent)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'mute',
                        child: Row(
                          children: [
                            Icon(
                                _isMuted
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_off_rounded,
                                color: AppColors.primary,
                                size: 20),
                            const SizedBox(width: 12),
                            Text(
                                _isMuted
                                    ? 'Unmute Notifications'
                                    : 'Mute Notifications',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Text('View Profile',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
  body: Stack(
        children: [
          Column(
            children: [
              // Search input bar when activated
              if (_showSearch)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isDark ? const Color(0xFF161F32) : Colors.grey.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Search messages in conversation...',
                            hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade500),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                    ],
                  ),
                ),

              // Messages list
              Expanded(
                child: _chatId.isEmpty
                    ? Center(
                        child: Text('No chat selected',
                            style: GoogleFonts.inter(color: Colors.grey)))
                    : StreamBuilder<List<ChatMessage>>(
                        stream: _messageStream,
                        builder: (ctx, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                      color: AppColors.primary, strokeWidth: 2),
                                  const SizedBox(height: 16),
                                  Text('Loading messages...',
                                      style: GoogleFonts.inter(
                                          color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            );
                          }
                          var messages = snap.data ?? [];
                          if (_searchQuery.trim().isNotEmpty) {
                            messages = messages
                                .where((m) => m.text
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()))
                                .toList();
                          }
                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                        _searchQuery.isNotEmpty
                                            ? Icons.search_off_rounded
                                            : Icons.waving_hand_rounded,
                                        size: 40,
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No matching messages'
                                          : 'Start the conversation!',
                                      style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.grey.shade600)),
                                  const SizedBox(height: 6),
                                  Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Try searching for a different word'
                                          : 'Send a message or photo to begin',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.grey.shade400)),
                                ],
                              ),
                            );
                          }
                          // Scroll to bottom on new messages
                          if (messages.length != _lastMessageCount) {
                            final wasEmpty = _lastMessageCount == 0;
                            _lastMessageCount = messages.length;
                            if (!wasEmpty &&
                                messages.isNotEmpty &&
                                !messages.last.isMe) {
                              AudioHelper.playMessageReceived();
                            }
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) => _scrollToBottom());
                          }
                          return ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            itemCount: messages.length,
                            itemBuilder: (ctx, i) {
                              final msg = messages[i];
                              final showDate =
                                  _needsDateSeparator(messages, i);

                              return Column(
                                children: [
                                  if (showDate)
                                    _DateSeparator(
                                      text:
                                          _formatDateSeparator(msg.timestamp),
                                      isDark: isDark,
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: GestureDetector(
                                      onLongPress: () =>
                                          _showMessageOptions(msg),
                                      child: msg.isMe
                                          ? _SentBubble(
                                              msg: msg, isDark: isDark)
                                          : _ReceivedBubble(
                                              msg: msg,
                                              avatarUrl: _contactAvatarUrl,
                                              initial: initial,
                                              isDark: isDark,
                                            ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),

              // Sending indicator
              if (_sending)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Text('Sending...',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),

              // Input bar
              _buildInputBar(isDark),
            ],
          ),

          // Scroll to bottom FAB
          if (_showScrollDown)
            Positioned(
              bottom: 90,
              right: 16,
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _showAttachmentOptions,
            child: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardDarkElevated
                    : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                minLines: 1,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(
                      color: isDark
                          ? Colors.white30
                          : AppColors.textSecondaryLight,
                      fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (text) {
                  AudioHelper.playTyping();
                  if (text.trim().isNotEmpty) {
                    _sendBtnController.forward();
                  } else {
                    _sendBtnController.reverse();
                  }
                },
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedBuilder(
              animation: _sendBtnController,
              builder: (ctx, child) {
                return Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(0.3 * _sendBtnController.value),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 19),
                );
              },
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

// ── Date Separator ────────────────────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final String text;
  final bool isDark;
  const _DateSeparator({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey.shade500)),
        ),
      ),
    );
  }
}

// ── Attachment Option ─────────────────────────────────────────────────────────
class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Call Option Card ──────────────────────────────────────────────────────────
class _CallOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _CallOptionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ── Helper: Get file icon ────────────────────────────────────────────────────
IconData _getFileIcon(String? fileName) {
  if (fileName == null) return Icons.insert_drive_file_rounded;
  final ext = fileName.split('.').last.toLowerCase();
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf_rounded;
    case 'doc':
    case 'docx':
      return Icons.description_rounded;
    case 'xls':
    case 'xlsx':
    case 'csv':
      return Icons.table_chart_rounded;
    case 'ppt':
    case 'pptx':
      return Icons.slideshow_rounded;
    case 'zip':
    case 'rar':
    case '7z':
      return Icons.folder_zip_rounded;
    case 'txt':
      return Icons.article_rounded;
    case 'mp3':
    case 'wav':
    case 'aac':
      return Icons.audio_file_rounded;
    case 'mp4':
    case 'avi':
    case 'mov':
      return Icons.video_file_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}

Color _getFileColor(String? fileName) {
  if (fileName == null) return const Color(0xFF6366F1);
  final ext = fileName.split('.').last.toLowerCase();
  switch (ext) {
    case 'pdf':
      return const Color(0xFFEF4444);
    case 'doc':
    case 'docx':
      return const Color(0xFF3B82F6);
    case 'xls':
    case 'xlsx':
    case 'csv':
      return const Color(0xFF10B981);
    case 'ppt':
    case 'pptx':
      return const Color(0xFFF59E0B);
    case 'zip':
    case 'rar':
    case '7z':
      return const Color(0xFF8B5CF6);
    default:
      return const Color(0xFF6366F1);
  }
}

// ── Sent Bubble ───────────────────────────────────────────────────────────────
class _SentBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isDark;
  const _SentBubble({required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildContent(context),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat('h:mm a').format(msg.timestamp),
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color:
                              isDark ? Colors.white30 : Colors.grey.shade400)),
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: msg.isRead
                        ? const Color(0xFF3B82F6)
                        : (isDark ? Colors.white30 : Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Image message
    if (msg.imageUrl != null) {
      return _ImageBubbleContent(
        imageUrl: msg.imageUrl!,
        heroTag: 'img_${msg.id}',
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(6),
        ),
      );
    }
    // File message
    if (msg.fileUrl != null) {
      return _FileBubbleContent(
        fileName: msg.fileName,
        isSent: true,
      );
    }
    // Text message
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(msg.text,
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 14, height: 1.4)),
    );
  }
}

// ── Received Bubble ──────────────────────────────────────────────────────────
class _ReceivedBubble extends StatelessWidget {
  final ChatMessage msg;
  final String? avatarUrl;
  final String initial;
  final bool isDark;
  const _ReceivedBubble({
    required this.msg,
    this.avatarUrl,
    required this.initial,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: avatarUrl == null ? AppColors.primaryGradient : null,
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? CachedNetworkImage(imageUrl: avatarUrl!, fit: BoxFit.cover)
                  : Center(
                      child: Text(initial,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildContent(context),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(DateFormat('h:mm a').format(msg.timestamp),
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color:
                              isDark ? Colors.white30 : Colors.grey.shade400)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Image message
    if (msg.imageUrl != null) {
      return _ImageBubbleContent(
        imageUrl: msg.imageUrl!,
        heroTag: 'img_${msg.id}',
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(20),
        ),
      );
    }
    // File message
    if (msg.fileUrl != null) {
      return _FileBubbleContent(
        fileName: msg.fileName,
        isSent: false,
      );
    }
    // Text message
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child:
          Text(msg.text, style: GoogleFonts.inter(fontSize: 14, height: 1.4)),
    );
  }
}

// ── Image Bubble Content (tap to zoom) ───────────────────────────────────────
class _ImageBubbleContent extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final BorderRadius borderRadius;
  const _ImageBubbleContent({
    required this.imageUrl,
    required this.heroTag,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = !kIsWeb && imageUrl.startsWith('file://');
    final path = isLocal ? Uri.parse(imageUrl).toFilePath() : imageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black87,
            pageBuilder: (ctx, anim, anim2) => _FullScreenImageViewer(
                imagePath: path, isLocal: isLocal, heroTag: heroTag),
            transitionsBuilder: (ctx, anim, anim2, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: isLocal
              ? Image.file(
                  File(path),
                  width: 220,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _brokenImagePlaceholder(),
                )
              : CachedNetworkImage(
                  imageUrl: path,
                  width: 220,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 220,
                    height: 180,
                    color: Colors.grey.withOpacity(0.15),
                    child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _brokenImagePlaceholder(),
                ),
        ),
      ),
    );
  }

  Widget _brokenImagePlaceholder() {
    return Container(
      width: 220,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: borderRadius,
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
          SizedBox(height: 4),
          Text('Image unavailable',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── File Bubble Content ──────────────────────────────────────────────────────
class _FileBubbleContent extends StatelessWidget {
  final String? fileName;
  final bool isSent;
  const _FileBubbleContent({required this.fileName, required this.isSent});

  @override
  Widget build(BuildContext context) {
    final icon = _getFileIcon(fileName);
    final color = _getFileColor(fileName);
    final ext = fileName?.split('.').last.toUpperCase() ?? 'FILE';

    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minWidth: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSent
                  ? Colors.white.withOpacity(0.2)
                  : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isSent ? Colors.white : color, size: 22),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName ?? 'File',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSent ? Colors.white : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  ext,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isSent
                        ? Colors.white.withOpacity(0.6)
                        : Colors.grey.shade500,
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

// ── Full Screen Image Viewer ─────────────────────────────────────────────────
class _FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final bool isLocal;
  final String heroTag;
  const _FullScreenImageViewer({
    required this.imagePath,
    required this.isLocal,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Zoomable image
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: isLocal
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  color: Colors.white38, size: 64),
                              SizedBox(height: 12),
                              Text('Image not available',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 14)),
                            ],
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  color: Colors.white38, size: 64),
                              SizedBox(height: 12),
                              Text('Image not available',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  right: 8,
                  bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  Text('Pinch to zoom',
                      style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
