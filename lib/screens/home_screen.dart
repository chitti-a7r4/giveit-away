import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'item_view_screen.dart';

// 🔼 Custom widget for each donation item card
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
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imagePath.isNotEmpty ? imagePath : 'https://via.placeholder.com/50',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/images/placeholder.png', width: 50, height: 50);
            },
          ),
        ),
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
        onTap: onTap,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedLocation = 'All';
  String selectedCategory = 'All';

  final List<String> locations = [
    'All', 'Shillong', 'Guwahati', 'Delhi', 'Hyderabad' // ➕ add more
  ];

  final List<String> categories = [
    'All', 'Electronics', 'Furniture', 'Clothing', 'Books', 'Others'
  ];

  // Function to get current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      final city = placemarks.first.locality;
      setState(() {
        selectedLocation = city ?? 'Unknown';
      });
    }
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
          'giveIT-away',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          //  const SizedBox(height: 15),
            const Text(
              'Give things away easily',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 🌍 Location Dropdown and Current Location Button
            Row(
              children: [
                const Text("Location: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedLocation,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLocation = value;
                      });
                    }
                  },
                  items: locations.map((loc) {
                    return DropdownMenuItem(
                      value: loc,
                      child: Text(loc),
                    );
                  }).toList(),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                ),
              ],
            ),

            const SizedBox(height: 5),

            // 📦 Category Dropdown
            Row(
              children: [
                const Text("Category: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                ),
              ],
            ),

            // 🔄 Posts List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No items available yet.'));
                  }

                  // ⛏️ Filter data by selected location and category
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final location = data['location'] ?? '';
                    final category = data['category'] ?? '';

                    bool locationMatch = selectedLocation == 'All' || location.toString().toLowerCase().startsWith(selectedLocation.toLowerCase());
                    bool categoryMatch = selectedCategory == 'All' || category.toString().toLowerCase().startsWith(selectedCategory.toLowerCase());

                    return locationMatch && categoryMatch;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text('No items found for this location and category.'));
                  }

                  return ListView(
                    children: filteredDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

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
                              builder: (_) => ItemViewScreen(
                                itemName: data['title'] ?? '',
                                description: data['description'] ?? '',
                                category: data['category'] ?? '',
                                contactInfo: data['contactInfo'] ?? '',
                                location: data['location'] ?? '',
                                imageUrls: List<String>.from(data['images'] ?? []),
                                donorName: data['userName'] ?? 'Unknown Donor',
                                donorImageUrl: data['userProfileImageUrl'] ?? '',
                                uid: data['uid'] ?? '',
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
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
