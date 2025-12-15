// file: lib/view_coupon_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mahek_cafe/coupon/purchase_coupon_page.dart';
import 'models/coupon_model.dart';

class ViewCouponPage extends StatelessWidget {
  ViewCouponPage({super.key});

  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightBackground = const Color(0xFFFBFBFB);

  // Sample data: These should be actual purchased coupons passed from the previous page or state management
  final List<CouponModel> _claimedCoupons = [
    CouponModel(
      code: 'DELIVERFREE',
      title: 'Free Delivery',
      description: 'Minimum order \$15.',
      minOrder: 15,
      discountValue: 100, // Representing free service
      isPurchased: true,
    ),
    CouponModel(
      code: 'MAHEK101',
      title: 'Mega Feast Discount',
      description: 'Save big on your next party order. Min order \$50.',
      minOrder: 50,
      discountValue: 35, // Example of a rare 35% discount
      isPurchased: true,
    ),
    CouponModel(
      code: 'WEEKEND5',
      title: 'Small Savings',
      description: 'Applies to any order over \$10.',
      minOrder: 10,
      discountValue: 5, // Example of a common 5% discount
      isPurchased: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: secondaryDarkColor),
        title: Text(
          'My Coupons',
          style: GoogleFonts.poppins(
            color: secondaryDarkColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available for Use (${_claimedCoupons.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: secondaryDarkColor, // Changed color for better contrast
                  ),
                ),
                // --- Updated Purchase Button ---
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseCouponPage()));
                  },
                  icon: Icon(Icons.shopping_bag_outlined, color: primaryAppColor, size: 20),
                  label: Text(
                    "Buy Coupons",
                    style: GoogleFonts.poppins(
                      color: primaryAppColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                ),
                // ------------------------------
              ],
            ),
          ),
          const Divider(indent: 20, endIndent: 20, height: 10), // Added a subtle divider

          Expanded(
            child: _claimedCoupons.isEmpty
                ? Center(
              child: Text(
                'You have no claimed coupons yet. Unlock some!',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _claimedCoupons.length,
              itemBuilder: (context, index) {
                final coupon = _claimedCoupons[index];
                return _buildCouponListItem(context, coupon);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponListItem(BuildContext context, CouponModel coupon) {
    // ... (The rest of this function remains the same as it was already attractive)
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: secondaryDarkColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Discount Circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryAppColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: primaryAppColor, width: 2),
            ),
            child: Center(
              child: Text(
                coupon.discountValue == 100 ? 'FREE' : '${coupon.discountValue.toInt()}%',
                style: GoogleFonts.poppins(
                  color: primaryAppColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: secondaryDarkColor,
                  ),
                ),
                Text(
                  coupon.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Code: ${coupon.code}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryAppColor,
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          ElevatedButton(
            onPressed: () {
              // In a real app, this would apply the coupon to the current cart
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Coupon ${coupon.code} applied to cart! 🛒')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAppColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              elevation: 4,
            ),
            child: Text(
              'Apply',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}