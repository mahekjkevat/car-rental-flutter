import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahek_cafe/EmailDemoScreen.dart';
import 'package:mahek_cafe/product_search_filter_page.dart';
import 'app_information_page.dart';
import 'home_page_body.dart';
import 'favorites_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';
import 'cart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // --- Consistent Color Definitions ---
  final Color primaryBrown = const Color(0xFF6D4C41); // Rich Dark Brown
  final Color accentOrange = const Color(0xFFE65100); // Burnt Orange/Gold
  final Color lightBgColor = const Color(0xFFFAF7F5); // Very light brown/off-white

  final List<Widget> _pages = [
    const HomePageBody(),
    const FavoritesPage(),
    const CartPage(),
    const OrdersPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  Stream<int> _getCartItemCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addToCart')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Helper method to build a custom item with a circular indicator
  Widget _buildCustomNavItem(int index, IconData icon, String label, int cartCount) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? primaryBrown.withOpacity(0.9) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? lightBgColor : primaryBrown.withOpacity(0.7),
                  size: 26,
                ),
                // Cart Badge Logic
                if (index == 2 && cartCount > 0)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '$cartCount',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? primaryBrown : primaryBrown.withOpacity(0.7),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBgColor,

      // --- Clean Themed AppBar ---
      appBar: AppBar(
        backgroundColor: lightBgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AppInformationPage()),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/app_icon.jpeg',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mahek Food Delivery',
                    style: GoogleFonts.yaldevi(
                      fontSize: 22, // Increased font size
                      fontWeight: FontWeight.bold,
                      color: primaryBrown,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    'Fresh. Fast. Flavorful.',
                    style: GoogleFonts.poppins(
                      fontSize: 14, // Slightly larger tagline
                      fontWeight: FontWeight.w500,
                      color: primaryBrown.withOpacity(0.65),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: accentOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.search, color: accentOrange, size: 26),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProductSearchFilterPage()),
                    );
                  },
                  splashRadius: 24,
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: primaryBrown.withOpacity(0.3),
          ),
        ),
      ),

      // --- Body with Animations ---
      body: Container(
        color: lightBgColor,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _pages[_selectedIndex],
          ),
        ),
      ),

      // --- New Custom Bottom Navigation Bar UI ---
      bottomNavigationBar: SafeArea(
        child: StreamBuilder<int>(
          stream: _getCartItemCount(),
          builder: (context, snapshot) {
            final cartCount = snapshot.data ?? 0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCustomNavItem(0, Icons.home_rounded, 'Home', cartCount),
                  _buildCustomNavItem(1, Icons.favorite_border_rounded, 'Favs', cartCount),
                  _buildCustomNavItem(2, Icons.shopping_cart_outlined, 'Food', cartCount),
                  _buildCustomNavItem(3, Icons.receipt_outlined, 'Orders', cartCount),
                  _buildCustomNavItem(4, Icons.person_outline_rounded, 'Profile', cartCount),
                ],
              ),
            );

          },
        ),
      ),
    );
  }
}