import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  String userEmail = '';
  String profilePic = 'assets/profile.png';
  String dob = '';
  String address = 'Add Address';
  String phone = 'Add Phone';

  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userData =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get()
              as DocumentSnapshot<Map<String, dynamic>>;

      setState(() {
        username = userData.data()?['name'] ?? 'User';
        userEmail = userData.data()?['email'] ?? user.email ?? 'user@example.com';
        profilePic = userData.data()?['profilePic'] ?? 'assets/profile.png';
        dob = userData.data()?['dob'] ?? 'Not Available';
        address = userData.data()?['address'] ?? 'Add Address';
        phone = userData.data()?['phone'] ?? 'Add Phone';
      });
    }
  }

  Future<void> _uploadProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String fileName = 'profile_pics/${user.uid}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profilePic': downloadUrl,
        });

        setState(() {
          profilePic = downloadUrl;
        });
      }
    }
  }

  Future<void> _updateAdditionalDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'address': addressController.text.trim(),
        'phone': phoneController.text.trim(),
      });
      setState(() {
        address = addressController.text.trim();
        phone = phoneController.text.trim();
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details Updated')));
    }
  }

  void _showEditDialog() {
    addressController.text = address;
    phoneController.text = phone;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _updateAdditionalDetails, child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.raleway(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(onPressed: _showEditDialog, icon: const Icon(Icons.edit)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: profilePic.contains('http')
                        ? NetworkImage(profilePic)
                        : AssetImage(profilePic) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadProfilePic,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.black,
                        child: const Icon(Icons.edit, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoCard("Name", username),
            _buildInfoCard("Email", userEmail),
            _buildInfoCard("Date of Birth", dob),
            _buildInfoCard("Address", address),
            _buildInfoCard("Phone Number", phone),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white, // ✅ Lighter tile
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: GoogleFonts.raleway(color: Colors.grey[700], fontSize: 16),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.raleway(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
