import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

// Order Success Page
class OrderSuccessPage extends StatelessWidget {
  final String orderId;
  final String name;
  final double totalPrice;
  final int quantity;
  final String deliveryOption;
  final String paymentMethod;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
    required this.name,
    required this.totalPrice,
    required this.quantity,
    required this.deliveryOption,
    required this.paymentMethod,
  });

  // --- Consistent Color Definitions ---
  final Color primaryBrown = const Color(0xFF6D4C41); // Rich Dark Brown
  final Color accentOrange = const Color(0xFFE65100); // Burnt Orange/Gold
  final Color lightBgColor = const Color(0xFFFAF7F5); // Very light brown/off-white

  // Helper method to truncate orderId to 20 characters with ellipsis
  String _truncateOrderId(String id) {
    return id.length > 20 ? '${id.substring(0, 20)}...' : id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Using `pop` instead of `pushReplacement` on the leading icon for navigation behavior
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: primaryBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Successful',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryBrown,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon with Themed Colors
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentOrange.withOpacity(0.15), // Slightly more opaque background
                  border: Border.all(color: accentOrange.withOpacity(0.4), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: accentOrange.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: accentOrange,
                  size: 100,
                ),
              ),
              const SizedBox(height: 24),
              // Success Message
              Text(
                'Order Placed Successfully!',
                style: GoogleFonts.poppins(
                  fontSize: 32, // Slightly larger
                  fontWeight: FontWeight.bold,
                  color: primaryBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your delicious Food is being prepared!',
                style: GoogleFonts.poppins(fontSize: 17, color: Colors.grey[700]), // Slightly larger font
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- UPDATED: Order Details Card using a Table-like structure ---
              _buildOrderDetailsTable(),
              // --- END UPDATED SECTION ---

              const SizedBox(height: 50),
              // Back to Home Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil( // Use pushAndRemoveUntil to clear stack
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                        (Route<dynamic> route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange, // Themed color
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10, // Higher elevation
                    shadowColor: accentOrange.withOpacity(0.7),
                  ),
                  child: Text(
                    'Continue Shopping',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW WIDGET: Builds the order details in a fully-boxed Table format ---
  Widget _buildOrderDetailsTable() {
    // Collect all details into a list of maps
    final List<Map<String, dynamic>> details = [
      {'label': 'Order ID', 'value': _truncateOrderId(orderId), 'isHighlight': true},
      {'label': 'Item', 'value': name},
      {'label': 'Quantity', 'value': quantity.toString()},
      {'label': 'Delivery Option', 'value': deliveryOption},
      {'label': 'Payment Method', 'value': paymentMethod},
      {'label': 'Total Amount', 'value': '₹${totalPrice.toStringAsFixed(2)}', 'isTotal': true},
    ];

    // Define the border style for the table
    TableBorder tableBorder = TableBorder.all(
      color: Color(0xFFE0E0E0), // Light grey border
      width: 1.0,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    );

    return Container(
      width: double.infinity,
      // The box decoration is now only for the shadow and overall look, the border is applied to the Table
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      // Removed internal padding so the table fills the container
      child: ClipRRect( // ClipRRect helps apply the border radius around the table borders
        borderRadius: BorderRadius.circular(20),
        child: Table(
          border: tableBorder, // Apply the full border here
          // Set column widths: first column takes 40% of space, second takes the rest
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(6),
          },
          children: details.map((detail) {
            bool isTotal = detail['isTotal'] ?? false;
            bool isHighlight = detail['isHighlight'] ?? false;

            return TableRow(
              // Background for the Total row
              decoration: isTotal
                  ? BoxDecoration(
                color: accentOrange.withOpacity(0.1),
              )
                  : null,
              children: [
                // Label (Field)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                  child: Text(
                    detail['label'],
                    style: GoogleFonts.poppins(
                      fontSize: isTotal ? 17 : 15,
                      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                      color: isTotal ? primaryBrown : Colors.grey[700],
                    ),
                  ),
                ),
                // Value
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                  child: Text(
                    detail['value'],
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: isTotal ? 18 : 15,
                      fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                      color: isTotal ? accentOrange : isHighlight ? primaryBrown : primaryBrown,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  // --- END NEW WIDGET ---

  // Helper method for consistent row styling (kept for potential reuse, though now deprecated by the Table)
  Widget _buildDetailRow(String label, String value, {bool isTotal = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Increased vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 19 : 16,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: isTotal ? primaryBrown : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 19 : 16,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? accentOrange : isHighlight ? primaryBrown : primaryBrown,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
