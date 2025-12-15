import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Mock Data Structures ---

enum OrderStatus { newOrder, preparing, readyForPickup, delivered, cancelled }

class Order {
  final String orderId;
  final String customerName;
  final double totalAmount;
  final String time;
  final OrderStatus status;

  Order({
    required this.orderId,
    required this.customerName,
    required this.totalAmount,
    required this.time,
    required this.status,
  });
}

// --- Main Widget ---

class OrdersManagementPage extends StatefulWidget {
  const OrdersManagementPage({super.key});

  @override
  State<OrdersManagementPage> createState() => _OrdersManagementPageState();
}

class _OrdersManagementPageState extends State<OrdersManagementPage> with SingleTickerProviderStateMixin {
  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightCardColor = const Color(0xFFFFFFFF);

  // Mock Orders Data
  List<Order> _allOrders = [
    Order(orderId: '#1001', customerName: 'Ritesh Varma', totalAmount: 450.00, time: '1 min ago', status: OrderStatus.newOrder),
    Order(orderId: '#1002', customerName: 'Anjali Desai', totalAmount: 890.50, time: '5 min ago', status: OrderStatus.preparing),
    Order(orderId: '#1003', customerName: 'Karan Singh', totalAmount: 120.00, time: '10 min ago', status: OrderStatus.readyForPickup),
    Order(orderId: '#1004', customerName: 'Priya Sharma', totalAmount: 335.75, time: '15 min ago', status: OrderStatus.newOrder),
    Order(orderId: '#1005', customerName: 'Mohit Patel', totalAmount: 600.00, time: '30 min ago', status: OrderStatus.preparing),
    Order(orderId: '#1006', customerName: 'Tanya Rao', totalAmount: 200.00, time: '1 hr ago', status: OrderStatus.delivered),
    Order(orderId: '#1007', customerName: 'Vivek K.', totalAmount: 150.00, time: '1 hr ago', status: OrderStatus.delivered),
    Order(orderId: '#1008', customerName: 'Neha A.', totalAmount: 50.00, time: '2 hr ago', status: OrderStatus.cancelled),
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper to filter orders based on the selected tab index
  List<Order> _getFilteredOrders(int tabIndex) {
    if (tabIndex == 0) {
      // 'All' tab
      return _allOrders.where((order) => order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled).toList();
    }

    final targetStatus = OrderStatus.values[tabIndex - 1]; // Offset index by 1 since tab 0 is 'All'
    return _allOrders.where((order) => order.status == targetStatus).toList();
  }

  // Function to map status to a readable string and color
  (String, Color) _getStatusDisplay(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return ('New Order', Colors.red.shade700);
      case OrderStatus.preparing:
        return ('Preparing', primaryAppColor);
      case OrderStatus.readyForPickup:
        return ('Ready for Pickup', Colors.blue.shade700);
      case OrderStatus.delivered:
        return ('Delivered', Colors.green.shade700);
      case OrderStatus.cancelled:
        return ('Cancelled', secondaryDarkColor.withOpacity(0.5));
    }
  }

  // Function to update order status (mock update)
  void _updateOrderStatus(String orderId, OrderStatus newStatus) {
    setState(() {
      final index = _allOrders.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        _allOrders[index] = Order(
          orderId: _allOrders[index].orderId,
          customerName: _allOrders[index].customerName,
          totalAmount: _allOrders[index].totalAmount,
          time: _allOrders[index].time,
          status: newStatus,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- 1. Tab Bar for Filtering ---
        Container(
          color: lightCardColor,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: primaryAppColor,
            labelColor: primaryAppColor,
            unselectedLabelColor: secondaryDarkColor.withOpacity(0.7),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15),
            tabs: const [
              Tab(text: 'All Active'),
              Tab(text: 'New Order'),
              Tab(text: 'Preparing'),
              Tab(text: 'Ready for Pickup'),
              Tab(text: 'Delivered'),
            ],
          ),
        ),

        // --- 2. Main Content (Order List) ---
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(
              5,
                  (index) => _buildOrderListView(index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderListView(int tabIndex) {
    final filteredOrders = _getFilteredOrders(tabIndex);

    if (filteredOrders.isEmpty) {
      return Center(
        child: Text(
          'No orders found for this status.',
          style: GoogleFonts.poppins(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(filteredOrders[index]);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    final (statusText, statusColor) = _getStatusDisplay(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID, Time, and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ${order.orderId}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: secondaryDarkColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Customer and Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: secondaryDarkColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placed ${order.time}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹ ${order.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryAppColor,
                  ),
                ),
              ],
            ),

            // Action Buttons (Only for active orders)
            if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // Primary Action Button (Next Status)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Determine the next status in the flow
                        final nextStatus = switch(order.status) {
                          OrderStatus.newOrder => OrderStatus.preparing,
                          OrderStatus.preparing => OrderStatus.readyForPickup,
                          OrderStatus.readyForPickup => OrderStatus.delivered,
                          _ => order.status, // Should not happen
                        };
                        _updateOrderStatus(order.orderId, nextStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAppColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        _getNextStatusButtonText(order.status),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Secondary Action Button (View Details)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        // Mock action for viewing order details
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Viewing details for Order ${order.orderId}')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Icon(Icons.description_outlined, color: Color(0xFF333333)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getNextStatusButtonText(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.newOrder:
        return 'Start Preparation';
      case OrderStatus.preparing:
        return 'Mark Ready for Pickup';
      case OrderStatus.readyForPickup:
        return 'Mark Delivered';
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return 'Order Complete';
    }
  }
}
