import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'TestPaymentScreen.dart';

class AppInformationPage extends StatefulWidget {
  const AppInformationPage({super.key});

  @override
  State<AppInformationPage> createState() => _AppInformationPageState();
}

class _AppInformationPageState extends State<AppInformationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Define your primary color palette here for easy access in helper methods
  static const Color _primaryBrown = Color(0xFF6D4C41);
  static const Color _accentOrange = Color(0xFFE65100);

  // --- Animation Setup ---
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Slide up animation from a bit lower
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Fade in animation with a slight delay
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.3,
          1.0,
          curve: Curves.easeIn,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // -----------------------

  // --- Function to Show Full-Screen Image Dialog ---
  void _showAppIconFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          // Set backgroundColor to transparent to only show the image
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(), // Tap anywhere to close
            child: InteractiveViewer( // Allows zoom and pan for the full image
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/app_icon.jpeg', // Use the same image path
                  fit: BoxFit.contain, // Ensure the whole image is visible
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  // -------------------------------------------------

  // --- Helper Widget for Information Cards ---
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Light background tint
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.4), width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _primaryBrown, // Consistent dark text color
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _primaryBrown.withOpacity(0.8), // A slightly lighter text color
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

  // -------------------------------------------

  @override
  Widget build(BuildContext context) {
    const Color lightBackground = Color(0xFFFAF7F5);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _primaryBrown),
        title: Text(
          'App Details',
          style: GoogleFonts.poppins(
            color: _primaryBrown,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- App Icon (Wrapped in GestureDetector) ---
                GestureDetector(
                  onTap: () => _showAppIconFullScreen(context), // Call the new function on tap
                  child: Hero( // Added Hero animation for a smooth transition
                    tag: 'app-icon',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/app_icon.jpeg',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // ---------------------------

                Text(
                  'Mahek Food Delivery',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _accentOrange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.2.5 (Build 42)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _primaryBrown.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 30),

                // --- App Mission Card ---
                _buildInfoCard(
                  icon: Icons.fastfood_rounded,
                  title: 'Our Mission',
                  subtitle:
                  'Delivering delicious meals from Mahuva’s finest kitchens straight to your doorstep. Fast, fresh, and full of flavor is our promise to you.',
                  color: _accentOrange,
                ),

                // --- Key Features ---
                _buildInfoCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Dedicated Support',
                  subtitle:
                  'Our customer support team is available 24/7 to ensure a smooth and delightful experience every time you order.',
                  color: _primaryBrown,
                ),
                _buildInfoCard(
                  icon: Icons.security_rounded,
                  title: 'Secure & Private',
                  subtitle:
                  'We prioritize your privacy and use industry-leading encryption to keep your data and transactions safe.',
                  color: Colors.green,
                ),

                const SizedBox(height: 30),

                // --- Call to Action Button (Refined) ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RazorPayWorkingDemo()),
                      );
                    },
                    icon: const Icon(Icons.confirmation_num_rounded, size: 24),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Explore Exclusive Coupons',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // --- Footer Information ---
                Text(
                  'Developed with ❤️ in Bilimora, Gujarat',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _primaryBrown.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '© 2025 Mahek Delivery Services. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _primaryBrown.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}