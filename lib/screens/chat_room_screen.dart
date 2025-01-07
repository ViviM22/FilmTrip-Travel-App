import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';



class ChatRoomScreen extends StatefulWidget {
  final String chatId;

  const ChatRoomScreen({super.key, required this.chatId});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  // Function to send a message
  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    if (user != null && _messageController.text.trim().isNotEmpty) {
      await _firestore
          .collection('messages')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  // Function to pick an image
Future<XFile?> _pickImage() async {
  final ImagePicker _picker = ImagePicker();
  return await _picker.pickImage(source: ImageSource.gallery);
}

// Function to upload an image to Firebase Storage
Future<String?> _uploadImage(XFile image) async {
  try {
    final storageRef = FirebaseStorage.instance.ref();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final imageRef = storageRef.child('chat_images/$fileName');

    if (kIsWeb) {
      // For web, upload image bytes
      final imageBytes = await image.readAsBytes();
      await imageRef.putData(imageBytes);
    } else {
      // For mobile, upload the file directly
      final file = File(image.path);
      await imageRef.putFile(file);
    }

    // Generate the correct download URL
    return await imageRef.getDownloadURL();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error uploading image: $e')),
    );
    return null;
  }
}

  // Function to send an image
  Future<void> _sendImage() async {
    final image = await _pickImage();
    if (image != null) {
      final imageUrl = await _uploadImage(image);
      if (imageUrl != null) {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore
              .collection('messages')
              .doc(widget.chatId)
              .collection('messages')
              .add({
            'senderId': user.uid,
            'imageUrl': imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Room')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data() as Map<String, dynamic>?; // Cast to Map<String, dynamic>
                    final isImage = data != null && data.containsKey('imageUrl');
                    final isCurrentUser =
                        data?['senderId'] == _auth.currentUser?.uid;

                    final timestamp = data?['timestamp'] as Timestamp?;
                    final formattedTime = timestamp != null
                        ? DateFormat('hh:mm a').format(timestamp.toDate())
                        : '';

                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.blue[100]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(10),
                            topRight: const Radius.circular(10),
                            bottomLeft: isCurrentUser
                                ? const Radius.circular(10)
                                : const Radius.circular(0),
                            bottomRight: isCurrentUser
                                ? const Radius.circular(0)
                                : const Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            isImage
                                ? Image.network(
                                    data['imageUrl'],
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                : Text(
                                    data!['message'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                            const SizedBox(height: 5),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
