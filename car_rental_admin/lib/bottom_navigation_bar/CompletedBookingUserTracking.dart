import 'dart:async';
import 'dart:io';
import 'package:car_rental_admin/bottom_navigation_bar/car_damage_report.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appwrite/appwrite.dart';
import 'package:fluttertoast/fluttertoast.dart'; // for toast
import 'package:car_rental_admin/utils/custom_toast.dart';

import 'DamageReportModel.dart';
import 'invoice_generator.dart';

class CompletedBookingUserTracking extends StatefulWidget {
  final DocumentReference documentReference;

  const CompletedBookingUserTracking({
    Key? key,
    required this.documentReference,
  }) : super(key: key);

  @override
  _CompletedBookingUserTrackingState createState() =>
      _CompletedBookingUserTrackingState();
}

class _CompletedBookingUserTrackingState
    extends State<CompletedBookingUserTracking> {
  bool _isLoading = true;
  Map<String, dynamic>? _bookingData;
  bool _hasInternet = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isSending = false;
  final storage = Storage(
    Client()
      ..setEndpoint('https://fra.cloud.appwrite.io/v1') // your endpoint
      ..setProject('67e8384a0024f79666ba'),
  );

  @override
  void initState() {
    super.initState();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final connectivityResult =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _hasInternet = false;
        });
      } else {
        setState(() {
          _hasInternet = true;
        });
        if (_isLoading && _bookingData == null) _fetchBookingData();
      }
    });

    _checkInternetConnection();
    _fetchBookingData();
    print(
      'Fetching data for documentReference: ${widget.documentReference.path}',
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _hasInternet = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBookingData() async {
    if (!_hasInternet) return;
    try {
      final docSnapshot = await widget.documentReference.get();
      if (docSnapshot.exists) {
        setState(() {
          _bookingData = docSnapshot.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('No document found at path: ${widget.documentReference.path}');
      }
    } catch (e) {
      print('Error fetching booking: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Phone number copied to clipboard: $phoneNumber')),
    );
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot launch phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context); // handle back navigation
          },
          child: Container(
            margin: const EdgeInsets.all(8), // optional padding
            decoration: BoxDecoration(
              color: Colors.white, // white background
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8), // size of the circle
            child: Icon(
              Icons.arrow_back, // back arrow icon
              color: Colors.black, // black arrow
              size: 24,
            ),
          ),
        ),
        title: Text(
          'Completed Bookings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Optional background image
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset('assets/images/car.png', fit: BoxFit.cover),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  child:
                      _isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.yellow,
                              ),
                            ),
                          )
                          : _hasInternet && _bookingData == null
                          ? Center(
                            child: Text(
                              'Booking not found',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          )
                          : !_hasInternet
                          ? Center(
                            child: Text(
                              'No internet connection',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          )
                          : SingleChildScrollView(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User Info with Call Button
                                Card(
                                  color: Colors.grey[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    title: Text(
                                      _bookingData!['userName'] ?? 'User Name',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _bookingData!['userMobile'] ??
                                          'No contact',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.call,
                                        color: Colors.green,
                                        size: 30,
                                      ),
                                      onPressed:
                                          () => _makePhoneCall(
                                            _bookingData!['userMobile'],
                                          ),
                                    ),
                                  ),
                                ),
                                // Car Details
                                _buildCarDetails(),
                                // Booking Details
                                _buildBookingDetails(),
                                // User Details
                                _buildUserDetails(),
                                // Finish Rental Button

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Find the GestureDetector for the "Damage Report" button
                                    // ... (Your existing code)

                                    GestureDetector(
                                      onTap: () async {
                                        // Get the car booking ID from the current document reference
                                        final String carBookingId = widget.documentReference.id;
                                        // Extract the userId from the document path
                                        final String userId = widget.documentReference.path.split('/')[1];

                                        String? damageReportId;
                                        try {
                                          // Use the correct userId to query the subcollection
                                          final damageReportSnapshot = await FirebaseFirestore.instance
                                              .collection(
                                              'Users/$userId/car_booking/$carBookingId/damage_report')
                                              .limit(1)
                                              .get();

                                          if (damageReportSnapshot.docs.isNotEmpty) {
                                            damageReportId = damageReportSnapshot.docs.first.id;
                                          }
                                        } catch (e) {
                                          print("Error fetching damage report ID: $e");
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to load damage report data.'),
                                            ),
                                          );
                                        }

                                        final reportModel = DamageReportModel(
                                          carBookingId: carBookingId,
                                          damageReportId: damageReportId,
                                          userId: userId, // Pass the correct userId to the model
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CarDamageReport(reportModel: reportModel),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'Damage Report',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to page 2
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent,
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'Button 2',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child:ElevatedButton(
                                    onPressed: _showReviewOptions,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.yellowAccent, // Slightly darker for depth
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12), // Slightly more rounded
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24, // Slightly more spacious
                                        vertical: 16,
                                      ),
                                      elevation: 4, // Added shadow for depth
                                    ),
                                    child: Text(
                                      'Click for Invoice',
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarDetails() {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Car Details',
              style: GoogleFonts.poppins(
                color: Colors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            CachedNetworkImage(
              imageUrl:
                  _bookingData!['carImage1'] ??
                  'https://via.placeholder.com/300x150',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) =>
                      const Center(child: CircularProgressIndicator()),
              errorWidget:
                  (context, url, error) => const Center(
                    child: Icon(Icons.directions_car, size: 100),
                  ),
            ),
            const SizedBox(height: 10),

            _buildDetailRow(
              Icons.directions_car,
              'Car Name',
              _bookingData!['carName'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.event_seat,
              'Seats',
              _bookingData!['seats']?.toString() ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.subscriptions,
              'Subscription',
              _bookingData!['subscription'] ?? 'Not provided',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: GoogleFonts.poppins(
                color: Colors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.info,
              'Status',
              _bookingData!['status'] ?? 'Not provided',
              isStatus: true,
            ),
            _buildDetailRow(
              Icons.attach_money,
              'Total Price',
              '₹${_bookingData!['totalPrice']?.toString() ?? 'Not provided'}',
              isPrice: true,
            ),
            _buildDetailRow(
              Icons.location_on,
              'Pickup Location',
              _bookingData!['fromLocation'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.place,
              'Pickup Address',
              _bookingData!['fromAddress'] ?? 'Not provided',
            ),
            if (_bookingData!['toLocation'] != null)
              _buildDetailRow(
                Icons.location_on,
                'Dropoff Location',
                _bookingData!['toLocation'],
              ),
            if (_bookingData!['toAddress'] != null)
              _buildDetailRow(
                Icons.place,
                'Dropoff Address',
                _bookingData!['toAddress'],
              ),
            _buildDetailRow(
              Icons.access_time,
              'Pickup Time',
              _formatTimestamp(_bookingData!['pickUpDateTime'] as Timestamp?),
            ),
            if (_bookingData!['returnDateTime'] != null)
              _buildDetailRow(
                Icons.access_time,
                'Return Time',
                _formatTimestamp(_bookingData!['returnDateTime'] as Timestamp?),
              ),
            if (_bookingData!['distance'] != null)
              _buildDetailRow(
                Icons.directions,
                'Distance',
                '${_bookingData!['distance']?.toString() ?? '0'} km',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetails() {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Details',
              style: GoogleFonts.poppins(
                color: Colors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.person,
              'Name',
              _bookingData!['userName'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.email,
              'Email',
              _bookingData!['userEmail'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.phone,
              'Mobile',
              _bookingData!['userMobile'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.card_membership,
              'License',
              _bookingData!['userLicense'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.location_city,
              'City',
              _bookingData!['userCity'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.map,
              'State',
              _bookingData!['userState'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.local_post_office,
              'Pin Code',
              _bookingData!['userPinCode'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.public,
              'Country',
              _bookingData!['userCountry'] ?? 'Not provided',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isPrice = false,
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.yellow, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color:
                          isStatus
                              ? (value.toLowerCase() == 'completed'
                                  ? Colors.green
                                  : value.toLowerCase() == 'rejected'
                                  ? Colors.red
                                  : Colors.orange)
                              : isPrice
                              ? Colors.yellow
                              : Colors.white,
                      fontWeight:
                          isStatus || isPrice
                              ? FontWeight.w600
                              : FontWeight.normal,
                      fontSize: 16
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Assume you have access to storage and client initialized
  Future<void> sendInvoiceToCustomer() async {
    setState(() {
      _isSending = true; // Show loading indicator
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Generate the PDF invoice
      final pdfFile = await createRentalInvoicePdf(
        _bookingData!,
        user.uid,
        FirebaseFirestore.instance,
      );

      // Create a unique filename for the invoice
      final filename = 'invoice_${_bookingData!['userName']}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Upload the PDF to Appwrite storage
      final uploadResponse = await storage.createFile(
        bucketId: '67ec1162000a2853d3f7',
        fileId: ID.unique(),
        file: InputFile(
          filename: filename,
          bytes: await pdfFile.readAsBytes(),
        ),
      );

      // Construct the URL for the uploaded invoice
      final fileId = uploadResponse.$id;
      final invoiceUrl =
          'https://fra.cloud.appwrite.io/v1/storage/buckets/67ec1162000a2853d3f7/files/$fileId/view?project=67e8384a0024f79666ba&mode=admin';

      // Update Firestore document with invoice link and status
      await widget.documentReference.update({
        'invoice_link': invoiceUrl,
        'invoice_sent_to_user': true,
        'invoice_to_user_date': Timestamp.now(),
      });

      CustomToast.show(context, message: "Invoice sent successfully!");
    } catch (e) {
      print('Error sending invoice: $e');
      Fluttertoast.showToast(msg: 'Failed to send invoice.');
    } finally {
      setState(() {
        _isSending = false; // Hide loading indicator
      });
    }
  }
void _showReviewOptions() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.grey[850],
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ListView(
      shrinkWrap: true,
      children: [
        // Always show "View Invoice"
        ListTile(
          leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent),
          title: Text(
            'View Invoice',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          onTap: () async {
            Navigator.pop(context);
            await _handleViewInvoice();
          },
        ),
        // Show "Send a Invoice to Customer" only if not sent yet
        if (_bookingData!['invoice_sent_to_user'] != true)
          ListTile(
            leading: _isSending
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                    ),
                  )
                : Icon(Icons.send, color: Colors.orangeAccent),
            title: Text(
              'Send a Invoice to Customer',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            onTap: () async {
              if (_isSending) return;
              await sendInvoiceToCustomer();
            },
          ),
      ],
    ),
  );
}Future<void> _handleViewInvoice() async {
  final invoiceLink = _bookingData?['invoice_link'];

  if (invoiceLink != null && invoiceLink.isNotEmpty) {
    // Open PDF inside app
    await _openPdfInApp(context, invoiceLink);
  } else {
    // Generate PDF and show options (as you already do)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final pdfFile = await createRentalInvoicePdf(
      _bookingData!,
      user.uid,
      FirebaseFirestore.instance,
    );

    _showPdfOptions(pdfFile);
  }
}

Future<void> _openUrl(String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open invoice link')),
    );
  }
}

void _showPdfOptions(File pdfFile) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Invoice Options', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20)),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.download, color: Colors.white),
            label: Text('Download', style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              Navigator.pop(context);
              await _savePdfFile(pdfFile);
            },
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.visibility, color: Colors.white),
            label: Text('View', style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              await _openPdfFile(pdfFile);
            },
          ),
        ],
      ),
    ),
  );
}
void _showInvoiceOptions(BuildContext context, String url) {
  showModalBottomSheet(
    backgroundColor: Colors.grey[900],
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    context: context,
    builder: (_) => ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent),
          title: Text(
            'Open PDF',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          onTap: () async {
            Navigator.pop(context);
            await _openPdfInApp(context, url); // Use this method
          },
        ),
        ListTile(
          leading: Icon(Icons.download, color: Colors.orangeAccent),
          title: Text(
            'Download Invoice',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
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
  );
}
// Replace your `_openUrl()` method with this:
Future<void> _openPdfInApp(BuildContext context, String url) async {
  try {
    // Download the PDF file
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Open the PDF file with OpenFile
      await OpenFile.open(filePath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load PDF')),
      );
    }
  } catch (e) {
    print('Error opening PDF: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to open PDF')),
    );
  }
}
  Future<void> _savePdfFile(File file) async {
    // Save to device storage (e.g., Downloads folder)
    final directory = await getExternalStorageDirectory(); // or getApplicationDocumentsDirectory()
    final savePath = '${directory!.path}/${file.uri.pathSegments.last}';
    final newFile = await File(savePath).create(recursive: true);
    await newFile.writeAsBytes(await file.readAsBytes());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $savePath')));
  }

  Future<void> _openPdfFile(File file) async {
    // Use open_file package
    await OpenFile.open(file.path);
  }
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not provided';
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  void _navigateToReviewPage(String title, String message) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _buildReviewPage(title, message)),
    );
  }

  Widget _buildReviewPage(String title, String message) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
      ),
      backgroundColor: Colors.grey[850],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 80, color: Colors.yellow),
              SizedBox(height: 20),
              Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to parse latitude and longitude strings into doubles
  double? _parseCoordinate(String? coordString) {
    if (coordString == null || coordString.isEmpty) return null;
    return double.tryParse(coordString);
  }
}
