import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'HomePage.dart';
import 'LanguageSelectionScreen.dart';
import 'l10n/app_localizations.dart';
import 'my_files/my_values.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static _MyAppState? instance;

  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() {
    final state = _MyAppState();
    MyApp.instance = state;
    return state;
  }

  static void setLocale(BuildContext context, Locale newLocale) {
    instance?.updateLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void updateLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gear Go',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  String _statusMessage = "Initializing...";
  String _currentVersion = MyValues.version;
  bool _updateAvailable = false;
  String _latestVersion = "";
  Map<String, dynamic>? _updateData;

  late final AnimationController _lottieController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start animations
    _lottieController.forward();

    // Check for updates first
    await _checkForUpdates();

    // If update is available, show update dialog and wait for user action
    if (_updateAvailable && _updateData != null) {
      _showUpdateDialog();
      return; // Don't proceed to navigation until user acts
    }

    // If no update needed, proceed with normal flow
    _proceedToApp();
  }

  Future<void> _checkForUpdates() async {
    try {
      QuerySnapshot versionSnapshot = await FirebaseFirestore.instance
          .collection('VersionUpdate')
          .limit(1)
          .get();

      if (versionSnapshot.docs.isNotEmpty) {
        _updateData = versionSnapshot.docs.first.data() as Map<String, dynamic>;
        _latestVersion = (_updateData?['version'] ?? 2.1).toString();

        bool isUpdateAvailable = _isUpdateAvailable(_currentVersion, _latestVersion);

        if (mounted) {
          setState(() {
            _updateAvailable = isUpdateAvailable;
          });
        }
      }
    } catch (e) {
      print("Error checking for update: $e");
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    List<String> currentParts = current.split('.');
    List<String> latestParts = latest.split('.');

    for (int i = 0; i < latestParts.length; i++) {
      int currentNum = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      int latestNum = int.tryParse(latestParts[i]) ?? 0;

      if (latestNum > currentNum) return true;
      if (latestNum < currentNum) return false;
    }
    return false;
  }

  void _showUpdateDialog() {
    String updateTitle = _updateData?['title'] ?? 'New Update Available';
    String updateDescription = _updateData?['description'] ?? 'A new version is available for download.';
    String updateDetails = _updateData?['update_details'] ?? '';
    String updateLink = _updateData?['update_link'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Icon(Icons.system_update, color: Colors.blue[700], size: 50),
              const SizedBox(height: 10),
              Text(
                updateTitle,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  updateDescription,
                  style: GoogleFonts.poppins(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    Text('v$_currentVersion', style: GoogleFonts.poppins(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Latest:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    Text('v$_latestVersion', style: GoogleFonts.poppins(color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedToApp(); // User chooses "Later"
              },
              child: Text('Later', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchUpdateLink(updateLink);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: Text('Update Now', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUpdateLink(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print("Error launching URL: $e");
    }
  }

  void _proceedToApp() async {
    if (mounted) {
      setState(() {
        _statusMessage = "Checking authentication...";
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (mounted) {
      setState(() {
        _statusMessage = currentUser != null ? "Welcome back!" : "Getting started...";
      });
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => currentUser != null ? const HomePage() : const LanguageSelectionScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Lottie.asset(
                  'assets/lottie/car.json',
                  controller: _lottieController,
                  onLoaded: (composition) {
                    _lottieController
                      ..duration = composition.duration
                      ..forward();
                  },
                  width: 200,
                  height: 200,
                ),
              ),

              const SizedBox(height: 30),

              // App title with fade animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Gear Go',
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Journey Starts Here',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Status and loading
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_updateAvailable)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.update, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Update Available',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Version info at bottom
              Positioned(
                bottom: 20,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Version $_currentVersion',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}