import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class CarDetailsPage extends StatefulWidget {
  final Map<String, dynamic> carData;

  const CarDetailsPage({Key? key, required this.carData}) : super(key: key);

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return 'VERIFIED';
      case 'rejected':
        return 'REJECTED';
      case 'pending':
        return 'PENDING REVIEW';
      default:
        return 'UNKNOWN';
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is Timestamp) {
        return DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate());
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  List<Widget> _buildFeatureChips() {
    List<Widget> chips = [];
    for (int i = 1; i <= 6; i++) {
      final feature = widget.carData['features$i'];
      if (feature != null && feature.toString().isNotEmpty) {
        chips.add(
          Container(
            margin: const EdgeInsets.only(right: 6, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Text(
              feature.toString(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }
    return chips;
  }

  Widget _buildDetailRow(String title, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$title:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: isStatus
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(value),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(value),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            )
                : Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Car Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Images Gallery
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    widget.carData['car_image1'] ?? '',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow('Status', widget.carData['status'] ?? 'pending', isStatus: true),
                    _buildDetailRow('Submitted On', _formatDate(widget.carData['created_at'])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Car Information Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Car Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Car Name', widget.carData['car_name'] ?? 'N/A'),
                    _buildDetailRow('Brand', widget.carData['car_brand'] ?? 'N/A'),
                    _buildDetailRow('Model', widget.carData['car_model'] ?? 'N/A'),
                    _buildDetailRow('Fuel Type', widget.carData['fuel_type'] ?? 'N/A'),
                    _buildDetailRow('Seats', '${widget.carData['no_of_seats'] ?? 0}'),
                    _buildDetailRow('Transmission', widget.carData['transmission'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pricing Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pricing',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Basic Price', '₹${widget.carData['basic_price'] ?? 0}'),
                    _buildDetailRow('Plus Price', '₹${widget.carData['plus_price'] ?? 0}'),
                    _buildDetailRow('Max Price', '₹${widget.carData['max_price'] ?? 0}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Features Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      children: _buildFeatureChips(),
                    ),
                  ],
                ),
              ),
            ),

            // Customer Information Card (if available)
            if (widget.carData['customerName'] != null)
              Column(
                children: [
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Information',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Name', widget.carData['customerName'] ?? 'N/A'),
                          _buildDetailRow('Mobile', widget.carData['mobile'] ?? 'N/A'),
                          _buildDetailRow('Village', widget.carData['village'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}