import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lad_courier/services/chat_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final String? targetUserId; // 🎯 Para notificaciones de llegada
  final String? senderName;   // 🎯 Para mostrar quién habla en la notif

  const ChatScreen({
    super.key, 
    required this.chatId, 
    required this.title,
    this.targetUserId,
    this.senderName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _clearNotification();
  }

  void _clearNotification() {
    if (_currentUid.isNotEmpty) {
      _chatService.clearChatNotification(_currentUid);
    }
  }

  void _send() {
    if (_messageController.text.isNotEmpty) {
      _chatService.sendMessage(
        widget.chatId, 
        _messageController.text,
        targetUserId: widget.targetUserId,
        senderName: widget.senderName,
      );
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _clearNotification();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.title.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("No hay mensajes aún", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _currentUid;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.deepPurple[800] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.text,
                style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(msg.timestamp.toDate()),
              style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black38,
                  fontSize: 9,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 🎙️ BOTÓN DE VOZ (PROXIMAMENTE)
            IconButton(
              icon: const Icon(Icons.mic, color: Colors.deepPurple),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Notas de voz disponibles en la próxima actualización."))
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // 🚀 ALTO CONTRASTE
                decoration: InputDecoration(
                  hintText: "Escribe un mensaje...",
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14), // 🚀 MEJOR VISIBILIDAD
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.deepPurple[800],
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
