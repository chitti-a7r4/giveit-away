import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _bio;
  String? _imageUrl;
  bool _loading = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    setState(() {
      _name = data?['name'];
      _bio = data?['bio'];
      _imageUrl = data?['imageUrl'];
      _loading = false;
    });
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<String?> _uploadImageToFirebase(String userId) async {
    if (_selectedImage == null) return _imageUrl; // Use old image if no new image selected
    final ref = FirebaseStorage.instance.ref().child('profile_images/$userId');
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newImageUrl = await _uploadImageToFirebase(user.uid);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': _name,
      'bio': _bio,
      'imageUrl': newImageUrl,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.center, // Center the icon
                        children: [
                          ClipOval(
                            child: Container(
                              width: 100, // Diameter of the circle
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : _imageUrl != null
                                          ? NetworkImage(_imageUrl!) as ImageProvider
                                          : const AssetImage('assets/profile_pic.png'),
                                  fit: BoxFit.contain, // Ensures the image fits inside the circle
                                ),
                              ),
                            ),
                          ),
                          if (_selectedImage == null) // Show the icon only if no image is selected
                            const Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: Color.fromARGB(255, 255, 255, 255), // Adjust the color as needed
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      onSaved: (value) => _name = value,
                      validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: _bio,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      onSaved: (value) => _bio = value,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
