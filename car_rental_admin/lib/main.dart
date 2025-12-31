import 'package:car_rental_admin/home_page.dart';
import 'package:car_rental_admin/authentication/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'dart:async';
import 'firebase_messaging_service.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// Import the new toast for consistent design
import 'MahekAdminToast.dart'; // Assuming the custom toast file is named this

// Define Theme Colors
const Color _primaryColor = Colors.black;
const Color _accentColor = Colors.yellow;
const Color _textColor = Colors.white;

class AppwriteSingleton {
  static final AppwriteSingleton _instance = AppwriteSingleton._internal();
  factory AppwriteSingleton() => _instance;
  AppwriteSingleton._internal();

  late appwrite.Client client;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  // The Appwrite client setup is kept but updated to the latest practices if possible.
  final appwriteClient = appwrite.Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('67e8384a0024f79666ba');

  AppwriteSingleton._instance.client = appwriteClient;

  print('🚀 Starting app initialization...');

  // Initialize FCM (don't wait for it - let it run in background)
  FirebaseMessagingService.initialize()
      .then((_) {
    print('✅ FCM initialized');
  })
      .catchError((e) {
    print('❌ FCM initialization failed: $e');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GearGo Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _primaryColor,
        primaryColor: _accentColor,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.yellow).copyWith(secondary: _accentColor),
        // Use Poppins globally
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: _textColor,
          displayColor: _textColor,
        ),
        appBarTheme: const AppBarTheme(
          color: _primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: _accentColor),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Total duration for all animations
    );

    // 1. Logo Scale Animation (Starts small, scales up quickly)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack), // 60% of duration
      ),
    );

    // 2. Text Opacity Animation (Fades in slightly later)
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut), // Last 60% of duration
      ),
    );

    // 3. Text Slide Animation (Slides up from below)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut), // Matches opacity
      ),
    );

    // Start the animation
    _animationController.forward();

    // Navigate after the animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    // Check if user is already signed in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is signed in, go to home page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // No user signed in, go to sign-in page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (More visually appealing)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000000), // Pure Black
                    Color(0xFF101010), // Very Dark Grey
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo with Pulsating Glow
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // This is a subtle pulsating glow effect on the logo container
                    final double pulse = 1.0 + (0.05 * _animationController.value.abs()); // Subtle scale for pulse

                    return Transform.scale(
                      scale: _scaleAnimation.value * pulse,
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black, // Inner circle color
                          boxShadow: [
                            BoxShadow(
                              // Pulsating/Glow effect
                              color: _accentColor.withOpacity(0.5 * _opacityAnimation.value),
                              blurRadius: 30.0,
                              spreadRadius: 5.0,
                            ),
                            BoxShadow(
                              // Inner shadow for depth
                              color: Colors.yellow[900]!.withOpacity(0.3),
                              blurRadius: 15.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo.jpeg',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Animated Text (Slides up and Fades in)
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Text(
                      'GearGo Admin',
                      style: GoogleFonts.poppins(
                        color: _accentColor,
                        fontSize: 36, // Slightly larger font size
                        fontWeight: FontWeight.w900, // Extra Bold
                        shadows: [
                          Shadow(
                            color: Colors.yellow.withOpacity(0.8),
                            offset: const Offset(0, 0),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle/Tagline (fades in as well)
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: Text(
                    'Command Center Activated',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 80),

                // Animated Loading Indicator (fades in)
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _accentColor,
                      ),
                      strokeWidth: 5,
                      backgroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}