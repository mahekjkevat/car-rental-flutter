// file: lib/promo_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PromoDetailsPage extends StatelessWidget {
  final String title;
  final String tagline;

  const PromoDetailsPage({
    super.key,
    required this.title,
    required this.tagline,
  });

  // Aesthetic Colors
  final Color primaryAppColor = const Color(0xFFF96D0A); // Vibrant Orange/Red
  final Color secondaryDarkColor = const Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: secondaryDarkColor),
        title: Text(
          'Current Promotion',
          style: GoogleFonts.poppins(
            color: secondaryDarkColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Featured Image/Icon Area
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: primaryAppColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryAppColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping_rounded,
                      color: primaryAppColor,
                      size: 80,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Free Delivery Offer!',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryAppColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Title and Tagline
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: secondaryDarkColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tagline,
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: secondaryDarkColor.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 40),

            // Terms and Conditions Section
            _buildInfoTile(
              icon: Icons.access_time_filled,
              text: 'Valid until the end of this week.',
            ),
            _buildInfoTile(
              icon: Icons.shopping_bag_rounded,
              text: 'Minimum order value must be \$10 or more.',
            ),
            _buildInfoTile(
              icon: Icons.location_on_rounded,
              text: 'Available for deliveries within the city limits.',
            ),

            const SizedBox(height: 50),

            // Call to Action Button
            ElevatedButton.icon(
              onPressed: () {
            //  Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerChatScreen()));

              },
              icon: const Icon(Icons.check_circle_outline, size: 28),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: Text(
                  'Start Ordering Now!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAppColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for attractive list items
  Widget _buildInfoTile({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryAppColor, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: secondaryDarkColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
