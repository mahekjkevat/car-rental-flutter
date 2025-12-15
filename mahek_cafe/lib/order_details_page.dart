import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:fluttertoast/fluttertoast.dart'; // For Toast notifications
import 'package:intl/intl.dart'; // For formatting timestamp
import 'package:order_tracker_zen/order_tracker_zen.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import 'CheckMyOrder.dart';
import 'order_model.dart'; // Assuming this file exists for navigation

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  const OrderDetailsPage({
    super.key,
    required this.order,
  });

  // --- Consistent Color Definitions for Theming (Enhanced for clarity) ---
  final Color primaryBrown = const Color(0xFF6D4C41); // Rich Dark Brown
  final Color accentOrange = const Color(0xFFE65100); // Burnt Orange/Gold
  final Color lightBgColor = const Color(0xFFF9F9F9); // Lighter background
  final Color cardColor = Colors.white; // Pure white for card background
  final Color detailLabelColor = const Color(0xFF8D8D8D); // Subtle gray for labels

  // Function to copy text to clipboard
  void _copyToClipboard(BuildContext context, String text, String fieldName) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      Fluttertoast.showToast(
        msg: "✓ $fieldName copied to clipboard!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: primaryBrown.withOpacity(0.95),
        textColor: Colors.white,
        fontSize: 14.0,
      );
    });
  }

  // Convert timeline to TrackerData
  List<TrackerData> _getTrackerStatus() {
    List<TrackerData> trackerData = [];

    // Default statuses based on order status
    if (order.status == 'Delivered') {
      trackerData = [
        TrackerData(
          title: "Order Placed",
          date: _formatDate(order.timestamp),
          tracker_details: [
            TrackerDetails(
              title: "Your order was placed successfully",
              datetime: _formatDateTime(order.timestamp),
            ),
          ],
        ),
        TrackerData(
          title: "Order Prepared",
          date: _getEstimatedDate(order.timestamp, hours: 1),
          tracker_details: [
            TrackerDetails(
              title: "Your order is being prepared",
              datetime: _getEstimatedDateTime(order.timestamp, hours: 1),
            ),
          ],
        ),
        TrackerData(
          title: "Out for Delivery",
          date: _getEstimatedDate(order.timestamp, hours: 2),
          tracker_details: [
            TrackerDetails(
              title: "Your order is out for delivery",
              datetime: _getEstimatedDateTime(order.timestamp, hours: 2),
            ),
          ],
        ),
        TrackerData(
          title: "Delivered",
          date: _getEstimatedDate(order.timestamp, hours: 3),
          tracker_details: [
            TrackerDetails(
              title: "Your order has been delivered successfully",
              datetime: _getEstimatedDateTime(order.timestamp, hours: 3),
            ),
          ],
        ),
      ];
    } else if (order.status == 'Out for Delivery') {
      trackerData = [
        TrackerData(
          title: "Order Placed",
          date: _formatDate(order.timestamp),
          tracker_details: [
            TrackerDetails(
              title: "Your order was placed successfully",
              datetime: _formatDateTime(order.timestamp),
            ),
          ],
        ),
        TrackerData(
          title: "Order Prepared",
          date: _getEstimatedDate(order.timestamp, hours: 1),
          tracker_details: [
            TrackerDetails(
              title: "Your order is being prepared",
              datetime: _getEstimatedDateTime(order.timestamp, hours: 1),
            ),
          ],
        ),
        TrackerData(
          title: "Out for Delivery",
          date: _formatDate(DateTime.now()),
          tracker_details: [
            TrackerDetails(
              title: "Your order is out for delivery",
              datetime: _formatDateTime(DateTime.now()),
            ),
          ],
        ),
        TrackerData(
          title: "Delivered",
          date: "Expected soon",
          tracker_details: [
            TrackerDetails(
              title: "Your order will be delivered shortly",
              datetime: "Waiting for delivery",
            ),
          ],
        ),
      ];
    } else if (order.status == 'Processing') {
      trackerData = [
        TrackerData(
          title: "Order Placed",
          date: _formatDate(order.timestamp),
          tracker_details: [
            TrackerDetails(
              title: "Your order was placed successfully",
              datetime: _formatDateTime(order.timestamp),
            ),
          ],
        ),
        TrackerData(
          title: "Processing",
          date: "In progress",
          tracker_details: [
            TrackerDetails(
              title: "We are preparing your order",
              datetime: "Currently processing",
            ),
          ],
        ),
        TrackerData(
          title: "Prepared",
          date: "Upcoming",
          tracker_details: [
            TrackerDetails(
              title: "Your order will be prepared soon",
              datetime: "Waiting for preparation",
            ),
          ],
        ),
        TrackerData(
          title: "Delivery",
          date: "Upcoming",
          tracker_details: [
            TrackerDetails(
              title: "Delivery will start after preparation",
              datetime: "Not yet started",
            ),
          ],
        ),
      ];
    } else if (order.status == 'Cancelled') {
      trackerData = [
        TrackerData(
          title: "Order Placed",
          date: _formatDate(order.timestamp),
          tracker_details: [
            TrackerDetails(
              title: "Your order was placed successfully",
              datetime: _formatDateTime(order.timestamp),
            ),
          ],
        ),
        TrackerData(
          title: "Cancelled",
          date: _formatDate(DateTime.now()),
          tracker_details: [
            TrackerDetails(
              title: "Your order has been cancelled",
              datetime: _formatDateTime(DateTime.now()),
            ),
          ],
        ),
      ];
    } else {
      // Fallback for other statuses
      trackerData = [
        TrackerData(
          title: "Order Placed",
          date: _formatDate(order.timestamp),
          tracker_details: [
            TrackerDetails(
              title: "Your order was placed successfully",
              datetime: _formatDateTime(order.timestamp),
            ),
          ],
        ),
        TrackerData(
          title: order.status,
          date: "Current status",
          tracker_details: [
            TrackerDetails(
              title: "Your order is currently: ${order.status}",
              datetime: "In progress",
            ),
          ],
        ),
      ];
    }

    // Use actual timeline data if available
    if (order.timeline.isNotEmpty) {
      trackerData = order.timeline.map((timelineItem) {
        final status = timelineItem['status'] ?? 'Unknown';
        final time = timelineItem['time'] != null
            ? DateTime.parse(timelineItem['time'])
            : order.timestamp;

        return TrackerData(
          title: status,
          date: _formatDate(time),
          tracker_details: [
            TrackerDetails(
              title: "Status: $status",
              datetime: _formatDateTime(time),
            ),
          ],
        );
      }).toList();
    }

    return trackerData;
  }

  String _formatDate(DateTime date) {
    return DateFormat("EEE, d MMM ''yy").format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat("EEE, d MMM ''yy - HH:mm").format(date);
  }

  String _getEstimatedDate(DateTime baseDate, {int hours = 0}) {
    final estimatedDate = baseDate.add(Duration(hours: hours));
    return _formatDate(estimatedDate);
  }

  String _getEstimatedDateTime(DateTime baseDate, {int hours = 0}) {
    final estimatedDate = baseDate.add(Duration(hours: hours));
    return _formatDateTime(estimatedDate);
  }

  // Helper widget to display a single detail row
  Widget _DetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBoldValue = false,
    bool isAddress = false,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Label
          SizedBox(
            width: 140, // Wider container to accommodate icon and label
            child: Row(
              children: [
                Icon(icon, size: 18, color: primaryBrown.withOpacity(0.5)), // Smaller, subtler icon
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 14, color: detailLabelColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Value and Copy Icon
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5, // Slightly larger font for value
                      fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
                      color: valueColor ?? primaryBrown.withOpacity(0.85),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: isAddress ? 4 : 2,
                    overflow: isAddress ? TextOverflow.ellipsis : TextOverflow.clip,
                  ),
                ),
                if (onCopy != null)
                  InkWell(
                    onTap: onCopy,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 0.0), // Align copy icon with text
                      child: Icon(Icons.copy, size: 16, color: accentOrange),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for section headers
  Widget _SectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28.0, bottom: 8.0), // Increased top spacing
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: primaryBrown,
        ),
      ),
    );
  }

  // Helper widget for a unified card structure
  Widget _buildCard({required List<Widget> children, double elevation = 5.0}) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: elevation,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the color for the status text
    Color statusColor;
    switch (order.status) {
      case 'Delivered':
        statusColor = Colors.green.shade700;
        break;
      case 'Cancelled':
        statusColor = Colors.red.shade700;
        break;
      case 'Processing':
        statusColor = accentOrange;
        break;
      case 'Out for Delivery':
        statusColor = Colors.blue.shade700;
        break;
      default:
        statusColor = primaryBrown;
    }

    // Combine address components for easy copying
    final fullAddress = '${order.deliveryAddress}, ${order.cityPinCode}';

    // Format the timestamp to a readable date string
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(order.timestamp); // Added time

    return Scaffold(
      backgroundColor: lightBgColor,
      appBar: AppBar(
        backgroundColor: accentOrange,
        foregroundColor: lightBgColor,
        elevation: 0,
        title: Text(
          'Order Summary',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Elevated Product/Order Summary Card (Highest Elevation) ---
                  _buildCard(
                    elevation: 10.0, // Higher elevation to stand out
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: CachedNetworkImage(
                              imageUrl: order.imgUrl ?? "https://placehold.co/100x100/ECEFF1/6D4C41?text=Coffee",
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 40, color: primaryBrown.withOpacity(0.5)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBrown,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Quantity: ${order.quantity}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '₹${order.totalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22, // Extra large price
                                    fontWeight: FontWeight.w900,
                                    color: accentOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Status indicator integrated into the card (refined padding)
                      const Padding(
                        padding: EdgeInsets.only(top: 15.0, bottom: 8.0),
                        child: Divider(height: 1, color: Color(0xFFEFEFEF)),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Status:',
                            style: GoogleFonts.poppins(fontSize: 15, color: detailLabelColor, fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Better padding
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15), // Stronger background hint
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              order.status,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // --- Order Information Section ---
                  _SectionHeader('Order Details'),
                  _buildCard(
                    children: [
                      // Order ID
                      _DetailRow(
                        context: context,
                        icon: Icons.qr_code, // Changed icon for a digital look
                        label: 'Order ID',
                        value: order.orderId,
                        isBoldValue: true,
                        onCopy: () => _copyToClipboard(context, order.orderId, 'Order ID'),
                      ),
                      // Date Placed
                      _DetailRow(
                        context: context,
                        icon: Icons.access_time_filled, // Changed icon
                        label: 'Placed On',
                        value: formattedDate,
                      ),
                      // Payment Method
                      _DetailRow(
                        context: context,
                        icon: Icons.payments_outlined, // Changed icon
                        label: 'Payment',
                        value: order.paymentMethod,
                      ),
                    ],
                  ),

                  // --- Delivery Information Section ---
                  _SectionHeader('Delivery Information'),
                  _buildCard(
                    children: [
                      // Full Address
                      _DetailRow(
                        context: context,
                        icon: Icons.location_on_outlined,
                        label: 'Ship To',
                        value: fullAddress,
                        isAddress: true,
                        onCopy: () => _copyToClipboard(context, fullAddress, 'Address'),
                      ),
                      // Delivery Option
                      _DetailRow(
                        context: context,
                        icon: Icons.delivery_dining,
                        label: 'Delivery Type',
                        value: order.deliveryOption,
                      ),
                    ],
                  ),

                  // --- Order Tracker Section ---
                  _SectionHeader('Order Tracking'),
                  _buildCard(
                    children: [
                      OrderTrackerZen(
                        tracker_data: _getTrackerStatus(),
                        success_color: accentOrange,
                        background_color: Colors.grey.shade300,
                        screen_background_color: lightBgColor,
                        text_primary_color: primaryBrown,
                        text_secondary_color: detailLabelColor,
                        isShrinked: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40), // Increased spacing before button
                ],
              ),
            ),
          ),

          // --- Fixed Bottom Track Order Button (Always visible) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckMyOrder(
                      orderId: order.orderId,
                      order: order, // Pass the order object directly
                    ),
                  ),
                );
              },
              icon: Icon(
                order.status == 'Delivered' ? Icons.history_toggle_off : Icons.assistant_direction_outlined,
                size: 24,
              ),
              label: Text(
                order.status == 'Delivered' ? 'View Order History' : 'Track Order Live',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18), // Taller button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8, // Prominent button shadow
              ),
            ),
          ),
        ],
      ),
    );
  }
}