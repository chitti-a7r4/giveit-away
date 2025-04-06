import 'package:flutter/material.dart';

class ItemViewScreen extends StatelessWidget {
  final String itemName;
  final String description;
  final String category;
  final String contactInfo;
  final String imageUrl;

  const ItemViewScreen({super.key, 
    required this.itemName,
    required this.description,
    required this.category,
    required this.contactInfo,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
        backgroundColor: const Color.fromARGB(255, 166, 215, 67),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Add share functionality here
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                imageUrl,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            Text(
              itemName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Category: $category',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Text(
              'Location: $contactInfo',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Handle contact action (e.g., show a dialog or call a contact function)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.green, // Use backgroundColor instead of primary
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                textStyle: TextStyle(fontSize: 16),
              ),
              child: Text('Contact Donator'),
            ),
          ],
        ),
      ),
    );
  }
}
