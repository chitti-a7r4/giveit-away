import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtherUserProfileScreen extends StatelessWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2196F3), // Blue
                Color(0xFFBBDEFB), // Light Blue
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text(
          'User Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUserData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData = snapshot.data;

                  if (userData == null) {
                    return const Center(
                      child: Text("User data not found."),
                    );
                  }

                  final name = userData['name'] ?? 'Anonymous';
                  final bio = userData['bio'] ?? 'No bio added';
                  final profilePic = userData['imageUrl'] ?? '';
                  final createdAt = userData['createdAt'] as Timestamp?;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile picture
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: profilePic.isNotEmpty
                                ? NetworkImage(profilePic)
                                : const AssetImage('assets/profile_pic.png') as ImageProvider,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Name
                        Center(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Bio
                        Center(
                          child: Text(
                            'Bio: $bio',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // User since
                        Center(
                          child: Text(
                            'User since: ${_formatDate(createdAt)}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          'User Donations',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        // StreamBuilder to show user's donations
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('posts')
                                .where('uid', isEqualTo: userId)
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text("This user hasn't posted any items yet."),
                                );
                              }

                              final posts = snapshot.data!.docs;

                              return ListView.builder(
                                itemCount: posts.length,
                                itemBuilder: (context, index) {
                                  final post = posts[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      leading: Image(
                                        image: post['images'].isNotEmpty
                                            ? NetworkImage(post['images'][0])
                                            : const AssetImage('assets/profile_pic.png') as ImageProvider,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                      title: Text(
                                        post['title'],
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        '${post['category']}\n${post['location']}',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}