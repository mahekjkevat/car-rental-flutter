import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:open_file/open_file.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'AddDamageReportUser.dart';
import 'car_booking_model.dart';

class CompletedBookingDetailsPage extends StatefulWidget {
  final CarBooking booking;

  const CompletedBookingDetailsPage({Key? key, required this.booking})
    : super(key: key);

  @override
  _CompletedBookingDetailsPageState createState() =>
      _CompletedBookingDetailsPageState();
}

class _CompletedBookingDetailsPageState
    extends State<CompletedBookingDetailsPage> {
  String reviewDocId = '';
  double? currentRating;
  String? currentReview;
  TextEditingController reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadReview();
  }

  void loadReview() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      setState(() {
        reviewDocId = widget.booking.id;
        currentRating = null;
        currentReview = null;
        reviewController.clear();
      });
      return;
    }

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('CarData')
            .where('carName', isEqualTo: widget.booking.carName)
            .get();

    if (querySnapshot.docs.isEmpty) {
      setState(() {
        reviewDocId = widget.booking.id;
        currentRating = null;
        currentReview = null;
        reviewController.clear();
      });
      return;
    }

    final carDoc = querySnapshot.docs.first;
    final reviewDocRef = carDoc.reference
        .collection('Reviews')
        .doc(widget.booking.id);
    final reviewSnapshot = await reviewDocRef.get();

    if (reviewSnapshot.exists) {
      final data = reviewSnapshot.data()!;
      setState(() {
        reviewDocId = reviewSnapshot.id;
        currentRating = data['feedback_rating']?.toDouble();
        currentReview = data['feedback_line'];
        reviewController.text = currentReview ?? '';
      });
    } else {
      setState(() {
        reviewDocId = widget.booking.id;
        currentRating = null;
        currentReview = null;
        reviewController.clear();
      });
    }
  }

  void submitReview() async {
    if (currentRating == null || reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide rating and review')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final userName = widget.booking.userName ?? 'Anonymous';

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User not logged in')));
      return;
    }

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('CarData')
            .where('car_name', isEqualTo: widget.booking.carName)
            .get();

    if (querySnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Car data not found')));
      return;
    }

    final carDocRef = querySnapshot.docs.first.reference;
    final reviewRef = carDocRef.collection('Reviews').doc(widget.booking.id);

    await reviewRef.set({
      'feedback_rating': currentRating,
      'feedback_line': reviewController.text.trim(),
      'feedback_time': FieldValue.serverTimestamp(),
      'userName': userName,
      'car_name': widget.booking.carName,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Feedback Saved successfully')));
    loadReview();
  }

  String formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Not provided';
    final date = timestamp.toDate();
    return DateFormat('d MMM, yyyy at h:mm a').format(date);
  }

  Color _getStatusColor() {
    return Colors.green; // Completed status color
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        title: Text(
          'Completed Booking',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Completed Status Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 40),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Completed',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Thank you for choosing our service',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Car Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      widget.booking.carImage1.isNotEmpty
                          ? widget.booking.carImage1
                          : 'https://via.placeholder.com/400x250',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.error,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Car Name',
                          widget.booking.carName,
                          Icons.directions_car,
                        ),
                        _buildDetailRow(
                          'Status',
                          widget.booking.status,
                          Icons.info,
                          isStatus: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Invoice Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSectionTitle('Invoice', Icons.receipt),
                    if (widget.booking.invoiceLink != null)
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              () => _showInvoiceOptions(
                                context,
                                widget.booking.invoiceLink!,
                              ),
                          icon: Icon(
                            Icons.picture_as_pdf,
                            size: 24,
                            color: Colors.white,
                          ),
                          label: Text(
                            'View Invoice',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    _buildDetailRow(
                      'Invoice Sent Date',
                      widget.booking.invoiceSentDate != null
                          ? formatDateTime(widget.booking.invoiceSentDate!)
                          : 'Not Sent',
                      Icons.send,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Damage Report Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSectionTitle('Damage Report', Icons.report_problem),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AddDamageReportUser(
                                  carBookingId: widget.booking.id,
                                ),
                          ),
                        );
                      },
                      icon: Icon(Icons.report_problem, size: 24),
                      label: Text(
                        'Damage Report',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Review & Rating Card
            _buildRatingReviewCard(),
            SizedBox(height: 20),

            // Booking Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Booking Details', Icons.event_note),
                    _buildDetailRow(
                      'Pickup Date',
                      formatDateTime(widget.booking.pickUpDateTime),
                      Icons.date_range,
                    ),
                    _buildDetailRow(
                      'Return Date',
                      formatDateTime(widget.booking.returnDateTime),
                      Icons.date_range,
                    ),
                    _buildDetailRow(
                      'Seats',
                      widget.booking.seats ?? 'N/A',
                      Icons.event_seat,
                    ),
                    _buildDetailRow(
                      'Total Price',
                      '₹${widget.booking.totalPrice.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                    _buildDetailRow(
                      'Payment Method',
                      widget.booking.paymentMethod ?? 'N/A',
                      Icons.payment,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Location Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Locations', Icons.location_on),
                    _buildDetailRow(
                      'From Address',
                      widget.booking.fromAddress,
                      Icons.location_on,
                    ),
                    _buildDetailRow(
                      'To Address',
                      widget.booking.toAddress,
                      Icons.location_on,
                    ),
                    _buildDetailRow(
                      'From Location',
                      widget.booking.fromLocation,
                      Icons.my_location,
                    ),
                    _buildDetailRow(
                      'To Location',
                      widget.booking.toLocation,
                      Icons.location_city,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // User Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('User Details', Icons.person),
                    _buildDetailRow(
                      'Name',
                      widget.booking.userName ?? 'N/A',
                      Icons.person,
                    ),
                    _buildDetailRow(
                      'Email',
                      widget.booking.userEmail ?? 'N/A',
                      Icons.email,
                    ),
                    _buildDetailRow(
                      'Mobile',
                      widget.booking.userMobile ?? 'N/A',
                      Icons.phone,
                    ),
                    _buildDetailRow(
                      'City',
                      widget.booking.userCity ?? 'N/A',
                      Icons.location_city,
                    ),
                    _buildDetailRow(
                      'State',
                      widget.booking.userState ?? 'N/A',
                      Icons.map,
                    ),
                    _buildDetailRow(
                      'Country',
                      widget.booking.userCountry ?? 'N/A',
                      Icons.flag,
                    ),
                    _buildDetailRow(
                      'Pin Code',
                      widget.booking.userPinCode ?? 'N/A',
                      Icons.pin_drop,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingReviewCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionTitle('Rate & Review', Icons.star),
            SizedBox(height: 16),

            // Rating Stars
            RatingBar.builder(
              initialRating: currentRating ?? 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder:
                  (context, _) => Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  currentRating = rating;
                });
              },
            ),
            SizedBox(height: 16),

            // Review Text Field
            TextField(
              controller: reviewController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),

            // Submit Button
            ElevatedButton.icon(
              onPressed: submitReview,
              icon: Icon(Icons.send, size: 24),
              label: Text(
                'Submit Review',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            if (currentReview != null && currentReview!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your Review: $currentReview',
                          style: GoogleFonts.poppins(color: Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[800], size: 24),
        SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isStatus ? _getStatusColor() : Colors.blue[800],
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: ',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isStatus ? _getStatusColor() : Colors.grey[800],
                fontWeight: isStatus ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceOptions(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Invoice Options',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text('Open PDF'),
                  subtitle: Text('View invoice in app'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _openPdfInApp(context, url);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.download, color: Colors.blue),
                  title: Text('Download'),
                  subtitle: Text('Save to device'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open the link')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<String?> _downloadPdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      }
    } catch (e) {
      print('Error downloading PDF: $e');
    }
    return null;
  }

  Future<void> _openPdfInApp(BuildContext context, String url) async {
    final filePath = await _downloadPdf(url);
    if (filePath != null) {
      await OpenFile.open(filePath);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load PDF')));
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}
