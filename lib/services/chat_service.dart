import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../main.dart' show firebaseInitialized;

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

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      imageUrl: d['imageUrl'],
      fileUrl: d['fileUrl'],
      fileName: d['fileName'],
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isMe: d['senderId'] == myUid,
    );
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

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(d['participants'] ?? []),
      lastMessage: d['lastMessage'] ?? '',
      lastMessageTime: (d['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(d['unreadCounts'] ?? {}),
    );
  }
}

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Chat Rooms ────────────────────────────────────────────────────────────

  /// Stream of all chat rooms for the current user, ordered by last message.
  Stream<List<ChatRoom>> getChatRooms() {
    if (!firebaseInitialized || _myUid.isEmpty) return const Stream.empty();
    return _db
        .collection('chats')
        .where('participants', arrayContains: _myUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatRoom.fromFirestore).toList());
  }

  /// Get or create a 1-to-1 chat room with another user.
  Future<String> getOrCreateChatRoom(String otherUid) async {
    if (!firebaseInitialized) return '';

    // Check if a chat already exists between these two users
    final existing = await _db
        .collection('chats')
        .where('participants', arrayContains: _myUid)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(otherUid) && participants.length == 2) {
        return doc.id;
      }
    }

    // Create new chat room
    final chatDoc = await _db.collection('chats').add({
      'participants': [_myUid, otherUid],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': {_myUid: 0, otherUid: 0},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return chatDoc.id;
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Real-time stream of messages in a chat room.
  Stream<List<ChatMessage>> getMessages(String chatId) {
    if (!firebaseInitialized || chatId.isEmpty) return const Stream.empty();
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  /// Send a text message.
  Future<void> sendText(String chatId, String text) async {
    if (!firebaseInitialized || chatId.isEmpty || text.trim().isEmpty) return;

    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': _myUid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update chat room metadata
    await _updateChatMeta(chatId, text.trim());
  }

  /// Send a photo message.
  Future<void> sendPhoto(String chatId, File imageFile) async {
    if (!firebaseInitialized || chatId.isEmpty) return;

    final ref = _storage
        .ref('chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': _myUid,
      'text': '',
      'imageUrl': url,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _updateChatMeta(chatId, '📷 Photo');
  }

  /// Send a file.
  Future<void> sendFile(String chatId, File file, String fileName) async {
    if (!firebaseInitialized || chatId.isEmpty) return;

    final ref = _storage
        .ref('chat_files/$chatId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': _myUid,
      'text': '',
      'fileUrl': url,
      'fileName': fileName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _updateChatMeta(chatId, '📎 $fileName');
  }

  /// Mark all messages as read for current user.
  Future<void> markAsRead(String chatId) async {
    if (!firebaseInitialized || chatId.isEmpty) return;
    await _db.collection('chats').doc(chatId).update({
      'unreadCounts.$_myUid': 0,
    });
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _updateChatMeta(String chatId, String lastMsg) async {
    // Get the other user's UID
    final chatDoc = await _db.collection('chats').doc(chatId).get();
    final participants = List<String>.from(chatDoc['participants'] ?? []);
    final otherUid = participants.firstWhere((p) => p != _myUid, orElse: () => '');

    await _db.collection('chats').doc(chatId).update({
      'lastMessage': lastMsg,
      'lastMessageTime': FieldValue.serverTimestamp(),
      if (otherUid.isNotEmpty) 'unreadCounts.$otherUid': FieldValue.increment(1),
    });
  }
}
