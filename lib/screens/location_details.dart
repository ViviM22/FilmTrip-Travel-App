import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class LocationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> locationData;
  final String movieId;
  final String locationId;

  const LocationDetailsScreen({
    Key? key,
    required this.locationData,
    required this.movieId,
    required this.locationId,
  }) : super(key: key);

  @override
  _LocationDetailsScreenState createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  double _rating = 5.0;

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _addFeedback() async {
    if (_feedbackController.text.isEmpty) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add feedback.')),
      );
      return;
    }

    final feedbackData = {
      'userId': _currentUser!.uid,
      'username': _currentUser!.email ?? 'Anonymous',
      'rating': _rating,
      'comment': _feedbackController.text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('movies')
        .doc(widget.movieId)
        .collection('locations')
        .doc(widget.locationId)
        .collection('feedbacks')
        .add(feedbackData);

    _feedbackController.clear();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback added successfully!')),
    );
  }

  Future<void> _addToFavorites() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add favorites.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('favorites')
        .doc(widget.locationId)
        .set(widget.locationData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to favorites!')),
    );
  }

   Future<void> _bookNow() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.')),
      );
      return;
    }

    DateTime? fromDate;
    DateTime? toDate;
    bool paymentConfirmed = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Book Now'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          fromDate = picked;
                        });
                      }
                    },
                    child: Text(
                      fromDate == null
                          ? 'Select From Date'
                          : 'From: ${DateFormat.yMMMd().format(fromDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          toDate = picked;
                        });
                      }
                    },
                    child: Text(
                      toDate == null
                          ? 'Select To Date'
                          : 'To: ${DateFormat.yMMMd().format(toDate!)}',
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('I confirm I have made the payment'),
                    value: paymentConfirmed,
                    onChanged: (value) {
                      setState(() {
                        paymentConfirmed = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (fromDate != null && toDate != null && paymentConfirmed) {
                      Navigator.of(context).pop(true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please complete all fields.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (fromDate != null && toDate != null && paymentConfirmed) {
      final bookingData = {
        'locationId': widget.locationId,
        'movieId': widget.movieId,
        'locationName': widget.locationData['name'],
        'fromDate': fromDate,
        'toDate': toDate,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('bookings')
          .add(bookingData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!')),
      );
    }
  }

  Future<void> _launchWebsite(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch website.')),
      );
    }
  }

  Future<void> _callPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not make the call.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.locationData['name']),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.locationData['imageURL'],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10),
            Text(
              widget.locationData['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
RichText(
  text: TextSpan(
    children: [
      const TextSpan(
        text: 'Description: ',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      TextSpan(
        text: widget.locationData['description'],
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
    ],
  ),
),
const SizedBox(height: 10),
RichText(
  text: TextSpan(
    children: [
      const TextSpan(
        text: 'Address: ',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      TextSpan(
        text: widget.locationData['address'],
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
    ],
  ),
),
const SizedBox(height: 10),
GestureDetector(
  onTap: () => _callPhone(widget.locationData['phone']),
  child: RichText(
    text: TextSpan(
      children: [
        const TextSpan(
          text: 'Phone: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        TextSpan(
          text: widget.locationData['phone'],
          style: const TextStyle(fontSize: 16, color: Colors.blue),
        ),
      ],
    ),
  ),
),
const SizedBox(height: 10),
if (widget.locationData['website'] != null)
  GestureDetector(
    onTap: () => _launchWebsite(widget.locationData['website']),
    child: RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Website: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          TextSpan(
            text: widget.locationData['website'],
            style: const TextStyle(fontSize: 16, color: Colors.blue),
          ),
        ],
      ),
    ),
  ),
        const SizedBox(height: 20),
Center(
  child: Row(
    mainAxisSize: MainAxisSize.min, // Ensures the row takes minimal width
    children: [
      ElevatedButton(
        onPressed: _bookNow,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 89, 35, 35),
        ),
        child: const Text(
          'Book Now',
          style: TextStyle(color: Colors.white),
        ),
      ),
      const SizedBox(width: 10),
      IconButton(
        onPressed: _addToFavorites,
        icon: const Icon(Icons.favorite, color: Colors.red),
      ),
    ],
  ),
),

            const Divider(height: 30),
            const Text(
              'Feedbacks:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('movies')
                  .doc(widget.movieId)
                  .collection('locations')
                  .doc(widget.locationId)
                  .collection('feedbacks')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading feedbacks.');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final feedbacks = snapshot.data?.docs ?? [];
                if (feedbacks.isEmpty) {
                  return const Text('No feedbacks available.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final feedback = feedbacks[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(feedback['username'] ?? 'Anonymous'),
                      subtitle: Text(feedback['comment'] ?? ''),
                      trailing: Text('${feedback['rating'] ?? 0}/5'),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Feedback:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Your feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Rating:'),
                const SizedBox(width: 10),
                DropdownButton<double>(
                  value: _rating,
                  items: [1, 2, 3, 4, 5]
                      .map((e) => DropdownMenuItem(value: e.toDouble(), child: Text('$e')))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _rating = value ?? 5.0;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Submit Feedback',
              style: TextStyle(color: Colors.white), 
            ),
            )
          ],
        ),
      ),
    );
  }
}
