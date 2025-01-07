import 'package:flutter/material.dart';
import 'home2.dart'; // Import Home2 page

class Home1 extends StatelessWidget {
  const Home1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/globe.png'), // Image from assets folder
            const SizedBox(height: 20),
            const Text(
              'FilmTrip',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'Kaushan Script',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Start your cinematic adventure....',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Dekko',
                color: Color.fromARGB(255, 42, 41, 41),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Home2()),
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
