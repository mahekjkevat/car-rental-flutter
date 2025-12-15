import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'cart_summary_page.dart';
import 'home_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  // --- Consistent Color Definitions ---
  final Color primaryBrown = const Color(0xFF6D4C41); // Rich Dark Brown
  final Color accentOrange = const Color(0xFFE65100); // Burnt Orange/Gold
  final Color lightBgColor = const Color(0xFFFAF7F5); // Very light brown/off-white
  final Color deleteRed = const Color(0xFFC62828); // Deep Red for delete actions
  final Color primaryAppColor = const Color(0xFFF96D0A); // Requested AppBar BG Color
  final Color secondaryDarkColor = const Color(0xFF212121);
  final Color lightBackground = const Color(0xFFF5F5F5);

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchCartItems() async {
    if (_currentUser == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('addToCart')
        .get();

    return snapshot.docs
        .map((doc) => {'docId': doc.id, ...doc.data()})
        .toList();
  }

  Future<void> _updateQuantity(String docId, int newQuantity) async {
    if (_currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('addToCart')
        .doc(docId)
        .update({
      'quantity': newQuantity,
      'timestamp': FieldValue.serverTimestamp(),
    });

    Fluttertoast.showToast(
      msg: 'Quantity updated!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: primaryBrown,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _deleteItem(String docId, String itemName) async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('addToCart')
          .doc(docId)
          .delete();

      Fluttertoast.showToast(
        msg: '$itemName removed!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: deleteRed,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      setState(() {}); // Refresh the UI
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error removing item: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _clearCart() async {
    if (_currentUser == null) return;

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('addToCart')
          .get();

      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      Fluttertoast.showToast(
        msg: 'Cart cleared!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: primaryBrown,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      setState(() {}); // Refresh the UI
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error clearing cart: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _showDeleteConfirmationDialog(String docId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: deleteRed, size: 40),
              const SizedBox(height: 16),
              Text(
                'Remove Item',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: primaryBrown,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to remove $itemName from your cart?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteItem(docId, itemName);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deleteRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'Remove',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCartSummaryPage(List<Map<String, dynamic>> cartItems, double total) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartSummaryPage(
          cartItems: cartItems,
          total: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'My Food',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryAppColor,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCartItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: accentOrange),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 800),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBrown.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_cafe_outlined,
                        size: 100,
                        color: primaryBrown.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your Cart is Empty!',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Explore our menu and add some delicious items!',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentOrange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: accentOrange.withOpacity(0.5),
                        ),
                        child: Text(
                          'Shop Now',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final cartItems = snapshot.data!;
          final double subtotal = cartItems.fold(
            0,
                (sum, item) => sum + (item['price'] * item['quantity']),
          );
          const double taxRate = 0.05;
          final double tax = subtotal * taxRate;
          final double total = subtotal + tax;

          return Stack(
            children: [
              // --- Cart Item List ---
              ListView.builder(
                padding: const EdgeInsets.all(20).copyWith(bottom: 220),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          (index / cartItems.length) * 0.5,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBrown.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: accentOrange.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: item['imgUrl'],
                                height: 90,
                                width: 90,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: primaryBrown,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    Image.asset(
                                      'assets/images/coffee.png', // Fallback
                                      height: 90,
                                      width: 90,
                                      fit: BoxFit.cover,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Details and Quantity Controls
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: primaryBrown,
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                  // Quantity Controls
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: item['quantity'] > 1 ? accentOrange : Colors.grey,
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          if (item['quantity'] > 1) {
                                            _updateQuantity(
                                              item['docId'],
                                              item['quantity'] - 1,
                                            );
                                            setState(() {
                                              item['quantity']--;
                                            });
                                          }
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          '${item['quantity']}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: primaryBrown,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.add_circle,
                                          color: item['quantity'] < 10 ? accentOrange : Colors.grey,
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          if (item['quantity'] < 10) {
                                            _updateQuantity(
                                              item['docId'],
                                              item['quantity'] + 1,
                                            );
                                            setState(() {
                                              item['quantity']++;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Price and Delete Button
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: accentOrange,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_forever_rounded,
                                    color: deleteRed,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(
                                      item['docId'],
                                      item['name'],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // --- Bottom Summary and Checkout ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBrown.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        'Subtotal',
                        '₹${subtotal.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'Tax (5%)',
                        '₹${tax.toStringAsFixed(2)}',
                      ),
                      const Divider(
                        height: 28,
                        thickness: 1.5,
                        color: Colors.grey,
                      ),
                      _buildSummaryRow(
                        'Total',
                        '₹${total.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          // Checkout Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _showCartSummaryPage(cartItems, total);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentOrange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                                shadowColor: accentOrange.withOpacity(0.6),
                              ),
                              child: Text(
                                'CheckOut',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Clear Cart Button
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.delete_sweep_rounded,
                                          color: deleteRed,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Clear Cart',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: primaryBrown,
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Are you sure you want to clear all items from your cart?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.grey[700],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text(
                                                'Cancel',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey[600],
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _clearCart();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: deleteRed,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 10,
                                                ),
                                                elevation: 3,
                                              ),
                                              child: Text(
                                                'Clear',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: deleteRed,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: const Icon(
                              Icons.delete_sweep_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? primaryBrown : primaryBrown.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? accentOrange : primaryBrown,
          ),
        ),
      ],
    );
  }
}
