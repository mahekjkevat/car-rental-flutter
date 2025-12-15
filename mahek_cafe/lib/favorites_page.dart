import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_detail_page.dart'; // Import the CoffeeDetailPage

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- Consistent Color Definitions ---

  final Color primaryBrown = const Color(0xFF6D4C41); // Rich Dark Brown
  final Color accentOrange = const Color(0xFFE65100); // Burnt Orange/Gold
  final Color lightBgColor = const Color(0xFFFAF7F5); // Very light brown/off-white
  final Color deleteRed = const Color(0xFFC62828); // Deep Red for delete actions
  final Color primaryAppColor = const Color(0xFFF96D0A); // Requested AppBar BG Color
  final Color secondaryDarkColor = const Color(0xFF212121);
  final Color lightBackground = const Color(0xFFF5F5F5);

  // Remove favorite from Firestore and refresh the list
  Future<void> _removeFavorite(String coffeeName) async {
    if (_currentUser == null) {
      // In a real app, this should trigger a login prompt or be handled upstream
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('Favourites')
        .doc(coffeeName); // Assuming coffeeName is the document ID

    await docRef.delete();
  }

  // Show confirmation dialog for removing favorite with themed styles
  void _showRemoveDialog(String coffeeName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: deleteRed, size: 40),
              const SizedBox(height: 16),
              Text(
                'Remove Favorite',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: primaryBrown,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to remove $coffeeName from your favorites?',
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
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: primaryBrown.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _removeFavorite(coffeeName); // Remove from Firestore
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$coffeeName removed from favorites',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: deleteRed,
                        ),
                      );
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

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: lightBackground,
        appBar: AppBar(
          title: Text(
            'My Favorites',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryAppColor,
          elevation: 4,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 80, color: accentOrange),
              const SizedBox(height: 16),
              Text(
                'Please sign in to view your favorites',
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Favorites',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: primaryBrown,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: lightBgColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('Favourites')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentOrange));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading favorites.',
                style: GoogleFonts.poppins(fontSize: 20, color: deleteRed),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(32),
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
                        Icons.favorite_border_rounded,
                        size: 80,
                        color: accentOrange.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Favorites Found!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the heart icon on a coffee to add it here.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final favoriteCoffees = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            itemCount: favoriteCoffees.length,
            itemBuilder: (context, index) {
              final coffee = favoriteCoffees[index].data() as Map<String, dynamic>;
              final coffeeName = coffee['name'] as String;

              return Dismissible(
                key: Key(coffeeName),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _removeFavorite(coffeeName); // Remove from Firestore
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$coffeeName removed from favorites',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: deleteRed,
                    ),
                  );
                },
                background: Container(
                  decoration: BoxDecoration(
                    color: deleteRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                child: _buildCoffeeCard(
                  context,
                  coffee['name'] as String,
                  coffee['rating'] as double,
                  coffee['price'] as double,
                  coffee['description'] as String,
                  coffee['imgUrl'] as String,
                  index,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to build an attractive coffee card with the new theme
  Widget _buildCoffeeCard(
      BuildContext context,
      String name,
      double rating,
      double price,
      String description,
      String imgUrl,
      int index,
      ) {
    return GestureDetector(
      onTap: () {
        // Navigate to CoffeeDetailPage with a Hero animation
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProductDetailPage(
                  name: name,
                  rating: rating,
                  price: price,
                  description: description,
                  heroTag: 'favorite-coffee-image-$index', // Unique Hero tag
                  imgUrl: imgUrl,
                ),
            transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
                ) {
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
          borderRadius: BorderRadius.circular(20), // Larger radius
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
            // Coffee image with Hero animation
            Hero(
              tag: 'favorite-coffee-image-$index', // Unique tag for Hero animation
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: CachedNetworkImage(
                  imageUrl: imgUrl,
                  height: 110,
                  width: 110,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(child: CircularProgressIndicator(color: accentOrange)),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/images/cofee.png', // Fallback
                    height: 110,
                    width: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Coffee details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryBrown, // Themed color
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: accentOrange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primaryBrown.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accentOrange, // Themed price color
                          ),
                        ),
                        // Explicit Delete Button (optional, but good for visibility)
                        GestureDetector(
                          onTap: () {
                            _showRemoveDialog(name); // Show remove dialog
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: deleteRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.remove_circle,
                              color: deleteRed,
                              size: 24,
                            ),
                          ),
                        ),
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