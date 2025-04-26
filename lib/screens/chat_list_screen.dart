import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_coversation.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF9400), // Orange
                Color(0xFFFFCC80),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text(
          'Chats',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, chatSnapshot) {
          if (!chatSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatDocs = chatSnapshot.data!.docs;

          if (chatDocs.isEmpty) {
            return const Center(child: Text("No conversations yet."));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chat = chatDocs[index];
              final participants = List<String>.from(chat['participants']);
              final otherUserId = participants.firstWhere((id) => id != currentUserId);
              final chatId = chat.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final name = userData['name'] ?? 'User';
                  final imageUrl = userData['imageUrl'] ?? '';

                 return StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('chats/$chatId/messages')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots(),
  builder: (context, messageSnapshot) {
    String lastMessage = '';
    String time = '';
    bool isUnread = false;

    if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
      final lastMsg = messageSnapshot.data!.docs.first;
      final data = lastMsg.data() as Map<String, dynamic>;
      lastMessage = data['text'] ?? '';
      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        time = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }

      final seenBy = List<String>.from(data['seenBy'] ?? []);
      isUnread = !seenBy.contains(currentUserId);
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty ? Text(name[0]) : null,
      ),
      title: Text(
        name,
        style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage,
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (isUnread)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.circle, size: 10, color: Colors.blue),
            ),
        ],
      ),
      trailing: Text(time, style: const TextStyle(color: Colors.grey)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversation: ChatConversation(
                id: otherUserId,
                name: name,
                imageUrl: imageUrl,
              ),
            ),
          ),
        );
      },
    );
  },
)
;
                },
              );
            },
          );
        },
      ),
    );
  }
}
