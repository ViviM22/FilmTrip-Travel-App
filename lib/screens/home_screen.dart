import 'dart:convert';
import 'dart:io'; // Import for File class
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:testapp/widgets/movie_list_widget.dart';
//import 'package:testapp/services/image_recognition_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;


// Import individual screens
import 'message_screen.dart';
import 'favorites_screen.dart';
import 'trips_screen.dart';
import 'my_account_screen.dart';
import 'location_details.dart';

//API Configuration
Future<void> performImageRecognition(BuildContext context, dynamic image) async {
  const apiKey = 'AIzaSyAa1DvzYwl1E4R2vhIDs0TLJXLv9WGN8'; // API key
  const url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

  String base64Image;

  // Determine the image source (web or mobile/desktop)
  if (kIsWeb) {
    if (image is Uint8List) {
      base64Image = base64Encode(image);
    } else {
      throw Exception('Expected Uint8List for web image input');
    }
  } else if (image is File) {
    final imageBytes = await image.readAsBytes();
    base64Image = base64Encode(imageBytes);
  } else {
    throw Exception('Invalid image type');
  }

  // Prepare the request payload
  final requestPayload = {
    "requests": [
      {
        "image": {"content": base64Image},
        "features": [
          {"type": "LABEL_DETECTION", "maxResults": 10}
        ]
      }
    ]
  };

  try {
    // Send the post request to Cloud Vision API with the payload
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestPayload),
    );

    //If the API call is successful
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final labels = jsonResponse['responses'][0]['labelAnnotations'];
      List<String> detectedLabels = labels
          .where((label) => label['description'] is String) // Ensure it's a String
          .map<String>((label) => (label['description'] as String).toLowerCase()) // Safely cast and convert
          .toList();
      print('Detected Labels: $detectedLabels');

      // Query Firestore with detected labels
      List<Map<String, dynamic>> results = await searchFirestore(detectedLabels);
      if (results.isNotEmpty) {
        print("Matching Locations Found: $results");
        // Display results in the app
        showResults(context, results);
      } else {
        print("No matching locations found.");
      }
    } else {
      print("Error from Cloud Vision API: ${response.body}");
    }
  } catch (e) {
    print("Error during image recognition: $e");
  }
}

void showResults(BuildContext context, List<Map<String, dynamic>> results) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Matching Locations"),
      content: SingleChildScrollView(
        child: Column(
          children: results.map((result) {
            String movieId = "1"; 
            String locationId = "UA2yjpSILYI0J7V23egl"; 
            print("Location found: movieId=$movieId, locationId=$locationId");

            return GestureDetector(
              onTap: () async {
            
                print("Tapped on location: $movieId, $locationId");

                if (movieId.isNotEmpty && locationId.isNotEmpty) {
                  
                  DocumentSnapshot locationSnapshot = await FirebaseFirestore.instance
                      .collection('movies')
                      .doc(movieId)
                      .collection('locations')
                      .doc(locationId)
                      .get();

                  if (locationSnapshot.exists) {
                    var locationData = locationSnapshot.data() as Map<String, dynamic>;

                    QuerySnapshot feedbacksSnapshot = await FirebaseFirestore.instance
                        .collection('movies')
                        .doc(movieId)
                        .collection('locations')
                        .doc(locationId)
                        .collection('feedbacks')
                        .get();

                    var feedbacks = feedbacksSnapshot.docs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .toList();

                    locationData['feedbacks'] = feedbacks;

                    // If passed Navigate to LocationDetailsScreen
                    Navigator.pop(context); // Close the dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationDetailsScreen(
                          locationData: locationData,
                          movieId: movieId,
                          locationId: locationId,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Location data not found")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid location")),
                  );
                }
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        result['imageURL'] ?? '', // Fallback to empty string if null
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result['locationName'] ?? 'Unknown Location', // Fallback to 'Unknown Location' if null
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            result['description'] ?? 'No description available', // Fallback to 'No description available' if null
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close"),
        ),
      ],
    ),
  );
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Default selected page is Home.

  final List<Widget> _pages = [
    const MessageScreen(),     // Chatroom Page
    const FavoritesScreen(),   // Favorites Page
    const HomeContent(),       // Home Page
    const TripsScreen(),       // Trips Page
    const MyAccountScreen(),   // My Account Page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Chatroom'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favourites'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flight_takeoff), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'My Account'),
        ],
      ),
    );
  }
}

