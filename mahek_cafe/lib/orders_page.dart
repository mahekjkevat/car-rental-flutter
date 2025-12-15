import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'order_details_page.dart';
import 'order_model.dart'; // Import the new model

// Orders Page (History)
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  // --- Consistent Color Definitions ---
  final Color primaryBrown = const Color(0xFF6D4C41); // Rich Dark Brown
  final Color accentOrange = const Color(0xFFE65100); // Burnt Orange/Gold
  final Color lightBgColor = const Color(0xFFFAF7F5); // Very light brown/off-white

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Show a sign-in prompt if the user is not authenticated
      return Scaffold(
        backgroundColor: lightBgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'My Orders',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: primaryBrown,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon for unauthenticated state
              Icon(Icons.person_off_rounded, size: 80, color: accentOrange),
              const SizedBox(height: 16),
              Text(
                'Please sign in to view your orders.',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryBrown.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Main Orders View for authenticated user
    return Scaffold(
      backgroundColor: lightBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryBrown,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listen to the user's orders collection, ordered by timestamp
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentOrange));
          }

          if (snapshot.hasError) {
            print("Firestore Error: ${snapshot.error}"); // Log the error
            return Center(
              child: Text(
                'Error loading orders. Please check connection.',
                style: GoogleFonts.poppins(fontSize: 20, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            // Show a message when no orders are found
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 80, color: primaryBrown.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No Orders Yet!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryBrown.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your coffee journey with us!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              // 🚀 Use the model to parse the snapshot data
              final Order order = Order.fromFirestore(orders[index]);

              // Pass the entire Order object to the card builder
              return _buildOrderCard(context, order);
            },
          );
        },
      ),
    );
  }

  // Widget to build a single order summary card, now accepting an Order object
  Widget _buildOrderCard(
      BuildContext context,
      Order order,
      ) {
    Color statusColor;
    switch (order.status) {
      case 'Delivered':
        statusColor = Colors.green[700]!; // Darker green for contrast
        break;
      case 'In Progress':
        statusColor = accentOrange; // Themed In Progress color
        break;
      case 'Cancelled':
        statusColor = Colors.red[700]!; // Darker red for contrast
        break;
      default:
        statusColor = primaryBrown.withOpacity(0.6);
    }

    // Safely format the date from the DateTime object
    final dateString = '${order.timestamp.year}-${order.timestamp.month.toString().padLeft(2, '0')}-${order.timestamp.day.toString().padLeft(2, '0')}';


    return GestureDetector(
      onTap: () {
        // 🚀 NAVIGATION UPDATE: Pass the entire Order object to OrderDetailsPage
        // ASSUMES OrderDetailsPage constructor is updated to accept: required final Order order;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => OrderDetailsPage(
              order: order, // Pass the clean, typed Order object
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Larger radius for modern card
          boxShadow: [
            BoxShadow(
              color: primaryBrown.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Item Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: order.imgUrl ?? '',
                height: 110, // Slightly larger image
                width: 110,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(child: CircularProgressIndicator(color: accentOrange)),
                errorWidget: (context, url, error) => Container(
                  color: lightBgColor, // Fallback background color
                  height: 110,
                  width: 110,
                  child: Center(
                    child: Icon(Icons.image_not_supported_rounded, color: primaryBrown.withOpacity(0.5)),
                  ),
                ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            order.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18, // Slightly larger font
                              fontWeight: FontWeight.w700,
                              color: primaryBrown,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            order.status,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quantity and Date
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: primaryBrown.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          dateString,
                          style: GoogleFonts.poppins(fontSize: 13, color: primaryBrown.withOpacity(0.8)),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.local_cafe, size: 14, color: primaryBrown.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'Qty: ${order.quantity}',
                          style: GoogleFonts.poppins(fontSize: 13, color: primaryBrown.withOpacity(0.8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Total Price and Arrow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ₹${order.totalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accentOrange, // Themed accent color
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: primaryBrown, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
