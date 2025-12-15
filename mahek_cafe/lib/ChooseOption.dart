import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_in.dart'; // Import SignIn page
import 'sign_up.dart'; // Import SignUp page

class ChooseOption extends StatelessWidget {
  const ChooseOption({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the primary orange color for consistency
    final Color primaryOrange = Colors.orange[800]!;
    final Color lightOrange = Colors.orange[300]!;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/onboarding_1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2), // Lighter top
                  Colors.black.withOpacity(0.8), // Darker bottom for text contrast
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0), // Increased padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Coffee shop information
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Welcome to ',
                          style: GoogleFonts.poppins(
                            fontSize: 34, // Increased size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            // Added text shadow
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black.withOpacity(0.8),
                                offset: const Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'Mahek Cafe',
                          style: GoogleFonts.poppins(
                            fontSize: 34, // Increased size
                            fontWeight: FontWeight.w900, // Extra bold for impact
                            color: lightOrange,
                            // Added text shadow
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black.withOpacity(0.8),
                                offset: const Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'At Mahek Cafe, we craft the finest coffee with love and care. '
                        'Join us for a warm, cozy experience with every sip. '
                        'Choose your journey below!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                      // Added text shadow
                      shadows: [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48), // Increased space before buttons
                  // Row with Sign In and Sign Up buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Sign In button (Solid primary button)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to SignIn page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignIn(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              padding: const EdgeInsets.symmetric(vertical: 18), // Thicker padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50), // Fully rounded corners
                              ),
                            ),
                            child: Text(
                              'SIGN IN',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Sign Up button (Outline/Ghost button)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to SignUp page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUp(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, // Transparent background
                              elevation: 0, // No shadow
                              padding: const EdgeInsets.symmetric(vertical: 18), // Thicker padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50), // Fully rounded corners
                                side: BorderSide(color: primaryOrange, width: 2), // Orange border
                              ),
                            ),
                            child: Text(
                              'SIGN UP',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: lightOrange, // Orange text
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60), // Increased space at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
