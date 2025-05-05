import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'item_view_screen.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';


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
  final String? selectedCategory;
  final String? selectedLocation;

  const HomeScreen({
    super.key,
    this.selectedCategory,
    this.selectedLocation,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String selectedCategory;
  late String selectedLocation;

  // This duplicate initState method is removed to resolve the error.

  // Locations for the cards
  final List<Map<String, dynamic>> locations = [
    {'name': 'All', 'icon': Icons.public, 'state': ''},
    {'name': 'Shillong', 'icon': Icons.terrain, 'state': 'Meghalaya'},
    {'name': 'Guwahati', 'icon': Icons.water, 'state': 'Assam'},
    {'name': 'Delhi', 'icon': Icons.account_balance, 'state': 'Delhi'},
    {'name': 'Hyderabad', 'icon': Icons.fort, 'state': 'Telangana'},
    {'name': 'Mumbai', 'icon': Icons.apartment, 'state': 'Maharashtra'},
    {'name': 'Chennai', 'icon': Icons.beach_access, 'state': 'Tamil Nadu'},
    {'name': 'Kolkata', 'icon': Icons.tram, 'state': 'West Bengal'},
    {'name': 'Bangalore', 'icon': Icons.computer, 'state': 'Karnataka'},
    {'name': 'Pune', 'icon': Icons.school, 'state': 'Maharashtra'},
    {'name': 'Jaipur', 'icon': Icons.festival, 'state': 'Rajasthan'},
    {'name': 'Lucknow', 'icon': Icons.mosque, 'state': 'Uttar Pradesh'},
    {'name': 'Ahmedabad', 'icon': Icons.factory, 'state': 'Gujarat'},
    {'name': 'Others', 'icon': Icons.apartment, 'state': ''},
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


  List<String> cityNames = []; // List to store city names
  List<String> stateNames = []; // List to store state names

@override
void initState() {
  super.initState();

  // Initialize selectedCategory and selectedLocation with passed values or defaults
  selectedCategory = widget.selectedCategory ?? 'All';
  selectedLocation = widget.selectedLocation ?? 'All';

  // Load both cities and states
  _loadCitiesAndStates();
}
  // Load cities and states from the CSV file
  Future<void> _loadCitiesAndStates() async {
    final String csvData = await rootBundle.loadString('assets/cities.csv');
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

    setState(() {
      // Extract city names and state names
      cityNames = rows.skip(1).map((row) => row[0].toString().trim()).toList();
      stateNames = rows.skip(1).map((row) => row[5].toString().trim()).toSet().toList(); // Unique states
    });
  }

  // Combine cities and states for the Autocomplete widget
  List<String> get combinedLocations => [...cityNames, ...stateNames];

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

    // **UPDATED:** Replacing desiredAccuracy with settings
    Position position = await Geolocator.getCurrentPosition(
       desiredAccuracy: LocationAccuracy.high, // Set desired accuracy
    );

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      final city = placemarks.first.locality;
      if (city != null && city.isNotEmpty) {
        setState(() {
          selectedLocation = city;

          // Add the fetched location to the locations list if it doesn't exist
          if (!locations.any((loc) => loc['name'] == city)) {
            locations.add({'name': city, 'icon': Icons.location_city, 'state': ''});
          }
        });
      }
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
          'GiveIT-away',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // Carousel Slider
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Roboto',
                                    letterSpacing: 1.2,
                                    color: Colors.white,
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

                  // Locations List
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedLocation = location['name'];
                            });
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5), // Added vertical margin
                            child: Container(
                              width: 100,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: selectedLocation == location['name']
                                    ? Colors.blue[100]
                                    : Colors.white,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    location['icon'],
                                    size: 30,
                                    color: selectedLocation == location['name']
                                        ? Colors.blue
                                        : Colors.grey[700],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    location['name'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: selectedLocation == location['name']
                                          ? Colors.blue
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Location Dropdown and Category Dropdown
                  Row(
                    children: [
                      // Location Autocomplete and Locator Button
                      SizedBox(
                        width: 193, // Adjust width as needed
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Autocomplete<String>(
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<String>.empty();
                                  }
                                  return combinedLocations.where((location) =>
                                      location.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                },
                                onSelected: (String selection) {
                                  setState(() {
                                    selectedLocation = selection;
                                  });
                                  FocusScope.of(context).unfocus(); // Unfocus the text field after selection
                                },
                                fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                                  // Set the initial text in the field to the currently selected location
                                  if (textEditingController.text.isEmpty || textEditingController.text != selectedLocation) {
                                     textEditingController.text = selectedLocation;
                                  }
                                  return TextFormField(
                                    controller: textEditingController,
                                    focusNode: focusNode,
                                     onFieldSubmitted: (String value) {
                                      // Optional: Update selectedLocation when user submits via keyboard
                                       setState(() {
                                         selectedLocation = value;
                                       });
                                     },
                                    decoration: const InputDecoration(
                                      labelText: 'Search Location',
                                      border: OutlineInputBorder(),
                                       isDense: true, // Compact the input field
                                       contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15), // Adjust padding
                                    ),
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _getCurrentLocation,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 5),

                      // Category Dropdown
                      SizedBox(
                        width: 180, // Adjust width as needed
                        child: Row(
                          children: [
                            const Icon(Icons.category, size: 18),
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
                                            overflow: TextOverflow.visible, // Allow text to wrap or overflow
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                 underline: Container(), // Remove default underline
                                 icon: const Icon(Icons.arrow_drop_down), // Custom dropdown icon
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),

          // Posts List
          SliverToBoxAdapter(
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

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final location = data['location'] ?? '';
                  final category = data['category'] ?? '';

                  // Extract city and state from the location field
                  final city = location.split(',').first.trim(); // Assuming "City, State" format
                  final state = location.split(',').length > 1
                      ? location.split(',')[1].trim()
                      : '';

                  // Match selectedLocation with either city or state
                  bool locationMatch = selectedLocation == 'All' ||
                      city.toLowerCase().startsWith(selectedLocation.toLowerCase()) ||
                      state.toLowerCase().startsWith(selectedLocation.toLowerCase());

                  bool categoryMatch = selectedCategory == 'All' ||
                      category.toString().toLowerCase().startsWith(selectedCategory.toLowerCase());

                  return locationMatch && categoryMatch;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No items found for this location and category.'));
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
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
    );
  }
}