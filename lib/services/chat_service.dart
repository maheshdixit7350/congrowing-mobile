import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseInitialized;
import '../utils/chat_encryption.dart';
import 'supabase_auth_service.dart';
import 'package:uuid/uuid.dart';

/// A single message in a chat.
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    required this.timestamp,
    required this.isMe,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String myUid) {
    final senderId = (json['sender_id'] ?? json['senderId']) as String? ?? '';
    DateTime timestamp;
    final rawTime = json['timestamp'];

    if (rawTime is String) {
      timestamp = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      timestamp = DateTime.now();
    }

    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      senderId: senderId,
      text: json['text'] as String? ?? '',
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      fileUrl: (json['file_url'] ?? json['fileUrl']) as String?,
      fileName: (json['file_name'] ?? json['fileName']) as String?,
      timestamp: timestamp,
      isMe: senderId == myUid,
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'text': text,
      'image_url': imageUrl,
      'file_url': fileUrl,
      'file_name': fileName,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }
}

/// Metadata for a chat room.
class ChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;

  const ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCounts,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final roomId = (json['id'] ?? '').toString();
    final rawParticipants = json['participants'];
    List<String> list = [];
    if (rawParticipants is List) {
      list = rawParticipants.map((p) => p.toString()).toList();
    }

    DateTime lastTime;
    final rawTime = json['last_message_time'] ?? json['lastMessageTime'];
    if (rawTime is String) {
      lastTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      lastTime = DateTime.now();
    }

    // Parse unread counts
    final rawUnread = json['unread_counts'] ?? json['unreadCounts'] ?? {};
    final unreadMap = <String, int>{};
    if (rawUnread is Map) {
      rawUnread.forEach((key, val) {
        unreadMap[key.toString()] = int.tryParse(val.toString()) ?? 0;
      });
    }

    // Last message is stored as plaintext preview — no decryption needed
    final rawLastMsg =
        (json['last_message'] ?? json['lastMessage']) as String? ?? '';

    return ChatRoom(
      id: roomId,
      participants: list,
      lastMessage: rawLastMsg,
      lastMessageTime: lastTime,
      unreadCounts: unreadMap,
    );
  }
}

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  String get _myUid => supabaseInitialized
      ? (SupabaseAuthService.instance.currentUser?.id ?? '')
      : '';

  // Centralized in-memory message cache per chat room ID
  final Map<String, List<ChatMessage>> _chatMessagesCache = {};

  // Active broadcast stream controllers per chat room ID
  final Map<String, StreamController<List<ChatMessage>>> _streamControllers = {};

  // Active realtime subscriptions per chat room ID
  final Map<String, StreamSubscription> _realtimeSubs = {};

  /// Helper to get or create stream controller for a chat room
  StreamController<List<ChatMessage>> _getController(String chatId) {
    if (!_streamControllers.containsKey(chatId) || _streamControllers[chatId]!.isClosed) {
      _streamControllers[chatId] = StreamController<List<ChatMessage>>.broadcast();
    }
    return _streamControllers[chatId]!;
  }

  /// Helper to emit updated messages to listeners and save to disk
  Future<void> _notifyAndSave(String chatId, List<ChatMessage> messages) async {
    // Deduplicate by message id
    final seenIds = <String>{};
    final deduplicated = <ChatMessage>[];
    for (final m in messages) {
      if (seenIds.add(m.id)) {
        deduplicated.add(m);
      }
    }
    deduplicated.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _chatMessagesCache[chatId] = deduplicated;
    await _saveLocalMessages(chatId, deduplicated);

    final ctrl = _streamControllers[chatId];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(List.from(deduplicated));
    }
  }

  // ── Chat Rooms ────────────────────────────────────────────────────────────

  /// Stream of all chat rooms for the current user, ordered by last message.
  Stream<List<ChatRoom>> getChatRooms() {
    if (!supabaseInitialized || _myUid.isEmpty) return const Stream.empty();

    return Supabase.instance.client
        .from('chat_rooms')
        .stream(primaryKey: ['id']).map((list) {
      final mapped = list
          .map((map) => ChatRoom.fromJson(map))
          .where((room) => room.participants.contains(_myUid))
          .toList();

      mapped.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return mapped;
    });
  }

  /// Get or create a 1-to-1 chat room with another user.
  Future<String> getOrCreateChatRoom(String otherUid) async {
    if (!supabaseInitialized || _myUid.isEmpty) return '';

    try {
      final res = await Supabase.instance.client
          .from('chat_rooms')
          .select()
          .contains('participants', [_myUid, otherUid]);

      if (res.isNotEmpty) {
        return res.first['id'].toString();
      }

      // Create new chat room if none exists
      final newRoom = await Supabase.instance.client
          .from('chat_rooms')
          .insert({
            'participants': [_myUid, otherUid],
            'last_message': '',
            'last_message_time': DateTime.now().toIso8601String(),
            'unread_counts': {_myUid: 0, otherUid: 0},
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return newRoom['id'].toString();
    } catch (e) {
      debugPrint('Error getting/creating chat room: $e');
      return '';
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Real-time stream of messages in a chat room.
  /// Uses a unified in-memory cache and local storage backing.
  Stream<List<ChatMessage>> getMessages(String chatId) {
    if (!supabaseInitialized || chatId.isEmpty) return const Stream.empty();

    final controller = _getController(chatId);

    // Initialize cache & listen to Supabase realtime
    _initChatStream(chatId);

    return controller.stream;
  }

  Future<void> _initChatStream(String chatId) async {
    // Load local messages into cache if not cached yet
    if (!_chatMessagesCache.containsKey(chatId)) {
      final localMsgs = await _loadLocalMessages(chatId);
      _chatMessagesCache[chatId] = localMsgs;
      final ctrl = _getController(chatId);
      if (!ctrl.isClosed) {
        ctrl.add(List.from(localMsgs));
      }
    } else {
      // Emit current cache immediately
      final ctrl = _getController(chatId);
      if (!ctrl.isClosed) {
        ctrl.add(List.from(_chatMessagesCache[chatId]!));
      }
    }

    // Subscribe to realtime if subscription is not active
    if (!_realtimeSubs.containsKey(chatId)) {
      _realtimeSubs[chatId] = Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('chat_id', chatId)
          .listen((serverRows) async {
            final serverMsgIds = serverRows.map((map) => map['id'].toString()).toSet();
            final cache = _chatMessagesCache[chatId] ?? [];
            bool anyNew = false;
            
            // Remove local items that were deleted remotely if server returned non-empty list or empty list when server sync happens
            if (serverRows.isEmpty && cache.isNotEmpty) {
              cache.clear();
              anyNew = true;
            } else {
              // Retain local items that are either in serverMsgIds or are pending optimistic items
              cache.removeWhere((m) => !serverMsgIds.contains(m.id) && !m.id.startsWith('local_'));
            }

            for (final map in serverRows) {
              final serverMsgId = map['id'].toString();
              final senderIdRaw = map['sender_id'] as String? ?? '';
              final isMe = senderIdRaw == _myUid;

              // Check if we already have this message by ID in our cache
              final existingIndex = cache.indexWhere((m) => m.id == serverMsgId);

              // Decrypt message content
              final encryptedText = map['text'] as String? ?? '';
              final encryptedImgUrl = map['image_url'] as String? ?? '';
              final encryptedFileUrl = map['file_url'] as String? ?? '';
              final encryptedFileName = map['file_name'] as String? ?? '';

              final decryptedText = ChatEncryption.decrypt(encryptedText, chatId);
              final decryptedImgUrl = ChatEncryption.decrypt(encryptedImgUrl, chatId);
              final decryptedFileUrl = ChatEncryption.decrypt(encryptedFileUrl, chatId);
              final decryptedFileName = ChatEncryption.decrypt(encryptedFileName, chatId);

              if (existingIndex >= 0) {
                // Message already exists locally in cache (e.g. optimistic local send).
                // Keep local file:// URI if present so rendering stays instant from disk.
                continue;
              }

              // Download media files to local storage for incoming messages from others
              String? finalImgUrl = decryptedImgUrl.isNotEmpty ? decryptedImgUrl : null;
              String? finalFileUrl = decryptedFileUrl.isNotEmpty ? decryptedFileUrl : null;

              if (!isMe && finalImgUrl != null && finalImgUrl.startsWith('http')) {
                final localUri = await _downloadAndSaveFile(
                    finalImgUrl, '${serverMsgId}_image.jpg');
                if (localUri != null) {
                  finalImgUrl = localUri;
                }
              }

              if (!isMe && finalFileUrl != null && finalFileUrl.startsWith('http')) {
                final fileNameClean =
                    decryptedFileName.isNotEmpty ? decryptedFileName : 'file';
                final localUri = await _downloadAndSaveFile(
                    finalFileUrl, '${serverMsgId}_$fileNameClean');
                if (localUri != null) {
                  finalFileUrl = localUri;
                }
              }

              final timestampRaw = map['timestamp'];
              final timestamp = timestampRaw is String
                  ? (DateTime.tryParse(timestampRaw) ?? DateTime.now())
                  : DateTime.now();

              final msg = ChatMessage(
                id: serverMsgId,
                senderId: senderIdRaw,
                text: decryptedText,
                imageUrl: finalImgUrl,
                fileUrl: finalFileUrl,
                fileName:
                    decryptedFileName.isNotEmpty ? decryptedFileName : null,
                timestamp: timestamp,
                isMe: isMe,
                isRead: map['is_read'] as bool? ?? false,
              );

              cache.add(msg);
              anyNew = true;
            }

            if (anyNew) {
              await _notifyAndSave(chatId, cache);
            }
          });
    }
  }

  /// Clears all messages in a chat room locally and remotely.
  Future<bool> clearChatHistory(String chatId) async {
    if (chatId.isEmpty) return false;

    // 1. Clear local memory cache
    _chatMessagesCache[chatId] = [];

    // 2. Clear SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_messages_$chatId');
    } catch (e) {
      debugPrint('Error clearing local messages prefs: $e');
    }

    // 3. Delete remote messages from Supabase if connected
    if (supabaseInitialized) {
      try {
        await Supabase.instance.client
            .from('messages')
            .delete()
            .eq('chat_id', chatId);

        // Update chat room last message preview
        await Supabase.instance.client.from('chat_rooms').update({
          'last_message': '',
          'last_message_time': DateTime.now().toIso8601String(),
        }).eq('id', chatId);
      } catch (e) {
        debugPrint('Error deleting Supabase messages: $e');
      }
    }

    // 4. Notify stream subscribers
    final ctrl = _streamControllers[chatId];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add([]);
    }

    return true;
  }

  /// Deletes a single message by ID.
  Future<bool> deleteMessage(String chatId, String messageId) async {
    if (chatId.isEmpty || messageId.isEmpty) return false;

    // 1. Remove from local memory cache
    final cache = _chatMessagesCache[chatId] ?? [];
    cache.removeWhere((m) => m.id == messageId);
    _chatMessagesCache[chatId] = cache;
    await _saveLocalMessages(chatId, cache);

    // 2. Remove from Supabase
    if (supabaseInitialized) {
      try {
        await Supabase.instance.client
            .from('messages')
            .delete()
            .eq('id', messageId);
      } catch (e) {
        debugPrint('Error deleting message from Supabase: $e');
      }
    }

    // 3. Notify listeners
    final ctrl = _streamControllers[chatId];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(List.from(cache));
    }

    return true;
  }

  /// Send a text message.
  Future<void> sendText(String chatId, String text) async {
    if (!supabaseInitialized ||
        chatId.isEmpty ||
        text.trim().isEmpty ||
        _myUid.isEmpty) {
      return;
    }

    try {
      final msgId = const Uuid().v4();
      final now = DateTime.now();
      final localMsg = ChatMessage(
        id: msgId,
        senderId: _myUid,
        text: text.trim(),
        timestamp: now,
        isMe: true,
      );

      // Add to cache & notify UI immediately (optimistic UI update)
      final cache = _chatMessagesCache[chatId] ?? await _loadLocalMessages(chatId);
      cache.add(localMsg);
      await _notifyAndSave(chatId, cache);

      // Encrypt for transit
      final encryptedText = ChatEncryption.encrypt(text.trim(), chatId);

      await Supabase.instance.client.from('messages').insert({
        'id': msgId,
        'chat_id': chatId,
        'sender_id': _myUid,
        'text': encryptedText,
        'timestamp': now.toIso8601String(),
        'is_read': false,
      });

      // Update chat room metadata with plaintext preview
      await _updateChatMeta(chatId, _truncatePreview(text.trim()));
    } catch (e) {
      debugPrint('Error sending text message: $e');
    }
  }

  /// Send a photo message.
  Future<void> sendPhoto(String chatId, File imageFile) async {
    if (!supabaseInitialized || chatId.isEmpty || _myUid.isEmpty) return;

    try {
      final msgId = const Uuid().v4();
      final now = DateTime.now();

      // Save the photo locally first in app documents
      final docDir = await getApplicationDocumentsDirectory();
      final localPath = '${docDir.path}/chat_files';
      await Directory(localPath).create(recursive: true);
      final localFile = File('$localPath/${msgId}_image.jpg');
      await imageFile.copy(localFile.path);

      final localMsg = ChatMessage(
        id: msgId,
        senderId: _myUid,
        text: '',
        imageUrl: localFile.uri.toString(),
        timestamp: now,
        isMe: true,
      );

      // Add to cache & notify UI immediately (optimistic UI update)
      final cache = _chatMessagesCache[chatId] ?? await _loadLocalMessages(chatId);
      cache.add(localMsg);
      await _notifyAndSave(chatId, cache);

      // Upload raw file to Supabase storage permanently for remote retrieval
      final fileName = '$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();
      await Supabase.instance.client.storage.from('chat').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      final url =
          Supabase.instance.client.storage.from('chat').getPublicUrl(fileName);

      // Encrypt URL for transit
      final encryptedUrl = ChatEncryption.encrypt(url, chatId);

      await Supabase.instance.client.from('messages').insert({
        'id': msgId,
        'chat_id': chatId,
        'sender_id': _myUid,
        'text': '',
        'image_url': encryptedUrl,
        'timestamp': now.toIso8601String(),
        'is_read': false,
      });

      await _updateChatMeta(chatId, '📷 Photo');
    } catch (e) {
      debugPrint('Error sending photo: $e');
    }
  }

  /// Send a file.
  Future<void> sendFile(String chatId, File file, String fileName) async {
    if (!supabaseInitialized || chatId.isEmpty || _myUid.isEmpty) return;

    try {
      final msgId = const Uuid().v4();
      final now = DateTime.now();

      // Save file locally first in app documents
      final docDir = await getApplicationDocumentsDirectory();
      final localPath = '${docDir.path}/chat_files';
      await Directory(localPath).create(recursive: true);
      final localFile = File('$localPath/${msgId}_$fileName');
      await file.copy(localFile.path);

      final localMsg = ChatMessage(
        id: msgId,
        senderId: _myUid,
        text: '',
        fileUrl: localFile.uri.toString(),
        fileName: fileName,
        timestamp: now,
        isMe: true,
      );

      // Add to cache & notify UI immediately (optimistic UI update)
      final cache = _chatMessagesCache[chatId] ?? await _loadLocalMessages(chatId);
      cache.add(localMsg);
      await _notifyAndSave(chatId, cache);

      // Upload raw file to Supabase storage
      final storagePath =
          '$chatId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final bytes = await file.readAsBytes();
      await Supabase.instance.client.storage
          .from('chat')
          .uploadBinary(storagePath, bytes);
      final url = Supabase.instance.client.storage
          .from('chat')
          .getPublicUrl(storagePath);

      // Encrypt URL and fileName for transit
      final encryptedUrl = ChatEncryption.encrypt(url, chatId);
      final encryptedFileName = ChatEncryption.encrypt(fileName, chatId);

      await Supabase.instance.client.from('messages').insert({
        'id': msgId,
        'chat_id': chatId,
        'sender_id': _myUid,
        'text': '',
        'file_url': encryptedUrl,
        'file_name': encryptedFileName,
        'timestamp': now.toIso8601String(),
        'is_read': false,
      });

      await _updateChatMeta(chatId, '📎 $fileName');
    } catch (e) {
      debugPrint('Error sending file: $e');
    }
  }

  /// Mark all messages as read for current user.
  Future<void> markAsRead(String chatId) async {
    if (!supabaseInitialized || chatId.isEmpty || _myUid.isEmpty) return;
    try {
      // 1. Reset unread counter on chat room
      final doc = await Supabase.instance.client
          .from('chat_rooms')
          .select()
          .eq('id', chatId)
          .single();
      final unread = Map<String, dynamic>.from(doc['unread_counts'] ?? {});
      unread[_myUid] = 0;

      await Supabase.instance.client.from('chat_rooms').update({
        'unread_counts': unread,
      }).eq('id', chatId);

      // 2. Mark all unread messages from the OTHER user as read
      await Supabase.instance.client
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', _myUid)
          .eq('is_read', false);

      // 3. Update local cache to reflect read status
      final cache = _chatMessagesCache[chatId];
      if (cache != null) {
        bool changed = false;
        final updated = cache.map((m) {
          if (!m.isMe && !m.isRead) {
            changed = true;
            return ChatMessage(
              id: m.id,
              senderId: m.senderId,
              text: m.text,
              imageUrl: m.imageUrl,
              fileUrl: m.fileUrl,
              fileName: m.fileName,
              timestamp: m.timestamp,
              isMe: m.isMe,
              isRead: true,
            );
          }
          return m;
        }).toList();
        if (changed) {
          _chatMessagesCache[chatId] = updated;
          await _saveLocalMessages(chatId, updated);
        }
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<List<ChatMessage>> _loadLocalMessages(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('local_messages_$chatId') ?? [];
      return rawList.map((str) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return ChatMessage.fromJson(map, _myUid);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalMessages(
      String chatId, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = messages.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList('local_messages_$chatId', rawList);
    } catch (_) {}
  }

  /// Downloads a remote file and saves it locally.
  /// Returns the local file:// URI on success, or null on failure.
  Future<String?> _downloadAndSaveFile(
      String remoteUrl, String fileName) async {
    try {
      final uri = Uri.parse(remoteUrl);
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        debugPrint(
            'Download failed with status ${response.statusCode}: $remoteUrl');
        return null;
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.isEmpty) return null;

      final docDir = await getApplicationDocumentsDirectory();
      final localPath = '${docDir.path}/chat_files';
      await Directory(localPath).create(recursive: true);

      final localFile = File('$localPath/$fileName');
      await localFile.writeAsBytes(bytes);
      return localFile.uri.toString();
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    }
  }

  /// Truncates a message for preview in the chat room list.
  String _truncatePreview(String text) {
    if (text.length <= 40) return text;
    return '${text.substring(0, 40)}…';
  }

  Future<void> _updateChatMeta(String chatId, String lastMsg) async {
    try {
      final doc = await Supabase.instance.client
          .from('chat_rooms')
          .select()
          .eq('id', chatId)
          .single();
      final participants = List<String>.from(doc['participants'] ?? []);
      final otherUid =
          participants.firstWhere((p) => p != _myUid, orElse: () => '');

      final unread = Map<String, dynamic>.from(doc['unread_counts'] ?? {});
      if (otherUid.isNotEmpty) {
        unread[otherUid] = (unread[otherUid] as int? ?? 0) + 1;
      }

      // Store last message as plaintext preview (not encrypted)
      // This is just metadata for the chat list, not sensitive message content
      await Supabase.instance.client.from('chat_rooms').update({
        'last_message': lastMsg,
        'last_message_time': DateTime.now().toIso8601String(),
        'unread_counts': unread,
      }).eq('id', chatId);
    } catch (e) {
      debugPrint('Error updating chat metadata: $e');
    }
  }
}
