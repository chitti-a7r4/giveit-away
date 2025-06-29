import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:reorderables/reorderables.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http; // Add this import

final Logger _logger = Logger();

List<String> _cities = [];

Future<void> _loadCities() async {
  try {
    String rawData;
    
    if (kIsWeb) {
      // For web deployment, use HTTP request
      final response = await http.get(Uri.parse('assets/assets/cities.csv'));
      if (response.statusCode == 200) {
        rawData = response.body;
      } else {
        throw Exception('Failed to load CSV file: ${response.statusCode}');
      }
    } else {
      // For mobile/desktop, use rootBundle
      rawData = await rootBundle.loadString('assets/cities.csv');
    }
    
    List<List<dynamic>> csvData = const CsvToListConverter().convert(rawData);
    _cities = csvData.map((row) => "${row[0]}, ${row[5]}, ${row[3]}").toList(); // City, State, Country
    _logger.i("Cities loaded successfully: ${_cities.length} cities.");
  } catch (e) {
    _logger.e("Error loading cities: $e");
  }
}

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final List<File> _selectedImages = []; // Replace individual image variables with a list
  final picker = ImagePicker();

  String? _category;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Electronics', 'icon': Icons.devices},
    {'name': 'Furniture', 'icon': Icons.chair},
    {'name': 'Clothing', 'icon': Icons.checkroom},
    {'name': 'Books', 'icon': Icons.book},
    {'name': 'Coupons', 'icon': Icons.local_offer},
    {'name': 'Toys', 'icon': Icons.toys},
    {'name': 'Groceries', 'icon': Icons.shopping_cart},
    {'name': 'Appliances', 'icon': Icons.kitchen},
    {'name': 'Sports Equipment', 'icon': Icons.sports_cricket},
    {'name': 'Others', 'icon': Icons.more_horiz},
  ];
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _isCitiesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCities().then((_) {
      setState(() {
        _isCitiesLoaded = true;
      });
    });
  }

  Future<void> _pickImages() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        // Append new images to the existing list, ensuring the limit is not exceeded
        final newImages = pickedFiles.map((file) => File(file.path)).toList();
        final remainingSlots = 3 - _selectedImages.length;
        _selectedImages.addAll(newImages.take(remainingSlots));
      });
    }
  }

  Future<File?> _compressImage(File image) async {
    try {
      img.Image? imageFile = img.decodeImage(image.readAsBytesSync());
      if (imageFile == null) {
        _logger.e("Error decoding image");
        return null;
      }
      img.Image compressedImage = img.copyResize(imageFile, width: 800);
      List<int> compressedImageBytes = img.encodeJpg(compressedImage, quality: 80);
      File compressedFile = File(image.path)..writeAsBytesSync(compressedImageBytes);
      return compressedFile;
    } catch (e) {
      _logger.e("Error compressing image: $e");
      return null;
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      File? compressedImage = await _compressImage(image);
      if (compressedImage == null) return null;

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = _storage.ref().child('images/$fileName');

      UploadTask uploadTask = storageReference.putFile(compressedImage);

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      TaskSnapshot snapshot = await uploadTask;
      setState(() {
        _isUploading = false;
      });

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _logger.e("Error uploading image: $e");
      setState(() {
        _isUploading = false;
      });
      return null;
    }
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied.")),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      String address = "${place.locality}, ${place.administrativeArea}, ${place.country}";

      _logger.i("Fetched location: $address");

      setState(() {
        _locationController.text = address; // This will now reflect in the Autocomplete field
      });
    } catch (e) {
      _logger.e("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to get location. Try again.")),
      );
    }
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      if (_category == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a category.")),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You need to be logged in to post.")),
        );
        return;
      }

      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one image.")),
        );
        return;
      }

      // Fetch user details
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String userName = userDoc['name'] ?? 'Anonymous';
      String profileImageUrl = userDoc['imageUrl'] ?? '';

      List<String> imageUrls = [];
      for (File image in _selectedImages) {
        String? imageUrl = await _uploadImage(image);
        if (imageUrl != null) imageUrls.add(imageUrl);
      }

      try {
        await FirebaseFirestore.instance.collection('posts').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'category': _category,
          'location': _locationController.text,
          'images': imageUrls,
          'timestamp': FieldValue.serverTimestamp(),
          'uid': user.uid,
          'userName': userName,
          'userProfileImageUrl': profileImageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item posted successfully!")),
        );

        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        setState(() {
          _category = null;
          _selectedImages.clear();
        });
      } catch (e) {
        _logger.e("Error saving post to Firestore: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error posting item. Please try again.")),
        );
      }
    }
  }

  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            "Upload Images",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Drag to rearrange (First image will be the cover photo)",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: ReorderableWrap(
            spacing: 8.0,
            runSpacing: 8.0,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final image = _selectedImages.removeAt(oldIndex);
                _selectedImages.insert(newIndex, image);
              });
            },
            children: [
              ..._selectedImages.map((image) {
                final isCoverPhoto = _selectedImages.indexOf(image) == 0;
                return Stack(
                  key: ValueKey(image),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isCoverPhoto)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Cover",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.remove(image);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: const Icon(Icons.close, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              if (_selectedImages.length < 3)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Icon(Icons.add, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4CAF50), // Green
                Color(0xFFC8E6C9), // Light Blue
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text(
          'Post an Item',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['name'],
                    child: Row(
                      children: [
                        Icon(category['icon'], size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(category['name']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newCategory) {
                  setState(() {
                    _category = newCategory;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 20),
              _isCitiesLoaded
                  ? Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _cities.where((city) =>
                            city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (String selection) {
                        _locationController.text = selection;
                      },
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController textEditingController,
                          FocusNode focusNode,
                          VoidCallback onFieldSubmitted) {
                        textEditingController.text = _locationController.text;
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Use My Location"),
                ),
              ),
              const SizedBox(height: 20),
              _buildImageGrid(),
              const SizedBox(height: 30),
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      const Text("Uploading image(s)..."),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _uploadProgress),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Post Item",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}