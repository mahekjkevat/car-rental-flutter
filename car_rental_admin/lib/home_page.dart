import 'dart:async';
import 'package:car_rental_admin/bottom_navigation_bar/all_cars_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'ToolsPage.dart';
import 'home_page_body.dart';
import 'bottom_navigation_bar/bookings_car_page.dart';
import 'profile_page.dart';


const Color _primaryColor = Colors.black;
const Color _accentColor = Colors.yellow;
const Color _textColor = Colors.white;
const Color _cardColor = Color(0xFF1C1C1C);
const Color _appBarColor = Color(0xFF1F1F1F);
const String _appLogoPath = 'assets/images/app_logo.jpeg';
const String _adminDocumentId = 'CARADMIN2025';


class LoadingDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                strokeWidth: 4,
              ),
              const SizedBox(height: 15),
              Text(
                'Please Wait',
                style: GoogleFonts.poppins(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  String? _currentAdminUid;
  late final List<Widget> _pages;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentAdminUid = user?.uid ?? _adminDocumentId;

          _pages = [
            HomeViewWithDynamicAppBar(adminId: _currentAdminUid!),
            const BookingsAndCarsPage(),
            const AllCarsPage(),
            const ToolsPage(),
            const ProfilePage(),
          ];
        });
      }
    });

    _currentAdminUid = FirebaseAuth.instance.currentUser?.uid ?? _adminDocumentId;
    _pages = [
      HomeViewWithDynamicAppBar(adminId: _currentAdminUid!),
      const BookingsAndCarsPage(),
      const AllCarsPage(),
      const ToolsPage(),
      const ProfilePage(),
    ];

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _cardColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentAdminUid == null) {
      return const Scaffold(
        backgroundColor: _primaryColor,
        body: Center(
          child: CircularProgressIndicator(color: _accentColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _primaryColor,

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _primaryColor,
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            _buildNavItem(icon: Icons.dashboard, label: 'Home', index: 0),
            _buildNavItem(icon: Icons.list_alt, label: 'Bookings', index: 1),
            _buildNavItem(icon: Icons.directions_car, label: 'Cars', index: 2),
            _buildNavItem(icon: Icons.build, label: 'Tools', index: 3),
            _buildNavItem(icon: Icons.person, label: 'Profile', index: 4),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: _cardColor,
          selectedItemColor: _accentColor,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
          showUnselectedLabels: true,
          elevation: 0,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final isSelected = _selectedIndex == index;

          return Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? LinearGradient(
                colors: [
                  _accentColor.withOpacity(0.8),
                  _accentColor.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isSelected ? null : Colors.black.withOpacity(0.3),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: _accentColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
                  : [],
            ),
            child: Transform.scale(
              scale: isSelected ? _scaleAnimation.value : 1.0,
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.black : Colors.grey[400],
              ),
            ),
          );
        },
      ),
      label: label,
    );
  }
}


class HomeViewWithDynamicAppBar extends StatelessWidget {
  final String adminId;

  const HomeViewWithDynamicAppBar({
    super.key,
    required this.adminId,
  });

  DocumentReference get adminDocRef => FirebaseFirestore.instance.collection('CarAdmin').doc(adminId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: adminId.isEmpty ? null : adminDocRef.snapshots(),
      builder: (context, snapshot) {
        String adminName = 'Admin';
        String profileImageUrl = '';
        bool isLoading = true;

        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            adminName = data['name']?.split(' ')[0] ?? 'Admin';
            profileImageUrl = data['profileImage'] ?? '';
          }
          isLoading = false;
        } else if (snapshot.hasError) {
          adminName = 'Error';
          isLoading = false;
          debugPrint('Error fetching admin data: ${snapshot.error}');
        } else if (snapshot.connectionState == ConnectionState.waiting || snapshot.connectionState == ConnectionState.none) {
          isLoading = true;
        }

        if (snapshot.hasData && snapshot.data!.data() == null) {
          adminName = 'Not Found';
          isLoading = false;
          profileImageUrl = '';
          debugPrint('Admin document with ID "$adminId" not found in Firestore in CarAdmin collection.');
        }


        return Scaffold(
          backgroundColor: _primaryColor,
          appBar: AppBar(
            backgroundColor: _appBarColor,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 0,

            title: Row(
              children: [
                // App Logo (Now tappable and in CircleAvatar)
                GestureDetector(
                  onTap: () {
                    // Navigate to view the App Logo in full screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FullScreenImagePage(
                          assetPath: _appLogoPath,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: _accentColor,
                      child: ClipOval(
                        child: Image.asset(
                          _appLogoPath,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.directions_car,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Welcome Text
                isLoading
                    ? Text(
                  'Loading...',
                  style: GoogleFonts.poppins(color: _textColor, fontSize: 18),
                )
                    : Text(
                  'Welcome Admin, $adminName',
                  style: GoogleFonts.poppins(
                    color: _textColor,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              // Profile Picture (Tappable)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    if (!isLoading && profileImageUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImagePage(
                            imageUrl: profileImageUrl,
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: _accentColor,
                    child: ClipOval(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : profileImageUrl.isNotEmpty
                          ? Image.network(
                        profileImageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Profile Image loading error: $error');
                          return const Icon(
                            Icons.person_off,
                            color: Colors.black,
                            size: 24,
                          );
                        },
                      )
                          : const Icon(
                        Icons.person,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: const HomePageBody(),
        );
      },
    );
  }
}


class FullScreenImagePage extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;

  const FullScreenImagePage({super.key, this.imageUrl, this.assetPath})
      : assert(imageUrl != null || assetPath != null, 'Either imageUrl or assetPath must be provided.');

  @override
  Widget build(BuildContext context) {
    // Determine which image widget to use based on provided path
    final Widget imageWidget = assetPath != null
        ? Image.asset(
      assetPath!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.error_outline, color: Colors.white, size: 100),
      ),
    )
        : Image.network(
      imageUrl!,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 100),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: imageWidget,
        ),
      ),
    );
  }
}