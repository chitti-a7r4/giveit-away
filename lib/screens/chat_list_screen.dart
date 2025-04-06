import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final List<ChatConversation> conversations = [
    ChatConversation(name: 'John Doe', lastMessage: 'Sure, I will pick it up tomorrow.', time: '5:30 PM'),
    ChatConversation(name: 'Jane Smith', lastMessage: 'Is the vacuum still available?', time: '4:15 PM'),
    ChatConversation(name: 'Anil Kumar', lastMessage: 'I am interested in the chocolate bar.', time: '2:45 PM'),
    ChatConversation(name: 'Priya Sharma', lastMessage: 'Can you share the lamp picture?', time: '1:10 PM'),
  ];

   ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return ListTile(
            onTap: () {
              // Navigate to the detailed chat screen for this conversation
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(conversation: conversation),
                ),
              );
            },
            leading: CircleAvatar(
              child: Text(conversation.name[0]), // Show first letter of the name
            ),
            title: Text(conversation.name),
            subtitle: Text(conversation.lastMessage),
            trailing: Text(conversation.time, style: TextStyle(color: Colors.grey)),
          );
        },
      ),
    );
  }
}

class ChatConversation {
  final String name;
  final String lastMessage;
  final String time;

  ChatConversation({required this.name, required this.lastMessage, required this.time});
}
