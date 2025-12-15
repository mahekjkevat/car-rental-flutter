// file: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'firebase_options.dart'; // Make sure this file exists
import 'get_started.dart'; // Import the GetStarted page
import 'home_page.dart'; // Import the HomePage
import 'splash_screen.dart'; // Import the new Splash Screen


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and check connection
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase Connected Successfully');
    Fluttertoast.showToast(
      msg: "Firebase Connected Successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  } catch (e) {
    print('Firebase Connection Failed: $e');
    Fluttertoast.showToast(
      msg: "Firebase Connection Failed",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mahek Food Delivery', // Set App Title
      home: const SplashScreen(), // Start with the Splash Screen
    );
  }
}

class AuthCheck extends StatelessWidget {
  AuthCheck({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(), // Listen to authentication state changes
      builder: (context, snapshot) {
        // If connection is waiting, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, go to HomePage
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }

        // If user is not logged in, go to GetStarted (original logic retained)
        return const GetStarted();
      },
    );
  }
}