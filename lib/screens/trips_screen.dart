import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  _TripsScreenState createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final TextEditingController _tripNameController = TextEditingController();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _createTrip(String tripName) async {
    if (_currentUser == null || tripName.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('trips')
        .add({'name': tripName, 'locations': []});

    _tripNameController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip created successfully!')),
    );
    setState(() {});
  }

  Future<void> _moveLocationToTrip(String tripId, Map<String, dynamic> locationData) async {
    if (_currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('trips')
        .doc(tripId)
        .update({
      'locations': FieldValue.arrayUnion([locationData]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location added to trip!')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Trip creation section
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tripNameController,
                      decoration: const InputDecoration(
                        labelText: 'Trip Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _createTrip(_tripNameController.text),
                    child: const Text('Create Trip'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Display Trips Section
              const Text('Your Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser?.uid)
                    .collection('trips')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No trips found.'));
                  }

                  final trips = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index].data() as Map<String, dynamic>;
                      final tripName = trip['name'] ?? 'Unnamed Trip';
                      //final tripId = trips[index].id;
                      final locations = trip['locations'] ?? [];

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ExpansionTile(
                          title: Text(tripName),
                          children: [
                            ...locations.map<Widget>((location) {
                              final locationName = location['locationName'] ?? 'Unknown Location';
                              return ListTile(
                                title: Text(locationName),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Display Bookings Section
              const Text('Your Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser?.uid)
                    .collection('bookings')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> bookingSnapshot) {
                  if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!bookingSnapshot.hasData || bookingSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No bookings available.'));
                  }

                  final bookings = bookingSnapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index].data() as Map<String, dynamic>;
                      final locationName = booking['locationName'] ?? 'Unknown Location';
                      final locationData = {
                        'locationName': locationName,
                        'locationId': booking['locationId'],
                      };

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(locationName),
                          trailing: ElevatedButton(
                            onPressed: () => _moveLocationToTrip(booking['tripId'], locationData),
                            child: const Text('Move to Trip'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
