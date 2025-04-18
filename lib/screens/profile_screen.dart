import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            runSpacing: 15,
            children: [
              const Center(
                child: Text(
                  'Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  // TODO: Add Help & Support logic
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Top bar (Always visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Profile',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showSettingsMenu(context),
                  ),
                ],
              ),
            ),

            // User Info and Content
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
                      child: Text("User data not found. Please update your profile."),
                    );
                  }

                  final name = userData['name'] ?? 'Anonymous';
                  final bio = userData['bio'] ?? 'No bio added';
                  final profilePic = userData['imageUrl'] ?? '';

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
                        const SizedBox(height: 30),

                        const Text(
                          'Your Donations',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        Expanded(
                          child: ListView(
                            children: const [
                              DonationCard(
                                title: 'Vaccum Cleaner',
                                category: 'Appliances',
                                location: 'Nagpur',
                                imagePath: 'assets/vaccum.png',
                              ),
                            ],
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

  const DonationCard({
    super.key,
    required this.title,
    required this.category,
    required this.location,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Image.asset(imagePath, width: 50, height: 50),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text('$category\n$location', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Available',
            style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
