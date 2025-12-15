import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'models/coupon_model.dart';

class _CouponGenerator {
  static double generateRandomDiscount() {
    final random = Random();
    int chance = random.nextInt(100);
    // 97% chance of 1-9%, 3% chance of 20-40%
    if (chance < 97) {
      return 1.0 + random.nextDouble() * 9.0;
    } else {
      return 20.0 + random.nextDouble() * 20.0;
    }
  }

  static List<CouponModel> generateCoupons(int count) {
    return List.generate(count, (index) {
      final discount = generateRandomDiscount();
      // Ensure minOrder is a whole number between 5 and 30
      final minOrder = 5 + Random().nextInt(25);
      return CouponModel(
        code: 'MAHEK${100 + index}',
        title: 'Discount Voucher ${index + 1}',
        description: 'Spend ₹${minOrder.toStringAsFixed(0)} to use this reward.',
        minOrder: minOrder,
        // Round to nearest whole number for display
        discountValue: double.parse(discount.toStringAsFixed(0)),
        isPurchased: false,
      );
    });
  }
}

class PurchaseCouponPage extends StatefulWidget {
  const PurchaseCouponPage({super.key});

  @override
  State<PurchaseCouponPage> createState() => _PurchaseCouponPageState();
}

class _PurchaseCouponPageState extends State<PurchaseCouponPage> {
  List<CouponModel> _availableCoupons = [];
  final Color primaryAppColor = const Color(0xFFF96D0A); // Orange
  final Color secondaryDarkColor = const Color(0xFF333333); // Dark Gray
  final Color lightBackground = const Color(0xFFFBFBFB);

  @override
  void initState() {
    super.initState();
    _availableCoupons = _CouponGenerator.generateCoupons(10);
  }

  // New function to show the purchase confirmation dialog
  void _showPurchaseConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Confirm Purchase',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: secondaryDarkColor),
          ),
          content: Text(
            'Do you want to spend 100 Loyalty Points to unlock this mystery coupon?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _revealCoupon(index); // Proceed to reveal the coupon
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAppColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Buy & Reveal', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Function to reveal the coupon and show the success dialog
  void _revealCoupon(int index) {
    setState(() {
      _availableCoupons[index] = _availableCoupons[index].copyWith(isPurchased: true);
    });

    final coupon = _availableCoupons[index];

    // Show the revealed coupon details
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, color: primaryAppColor, size: 55),
            const SizedBox(height: 15),
            Text(
              '🎉 REWARD UNLOCKED! 🎉',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: primaryAppColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryAppColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${coupon.discountValue.toInt()}% OFF',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryAppColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Code: ${coupon.code}',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: secondaryDarkColor),
            ),
            Text(
              coupon.description.replaceAll('.', ''), // Clean up description
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryDarkColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Got It!', style: GoogleFonts.poppins(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: secondaryDarkColor),
        title: Text(
          'Scratch & Win Rewards 🎁',
          style: GoogleFonts.poppins(
            color: secondaryDarkColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Attractive Banner (slightly updated text)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryAppColor, primaryAppColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryAppColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scratch Your Luck! ✨',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Redeem 100 Points to scratch a card and reveal a guaranteed food discount.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Coupon Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.85,
              ),
              itemCount: _availableCoupons.length,
              itemBuilder: (context, index) {
                final coupon = _availableCoupons[index];
                return _buildScratchCardItem(coupon, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  // New Widget for the Scratch Card concept
  Widget _buildScratchCardItem(CouponModel coupon, int index) {
    final bool isPurchased = coupon.isPurchased;

    // Choose the overlay color based on the purchase status
    final Color overlayColor = isPurchased ? Colors.white : secondaryDarkColor.withOpacity(0.95);

    return GestureDetector(
      onTap: isPurchased ? null : () => _showPurchaseConfirmation(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500), // Longer duration for a noticeable reveal
        curve: Curves.elasticOut, // A fun, bouncy curve for the reveal
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPurchased ? primaryAppColor.withOpacity(0.5) : Colors.grey.shade300,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isPurchased ? 0.1 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- REVEALED CONTENT (BACK) ---
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Display the actual discount value
                Text(
                  '${coupon.discountValue.toInt()}%',
                  style: GoogleFonts.poppins(
                    color: primaryAppColor,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'OFFER VALID',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondaryDarkColor,
                  ),
                ),
                Text(
                  coupon.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
              ],
            ),

            // --- SCRATCH OVERLAY (FRONT) ---
            // This is the key to the 'scratch' effect. It covers the content when not purchased.
            if (!isPurchased)
              Container(
                decoration: BoxDecoration(
                  color: overlayColor,
                  borderRadius: BorderRadius.circular(18),
                  // Add a metallic or rough texture look with a subtle gradient
                  gradient: LinearGradient(
                    colors: [
                      secondaryDarkColor.withOpacity(0.9),
                      secondaryDarkColor.withOpacity(0.7),
                      secondaryDarkColor.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vpn_key_rounded, color: Colors.amber, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        'MYSTERY REWARD',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Purchase button inside the card for better visual grouping
                      ElevatedButton(
                        onPressed: () => _showPurchaseConfirmation(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAppColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          'BUY FOR 100 PTS',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
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