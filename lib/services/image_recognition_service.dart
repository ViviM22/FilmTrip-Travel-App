import 'dart:convert';
import 'dart:typed_data'; // For Uint8List
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> performImageRecognition(dynamic image) async {
  const apiKey = 'AIzaSyAa1DvzYwl1E4R2vhIDs0TLJ8zLv9WGNJ8'; // Cloud vision API key 
  const url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

  String base64Image;

  // Check if the image is a File (for mobile/desktop) or Uint8List (for web)
  if (kIsWeb) {
    // For web, directly use the bytes from PlatformFile as Uint8List
    if (image is Uint8List) {
      base64Image = base64Encode(image);
    } else {
      throw Exception('Expected Uint8List for web image input');
    }
  } else if (image is File) {
    // For mobile/desktop, read the image as bytes
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