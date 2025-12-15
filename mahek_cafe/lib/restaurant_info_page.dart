// lib/restaurant_info_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mahek_cafe/models/restaurant_model.dart';

class RestaurantInfoPage extends StatelessWidget {
  final RestaurantData restaurant;

  const RestaurantInfoPage({super.key, required this.restaurant});

  // Helper method to display a field
  Widget _buildDetailRow(IconData icon, String title, String value, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryAppColor = const Color(0xFFF96D0A);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Restaurant Info',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryAppColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Header Image
            Container(
              height: 200,
              width: double.infinity,
              child: restaurant.profileUrl != null
                  ? CachedNetworkImage(
                imageUrl: restaurant.profileUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFF96D0A))),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.restaurant, size: 60, color: Colors.grey[400]),
                  ),
                ),
              )
                  : Container(
                color: primaryAppColor.withOpacity(0.8),
                child: Center(
                  child: Icon(Icons.restaurant, size: 60, color: Colors.white70),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name
                  Center(
                    child: Text(
                      restaurant.name,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: primaryAppColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          '${restaurant.rating.toStringAsFixed(1)} / 5.0',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Contact Information Section
                  Text(
                    'Contact Information',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryAppColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailRow(
                    Icons.email_rounded,
                    'Email',
                    restaurant.email,
                    color: primaryAppColor,
                  ),
                  _buildDetailRow(
                    Icons.phone_rounded,
                    'Phone',
                    restaurant.phone,
                    color: primaryAppColor,
                  ),
                  _buildDetailRow(
                    Icons.location_on_rounded,
                    'Address',
                    restaurant.address,
                    color: primaryAppColor,
                  ),

                  const SizedBox(height: 24),

                  // Business Hours Section
                  Text(
                    'Business Hours',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryAppColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailRow(
                    Icons.access_time_rounded,
                    'Opening Hours',
                    '${restaurant.openTime ?? 'N/A'} - ${restaurant.closeTime ?? 'N/A'}',
                    color: Colors.orange.shade800,
                  ),

                  const SizedBox(height: 24),

                  // Restaurant Status Section
                  Text(
                    'Restaurant Status',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryAppColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailRow(
                    restaurant.isApproved ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                    'Approval Status',
                    restaurant.isApproved ? 'Approved' : 'Pending Approval',
                    color: restaurant.isApproved ? Colors.green : Colors.orange,
                  ),
                  _buildDetailRow(
                    Icons.info_outline_rounded,
                    'Restaurant ID',
                    restaurant.resId,
                    color: Colors.blueGrey,
                  ),

                  const SizedBox(height: 30),

                  // Additional Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About ${restaurant.name}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryAppColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We are committed to providing the best dining experience with fresh ingredients and authentic flavors. Visit us for a memorable meal!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}