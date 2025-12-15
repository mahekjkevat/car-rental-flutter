// file: lib/discount_reflection_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscountReflectionPage extends StatelessWidget {
  final String couponCode;
  final double discountPercent;
  final double originalTotal = 45.00; // Sample order total

  DiscountReflectionPage({
    super.key,
    this.couponCode = 'MAHEK35',
    this.discountPercent = 35.0, // Example 35% discount
  });

  // Aesthetic Colors
  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightBackground = const Color(0xFFFBFBFB);

  @override
  Widget build(BuildContext context) {
    final double discountAmount = originalTotal * (discountPercent / 100);
    final double finalTotal = originalTotal - discountAmount;
    final String discountString = discountAmount.toStringAsFixed(2);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: secondaryDarkColor),
        title: Text(
          'Order Summary',
          style: GoogleFonts.poppins(
            color: secondaryDarkColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Discount Applied Banner
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: primaryAppColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryAppColor, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'Coupon Applied!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryAppColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Code: $couponCode | ${discountPercent.toInt()}% OFF',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: secondaryDarkColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Pricing Details
            _buildPriceRow('Subtotal:', '\$${originalTotal.toStringAsFixed(2)}', secondaryDarkColor),
            _buildPriceRow('Delivery Fee:', '\$5.00', secondaryDarkColor),
            _buildPriceRow('Tax:', '\$1.50', secondaryDarkColor),
            const Divider(height: 30, thickness: 1),

            // Discount Row (Highlighted)
            _buildPriceRow(
              'Coupon Discount (${discountPercent.toInt()}%):',
              '-\$$discountString',
              Colors.green.shade700,
              isDiscount: true,
            ),
            const Divider(height: 30, thickness: 2, color: Colors.grey),

            // Final Total
            _buildPriceRow(
              'TOTAL PAYABLE:',
              '\$${finalTotal.toStringAsFixed(2)}',
              primaryAppColor,
              isTotal: true,
            ),

            const Spacer(),

            // Checkout Button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order placed successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAppColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 5,
              ),
              child: Text(
                'Proceed to Payment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, Color color, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 22 : 16,
              fontWeight: isTotal || isDiscount ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? secondaryDarkColor : secondaryDarkColor.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 22 : 16,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}