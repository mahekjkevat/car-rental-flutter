// file: lib/products_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:appwrite/appwrite.dart';
// Import models and pages
import 'add_product_page.dart';
import 'product_model.dart';
import 'product_details_page.dart';

// --- Aesthetic Colors ---
const Color primaryAppColor = Color(0xFFF96D0A);
const Color secondaryDarkColor = Color(0xFF333333);
const Color lightBackground = Color(0xFFFBFBFB);
const Color cardColor = Color(0xFFFFFFFF);

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: secondaryDarkColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: CachedNetworkImage(
                  imageUrl: product.imgUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(color: primaryAppColor)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(Icons.broken_image, color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: secondaryDarkColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: primaryAppColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Rating Bar
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: product.rate.clamp(0.0, 5.0),
                        itemBuilder: (context, index) => const Icon(
                          Icons.star_rounded,
                          color: primaryAppColor,
                        ),
                        itemCount: 5,
                        itemSize: 18.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.rate.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: secondaryDarkColor.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    product.description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: secondaryDarkColor.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 1. Change ProductsPage to StatefulWidget
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  // 2. Add State Variables
  String _selectedCategory = 'All';
  // Stores {'name': 'Tea', 'type': 'tea'} from 'category' collection
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // 3. Implement Category Fetching
  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('category')
          .orderBy('name', descending: false)
          .get();

      final fetchedCategories = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? '',
          'type': data['type'] ?? '', // Use 'type' for filtering products
        };
      }).toList();

      // Ensure 'All' is the first option
      final categoriesWithAll = [
        {'name': 'All', 'type': 'All'},
        ...fetchedCategories,
      ];

      setState(() {
        _categories = categoriesWithAll;
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) {
        // Handle error if necessary
      }
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  // Helper method to build the horizontal scroll filter bar
  Widget _buildCategoryFilterBar() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: primaryAppColor),
        ),
      );
    }

    return Container(
      height: 50,
      color: cardColor, // White background for the bar
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category['name'] == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['name'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryAppColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryAppColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    category['name'], // Use the 'name' for the label
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? cardColor : secondaryDarkColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 6. Update the Stream to filter products
  Stream<QuerySnapshot> _getProductStream() {
    final CollectionReference productsCollection =
    FirebaseFirestore.instance.collection('products');

    // Convert the selected category name back into the 'type' field format
    // (e.g., 'Milk Shake' -> 'milk_shake') for filtering.
    final filterType = _selectedCategory.toLowerCase().replaceAll(' ', '_');

    if (_selectedCategory == 'All') {
      // Return all products
      return productsCollection.snapshots();
    } else {
      // Return filtered products
      // Note: We use the 'type' field from the category for the product document field name.
      return productsCollection
          .where('type', isEqualTo: filterType)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which product stream to use based on selected category
    // final CollectionReference productsCollection =
    //     FirebaseFirestore.instance.collection('products');

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'Our Menu',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: secondaryDarkColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: secondaryDarkColor),
      ),
      body: SafeArea(
        // 4. Use Column for Category Bar and GridView
        child: Column(
          children: [
            _buildCategoryFilterBar(), // Category filter bar at the top

            Expanded( // GridView takes the remaining space
              child: StreamBuilder<QuerySnapshot>(
                stream: _getProductStream(), // Use the conditional stream
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryAppColor),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading products: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    );
                  }

                  final products = snapshot.data!.docs
                      .map((doc) => Product.fromFirestore(doc))
                      .toList();

                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        'No products found in the "${_selectedCategory}" category.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 18, color: secondaryDarkColor.withOpacity(0.7)),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCard(product: products[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button to Add Product
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductPage(
                client: Client() // Add this client parameter
                    .setEndpoint('https://fra.cloud.appwrite.io/v1')
                    .setProject('68f2a01f00207f73a4d3'),
              ),
            ),
          );
        },
        label: Text('Add New Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
