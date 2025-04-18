import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:newapp/main.dart';
import 'package:image/image.dart' as img;




class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _pickedImage;
  bool _isSaving = false;

Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile == null) return;

  final originalFile = File(pickedFile.path);
  final imageBytes = await originalFile.readAsBytes();
  final image = img.decodeImage(imageBytes);

  if (image == null) return;

  // Resize if needed (optional)
  final resized = img.copyResize(image, width: 512); // limit to 512px width

  // Encode the resized image to JPEG with lower quality
  final compressedBytes = img.encodeJpg(resized, quality: 60);

  final compressedFile = File('${pickedFile.path}_compressed.jpg')
    ..writeAsBytesSync(compressedBytes);

  setState(() {
    _pickedImage = compressedFile;
  });
}


  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _nameController.text.trim().isEmpty || _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Upload image to Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pics/${user.uid}');
    await storageRef.putFile(_pickedImage!);
    final imageUrl = await storageRef.getDownloadURL();

    // Save user info to Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _nameController.text.trim(),
      'bio': "Hey there! I'm new here.",
      'imageUrl': imageUrl,
      'uid': user.uid,
      'email': user.email,
    });

    setState(() {
      _isSaving = false;
    });

  Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const MainScreen()),
  (route) => false,
);
 // go to main screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _pickedImage != null ? FileImage(_pickedImage!) : null,
                child: _pickedImage == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Enter your name"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text("Save and Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
