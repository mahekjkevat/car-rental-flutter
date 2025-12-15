import 'package:cloud_firestore/cloud_firestore.dart';

// --- Main User Model ---
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone; // 'mobile' in Firestore document is mapped here
  final DateTime createdAt; // 'createdAt' in Firestore document is mapped here

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
  });

  // Factory constructor to create an AppUser from a Firestore DocumentSnapshot
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // Safely parse the 'createdAt' Timestamp
    DateTime creationDate = DateTime(2000);
    if (data?['createdAt'] is Timestamp) {
      creationDate = (data!['createdAt'] as Timestamp).toDate();
    }

    return AppUser(
      id: doc.id,
      name: data?['name'] ?? 'N/A',
      email: data?['email'] ?? 'N/A',
      // Assuming phone/mobile is stored under 'mobile' or 'phone' field
      phone: data?['mobile'] ?? data?['phone'] ?? 'N/A',
      createdAt: creationDate,
    );
  }
}

// --- Address Model ---
class UserAddress {
  final String id;
  final String name;
  final String fullAddress; // Combines address, cityUrban, pincode

  UserAddress({required this.id, required this.name, required this.fullAddress});

  factory UserAddress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final address = data?['address'] ?? '';
    final city = data?['cityUrban'] ?? '';
    final pincode = data?['pincode'] ?? '';

    return UserAddress(
      id: doc.id,
      name: data?['name'] ?? 'N/A',
      fullAddress: '$address, $city, $pincode',
    );
  }
}

// --- Order Item Model (for subcollection) ---
class UserOrder {
  final String id;
  final double totalPrice;
  final String status;
  final String itemSummary; // Example: 2x Masala Chai

  UserOrder({required this.id, required this.totalPrice, required this.status, required this.itemSummary});

  factory UserOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    // Assuming 'quantity' and 'name' are present in the order document for a summary
    final quantity = (data?['quantity'] as num?)?.toInt() ?? 0;
    final name = data?['name'] ?? 'Item';

    return UserOrder(
      id: doc.id,
      totalPrice: (data?['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data?['status'] ?? 'Unknown',
      itemSummary: '$quantity x $name',
    );
  }
}

// --- Cart Item Model ---
class CartItem {
  final String id;
  final String name;
  final int quantity;
  final double price;

  CartItem({required this.id, required this.name, required this.quantity, required this.price});

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return CartItem(
      id: doc.id,
      name: data?['name'] ?? 'N/A',
      quantity: (data?['quantity'] as num?)?.toInt() ?? 0,
      price: (data?['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}