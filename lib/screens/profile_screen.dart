import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.settings, size: 24), // Settings icon
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/profile_pic.png'), // Replace with user's profile picture
              ),
            ),
            SizedBox(height: 15),
            Center(
              child: Text(
                'Shiva', // User's name
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                'Bio: Giving back to the community through small acts of kindness.', // User's bio
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Your Donations',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  DonationCard(
                    title: 'Vaccum Cleaner',
                    category: 'Appliances',
                    location: 'Nagpur',
                    imagePath: 'assets/vaccum.png',
                  ),
                  DonationCard(
                    title: 'T-shirt',
                    category: 'Clothing',
                    location: 'Mumbai',
                    imagePath: 'assets/tshirt.png',
                  ),
                  DonationCard(
                    title: 'Desk Lamp',
                    category: 'Household',
                    location: 'Delhi',
                    imagePath: 'assets/lamp.png',
                  ),
                  DonationCard(
                    title: 'Chocolate Bar',
                    category: 'Food',
                    location: 'Kolkata',
                    imagePath: 'assets/chocolate.png',
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

// Widget for donation card
class DonationCard extends StatelessWidget {
  final String title;
  final String category;
  final String location;
  final String imagePath;

  const DonationCard({super.key, 
    required this.title,
    required this.category,
    required this.location,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Image.asset(imagePath, width: 50, height: 50),
        title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text('$category\n$location', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
