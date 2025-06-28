import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_view_screen.dart';
import 'package:newapp/widgets/web_mobile_frame.dart';


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

                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.8,
                                ),
                                itemCount: posts.length,
                                itemBuilder: (context, index) {
                                  final post = posts[index];
                                  final data = post.data() as Map<String, dynamic>;

                                  final imagePath = data['images'] != null && data['images'].isNotEmpty
                                      ? data['images'][0]
                                      : '';

                                  return DonationCard(
                                    title: data['title'] ?? 'No Title',
                                    category: data['category'] ?? 'Unknown',
                                    location: data['location'] ?? 'Unknown',
                                    imagePath: imagePath,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WebMobileFrame(child: ItemViewScreen(
                                            itemName: data['title'] ?? '',
                                            description: data['description'] ?? '',
                                            category: data['category'] ?? '',
                                            contactInfo: data['contactInfo'] ?? '',
                                            location: data['location'] ?? '',
                                            imageUrls: List<String>.from(data['images'] ?? []),
                                            donorName: userData['name'] ?? 'Unknown Donor',
                                            donorImageUrl: userData['imageUrl'] ?? '',
                                            uid: data['uid'] ?? '',
                                          ),
                                        ),)
                                      );
                                    },
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

class DonationCard extends StatelessWidget {
  final String title;
  final String category;
  final String location;
  final String imagePath;
  final VoidCallback onTap;

  const DonationCard({
    super.key,
    required this.title,
    required this.category,
    required this.location,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image(
                  image: imagePath.isNotEmpty
                      ? NetworkImage(imagePath)
                      : const AssetImage('assets/profile_pic.png') as ImageProvider,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}