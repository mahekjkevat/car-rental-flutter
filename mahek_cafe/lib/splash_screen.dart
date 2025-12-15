import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'onboarding_screen.dart';
import 'home_page.dart'; // Placeholder: Assume you have a HomePage widget

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // Define the vibrant primary color
  final Color primaryAppColor = const Color(0xFFF96D0A); // Deep Orange

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Logo scales up from half size
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    // Elements fade in
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    // Start the logo animation
    _animationController.forward();

    // Navigate after animation completes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAuthenticationAndNavigate();
      }
    });
  }

  // Function to check auth state and navigate
  void _checkAuthenticationAndNavigate() {
    final user = FirebaseAuth.instance.currentUser;
    Widget nextScreen;

    if (user != null) {
      // User is logged in, go to the Home Page
      nextScreen = const HomePage();
      // print('User already logged in: ${user.uid}. Navigating to Home.'); // Commented out print for cleaner production code
    } else {
      // User is not logged in, show Onboarding
      nextScreen = const OnboardingScreen();
      // print('User not logged in. Navigating to Onboarding.'); // Commented out print for cleaner production code
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => nextScreen,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryAppColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // --- App Logo Image Container (Replaced Icon with Circular Image) ---
                    Container(
                      width: 120, // Badge size
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          // Enhanced soft, lifted shadow for an attractive look
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: const Offset(0, 15),
                            blurRadius: 35,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        // Clip the image to a perfect circle
                        child: Image.asset(
                          'assets/images/app_icon.jpeg', // Path provided by the user
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          // Fallback in case the asset isn't found
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: primaryAppColor.withOpacity(0.9),
                            child: const Center(
                              child: Text(
                                'App Logo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30), // Increased spacing
                    // App Name Text
                    Text(
                      'Mahek Food Delivery',
                      style: GoogleFonts.poppins(
                        fontSize: 36, // Slightly larger font
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2.0, // Increased letter spacing for impact
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tagline
                    Text(
                      'Taste the difference!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Loading Indicator
                    const SizedBox(
                      width: 35, // Slightly larger indicator
                      height: 35,
                      child: CircularProgressIndicator(
                        strokeWidth: 4, // Thicker stroke
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
