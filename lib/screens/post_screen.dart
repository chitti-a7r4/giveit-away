import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;  // Image package for compression

final Logger _logger = Logger();

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
  File? _selectedImage1;
  File? _selectedImage2;
  File? _selectedImage3;
  final picker = ImagePicker();

  String? _category;
  final List<String> _categories = ['Electronics', 'Furniture', 'Clothing', 'Books', 'Others'];

  // Function to pick images from gallery
  Future<void> _pickImages() async {
    final pickedFiles = await picker.pickMultiImage();
    setState(() {
      if (pickedFiles.length > 0) {
        _selectedImage1 = File(pickedFiles[0].path);
      }
      if (pickedFiles.length > 1) {
        _selectedImage2 = File(pickedFiles[1].path);
      }
      if (pickedFiles.length > 2) {
        _selectedImage3 = File(pickedFiles[2].path);
      }
    });
    }

  // Function to compress the image
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

  // Function to upload the image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      File? compressedImage = await _compressImage(image);
      if (compressedImage == null) {
        _logger.e("Failed to compress image.");
        return null;
      }

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = _storage.ref().child('images/$fileName');

      UploadTask uploadTask = storageReference.putFile(compressedImage);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _logger.e("Error uploading image: $e");
      return null;
    }
  }

  // Function to get location
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
        _locationController.text = address;
      });
    } catch (e) {
      _logger.e("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to get location. Try again.")),
      );
    }
  }

  // Function to submit the post
  void _submitPost() async {
    if (_formKey.currentState!.validate()) {
      if (_category == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a category.")),
        );
        return;
      }

      if (_selectedImage1 == null && _selectedImage2 == null && _selectedImage3 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one image.")),
        );
        return;
      }

      List<String> imageUrls = [];
      if (_selectedImage1 != null) {
        String? imageUrl1 = await _uploadImage(_selectedImage1!);
        if (imageUrl1 != null) imageUrls.add(imageUrl1);
      }
      if (_selectedImage2 != null) {
        String? imageUrl2 = await _uploadImage(_selectedImage2!);
        if (imageUrl2 != null) imageUrls.add(imageUrl2);
      }
      if (_selectedImage3 != null) {
        String? imageUrl3 = await _uploadImage(_selectedImage3!);
        if (imageUrl3 != null) imageUrls.add(imageUrl3);
      }

      // Save post details in Firestore
      try {
try {
  await FirebaseFirestore.instance.collection('posts').add({
    'title': _titleController.text,
    'description': _descriptionController.text,
    'category': _category,
    'location': _locationController.text,
    'images': imageUrls,
    'timestamp': FieldValue.serverTimestamp(),
  });

  _logger.i("Post saved successfully!");
} catch (e) {
  _logger.e("Error saving post to Firestore: $e");
}

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item posted successfully!")),
        );

        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        setState(() {
          _category = null;
          _selectedImage1 = null;
          _selectedImage2 = null;
          _selectedImage3 = null;
        });
      } catch (e) {
        _logger.e("Error saving post to Firestore: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error posting item. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post an Item"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title Field
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

              // Description Field
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

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
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

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Get Location Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Use My Location"),
                ),
              ),
              const SizedBox(height: 20),

              // Image Picker
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: _selectedImage1 == null && _selectedImage2 == null && _selectedImage3 == null
                      ? const Center(child: Text("Tap to select images"))
                      : GridView(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                          ),
                          children: [
                            if (_selectedImage1 != null)
                              Image.file(
                                _selectedImage1!,
                                fit: BoxFit.cover,
                              ),
                            if (_selectedImage2 != null)
                              Image.file(
                                _selectedImage2!,
                                fit: BoxFit.cover,
                              ),
                            if (_selectedImage3 != null)
                              Image.file(
                                _selectedImage3!,
                                fit: BoxFit.cover,
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitPost,
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
