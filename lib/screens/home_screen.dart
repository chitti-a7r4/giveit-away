import 'package:flutter/material.dart';
import 'item_view_screen.dart'; // Import the ItemViewScreen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                  'giveIT-away',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.lock_outline, size: 24),
              ],
            ),
            SizedBox(height: 15),
            Text(
              'Give things away easily',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  DonationCard(
                    title: 'Vacuum Cleaner',
                    category: 'Appliances',
                    location: 'Nagpur',
                    imagePath: 'assets/vaccum.png',
                    onTap: () {
                      _navigateToItemView(context, 'Vacuum Cleaner', 'A powerful vacuum cleaner.', 'Appliances', 'Nagpur', 'assets/vaccum.png');
                    },
                  ),
                  DonationCard(
                    title: 'T-shirt',
                    category: 'Clothing',
                    location: 'Mumbai',
                    imagePath: 'assets/tshirt.png',
                    onTap: () {
                      _navigateToItemView(context, 'T-shirt', 'A gently used cotton T-shirt.', 'Clothing', 'Mumbai', 'assets/tshirt.png');
                    },
                  ),
                  DonationCard(
                    title: 'Desk Lamp',
                    category: 'Household',
                    location: 'Delhi',
                    imagePath: 'assets/lamp.png',
                    onTap: () {
                      _navigateToItemView(context, 'Desk Lamp', 'A stylish desk lamp for your workspace.', 'Household', 'Delhi', 'assets/lamp.png');
                    },
                  ),
                  DonationCard(
                    title: 'Chocolate Bar',
                    category: 'Food',
                    location: 'Kolkata',
                    imagePath: 'assets/chocolate.png',
                    onTap: () {
                      _navigateToItemView(context, 'Chocolate Bar', 'A delicious chocolate bar.', 'Food', 'Kolkata', 'assets/chocolate.png');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to ItemViewScreen
  void _navigateToItemView(BuildContext context, String title, String description, String category, String location, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemViewScreen(
          itemName: title,
          description: description,
          category: category,
          contactInfo: location,
          imageUrl: imagePath,
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
  final VoidCallback onTap; // Add a callback for tap action

  const DonationCard({super.key, 
    required this.title,
    required this.category,
    required this.location,
    required this.imagePath,
    required this.onTap, // Add the onTap callback to the constructor
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
        onTap: onTap, // Handle the tap action to navigate
      ),
    );
  }
}
