import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _phone;
  String? _profilePictureUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _name = data?['name'];
            _phone = data?['phone'];
            _profilePictureUrl = data?['profilePicture'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': _name,
          'phone': _phone,
          'profilePicture': _profilePictureUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      print('Error updating user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _auth.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      } catch (e) {
        print('Error sending password reset email: $e');
      }
    }
  }

  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          if (kIsWeb) {
            final Uint8List fileBytes = await pickedFile.readAsBytes();
            final storageRef = _storage
                .ref()
                .child('profilePicture')
                .child('${user.uid}.jpg');

            final uploadTask = storageRef.putData(fileBytes);
            final snapshot = await uploadTask.whenComplete(() {});
            final profilePictureUrl = await snapshot.ref.getDownloadURL();

            setState(() {
              _profilePictureUrl = profilePictureUrl;
            });

            await _firestore
                .collection('users')
                .doc(user.uid)
                .update({'profilePicture': profilePictureUrl});

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated!')),
            );
          } else {
            final file = File(pickedFile.path);
            final storageRef = _storage
                .ref()
                .child('profilePicture')
                .child('${user.uid}.jpg');

            final uploadTask = storageRef.putFile(file);
            final snapshot = await uploadTask.whenComplete(() {});
            final profilePictureUrl = await snapshot.ref.getDownloadURL();

            setState(() {
              _profilePictureUrl = profilePictureUrl;
            });

            await _firestore
                .collection('users')
                .doc(user.uid)
                .update({'profilePicture': profilePictureUrl});

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated!')),
            );
          }
        }
      } catch (e) {
        print('Error uploading profile picture: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile picture: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 239, 233, 238), Color.fromARGB(255, 250, 244, 254)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickProfilePicture,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profilePictureUrl != null
                            ? NetworkImage(_profilePictureUrl!)
                            : null,
                        child: _profilePictureUrl == null
                            ? const Icon(Icons.camera_alt, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _name ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    Text(
                      _phone ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(179, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            ListTile(
                              title: const Text('Save Changes'),
                              onTap: _updateUserData,
                            ),
                            ListTile(
                              title: const Text('Change Password'),
                              onTap: _changePassword,
                            ),
                            const ListTile(
                              title: Text('Wallet'),
                              trailing: Icon(Icons.arrow_forward_ios),
                            ),
                            const ListTile(
                              title: Text('Settings'),
                              trailing: Icon(Icons.arrow_forward_ios),
                            ),
                            const ListTile(
                              title: Text('Help'),
                              trailing: Icon(Icons.arrow_forward_ios),
                            ),
                          ],
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
