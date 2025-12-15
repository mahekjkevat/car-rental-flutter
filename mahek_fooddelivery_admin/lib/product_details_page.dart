// file: lib/product_details_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_model.dart';
import 'admin_mahek_toast.dart';

// --- Colors ---
const Color primaryAppColor = Color(0xFFF96D0A);
const Color secondaryDarkColor = Color(0xFF333333);
const Color lightBackground = Color(0xFFFBFBFB);

class ProductDetailsPage extends StatelessWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  void _showEditPriceDialog(BuildContext context) {
    final TextEditingController priceController =
    TextEditingController(text: product.price.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Price',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: secondaryDarkColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Price (₹)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null && newPrice > 0) {
                await _updateProductPrice(context, newPrice);
                Navigator.pop(context);
              } else {
                AdminMahekToast.show(
                    context,
                    'Please enter a valid price',
                    ToastType.error
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAppColor,
            ),
            child: Text('Update', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProductPrice(BuildContext context, double newPrice) async {
    try {
      // Use the Firestore document ID (product.id) instead of productID field
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id) // Changed from product.productID to product.id
          .update({'price': newPrice});

      AdminMahekToast.show(
          context,
          'Price updated successfully!',
          ToastType.success
      );
    } catch (e) {
      AdminMahekToast.show(
          context,
          'Failed to update price: $e',
          ToastType.error
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Product',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, size: 50, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "${product.name}"?',
              style: GoogleFonts.poppins(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone!',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(BuildContext context) async {
    try {
      // Use the Firestore document ID (product.id) instead of productID field
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id) // Changed from product.productID to product.id
          .delete();

      AdminMahekToast.show(
          context,
          'Product deleted successfully!',
          ToastType.success
      );

      // Navigate back after successful deletion
      Navigator.pop(context);
    } catch (e) {
      AdminMahekToast.show(
          context,
          'Failed to delete product: $e',
          ToastType.error
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar with Back Button and Delete Icon
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: product.imgUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator(color: primaryAppColor)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                  ),
                ),
              ),
            ),
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _showDeleteConfirmation(context),
                  ),
                ),
              ),
            ],
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price with Edit Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: secondaryDarkColor,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: primaryAppColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: primaryAppColor.withOpacity(0.1),
                            child: IconButton(
                              icon: Icon(Icons.edit, size: 16, color: primaryAppColor),
                              onPressed: () => _showEditPriceDialog(context),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Rating and Type
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: product.rate.clamp(0.0, 5.0),
                        itemBuilder: (context, index) => const Icon(
                          Icons.star_rounded,
                          color: primaryAppColor,
                        ),
                        itemCount: 5,
                        itemSize: 24.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        product.rate.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: secondaryDarkColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryAppColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.type.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryAppColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Product IDs (Both Firestore ID and Custom Product ID)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.qr_code, color: primaryAppColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Product ID: ${product.productID}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: secondaryDarkColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Document ID: ${product.id}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Section
                  Text(
                    'Description',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: secondaryDarkColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      product.description,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: secondaryDarkColor.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Additional Details
                  _buildDetailRow('Category', product.type),
                  _buildDetailRow('Rating', '${product.rate.toStringAsFixed(1)}/5.0'),
                  _buildDetailRow('Price', '₹${product.price.toStringAsFixed(0)}'),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating Action Button for Edit
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditPriceDialog(context),
        icon: const Icon(Icons.edit_note),
        label: Text('Edit Price', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: primaryAppColor,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: secondaryDarkColor.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: secondaryDarkColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}