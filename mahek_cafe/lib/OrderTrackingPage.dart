import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'CheckMyOrder.dart';
import 'order_model.dart';
import 'package:order_tracker_zen/order_tracker_zen.dart';

// --- Consistent Color Definitions for Theming ---
const Color primaryOrange = Color(0xFFE65100); // Burnt Orange
const Color brownColor = Color(0xFF795548); // Earthy Brown
const Color statusGreen = Color(0xFF4CAF50); // Standard Green for status
const Color grayText = Color(0xFF757575); // Standard Gray for text
const Color darkGrayText = Color(0xFF5A5A5A); // Slightly darker gray for better contrast
const Color lightBackground = Colors.white; // Pure white background

class OrderTrackingPage extends StatefulWidget {
  final Order order; // Use Order model

  const OrderTrackingPage({super.key, required this.order});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final String driverName = "Mahek Kevat";
  final String driverPhone = "+919876543210";
  final int etaMinutes = 15; // Mock Estimated Time of Arrival

  @override
  Widget build(BuildContext context) {
    final String currentStatus = widget.order.status;
    // final String deliveryAddress = widget.order.deliveryAddress; // Not used in the original build method

    // Define tracking steps based on order status with String dates
    List<TrackerData> trackerData = _getTrackerData(currentStatus);

    return Scaffold(
      backgroundColor: lightBackground, // Set to pure white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Subtle elevation for app bar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryOrange),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Track Order',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: brownColor, // Use brown for the main title
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Item Card (Enhanced)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.0), // Lighter border
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Product Image
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.order.imgUrl ?? 'https://via.placeholder.com/100/A1887F/FFFFFF?text=Product', // Placeholder with brown tone
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.order.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: brownColor, // Product name in brown
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Quantity: ${widget.order.quantity} large pieces',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: grayText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\$${widget.order.totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryOrange, // Price in vibrant orange
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tracking Chip
                    Chip(
                      label: Text(
                        'Order tracking',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: primaryOrange, // Chip in orange
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Order Details Section Title (Enhanced)
            Text(
              'Order Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: brownColor, // Title in brown
              ),
            ),
            const SizedBox(height: 6),
            // Order Details Card (Enhanced)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderDetailRow('Expected Delivery Date', '8 Oct 2025'),
                    const Divider(height: 24, thickness: 0.8, color: Color(0xFFE0E0E0)),
                    _buildOrderDetailRow('Order ID', widget.order.orderId),
                    const Divider(height: 24, thickness: 0.8, color: Color(0xFFE0E0E0)),
                    _buildOrderDetailRow('Order Status', currentStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),

            // Timeline Section as Card (Enhanced)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: OrderTrackerZen(
                  tracker_data: trackerData,
                  // The tracker library will handle its own styling, but the card elevates the section
                ),
              ),
            ),
            const SizedBox(height: 10), // Reduced spacing here as the button is now in the bottom bar
          ],
        ),
      ),
      // --- FIXED BOTTOM NAVIGATION BAR WITH BUTTON ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20), // Padding adjusted for bottom safe area
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckMyOrder(orderId: widget.order.orderId),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange, // Button remains orange for action
            elevation: 6, // Prominent shadow
            padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(
            'Track Live Location',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Modified helper function for better label contrast
  Widget _buildOrderDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: darkGrayText, // Labels in dark gray
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: primaryOrange, // Key values in primary orange
          ),
        ),
      ],
    );
  }

  List<TrackerData> _getTrackerData(String currentStatus) {
    return [
      TrackerData(
        title: "Order Placed",
        date: "6 Oct 2025, 11:10 PM",
        tracker_details: [
          TrackerDetails(
            title: "Your order was placed",
            datetime: "6 Oct 2025, 11:10 PM",
          ),
        ],
      ),
      TrackerData(
        title: "In Progress",
        date: "6 Oct 2025, 11:15 PM",
        tracker_details: [
          TrackerDetails(
            title: "Order is being prepared",
            datetime: "6 Oct 2025, 11:15 PM",
          ),
        ],
      ),
      TrackerData(
        title: "Shipped",
        date: "6 Oct 2025, 12:35 PM",
        tracker_details: [
          TrackerDetails(
            title: "Order is on the way",
            datetime: "6 Oct 2025, 12:35 PM",
          ),
        ],
      ),
      TrackerData(
        title: "Delivered",
        date: "6 Oct 2025, 1:35 PM",
        tracker_details: [
          TrackerDetails(
            title: "Order has been delivered",
            datetime: "6 Oct 2025, 1:35 PM",
          ),
        ],
      ),
    ];
  }
}
