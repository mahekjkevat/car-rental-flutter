// lib/models/restaurant_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantData {
  // Editable fields
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? profileUrl;

  //Fields for Business Hours
  final String? openTime;
  final String? closeTime;

  // NEW: Rating field
  final double rating;

  // Read-only/Metadata fields
  final String documentPath;
  final String resId;
  final bool isApproved;
  final String status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  final String restaurant_id;

  RestaurantData({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.profileUrl,
    this.openTime,
    this.closeTime,
    required this.rating, // NEW: Added to constructor
    required this.documentPath,
    required this.resId,
    required this.isApproved,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.restaurant_id,
  });

  // Factory constructor to create a RestaurantData object from a Firestore DocumentSnapshot
  factory RestaurantData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Ensure rating is treated as a double, defaulting to 0.0
    double restaurantRating = 0.0;
    if (data.containsKey('rating')) {
      if (data['rating'] is int) {
        restaurantRating = (data['rating'] as int).toDouble();
      } else if (data['rating'] is double) {
        restaurantRating = data['rating'] as double;
      }
    }

    return RestaurantData(
      documentPath: doc.reference.path,
      address: data['address'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
      email: data['email'] ?? '',
      isApproved: data['isApproved'] ?? false,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      resId: data['res_id'] ?? '',
      status: data['status'] ?? 'pending',
      updatedAt: data['updatedAt'] as Timestamp,
      profileUrl: data['profile_url'] as String?,
      openTime: data['open_time'] as String?,
      closeTime: data['close_time'] as String?,
      rating: restaurantRating, // NEW: Assign parsed rating
      restaurant_id: data['res_id'] ?? '',
    );
  }
}