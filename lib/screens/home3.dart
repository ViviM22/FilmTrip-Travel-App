import 'package:flutter/material.dart';
import 'package:testapp/screens/login.dart'; // Import the Login page

class Home3 extends StatelessWidget {
  const Home3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FilmTrip text above the image
            const Text(
              'FilmTrip',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'Kaushan Script', // Or 'Dekko' if desired
              ),
            ),
            const SizedBox(height: 10),
            // Image
            Image.asset('assets/travel.png'), // Image from assets folder
            const SizedBox(height: 10),
            // Log in and sign-up messages
            const Text(
              'Log in to save favorites and connect with other film fans.',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Dekko',
                color: Color.fromARGB(255, 42, 41, 41),
                height: 1.2, // Reduced line height
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Sign up to start your adventure!',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Dekko',
                color: Color.fromARGB(255, 51, 51, 51),
                height: 1.2, // Match the reduced line height
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Let's Go button
            ElevatedButton(
              onPressed: () {
                // Navigate to the Login page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Button color
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Button padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
              ),
              child: const Text(
                'Let\'s go',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white, // Text color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
