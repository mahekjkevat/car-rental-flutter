// lib/restaurant_card_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/restaurant_model.dart';
import 'restaurant_view.dart';
import 'MahekCoffeeToast.dart';

final Color primaryAppColor = const Color(0xFFF96D0A);

class RestaurantCardView extends StatelessWidget {
  final RestaurantData restaurant;

  const RestaurantCardView({super.key, required this.restaurant});

  Widget _buildRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    List<Widget> stars = [];

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(const Icon(Icons.star_rounded, color: Colors.amber, size: 17));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(const Icon(Icons.star_half_rounded, color: Colors.amber, size: 17));
      } else {
        stars.add(Icon(Icons.star_border_rounded, color: Colors.grey.shade400, size: 17));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // FIX: Pass context to MahekCoffeeToast.show
        MahekCoffeeToast.show(context, 'Opening details for ${restaurant.name}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantView(restaurant: restaurant),
          ),
        );
      },
      child: Container(
        width: 220, // Fixed width for horizontal scrolling
        margin: const EdgeInsets.only(right: 15, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Landscape Photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: restaurant.profileUrl != null
                  ? CachedNetworkImage(
                imageUrl: restaurant.profileUrl!,
                height: 150, // Landscape height
                width: 220,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400])),
                ),
              )
                  : Container(
                height: 120,
                width: 250,
                color: primaryAppColor.withOpacity(0.8),
                child: Center(child: Icon(Icons.restaurant, size: 40, color: Colors.white70)),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name
                  Text(
                    restaurant.name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryAppColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Open and Close Time
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[600], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.openTime ?? 'N/A'} - ${restaurant.closeTime ?? 'N/A'}',
                        style: GoogleFonts.poppins(fontSize: 15, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Rating
                  _buildRating(restaurant.rating),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HorizontalRestaurantList extends StatelessWidget {
  const HorizontalRestaurantList({super.key});

  // Fetches all approved restaurants from Firestore
  Future<List<RestaurantData>> _fetchRestaurants(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('isApproved', isEqualTo: true) // Filter for approved restaurants
          .get();

      return snapshot.docs.map((doc) => RestaurantData.fromFirestore(doc)).toList();
    } catch (e) {
      // FIX: Pass context to MahekCoffeeToast.show
      MahekCoffeeToast.show(context, 'Error fetching restaurants: $e', isError: true);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RestaurantData>>(
      // FIX: Pass context to _fetchRestaurants
      future: _fetchRestaurants(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
        }

        final restaurants = snapshot.data ?? [];

        if (restaurants.isEmpty) {
          return Center(
            child: Text(
              'No approved restaurants found.',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }

        // Display the horizontal list
        return SizedBox(
          height: 250, // Set a fixed height for the horizontal list view
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              return RestaurantCardView(restaurant: restaurants[index]);
            },
          ),
        );
      },
    );
  }
}