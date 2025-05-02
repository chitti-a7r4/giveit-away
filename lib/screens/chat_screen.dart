import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_coversation.dart';
import 'other_user_profile_screen.dart';

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

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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
    // Removed unused variable 'otherUserId'
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF007AFF)], // Gradient colors
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(widget.conversation.id).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("Loading...");
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final profilePicUrl = userData['imageUrl'] ?? ''; // Replace 'imageUrl' with the actual field name in Firestore
            final username = userData['name'] ?? widget.conversation.name;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtherUserProfileScreen(userId: widget.conversation.id),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: profilePicUrl.isNotEmpty
                        ? NetworkImage(profilePicUrl)
                        : const AssetImage('assets/profile_pic.png') as ImageProvider,
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: _firestore.collection('chats').doc(chatId).snapshots(),
                        builder: (context, chatSnapshot) {
                          final isTyping = chatSnapshot.hasData
                              ? ((chatSnapshot.data!.data() as Map<String, dynamic>)['typing'] ?? {})[widget.conversation.id] == true
                              : false;

                          return isTyping
                              ? const Text(
                                  'Typing...',
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        centerTitle: false,
        elevation: 0,
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

                    // Get the current message's date
                    final messageDate = message.timestamp?.toDate();
                    final now = DateTime.now();

                    // Determine if a date header should be shown
                    bool showDateHeader = false;
                    if (index == 0) {
                      showDateHeader = true; // Always show the date header for the first message
                    } else {
                      final previousMessageDate =
                          (docs[index - 1].data() as Map<String, dynamic>)['timestamp']
                              ?.toDate();
                      if (previousMessageDate != null &&
                          messageDate != null &&
                          !isSameDay(messageDate, previousMessageDate)) {
                        showDateHeader = true; // Show the date header if the date changes
                      }
                    }

                    // Determine the date label (Today, Yesterday, or specific date)
                    String dateLabel = '';
                    if (messageDate != null) {
                      if (isSameDay(messageDate, now)) {
                        dateLabel = 'Today';
                      } else if (isSameDay(messageDate, now.subtract(const Duration(days: 1)))) {
                        dateLabel = 'Yesterday';
                      } else {
                        dateLabel = "${messageDate.day}/${messageDate.month}/${messageDate.year}";
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                dateLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        Align(
                          alignment: message.isSender
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: message.isSender
                                  ? const LinearGradient(
                                      colors: [Color(0xFF4A90E2), Color(0xFF007AFF)], // Gradient for sender
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null, // No gradient for receiver
                              color: message.isSender ? null : Colors.grey[300], // Solid color for receiver
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2), // Subtle shadow for depth
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    message.text,
                                    style: TextStyle(
                                      color: message.isSender ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8), // Space between message and timestamp
                                Row(
                                  children: [
                                    Text(
                                      _formatTimestamp(message.timestamp),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: message.isSender ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(width: 4), // Space between timestamp and ticks
                                    if (message.isSender)
                                      Icon(
                                        message.seenBy.contains(widget.conversation.id)
                                            ? Icons.done_all // Double ticks for "Seen"
                                            : Icons.done,    // Single tick for "Sent"
                                        size: 16,
                                        color: message.seenBy.contains(widget.conversation.id)
                                            ? Colors.white // White for "Seen"
                                            : Colors.white70, // Grey for "Sent"
                                      ),
                                  ],
                                ),
                              ],
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

