import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAboutPage extends StatelessWidget {
  const AdminAboutPage({super.key});

  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightBackground = const Color(0xFFFBFBFB);

  // Function to show the logo in a full-screen, dismissible dialog
  void _showBigLogo(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          // Remove default padding of the Dialog
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Tapping the main image dismisses the dialog
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Hero(
                      // IMPORTANT: The tag must match the one used in the main page
                      tag: 'appLogo',
                      child: Image.asset(
                        'assets/icon/app_icon.jpeg',
                        // Ensure it scales correctly on the screen
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              // Close button at the top right
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 35),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'About Mahek Admin',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo Image (Tappable)
            GestureDetector(
              onTap: () => _showBigLogo(context),
              child: Hero(
                tag: 'appLogo', // Used for the smooth transition (Hero animation)
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: secondaryDarkColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/icon/app_icon.jpeg',
                      fit: BoxFit.cover,
                      // Fallback in case the asset is not correctly configured
                      errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.fastfood_rounded,
                          size: 100,
                          color: primaryAppColor.withOpacity(0.7)
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Tap for Big Logo!',
              style: GoogleFonts.poppins(
                color: primaryAppColor.withOpacity(0.8),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 40),

            // App Title and Version
            Text(
              'Mahek Food Delivery Admin Panel',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: secondaryDarkColor,
              ),
            ),

            Text(
              'Version 1.0.0 (Build 20251030)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const Divider(height: 30, thickness: 1.5),

            // Description Section
            _buildInfoCard(
              Icons.admin_panel_settings_rounded,
              'Purpose',
              'This application is the central control panel for managing the Mahek Food Delivery service. It provides tools for product catalog management, restaurant partner approvals, customer support, and system monitoring.',
            ),

            _buildInfoCard(
              Icons.security_rounded,
              'Security',
              'Developed using Firebase Authentication and Firestore Security Rules to ensure data integrity and restricted access to authorized administrative personnel only.',
            ),

            _buildInfoCard(
              Icons.developer_mode_rounded,
              'Technologies',
              'Built with Flutter for cross-platform compatibility, Firebase (Firestore & Auth) for backend services, and Appwrite for secure file storage.',
            ),

            const SizedBox(height: 40),

            // Copyright/Legal
            Text(
              '© 2024 Mahek Food Delivery. All rights reserved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryAppColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: secondaryDarkColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryAppColor, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: secondaryDarkColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
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
