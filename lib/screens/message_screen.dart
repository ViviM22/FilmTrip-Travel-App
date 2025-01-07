import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _searchResult;

  Future<void> _searchUser() async {
    if (_searchController.text.isEmpty) return;

    final query = await _firestore
        .collection('users')
        .where('name', isEqualTo: _searchController.text)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() {
        _searchResult = query.docs.first.data();
        _searchResult!['id'] = query.docs.first.id; // Add the user ID to the result
      });
    } else {
      setState(() {
        _searchResult = null;
      });
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(userId).update({
        'friendRequests': FieldValue.arrayUnion([currentUser.uid]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!')),
      );
    }
  }

  Future<void> _acceptFriendRequest(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'friends': FieldValue.arrayUnion([userId]),
        'friendRequests': FieldValue.arrayRemove([userId]),
      });
      await _firestore.collection('users').doc(userId).update({
        'friends': FieldValue.arrayUnion([currentUser.uid]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted!')),
      );
    }
  }

  Future<void> _startPrivateChat(String friendId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final chatId = currentUser.uid.hashCode <= friendId.hashCode
          ? '${currentUser.uid}_$friendId'
          : '${friendId}_${currentUser.uid}';

      final chatRef = await _firestore.collection('messages').doc(chatId).get();
      if (!chatRef.exists) {
        await _firestore.collection('messages').doc(chatId).set({
          'participants': [currentUser.uid, friendId],
        });
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(chatId: chatId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatroom',)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search for Friends',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _searchUser,
            child: const Text('Search'),
          ),
          if (_searchResult != null) ...[
            Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(_searchResult!['name']),
                subtitle: Text('Email: ${_searchResult!['email']}'),
                trailing: ElevatedButton(
                  onPressed: () => _sendFriendRequest(_searchResult!['id']),
                  child: const Text('Send Friend Request'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('No data available'));
                }

                final userData = snapshot.data!;
                final friendRequests = userData['friendRequests'] ?? [];
                final friends = userData['friends'] ?? [];

                return Column(
                  children: [
                    if (friendRequests.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: friendRequests.length,
                          itemBuilder: (context, index) {
                            final requestId = friendRequests[index];
                            return FutureBuilder<DocumentSnapshot>(
                              future: _firestore.collection('users').doc(requestId).get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final friendData = snapshot.data?.data() as Map<String, dynamic>?;
                                return ListTile(
                                  leading: CircleAvatar(
                                  backgroundImage: NetworkImage(friendData?['profilePicture'] ?? ''),
                                  child: friendData?['profilePicture'] == null
                                  ? const Icon(Icons.person)
                                 : null,
                                 ),
                                  title: Text(friendData?['name'] ?? 'Unknown'),
                                  subtitle: Text(friendData?['email'] ?? ''),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check),
                                        onPressed: () =>
                                            _acceptFriendRequest(requestId),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          _firestore
                                              .collection('users')
                                              .doc(_auth.currentUser!.uid)
                                              .update({
                                            'friendRequests': FieldValue
                                                .arrayRemove([requestId]),
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friendId = friends[index];
                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('users').doc(friendId).get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final friendData = snapshot.data?.data() as Map<String, dynamic>?;
                              return ListTile(
                                leading: CircleAvatar(
                                backgroundImage: NetworkImage(friendData?['profilePicture'] ?? ''),
                                child: friendData?['profilePicture'] == null
                                  ? const Icon(Icons.person)
                                   : null,
                                 ),
                                title: Text(friendData?['name'] ?? 'Unknown'),
                                subtitle: Text(friendData?['email'] ?? ''),
                                onTap: () => _startPrivateChat(friendId),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
