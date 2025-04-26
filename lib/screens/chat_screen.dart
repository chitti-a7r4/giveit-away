import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_coversation.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String currentUserId;
  late String chatId;
  bool _isSending = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
    chatId = _getChatId(currentUserId, widget.conversation.id);
  }

  String _getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? '${user1}_$user2'
        : '${user2}_$user1';
  }
  String _formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) return '';
  final dt = timestamp.toDate();
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return "$hour:$minute";
}


  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final receiverId = widget.conversation.id;
    final chatDocRef = _firestore.collection('chats').doc(chatId);

    try {
      await chatDocRef.set({
        'participants': [currentUserId, receiverId],
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await chatDocRef.collection('messages').add({
        'text': text,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'seenBy': [currentUserId],
      });

      _controller.clear();
      _updateTyping(false);
    } catch (e) {
      debugPrint("Error sending message: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _markMessagesAsSeen(QuerySnapshot snapshot) {
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final seenBy = List<String>.from(data['seenBy'] ?? []);
      final senderId = data['senderId'];

      if (senderId != currentUserId && !seenBy.contains(currentUserId)) {
        doc.reference.update({
          'seenBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }
  }

  void _updateTyping(bool isTyping) {
    _firestore.collection('chats').doc(chatId).set({
      'typing': {currentUserId: isTyping}
    }, SetOptions(merge: true));
  }

  void _onTextChanged(String value) {
    _updateTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _updateTyping(false);
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _updateTyping(false);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherUserId = widget.conversation.id;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('chats').doc(chatId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text("Chat with ${widget.conversation.name}");
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final typing = (data['typing'] ?? {}) as Map<String, dynamic>;
            final isTyping = typing[otherUserId] == true;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conversation.name),
                if (isTyping)
                  Text(
                    'Typing...',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats/$chatId/messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                _markMessagesAsSeen(snapshot.data!);

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final message = ChatMessage.fromMap(data, currentUserId);
                   return Align(
  alignment: message.isSender
      ? Alignment.centerRight
      : Alignment.centerLeft,
  child: Column(
    crossAxisAlignment: message.isSender
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: message.isSender
              ? Colors.blueAccent
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isSender
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          _formatTimestamp(message.timestamp),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
      if (message.isSender)
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Text(
            message.seenBy.contains(widget.conversation.id)
                ? "✅✅ Seen"
                : "✅ Sent",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
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
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onTextChanged,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isSender;
  final Timestamp? timestamp;
  final List<String> seenBy;

  ChatMessage({
    required this.text,
    required this.isSender,
    required this.timestamp,
    required this.seenBy,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data, String currentUserId) {
    return ChatMessage(
      text: data['text'] ?? '',
      isSender: data['senderId'] == currentUserId,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      seenBy: List<String>.from(data['seenBy'] ?? []),
    );
  }
}

