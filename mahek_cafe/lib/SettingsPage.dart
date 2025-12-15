import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahek_cafe/app_information_page.dart';
import 'package:mahek_cafe/complaint_history_page.dart';
import 'package:mahek_cafe/edit_profile_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'faq_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- Theme Colors ---
  final Color primaryAppColor = const Color(0xFFF96D0A); // Primary Orange/Brown
  final Color secondaryDarkColor = const Color(0xFF333333); // Dark text color
  final Color lightBackgroundColor = const Color(0xFFF0F4F8); // Light background
  final Color cardColor = const Color(0xFFFFFFFF); // White for cards

  bool _notificationsEnabled = true;
  bool _darkMode = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Initialize settings from local storage or remote config if needed
  }

  // --- Function to send Password Reset Email (NEW) ---
  Future<void> _sendPasswordResetEmail() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(
            'Error: You must be logged in with an email account.',
            isError: true,
          ),
        );
      }
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: user.email!);

      // Show Success Toast/SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(
            'A password reset link has been sent to ${user.email}. Check your inbox!',
            isError: false,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'The user account associated with this email was not found.';
      }

      // Show Error Toast/SnackBar
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_buildSnackBar(message, isError: true));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('An unexpected error occurred.', isError: true),
        );
      }
    }
  }

  // --- Function to handle Firebase logout ---
  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      if (mounted) {
        // Assuming '/login' is the route to your sign-in screen
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_buildSnackBar('Error signing out: $e', isError: true));
    }
  }

  // --- Helper Widget for consistent SnackBar/Toast styling ---
  SnackBar _buildSnackBar(String message, {required bool isError}) {
    return SnackBar(
      content: Text(message, style: GoogleFonts.poppins(color: cardColor)),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    );
  }

  // --- Function to show Logout Confirmation Dialogue ---
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: secondaryDarkColor),
          ),
          content: Text(
            'Are you sure you want to log out of your Mahek Cafe account?',
            style: GoogleFonts.poppins(color: secondaryDarkColor.withOpacity(0.8)),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: secondaryDarkColor),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAppColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
              child: Text(
                'Log Out',
                style: GoogleFonts.poppins(color: cardColor, fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                await _signOut(context); // Perform actual sign out
              },
            ),
          ],
        );
      },
    );
  }

  // --- Widget Builders ---

  // Custom Wave Header container
  Widget _buildWaveContainer() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryAppColor, primaryAppColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: secondaryDarkColor,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: primaryAppColor, size: 28),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: secondaryDarkColor,
          ),
        ),
        trailing:
        trailing ??
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.grey,
            ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: primaryAppColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: secondaryDarkColor,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: primaryAppColor,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the height of the wave header
    const double headerHeight = 140;

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Custom Header Stack for Wave, Title, and Floating Icon ---
            Stack(
              clipBehavior: Clip.none, // Allows the icon to go above the stack boundary
              children: [
                // 1. Wave Background
                _buildWaveContainer(),

                // 2. Settings Title (Left Side, inside the colored area)
                Positioned(
                  top: 55, // Adjusted for typical status bar/padding
                  left: 20,
                  child: Text(
                    'Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: cardColor,
                    ),
                  ),
                ),

                // 3. Floating Logout Icon (Above the wave, right side)
                Positioned(
                  // Adjusting top to place it above the wave's curve
                  top: headerHeight - 30, // Pushes the circle partially above the wave
                  right: 20,
                  child: GestureDetector(
                    onTap: () => _confirmSignOut(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor, // White Circular Background
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: primaryAppColor, // Icon color (Orange/Brown)
                        size: 30, // Large Icon
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Add spacing to push the content down below the floating icon
            const SizedBox(height: 6),

            // --- Account Section ---
            _buildSectionTitle('Account'),

            // Edit Profile
            _buildSettingTile(
              icon: Icons.person_rounded,
              title: 'Edit Profile',
              onTap: () {
                final user = _auth.currentUser;
                final currentName = user?.displayName ?? 'Guest User';
                final currentEmail = user?.email ?? 'guest@example.com';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditProfilePage(
                      currentName: currentName,
                      currentEmail: currentEmail,
                    ),
                  ),
                );
              },
            ),

            // Change Password
            _buildSettingTile(
              icon: Icons.lock_rounded,
              title: 'Change Password',
              onTap: _sendPasswordResetEmail,
            ),

            // Complaint History
            _buildSettingTile(
              icon: Icons.local_fire_department_rounded,
              title: 'My Complaint History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComplaintHistoryPage(),
                  ),
                );
              },
            ),

            // FAQ's Page
            _buildSettingTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & FAQ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FaqPage()),
                );
              },
            ),

            // --- Preferences Section ---
            _buildSectionTitle('Preferences'),

            // Notifications Toggle
            _buildSwitchTile(
              icon: Icons.notifications_active_rounded,
              title: 'Notifications',
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
                // Logic to update notification settings
              },
            ),

            // Dark Mode Toggle
            _buildSwitchTile(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              value: _darkMode,
              onChanged: (val) {
                setState(() => _darkMode = val);
                // Logic to update theme mode
              },
            ),

            // --- General Section ---
            _buildSectionTitle('General'),

            // App Information
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'App Information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppInformationPage(),
                  ),
                );
              },
            ),

            // The list tile for Logout is no longer needed.

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Custom Clipper for Wave Effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var firstControlPoint = Offset(size.width / 3, size.height + 10);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    var secondControlPoint = Offset(2 * size.width / 3, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 40);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
