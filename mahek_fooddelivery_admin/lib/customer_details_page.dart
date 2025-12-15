import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'customer_models.dart';


// --- Data Models for Subcollections (based on your provided data) ---

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

class UserOrder {
  final String id;
  final double totalPrice;
  final String status;
  final String itemSummary; // Example: 2x Masala Chai

  UserOrder({required this.id, required this.totalPrice, required this.status, required this.itemSummary});

  factory UserOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
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

// --- Customer Details Page Widget ---

class CustomerDetailsPage extends StatelessWidget {
  final AppUser user;
  final Color primaryAppColor = const Color(0xFFF96D0A);

  const CustomerDetailsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          user.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: primaryAppColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),

            // Personal/Contact Information
            _buildInfoSection(
              title: 'Personal & Contact Info',
              icon: Icons.person_outline,
              children: [
                _buildInfoRow(Icons.email_outlined, 'Email', user.email),
                _buildInfoRow(Icons.phone_android, 'Mobile', user.phone),
                _buildInfoRow(
                  Icons.event_note,
                  'Joined Date',
                  DateFormat('dd MMM yyyy').format(user.createdAt),
                ),
                _buildInfoRow(Icons.vpn_key_outlined, 'Auth ID', user.id),
              ],
            ),
            const SizedBox(height: 20),

            // Dynamic Data Sections
            _buildAddressesSection(),
            const SizedBox(height: 20),
            _buildOrdersSection(),
            const SizedBox(height: 20),
            _buildCartSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: primaryAppColor.withOpacity(0.1),
              child: Icon(Icons.person, size: 35, color: primaryAppColor),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Info row with +2 size increase and left icon (consistent with partner page request)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primaryAppColor.withOpacity(0.8)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16, // +2 size
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: SelectableText( // Use SelectableText for Auth ID and Email/Phone
              value,
              style: GoogleFonts.poppins(
                fontSize: 16, // +2 size
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Generic card section header
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: primaryAppColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // Dynamic Section: Addresses
  Widget _buildAddressesSection() {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('Address')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserAddress.fromFirestore).toList());

    return StreamBuilder<List<UserAddress>>(
      stream: stream,
      builder: (context, snapshot) {
        final addresses = snapshot.data ?? [];
        return _buildInfoSection(
          title: 'Saved Addresses (${addresses.length})',
          icon: Icons.location_on_outlined,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: LinearProgressIndicator()),
            if (snapshot.hasError)
              Text('Error fetching addresses: ${snapshot.error}', style: GoogleFonts.poppins(color: Colors.red)),
            if (addresses.isEmpty && !snapshot.hasError && snapshot.connectionState != ConnectionState.waiting)
              Text('No saved addresses found.', style: GoogleFonts.poppins(color: Colors.grey)),

            ...addresses.take(3).map((addr) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                '• ${addr.fullAddress} (${addr.name})',
                style: GoogleFonts.poppins(fontSize: 15),
              ),
            )),
            if (addresses.length > 3)
              Text(
                'and ${addresses.length - 3} more...',
                style: GoogleFonts.poppins(fontSize: 14, color: primaryAppColor),
              ),
          ],
        );
      },
    );
  }

  // Dynamic Section: Orders
  Widget _buildOrdersSection() {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('orders')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserOrder.fromFirestore).toList());

    return StreamBuilder<List<UserOrder>>(
      stream: stream,
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final totalOrders = orders.length;
        final totalSpent = orders.fold(0.0, (sum, order) => sum + order.totalPrice);

        return _buildInfoSection(
          title: 'Order History (${totalOrders})',
          icon: Icons.shopping_bag_outlined,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: LinearProgressIndicator()),
            if (snapshot.hasError)
              Text('Error fetching orders: ${snapshot.error}', style: GoogleFonts.poppins(color: Colors.red)),
            if (orders.isEmpty && !snapshot.hasError && snapshot.connectionState != ConnectionState.waiting)
              Text('No orders found.', style: GoogleFonts.poppins(color: Colors.grey)),

            if (totalOrders > 0) ...[
              _buildStatRow(Icons.monetization_on_outlined, 'Total Spent', '₹${totalSpent.toStringAsFixed(2)}', Colors.green),
              _buildStatRow(Icons.local_shipping_outlined, 'Orders Processing', orders.where((o) => o.status == 'Processing').length.toString(), Colors.orange),
              _buildStatRow(Icons.check_circle_outline, 'Latest Item', orders.first.itemSummary, Colors.blue),
            ],
          ],
        );
      },
    );
  }

  // Dynamic Section: Cart Items
  Widget _buildCartSection() {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('addToCart')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CartItem.fromFirestore).toList());

    return StreamBuilder<List<CartItem>>(
      stream: stream,
      builder: (context, snapshot) {
        final cartItems = snapshot.data ?? [];
        final totalItems = cartItems.length;
        final totalCartValue = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

        return _buildInfoSection(
          title: 'Current Cart (${totalItems})',
          icon: Icons.shopping_cart_outlined,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: LinearProgressIndicator()),
            if (snapshot.hasError)
              Text('Error fetching cart: ${snapshot.error}', style: GoogleFonts.poppins(color: Colors.red)),
            if (cartItems.isEmpty && !snapshot.hasError && snapshot.connectionState != ConnectionState.waiting)
              Text('Cart is empty.', style: GoogleFonts.poppins(color: Colors.grey)),

            if (totalItems > 0) ...[
              _buildStatRow(Icons.price_change, 'Est. Cart Value', '₹${totalCartValue.toStringAsFixed(2)}', Colors.purple),
              _buildStatRow(Icons.production_quantity_limits, 'Unique Items', totalItems.toString(), Colors.blue),
              Text(
                'Top Item: ${cartItems.first.quantity}x ${cartItems.first.name}',
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade800),
              ),
            ]
          ],
        );
      },
    );
  }

  // Helper for displaying a key statistic within the sections
  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}