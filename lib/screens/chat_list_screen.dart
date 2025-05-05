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
            padding: const EdgeInsets.all(10),
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chat = chatDocs[index];
              final participants = List<String>.from(chat['participants']);
              final otherUserId = participants.firstWhere((id) => id != currentUserId);
              final chatId = chat.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data!.data() == null) {
                    return const SizedBox.shrink(); // Return an empty widget if data is null
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
                      bool isUnread = false;

                      if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                        final lastMsg = messageSnapshot.data!.docs.first;
                        final data = lastMsg.data() as Map<String, dynamic>;
                        lastMessage = data['text'] ?? '';

                        final seenBy = List<String>.from(data['seenBy'] ?? []);
                        isUnread = !seenBy.contains(currentUserId);
                      }

                      return GestureDetector(
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
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFAFAFA), // Light grey
                                Color(0xFFF5F5F5), // Slightly darker grey
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15), // Slightly darker shadow
                                blurRadius: 8, // Increased blur for a softer shadow
                                offset: const Offset(0, 4), // Adjusted offset for a more natural look
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2), // Subtle border for better definition
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                radius: 30,
                                child: imageUrl.isEmpty ? Text(name[0]) : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMessage,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
