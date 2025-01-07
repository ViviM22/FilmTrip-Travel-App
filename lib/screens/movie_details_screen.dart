import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:testapp/screens/location_details.dart';


class MovieDetailsScreen extends StatelessWidget {
  final String movieId;

  const MovieDetailsScreen({required this.movieId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movie Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('movies').doc(movieId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading movie details.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final movieData = snapshot.data?.data() as Map<String, dynamic>?;

          if (movieData == null) {
            return const Center(child: Text('Movie not found.'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(movieData['imageURL'], fit: BoxFit.cover, height: 200, width: double.infinity),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(movieData['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Locations:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('movies')
                      .doc(movieId)
                      .collection('locations')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading locations.'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final locations = snapshot.data?.docs ?? [];
                    if (locations.isEmpty) {
                      return const Center(child: Text('No locations available.'));
                    }
                    return ListView.builder(
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final locationData = locations[index].data() as Map<String, dynamic>;

                        return ListTile(
                          leading: Image.network(locationData['imageURL'], width: 50, height: 50, fit: BoxFit.cover),
                          title: Text(locationData['name']),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocationDetailsScreen(
                                    locationData: locationData,
                                    movieId: movieId,
                                    locationId: locations[index].id,)
                                ),
                              );
                            },
                            child: const Text('View'),
                          ),
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
    );
  }
}
