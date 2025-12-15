// file: lib/popular_meal_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mahek_cafe/product_detail_page.dart';

class PopularMealCard extends StatelessWidget {
  final String name;
  final double rating;
  final double price;
  final String description;
  final int index;
  final String imgUrl;

  // Aesthetic Colors - UPGRADED for better contrast and depth
  final Color primaryAppColor = const Color(0xFFE65100); // Darker, richer Orange
  final Color secondaryDarkColor = const Color(0xFF212121); // Almost black for high contrast
  final Color lightBackground = const Color(0xFFFBFBFB);

  const PopularMealCard({
    super.key,
    required this.name,
    required this.rating,
    required this.price,
    required this.description,
    required this.index,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the unique tag for the Hero animation
    final String heroTag = 'product-image-$index';

    return GestureDetector(
      onTap: () {
        // Navigation logic
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => ProductDetailPage(
              name: name,
              rating: rating,
              price: price,
              description: description,
              heroTag: heroTag,
              imgUrl: imgUrl,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: lightBackground, // Use a very light background color
          borderRadius: BorderRadius.circular(25), // More rounded corners
          boxShadow: [
            BoxShadow(
              // Deeper, softer shadow for a floating effect
              color: secondaryDarkColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Product Image (Top Section)
                Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: imgUrl,
                      height: 140, // Slightly taller image area
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(color: primaryAppColor.withOpacity(0.5)),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.fastfood_outlined,
                        color: secondaryDarkColor.withOpacity(0.5),
                        size: 40,
                      ),
                    ),
                  ),
                ),

                // 2. Product Details (Middle Section)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 17, // Increased font size for importance
                          fontWeight: FontWeight.w800, // Extra bold
                          color: secondaryDarkColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Subtitle/Brief Info
                      Text(
                        'Fast, Fresh & Flavorful',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Price and Add Button Placeholder
                const Spacer(), // Pushes everything above it up

                // 3. Price and Add Button (Bottom Section)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 0, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        '₹${price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 20, // Prominent price
                          fontWeight: FontWeight.w900,
                          color: primaryAppColor,
                        ),
                      ),

                      // Add Button (Modern Corner Design)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: primaryAppColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15), // Smooth edge transition
                            bottomRight: Radius.circular(25), // Matches card corner
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryAppColor.withOpacity(0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 4. Rating Pill
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryAppColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Favorite Button
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  // Implement favorite toggle logic
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85), // Semi-transparent white
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: secondaryDarkColor.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    color: Colors.red.shade400,
                    size: 20,
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