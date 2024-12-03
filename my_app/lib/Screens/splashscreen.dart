import 'package:flutter/material.dart';
import 'onboarding1.dart'; // Import your onboarding screen


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to onboarding screen after 7 seconds
    Future.delayed(const Duration(seconds: 7), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const OnboardingScreen1()), // Replace Onboarding1 with the actual screen widget
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF4FF), // Light blue background color
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 50,
              right: 20,
              child: Image.asset(
                'assets/images/pills.png',
                width: 80,
                height: 80,
              ),
            ),
            Positioned(
              bottom: 30,
              left: -29,
              child: Image.asset(
                'assets/images/stethoscope.png',
                width: 120,
                height: 120,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/heart.png',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Healthcare',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A3D66),
                  ),
                ),
                const Text(
                  'Medical app',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2A3D66),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: -6,
              right: 0,
              child: Image.asset(
                'assets/images/pill_left.png',
                width: 50,
                height: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
