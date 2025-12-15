import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'admin_splash_screen.dart';
import 'package:appwrite/appwrite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize AppWrite Client
  final client = Client()
      .setEndpoint('https://fra.cloud.appwrite.io/v1')
      .setProject('68f2a01f00207f73a4d3');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mahek Admin',
      theme: ThemeData(
        primaryColor: const Color(0xFFF96D0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF96D0A),
          primary: const Color(0xFFF96D0A),
        ),
        useMaterial3: true,
      ),
      home: const AdminSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}