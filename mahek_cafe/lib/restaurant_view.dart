// lib/restaurant_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mahek_cafe/MahekCoffeeToast.dart';
import 'package:mahek_cafe/models/restaurant_model.dart';
import 'package:mahek_cafe/popular_meal_card.dart';
import 'restaurant_info_page.dart'; // Import the new info page

class RestaurantView extends StatelessWidget {
  final RestaurantData restaurant;

  const RestaurantView({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final Color primaryAppColor = const Color(0xFFF96D0A);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          restaurant.name,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryAppColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Info button to show restaurant details
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantInfoPage(restaurant: restaurant),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Restaurant Header Image
          Container(
            height: 200,
            width: double.infinity,
            child: restaurant.profileUrl != null
                ? CachedNetworkImage(
              imageUrl: restaurant.profileUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(color: Color(0xFFF96D0A))),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.restaurant, size: 60, color: Colors.grey[400]),
                ),
              ),
            )
                : Container(
              color: primaryAppColor.withOpacity(0.8),
              child: Center(
                child: Icon(Icons.restaurant, size: 60, color: Colors.white70),
              ),
            ),
          ),

          // Restaurant Basic Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Name
                Text(
                  restaurant.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: primaryAppColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Rating
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      '${restaurant.rating.toStringAsFixed(1)} / 5.0',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Business Hours
                if (restaurant.openTime != null && restaurant.closeTime != null)
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: Colors.orange[800], size: 16),
                      const SizedBox(width: 5),
                      Text(
                        '${restaurant.openTime!} - ${restaurant.closeTime!}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Products Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Our Menu',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                Text(
                  '${restaurant.name} Specials',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Products Grid - Wrapped with Expanded to ensure it takes available space
          Expanded(
            child: _buildProductsGrid(context),
          ),
        ],
      ),

      // Floating Action Button for Restaurant Info
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantInfoPage(restaurant: restaurant),
            ),
          );
        },
        backgroundColor: primaryAppColor,
        child: const Icon(Icons.info_outline_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildProductsGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('res_id', isEqualTo: restaurant.restaurant_id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF96D0A)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading products',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fastfood_outlined, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Products Available',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for menu updates',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!.docs;

        // Modified GridView with constraints to prevent overflow
        return LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.70, // You can adjust this if needed
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index].data() as Map<String, dynamic>;

                return Container(
                  // Constrain the card to prevent overflow
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight,
                  ),
                  child: PopularMealCard(
                    name: product['name'] ?? 'No Name',
                    rating: (product['rate'] as num?)?.toDouble() ?? 0.0,
                    price: (product['price'] as num?)?.toDouble() ?? 0.0,
                    description: product['description'] ?? 'No description available',
                    index: index,
                    imgUrl: product['img_url'] ?? '',
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}