import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imagePath.isNotEmpty ? imagePath : 'https://via.placeholder.com/150',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/placeholder.png',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            // Text Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedLocation = 'All';
  String selectedCategory = 'All';

  final List<Map<String, dynamic>> locations = [
    {'name': 'All', 'icon': Icons.public},
    {'name': 'Shillong', 'icon': Icons.terrain}, // Example icon for Shillong
    {'name': 'Guwahati', 'icon': Icons.water}, // Example icon for Guwahati
    {'name': 'Delhi', 'icon': Icons.account_balance}, // Example icon for Delhi
    {'name': 'Hyderabad', 'icon': Icons.fort}, // Charminar-like icon
    {'name': 'Mumbai', 'icon': Icons.apartment}, // Example icon for Mumbai
    {'name': 'Chennai', 'icon': Icons.beach_access}, // Example icon for Chennai
    {'name': 'Kolkata', 'icon': Icons.tram}, // Example icon for Kolkata
    {'name': 'Bangalore', 'icon': Icons.computer}, // Example icon for Bangalore
    {'name': 'Pune', 'icon': Icons.school}, // Example icon for Pune
    {'name': 'Jaipur', 'icon': Icons.festival}, // Example icon for Jaipur
    {'name': 'Lucknow', 'icon': Icons.mosque}, // Example icon for Lucknow
    {'name': 'Ahmedabad', 'icon': Icons.factory}, // Example icon for Ahmedabad
    {'name': 'Chandigarh', 'icon': Icons.park}, // Example icon for Chandigarh
  ];

  final List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.all_inclusive},
    {'name': 'Electronics', 'icon': Icons.devices},
    {'name': 'Furniture', 'icon': Icons.chair},
    {'name': 'Clothing', 'icon': Icons.checkroom},
    {'name': 'Books', 'icon': Icons.book},
    {'name': 'Coupons', 'icon': Icons.local_offer}, // New category
    {'name': 'Toys', 'icon': Icons.toys},
    {'name': 'Groceries', 'icon': Icons.shopping_cart},
    {'name': 'Appliances', 'icon': Icons.kitchen},
    {'name': 'Sports Equipment', 'icon': Icons.sports_cricket},
    {'name': 'Others', 'icon': Icons.more_horiz},
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
            // Replace the text with a carousel slider
            CarouselSlider(
              options: CarouselOptions(
                height: 150,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                autoPlayInterval: const Duration(seconds: 3),
              ),
              items: [
                'Sharing is caring.',
                'Happiness grows by sharing.',
                'The joy of giving is the greatest joy.',
                'What we share, we multiply.',
                'Giving is the ultimate act of kindness.',
              ].map((quote) {
                return Builder(
                  builder: (BuildContext context) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF42A5F5), // Light Blue
                              Color(0xFF7E57C2), // Purple
                              Color(0xFF26C6DA), // Teal
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            quote,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16, // Slightly larger font size for better visibility
                              fontWeight: FontWeight.w600, // Semi-bold for emphasis
                              fontFamily: 'Roboto', // Use a clean and modern font
                              letterSpacing: 1.2, // Add spacing between letters for elegance
                              color: Colors.white, // Ensure good contrast with the gradient background
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 🌍 Location Dropdown and Category Dropdown
            Row(
              children: [
                // 🌍 Location Dropdown and Locator Button
                SizedBox(
                  width: 193, // Set a specific width for the Location dropdown
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 18), // Location Icon
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedLocation,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedLocation = value;
                              });
                            }
                          },
                          isExpanded: true,
                          items: locations.map((loc) {
                            return DropdownMenuItem<String>(
                              value: loc['name'] as String,
                              child: Row(
                                children: [
                                  Icon(loc['icon'], size: 18, color: Colors.grey[700]), // City-specific icon
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      loc['name'] as String,
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 1, // Limit to one line
                                      overflow: TextOverflow.ellipsis, // Show "..." for overflow
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _getCurrentLocation,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 5), // Reduced gap between the two dropdowns

                // 📦 Category Dropdown
                SizedBox(
                  width: 180, // Set a specific width for the Category dropdown
                  child: Row(
                    children: [
                      const Icon(Icons.category, size: 18), // Category Icon
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedCategory = value;
                              });
                            }
                          },
                          isExpanded: true,
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat['name'] as String,
                              child: Row(
                                children: [
                                  Icon(cat['icon'], size: 18, color: Colors.grey[700]),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      cat['name'] as String,
                                      style: const TextStyle(fontSize: 14),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

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

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of columns
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8, // Adjust for card height/width ratio
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;

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
                    },
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
