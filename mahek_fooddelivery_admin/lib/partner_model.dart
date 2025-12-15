// file: lib/models/partner_model.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DriverStatus {
  available,
  receiving,
  outForDelivery,
  offline,
}

class Partner {
  final String id;
  final String name;
  final String email;
  final String mobileNumber;
  final String city;
  final bool isApproved;
  final DateTime createdAt;
  final int ordersCompleted;
  final DriverStatus status;
  final String? vehicleType;
  final String? licenseNumber;
  final String? address;
  final double? rating;
  final int? totalEarnings;
  final String? profileImageUrl;

  Partner({
    required this.id,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.city,
    required this.isApproved,
    required this.createdAt,
    required this.ordersCompleted,
    required this.status,
    this.vehicleType,
    this.licenseNumber,
    this.address,
    this.rating,
    this.totalEarnings,
    this.profileImageUrl,
  });

  static DriverStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return DriverStatus.available;
      case 'receiving':
        return DriverStatus.receiving;
      case 'outfordelivery':
        return DriverStatus.outForDelivery;
      case 'offline':
        return DriverStatus.offline;
      default:
        return DriverStatus.available;
    }
  }

  factory Partner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    DateTime creationDate = DateTime(2000);
    if (data?['createdAt'] is Timestamp) {
      creationDate = (data!['createdAt'] as Timestamp).toDate();
    } else if (data?['createdAt'] is String) {
      creationDate = DateTime.tryParse(data!['createdAt'] as String) ?? DateTime(2000);
    }

    final String statusString = (data?['status'] as String?) ?? 'available';

    return Partner(
      id: doc.id,
      name: data?['name'] ?? 'N/A',
      email: data?['email'] ?? 'N/A',
      mobileNumber: data?['mobileNumber'] ?? 'N/A',
      city: data?['city'] ?? 'N/A',
      isApproved: data?['isApproved'] ?? false,
      createdAt: creationDate,
      ordersCompleted: data?['ordersCompleted'] is int ? data!['ordersCompleted'] : 0,
      status: _parseStatus(statusString),
      vehicleType: data?['vehicleType'],
      licenseNumber: data?['licenseNumber'],
      address: data?['address'],
      rating: data?['rating'] is double ? data!['rating'] : 0.0,
      totalEarnings: data?['totalEarnings'] is int ? data!['totalEarnings'] : 0,
      profileImageUrl: data?['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'city': city,
      'isApproved': isApproved,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'ordersCompleted': ordersCompleted,
      'status': status.name,
      'vehicleType': vehicleType,
      'licenseNumber': licenseNumber,
      'address': address,
      'rating': rating,
      'totalEarnings': totalEarnings,
      'profileImageUrl': profileImageUrl,
    };
  }

  String get formattedJoinDate => DateFormat('dd MMM yyyy').format(createdAt);
  String get formattedJoinDateTime => DateFormat('dd MMM yyyy, HH:mm').format(createdAt);

  String get statusText {
    switch (status) {
      case DriverStatus.available:
        return 'Available';
      case DriverStatus.receiving:
        return 'Receiving Order';
      case DriverStatus.outForDelivery:
        return 'Out for Delivery';
      case DriverStatus.offline:
        return 'Offline';
    }
  }

  Color get statusColor {
    switch (status) {
      case DriverStatus.available:
        return Colors.green;
      case DriverStatus.receiving:
        return Colors.blue;
      case DriverStatus.outForDelivery:
        return Colors.orange;
      case DriverStatus.offline:
        return Colors.red;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case DriverStatus.available:
        return Icons.directions_bike;
      case DriverStatus.receiving:
        return Icons.shopping_bag;
      case DriverStatus.outForDelivery:
        return Icons.delivery_dining;
      case DriverStatus.offline:
        return Icons.access_time;
    }
  }
}