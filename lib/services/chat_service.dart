import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final String? audioUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.audioUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      audioUrl: data['audioUrl'],
    );
  }
}

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🛡️ Obtener mensajes de una "sala" (Frecuencia de chat)
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
          // Ordenamos localmente para evitar requerir un índice compuesto en Firestore inicialmente
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages;
        });
  }

  // 📝 Enviar mensaje de texto
  Future<void> sendMessage(String chatId, String text, {String? targetUserId, String? senderName}) async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty || text.trim().isEmpty) return;

    final messageData = {
      'senderId': uid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    // 1. Guardar mensaje
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // 2. Actualizar metadatos de la sala
    await _db.collection('chats').doc(chatId).set({
      'lastMessage': text.trim(),
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
    }, SetOptions(merge: true));

    // 3. 🔔 NOTIFICACIÓN TÁCTICA: Avisar al receptor (Si se proporciona)
    if (targetUserId != null) {
      await _db.collection('users').doc(targetUserId).set({
        'lastIncomingChatId': chatId,
        'lastIncomingChatTitle': senderName ?? 'Nuevo Mensaje',
      }, SetOptions(merge: true));
    }
  }

  // 🧹 Limpiar notificación al leer el chat
  Future<void> clearChatNotification(String uid) async {
    await _db.collection('users').doc(uid).set({
      'lastIncomingChatId': null,
      'lastIncomingChatTitle': null,
    }, SetOptions(merge: true));
  }
}
