import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'location_details.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: const Center(
          child: Text(
            'Please log in to view your favorites.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('favorites')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading favorites.'));
          }

          final favoriteDocs = snapshot.data?.docs ?? [];

          if (favoriteDocs.isEmpty) {
            return const Center(
              child: Text('No favorites added yet.'),
            );
          }

          return ListView.builder(
            itemCount: favoriteDocs.length,
            itemBuilder: (context, index) {
              final favoriteData =
                  favoriteDocs[index].data() as Map<String, dynamic>;
              final locationId = favoriteDocs[index].id;

              
              final name = favoriteData['name'] ?? 'Unknown Name';
              final description = favoriteData['description'] ?? 'No description available.';
              final imageURL = favoriteData['imageURL'] ??
                  'https://via.placeholder.com/150'; // Placeholder image
              final movieId = favoriteData['movieId'] ?? 'Unknown Movie ID';
              final phone = favoriteData['phone'] ?? 'No Phone Number';
              final website = favoriteData['website']?? 'No Website';
              final address = favoriteData['address']?? 'No Address';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Image.network(
                    imageURL,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(name),
                  //subtitle: Text(description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationDetailsScreen(
                                locationData: {
                                  'name': name,
                                  'description': description,
                                  'imageURL': imageURL,
                                  'movieId': movieId,
                                  'phone':phone,
                                  'website':website,
                                  'address':address,
                                },
                                movieId: movieId,
                                locationId: locationId,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 75, 178, 202),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black),
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser.uid)
                                .collection('favorites')
                                .doc(locationId)
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from favorites.'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Failed to remove: ${e.toString()}'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
