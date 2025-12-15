import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_page.dart';

class OrderConfirmationPage extends StatelessWidget {
  final List<Map<String, dynamic>> orderedItems;
  final double total;

  const OrderConfirmationPage({
    super.key,
    required this.orderedItems,
    required this.total,
  });

  // --- Consistent Color Definitions ---
  final Color primaryBrown = const Color(0xFF6D4C41); // Rich Dark Brown
  final Color accentOrange = const Color(0xFFE65100); // Burnt Orange/Gold
  final Color lightBgColor = const Color(0xFFFAF7F5); // Very light brown/off-white


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: lightBgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Order Confirmation',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: primaryBrown, // Themed color
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false, // No back button
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Order Summary',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryBrown, // Themed color
                      ),
                    ),
                    const SizedBox(height: 20),
                    // --- List of Ordered Items ---
                    ...orderedItems.asMap().entries.map((entry) {
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBrown.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Item Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: item['imgUrl'],
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(color: accentOrange),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Image.asset(
                                          'assets/images/cofee.png', // Fallback
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Item Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: primaryBrown, // Themed color
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['isIce'] ? 'Iced' : 'Hot'} - Qty: ${item['quantity']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: primaryBrown.withOpacity(0.7), // Themed color
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Item Total Price
                                Text(
                                  '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: accentOrange, // Themed color
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 1.5, color: Colors.grey),
                    const SizedBox(height: 24),

                    // --- Final Total Row ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryBrown, // Themed color
                          ),
                        ),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: accentOrange, // Themed color
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // --- Bottom Action Container ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to the home page or a specific orders page
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                          (Route<dynamic> route) => false, // Remove all previous routes
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange, // Themed color
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 6,
                    shadowColor: accentOrange.withOpacity(0.4),
                  ),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}