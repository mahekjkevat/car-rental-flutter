import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Define the consistent theme colors based on home_page.dart
const Color primaryBrown = Color(0xFF5D4037); // Richer Dark Brown
const Color accentOrange = Color(0xFFF4511E); // Vibrant Orange/Terracotta
const Color lightBgColor = Colors.white;
final Color primaryAppColor = const Color(0xFFF96D0A);

final Color lightBackground = const Color(0xFFF5F5F5);


class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  // Placeholder function for action (e.g., launching an email client or phone dialer)
  void _handleContactAction(String type, String value) {
    // In a real app, you would use a package like 'url_launcher' here.
    // For now, we'll just print a message.
    print('Action: $type, Value: $value');
  }

  Widget _buildContactCard(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        leading: Icon(
          icon,
          color: accentOrange,
          size: 30,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryBrown,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: primaryBrown.withOpacity(0.7),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryBrown),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'Contact Support',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryAppColor,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We are here to help!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the best way to reach our customer support team.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: primaryBrown.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 30),

            // --- Contact Options ---

            // 1. Email Support
            _buildContactCard(
              context,
              Icons.email_outlined,
              'Email Support',
              'Send us a detailed message.',
                  () => _handleContactAction('email', 'support@mahekfood.com'),
            ),

            // 2. Phone Support
            _buildContactCard(
              context,
              Icons.phone_outlined,
              'Call Us',
              'Available during business hours (9 AM - 6 PM).',
                  () => _handleContactAction('phone', '+1-800-555-FOOD'),
            ),

            // 3. Live Chat (Placeholder)
            _buildContactCard(
              context,
              Icons.chat_bubble_outline_rounded,
              'Live Chat',
              'Get instant help through our in-app chat.',
                  () => _handleContactAction('chat', 'Open Chat Window'),
            ),

            const SizedBox(height: 30),

            // --- Follow Us Section ---
            Center(
              child: Column(
                children: [
                  Text(
                    'Find us on social media!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon(Icons.facebook, 'Facebook'),
                      _buildSocialIcon(Icons.camera_alt_outlined, 'Instagram'), // Placeholder for Instagram icon
                      _buildSocialIcon(Icons.ac_unit_outlined, 'Twitter'), // Placeholder for X/Twitter icon
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: IconButton(
        icon: Icon(icon, color: accentOrange, size: 30),
        onPressed: () => _handleContactAction('social', name),
      ),
    );
  }
}
