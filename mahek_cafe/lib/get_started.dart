// file: lib/get_started.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ChooseOption.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});

  // --- Consistent Color Definitions for Mahek Food Delivery ---
  // Reusing the primary color defined in the Onboarding (kPrimaryColor: 0xFFF96D0A)
  final Color primaryOrange = const Color(0xFFF96D0A); // Vibrant Orange/Red (Main App Color)
  final Color darkBgColor = const Color(0xFF212121); // Near Black for text contrast
  final Color lightBgColor = const Color(0xFFFFFFFF); // Pure white

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // Placeholder for a high-quality food delivery image
                // Make sure to replace 'food_delivery_bg.jpg' with your actual asset name.
                image: AssetImage('assets/images/onboarding_4.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay for better text readability and themed depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  darkBgColor.withOpacity(0.8), // Themed dark color at the bottom for contrast
                ],
              ),
            ),
          ),
          // Text and button content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Headline
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Delicious Food\nDelivered to Your ',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: 'DOOR',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: primaryOrange, // Themed accent color
                          ),
                        ),
                        TextSpan(
                          text: '!',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'Welcome to Mahek Food Delivery! Your favorite meals are just a few taps away. Fast, fresh, and reliable service.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // "Get Started" button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to ChooseOption page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChooseOption(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange, // Themed accent color
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: primaryOrange.withOpacity(0.6),
                      ),
                      child: Text(
                        'FIND MY MEAL',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}