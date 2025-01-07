import 'package:flutter/material.dart';
import 'package:testapp/screens/home3.dart'; // Import Home3 page

class Home2 extends StatelessWidget {
  const Home2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FilmTrip text moved above the image
            const Text(
              'FilmTrip',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'Kaushan Script', // Or 'Dekko' if you want to use that font
              ),
            ),
            const SizedBox(height: 10),
            // Image
            Image.asset('assets/house.png'), // Image from assets folder
            const SizedBox(height: 20),
            // Description split into 3 lines
            const Text(
              'Find and explore movie and TV filming locations.\n',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Dekko',
                color: Color.fromARGB(255, 42, 41, 41),
              ),
              textAlign: TextAlign.center, // Center-align the text
            ),
            const SizedBox(height: 20),
            // Circular arrow button
            GestureDetector(
              onTap: () {
                // Navigate to Home3 page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Home3()),
                );
              },
              child: Container(
                width: 60, // Adjust the size of the circle
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color.fromARGB(255, 27, 27, 27), width: 2), // Circular border
                  color: Colors.white, // Background color of the circle
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 30, // Increase the size of the arrow
                  color: Colors.black, // Color of the arrow
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