// Main Home Content Widget
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Title and Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'FilmTrip',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Kaushan Script',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: () async {
                            // Use File Picker to select an image
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              PlatformFile platformFile = result.files.first;

                              // Check if it's running on the web
                              if (kIsWeb) {
                                // Get bytes from the file
                                Uint8List bytes = platformFile.bytes!;
                                // Convert bytes to base64
                                String base64Image = base64Encode(bytes);

                                // Call the image recognition function
                                await performImageRecognitionFromBytes(context,base64Image);
                              } else {
                                // For mobile/desktop, use the path
                                File file = File(platformFile.path!);
                                await performImageRecognition(context,file);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Recent Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Recent',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            const MovieListWidget(collectionName: 'movies'),
            const SizedBox(height: 20),
            // Recommendations Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Recommendations',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            const MovieListWidget(collectionName: 'recomovies'),
            const SizedBox(height: 30),
            // Most popular Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Most Popular',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            const MovieListWidget(collectionName: 'popular'),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> performImageRecognitionFromBytes(BuildContext context, String base64Image) async {
  const apiKey = 'AIzaSyAa1DvzYwl1E4R2vhIDs0TLJXLv9WGN8'; // Replace with your actual API key
  const url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

  // Prepare the request payload
  final requestPayload = {
    "requests": [
      {
        "image": {"content": base64Image},
        "features": [
          {"type": "LABEL_DETECTION", "maxResults": 10}
        ]
      }
    ]
  };

  try {
    // Send the request to Cloud Vision API
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestPayload),
    );

        if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final labels = jsonResponse['responses'][0]['labelAnnotations'];
      List<String> detectedLabels = labels
          .where((label) => label['description'] is String) // Ensure it's a String
          .map<String>((label) => (label['description'] as String).toLowerCase()) // Safely cast and convert
          .toList();
      print('Detected Labels: $detectedLabels');

      // Query Firestore with detected labels
      List<Map<String, dynamic>> results = await searchFirestore(detectedLabels);
      if (results.isNotEmpty) {
        print("Matching Locations Found: $results");
        // Display results in the app
        showResults(context, results);
      } else {
        // Show a dialog if no matching locations are found
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("No Matching Locations"),
        content: Text("We couldn't find any matching locations based on the detected labels."),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text("OK"),
          ),
        ],
      );
    },
  );
      }
    } else {
      print("Error from Cloud Vision API: ${response.body}");
    }
  } catch (e) {
    print("Error during image recognition: $e");
  }
}
}
Future<List<Map<String, dynamic>>> searchFirestore(List<String> detectedLabels) async {
  List<Map<String, dynamic>> results = [];

  final moviesCollection = FirebaseFirestore.instance.collection('movies');
  final moviesSnapshot = await moviesCollection.get();

  for (var movieDoc in moviesSnapshot.docs) {
    final locationsSnapshot = await movieDoc.reference.collection('locations').get();

    for (var locationDoc in locationsSnapshot.docs) {
      List<dynamic> locationLabels = locationDoc['labels'] ?? [];
      
      // Check if any detected label matches the Firestore labels
      if (detectedLabels.any((label) => locationLabels.contains(label))) {
        results.add({
          'movieTitle': movieDoc['title'],
          'locationName': locationDoc['name'],
          'description': locationDoc['description'],
          'imageURL': locationDoc['imageURL'],
        });
      }
    }
  }

  return results;
}