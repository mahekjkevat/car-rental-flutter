// lib/restaurant_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Restaurant {
  final String id;

  final String resId;
  final String status;

  final String name;
  final String email;
  final String phone;
  final String address;
  final String city;
  final double rating;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;

  // Performance Metrics (usually fetched separately or aggregated)
  final int totalOrders;
  final double totalRevenue;
  final double commissionRate; // e.g., 0.15 for 15%

  Restaurant({
    required this.id,
    required this.resId,
    required this.status,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.rating,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    required this.totalOrders,
    required this.totalRevenue,
    required this.commissionRate,
  });

  // Helper getters for display
  String get formattedJoinDate => DateFormat('dd MMM yyyy').format(createdAt);

  String get commissionRateText => '${(commissionRate * 100).toStringAsFixed(0)}%';

  Color get statusColor => isApproved ? Colors.green : Colors.orange;

  String get statusText => isApproved ? 'Approved' : 'Pending';

  // Factory constructor to map a Firestore DocumentSnapshot to a Restaurant object
  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    DateTime creationDate = DateTime(2000);
    if (data?['createdAt'] is Timestamp) {
      creationDate = (data!['createdAt'] as Timestamp).toDate();
    }
  // for updatedAt
    DateTime updateDate = DateTime(2000);
    if (data?['updatedAt'] is Timestamp) {
      updateDate = (data!['updatedAt'] as Timestamp).toDate();
    }
    return Restaurant(
      id: doc.id,
      resId: data?['res_id'] ?? 'N/A',
      status: data?['status'] ?? 'N/A',
      name: data?['name'] ?? 'N/A',
      email: data?['email'] ?? 'N/A',
      phone: data?['phone'] ?? data?['mobile'] ?? 'N/A',
      address: data?['address'] ?? 'Not set',
      city: data?['city'] ?? 'N/A',
      rating: (data?['rating'] as num?)?.toDouble() ?? 0.0,
      isApproved: data?['isApproved'] ?? false,
      createdAt: creationDate,
      updatedAt: updateDate,
      imageUrl: data?['imageUrl'],

      // Dummy/Placeholder for performance metrics if not directly in doc
      totalOrders: data?['totalOrders'] ?? 0,
      totalRevenue: (data?['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      commissionRate: (data?['commissionRate'] as num?)?.toDouble() ?? 0.15,
    );
  }
}

// --- Dummy Data for immediate testing ---
final dummyRestaurant = Restaurant(
  id: 'RST-987654',
  resId: 'RST-987654',
  status: 'Approved',
  name: 'The Golden Spoon',
  email: 'golden.spoon@example.com',
  phone: '+91 99887 76655',
  address: 'Shop 10, City Central Mall, B Block',
  city: 'Mumbai',
  rating: 4.6,
  isApproved: true,
  createdAt: DateTime.now().subtract(const Duration(days: 150)),
  updatedAt: DateTime.now(),
  imageUrl: 'https://via.placeholder.com/150', // Replace with a real image URL
  totalOrders: 2450,
  totalRevenue: 750000.00,
  commissionRate: 0.18,
);