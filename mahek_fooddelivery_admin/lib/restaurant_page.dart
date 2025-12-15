// lib/restaurant_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'restaurant_model.dart';
import 'restaurant_details_page.dart'; // Import the details page

class RestaurantPage extends StatefulWidget {
  const RestaurantPage({super.key});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  final Color primaryAppColor = const Color(0xFFF96D0A); // Orange theme color
  final Color secondaryDarkColor = const Color(0xFF333333); // Dark theme color
  final Color backgroundColor = const Color(0xFFF7F7F7); // Light grey background

  // State for filtering: 'all', 'pending', 'approved', 'rejected'
  String _selectedStatus = 'all';

  // --- Firestore Stream ---
  Stream<List<Restaurant>> get _fetchRestaurantsStream {
    // Start with all restaurants, ordered by creation date
    Query query = FirebaseFirestore.instance.collection('restaurants').orderBy('createdAt', descending: true);

    // Apply status filter if not 'all'
    if (_selectedStatus != 'all') {
      // Must use .toLowerCase() as Firestore is case-sensitive
      query = query.where('status', isEqualTo: _selectedStatus.toLowerCase());
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map(Restaurant.fromFirestore).toList()
    );
  }

  // --- UI Builder Methods ---

  // Segmented control for status filter (Improved Style)
  Widget _buildStatusFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Center(
        child: SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(
                value: 'all',
                label: Text('All'),
                icon: Icon(Icons.list_alt)
            ),
            ButtonSegment<String>(
                value: 'pending',
                label: Text('Pending'),
                icon: Icon(Icons.hourglass_empty)
            ),
            ButtonSegment<String>(
                value: 'approved',
                label: Text('Approved'),
                icon: Icon(Icons.check_circle_outline)
            ),
            ButtonSegment<String>(
                value: 'rejected',
                label: Text('Rejected'),
                icon: Icon(Icons.dangerous_outlined)
            ),
          ],
          selected: <String>{_selectedStatus},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedStatus = newSelection.first;
            });
          },
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: primaryAppColor.withOpacity(0.1),
            selectedForegroundColor: primaryAppColor,
            side: BorderSide(color: primaryAppColor.withOpacity(0.4)),
            // Make segments fill container if possible or center them
            // Use size constraints if you need full width fill
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }

  // List tile for a single restaurant entry (Improved Card Design)
  Widget _buildRestaurantListTile(BuildContext context, Restaurant restaurant) {
    return Card(
      elevation: 4, // Higher elevation for a floating effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Add border color for status hint
        side: BorderSide(color: restaurant.statusColor.withOpacity(0.6), width: 1.5),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        onTap: () {
          // Navigate to the details page
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RestaurantDetailsPage(restaurant: restaurant),
            ),
          );
        },
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: primaryAppColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.storefront, color: primaryAppColor, size: 30),
        ),
        title: Text(
          restaurant.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: secondaryDarkColor, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(restaurant.address, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
            Text(restaurant.phone, style: GoogleFonts.poppins(fontSize: 14, color: secondaryDarkColor.withOpacity(0.8))),
          ],
        ),
        // Display status badge (More prominent badge)
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: restaurant.statusColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: restaurant.statusColor.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            restaurant.status.toUpperCase(),
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white // White text for better contrast
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Restaurant Approvals', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        // Optional: Add a subtle shadow to the app bar for depth
        shadowColor: secondaryDarkColor.withOpacity(0.1),
      ),
      body: Column(
        children: [
          _buildStatusFilter(), // Filter widget at the top
          // Add a divider below the filter for clean separation
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          Expanded(
            child: StreamBuilder<List<Restaurant>>(
              stream: _fetchRestaurantsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins(color: Colors.red)));
                }

                final restaurants = snapshot.data ?? [];

                if (restaurants.isEmpty) {
                  String emptyMessage = _selectedStatus == 'all'
                      ? 'No restaurants found.'
                      : 'No ${_selectedStatus} restaurants found.';

                  return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              emptyMessage,
                              style: GoogleFonts.poppins(fontSize: 18, color: secondaryDarkColor.withOpacity(0.6)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    return _buildRestaurantListTile(context, restaurants[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
