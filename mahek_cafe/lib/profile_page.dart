import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SettingsPage.dart';
import 'ChooseOption.dart';
import 'edit_profile_page.dart';
import 'favorites_page.dart';
import 'orders_page.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import for better image loading

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables for data fetching and loading
  bool _isLoading = true;
  String _userName = "Guest";
  String? _userImageUrl;
  String _userEmail = "loading...";
  String _currentUserId = '';

  // Theme colors
  final Color primaryAppColor = const Color(0xFFF96D0A);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _currentUserId = user.uid;
      _userEmail = user.email ?? "Email Not Set";
    });

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          setState(() {
            // Use display name from auth if available, otherwise fallback to Firestore or a default.
            _userName = data?['name'] ?? user.displayName ?? "User Name";
            // Assuming the image URL is stored under 'profile_photo_url' from the EditProfilePage logic
            _userImageUrl = data?['profile_photo'];
          });
        }
      } else {
        // If Firestore document doesn't exist, use FirebaseAuth data
        if (mounted) {
          setState(() {
            _userName = user.displayName ?? "New User";
            _userImageUrl = user.photoURL;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      // Fallback in case of error
      if (mounted) {
        setState(() {
          _userName = _auth.currentUser?.displayName ?? "Error Loading";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ChooseOption()),
            (Route<dynamic> route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged out successfully!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: primaryAppColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error logging out: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Widget Builders ---

  Widget _buildProfileHeader(BuildContext context) {
    // Conditional rendering for the profile header area
    // Show a loading indicator if data is being fetched
    if (_isLoading) {
      return Container(
        // Use the requested decoration for visual consistency even during load
        width: double.infinity,
        height: 250,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.brown[800]!, Colors.orange[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          image: const DecorationImage(
            image: AssetImage('assets/images/coffee_bean_pattern.png'), // Retained pattern
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Full profile header once loading is complete
    return Container(
      // --- START: Requested Decoration Block ---
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown[800]!, Colors.orange[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/coffee_bean_pattern.png'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      // --- END: Requested Decoration Block ---
      child: Column(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: ClipOval(
              child: _userImageUrl != null && _userImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: _userImageUrl!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                        color: primaryAppColor)),
                errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    size: 50,
                    color: primaryAppColor.withOpacity(0.7)),
              )
                  : Icon(Icons.person, size: 50, color: primaryAppColor),
            ),
          ),
          const SizedBox(height: 16),

          // User Name
          Text(
            _userName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // User Email
          Text(
            _userEmail,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.brown[50]!.withOpacity(0.5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: primaryAppColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown[900],
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.brown[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.brown[900],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with Conditional Loading
            _buildProfileHeader(context),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Edit Profile
                  _buildProfileOption(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    onTap: () {
                      if (_isLoading) return; // Prevent navigation while loading
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            currentName: _userName,
                            currentEmail: _userEmail,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),

                  // My Orders
                  _buildProfileOption(
                    icon: Icons.list_alt_rounded,
                    title: 'My Orders',
                    onTap: () {
                      if (_isLoading) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrdersPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),

                  // Favorites
                  _buildProfileOption(
                    icon: Icons.favorite_rounded,
                    title: 'Favorites',
                    onTap: () {
                      if (_isLoading) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),

                  // Settings
                  _buildProfileOption(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () {
                      if (_isLoading) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout_rounded, size: 24),
                      label: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAppColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
