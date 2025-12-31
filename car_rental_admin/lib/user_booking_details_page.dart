import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // Add this import at the top
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'EmailService.dart';
import 'MahekAdminToast.dart'; // Import the toast file

class UserBookingDetailsPage extends StatefulWidget {
  final DocumentReference documentReference;

  const UserBookingDetailsPage({Key? key, required this.documentReference}) : super(key: key);

  @override
  _UserBookingDetailsPageState createState() => _UserBookingDetailsPageState();
}

class _UserBookingDetailsPageState extends State<UserBookingDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _bookingData;
  bool _hasInternet = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final connectivityResult = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _hasInternet = false;
        });
      } else {
        setState(() {
          _hasInternet = true;
          if (_isLoading && _bookingData == null) _fetchBookingData();
        });
      }
    });
    _checkInternetConnection();
    _fetchBookingData();
    print('Fetching data for documentReference: ${widget.documentReference.path}');
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
        print('Fetched booking data: $_bookingData');
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

  Future<void> _sendEmailToCustomer(String action) async {
    try {
      String userEmail = _bookingData?['userEmail'] ?? '';
      String userName = _bookingData?['userName'] ?? 'Customer';
      String carName = _bookingData?['carName'] ?? 'the vehicle';

      if (userEmail.isEmpty) {
        print('No customer email found');
        return;
      }

      String subject = '';
      String htmlBody = '';

      if (action == 'accepted') {
        subject = '🎉 Your Booking Has Been Accepted - GearGo';
        htmlBody = '''
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                /* Poppins is used conceptually, replace with a web-safe font if Poppins import is complex */
                body { font-family: 'Poppins', sans-serif; background-color: #000000; padding: 0; margin: 0; }
                .email-wrapper { background-color: #000000; padding: 20px; }
                .container { 
                    background: #1C1C1C; 
                    padding: 30px; 
                    border-radius: 12px; 
                    border: 1px solid #FFC10750; 
                    margin: 0 auto; 
                    max-width: 600px; 
                    box-shadow: 0 4px 15px rgba(255,193,7,0.1); 
                }
                .header { 
                    color: #FFC107; 
                    text-align: center; 
                    border-bottom: 2px solid #FFC107; 
                    padding-bottom: 10px; 
                    margin-bottom: 20px;
                    font-size: 24px;
                    font-weight: bold;
                }
                .content { margin: 20px 0; line-height: 1.8; color: #FFFFFF; font-size: 16px; }
                .status-highlight { color: #4CAF50; font-weight: bold; font-size: 1.1em; }
                .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #333; text-align: center; color: #999; }
                .logo-text { color: #FFC107; font-weight: bold; }
                ul { list-style-type: none; padding-left: 0; }
                ul li::before { content: '• '; color: #FFC107; font-weight: bold; display: inline-block; width: 1em; margin-left: -1em; }
            </style>
        </head>
        <body>
            <div class="email-wrapper">
                <div class="container">
                    <h1 class="header">🎉 Your Booking is Confirmed! <span class="logo-text">GearGo</span></h1>
                    <div class="content">
                        <p>Dear <strong style="color: #FFC107;">$userName</strong>,</p>
                        <p>We are delighted to inform you that your booking for <strong style="color: #FFC107;">$carName</strong> has been officially <span class="status-highlight">ACCEPTED</span>!</p>
                        <p>Your vehicle is reserved and ready for pickup on the scheduled date and time.</p>
                        <p style="font-weight: bold; color: #FFC107;">Next Steps:</p>
                        <ul>
                            <li>Please ensure your driver's license and booking confirmation are easily accessible.</li>
                            <li>Check your app for the final pickup location and time.</li>
                        </ul>
                    </div>
                    <div class="footer">
                        <p style="color: #FFC107; font-weight: bold;">Thank you for choosing GearGo!</p>
                        <p style="font-size: 0.9em;">Best regards, The GearGo Team</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
        ''';
      } else if (action == 'rejected') {
        subject = '⚠️ Update on Your Booking Request - GearGo';
        htmlBody = '''
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: 'Poppins', sans-serif; background-color: #000000; padding: 0; margin: 0; }
                .email-wrapper { background-color: #000000; padding: 20px; }
                .container { 
                    background: #1C1C1C; 
                    padding: 30px; 
                    border-radius: 12px; 
                    border: 1px solid #F4433650; 
                    margin: 0 auto; 
                    max-width: 600px; 
                    box-shadow: 0 4px 15px rgba(244,67,54,0.1); 
                }
                .header { 
                    color: #FFC107; 
                    text-align: center; 
                    border-bottom: 2px solid #F44336; 
                    padding-bottom: 10px; 
                    margin-bottom: 20px;
                    font-size: 24px;
                    font-weight: bold;
                }
                .content { margin: 20px 0; line-height: 1.8; color: #FFFFFF; font-size: 16px; }
                .status-highlight { color: #F44336; font-weight: bold; font-size: 1.1em; }
                .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #333; text-align: center; color: #999; }
                .logo-text { color: #FFC107; font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="email-wrapper">
                <div class="container">
                    <h1 class="header">🚫 Important Update on Your Booking</h1>
                    <div class="content">
                        <p>Dear <strong style="color: #FFC107;">$userName</strong>,</p>
                        <p>We regret to inform you that your booking request for <strong style="color: #FFC107;">$carName</strong> has been <span class="status-highlight">DECLINED</span> by the administrator.</p>
                        <p>This decision is usually due to one of the following reasons:</p>
                        <ul style="color: #D3D3D3; line-height: 1.5;">
                            <li>Vehicle unavailability for the requested dates.</li>
                            <li>Incomplete or unverified documentation.</li>
                            <li>Issue with payment or security deposit.</li>
                        </ul>
                        <p>We apologize for any inconvenience. Please feel free to browse other available vehicles or contact our support team for assistance.</p>
                    </div>
                    <div class="footer">
                        <p style="color: #FFC107; font-weight: bold;">Thank you for your understanding.</p>
                        <p style="font-size: 0.9em;">Best regards, The GearGo Team</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
        ''';
      }

      bool emailSent = await EmailService.sendEmail(
        recipientEmail: userEmail,
        subject: subject,
        htmlBody: htmlBody,
      );

      if (emailSent) {
        print('✅ Email sent successfully to $userEmail');
      } else {
        print('❌ Failed to send email to $userEmail');
      }
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  Future<void> _acceptBooking() async {
    if (!_hasInternet) {
      MahekAdminToast.show(
        context: context,
        message: 'No internet connection',
        status: ToastStatus.error,
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading
    });

    try {
      await widget.documentReference.update({'status': 'accepted'});

      // Send email to customer
      await _sendEmailToCustomer('accepted');

      MahekAdminToast.show(
        context: context,
        message: 'Booking accepted successfully',
        status: ToastStatus.success,
      );

      await _fetchBookingData();
    } catch (e) {
      print('Error accepting booking: $e');
      MahekAdminToast.show(
        context: context,
        message: 'Failed to accept booking',
        status: ToastStatus.error,
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading
      });
    }
  }
// Add this list of cancellation reasons at the top of your class
  final List<String> _cancellationReasons = [
    'Vehicle unavailable',
    'Document issue',
    'Payment failed',
    'Customer request',
    'Schedule conflict',
    'Maintenance required',
    'Insurance issue',
    'Price mismatch',
    'Duplicate booking',
    'Other reason'
  ];

  String? _selectedCancellationReason;

  void _showConfirmationDialog({required String action, required VoidCallback onConfirm}) {
    if (action == 'Reject') {
      _selectedCancellationReason = null; // Reset selection
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text(
                'Confirm $action',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: action == 'Reject'
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Are you sure you want to $action this booking?',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[300],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please select cancellation reason:',
                    style: GoogleFonts.poppins(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCancellationReason,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: Colors.grey[800],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      hint: Text(
                        'Select reason',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      items: _cancellationReasons.map((String reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(
                            reason,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          _selectedCancellationReason = newValue;
                        });
                      },
                    ),
                  ),
                ],
              )
                  : Text(
                'Are you sure you want to $action this booking?',
                style: GoogleFonts.poppins(
                  color: Colors.grey[300],
                  fontSize: 16,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (action == 'Reject' && (_selectedCancellationReason == null || _selectedCancellationReason!.isEmpty)) {
                      MahekAdminToast.show(
                        context: context,
                        message: 'Please select cancellation reason',
                        status: ToastStatus.error,
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  child: Text(
                    action,
                    style: GoogleFonts.poppins(
                      color: action == 'Accept' ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _rejectBooking() async {
    if (!_hasInternet) {
      MahekAdminToast.show(
        context: context,
        message: 'No internet connection',
        status: ToastStatus.error,
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading
    });

    try {
      // Prepare update data
      Map<String, dynamic> updateData = {
        'status': 'rejected',
        'cancel_request': _selectedCancellationReason ?? 'No reason provided',
        'cancel_request_amount': 0,
        'cancel_request_date': FieldValue.serverTimestamp(),
      };

      print('🎯 Updating booking with rejection data:');
      print('📝 Status: rejected');
      print('❌ Cancellation Reason: ${_selectedCancellationReason}');
      print('💰 Cancel Amount: 0');
      print('📅 Cancel Date: ${DateTime.now()}');

      // Update the document
      await widget.documentReference.update(updateData);

      print('✅ Booking rejected successfully with reason: $_selectedCancellationReason');

      // Send email to customer
      await _sendEmailToCustomer('rejected');

      MahekAdminToast.show(
        context: context,
        message: 'Booking rejected successfully',
        status: ToastStatus.success,
      );

      await _fetchBookingData();
    } catch (e) {
      print('❌ Error rejecting booking: $e');
      MahekAdminToast.show(
        context: context,
        message: 'Failed to reject booking',
        status: ToastStatus.error,
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading
        _selectedCancellationReason = null; // Reset selection
      });
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not provided';
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showReviewOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Finish Rental Options',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildReviewOptionsList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReviewOptionsList() {
    final options = [
      {
        'icon': Icons.rate_review,
        'color': Colors.yellow,
        'title': 'Review Damage Inspection',
        'subtitle': 'Inspect vehicle for any damages',
      },
      {
        'icon': Icons.receipt,
        'color': Colors.green,
        'title': 'Generate Final Invoice',
        'subtitle': 'Create and send final bill',
      },
      {
        'icon': Icons.feedback,
        'color': Colors.blue,
        'title': 'Request Customer Feedback',
        'subtitle': 'Get customer rating and review',
      },
      {
        'icon': Icons.build,
        'color': Colors.orange,
        'title': 'Schedule Maintenance',
        'subtitle': 'Plan next vehicle service',
      },
      {
        'icon': Icons.thumb_up,
        'color': Colors.purple,
        'title': 'Send Thank You Message',
        'subtitle': 'Appreciate customer business',
      },
    ];

    return options.map((option) => Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(option['icon'] as IconData, color: option['color'] as Color),
        title: Text(
          option['title'] as String,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          option['subtitle'] as String,
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
        ),
        onTap: () {
          Navigator.pop(context);
          _navigateToReviewPage(option['title'] as String, 'Processing ${option['title']}...');
        },
      ),
    )).toList();
  }

  void _navigateToReviewPage(String title, String message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _buildReviewPage(title, message),
      ),
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
              const SizedBox(height: 20),
              Text(message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('OK', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      MahekAdminToast.show(
        context: context,
        message: 'Phone number not available',
        status: ToastStatus.error,
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: phoneNumber));
    MahekAdminToast.show(
      context: context,
      message: 'Phone number copied to clipboard',
      status: ToastStatus.info,
    );

    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        MahekAdminToast.show(
          context: context,
          message: 'Cannot launch phone dialer',
          status: ToastStatus.error,
        );
      }
    } catch (e) {
      print('Error launching dialer: $e');
      MahekAdminToast.show(
        context: context,
        message: 'Failed to launch phone dialer',
        status: ToastStatus.error,
      );
    }
  }

  Widget _buildStatusMessage() {
    final status = _bookingData?['status']?.toString().toLowerCase() ?? '';

    if (status == 'accepted') {
      return _buildFixedMessage('✅ Booking Accepted', Colors.green);
    } else if (status == 'rejected') {
      return _buildFixedMessage('❌ Booking Rejected', Colors.red);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildFixedMessage(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _bookingData?['status']?.toString().toLowerCase() ?? '';
    final showActionButtons = status == 'pending';
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: Text(
          'Booking Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.yellow),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: Image.asset('assets/images/car.png', fit: BoxFit.cover),
                  ),
                ),
                _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                  ),
                )
                    : _hasInternet && _bookingData == null
                    ? Center(
                  child: Text(
                    'Booking not found',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                  ),
                )
                    : !_hasInternet
                    ? Center(
                  child: Text(
                    'No internet connection',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                  ),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      _buildUserInfoCard(),
                      const SizedBox(height: 16),

                      // Car Details Card
                      _buildCarDetailsCard(),
                      const SizedBox(height: 16),

                      // Booking Details Card
                      _buildBookingDetailsCard(),
                      const SizedBox(height: 16),

                      // User Details Card
                      _buildUserDetailsCard(),
                      const SizedBox(height: 24),

                      // Finish Rental Button
                      if (status == 'accepted')
                        Center(
                          child: ElevatedButton(
                            onPressed: _showReviewOptions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            ),
                            child: Text(
                              'Finish Rental',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status Message (Fixed at bottom, not scrollable)
          _buildStatusMessage(),

      // Action Buttons (Only show for pending status)
          if (showActionButtons)
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showConfirmationDialog(
                        action: 'Accept',
                        onConfirm: _acceptBooking,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Accept',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showConfirmationDialog(
                        action: 'Reject',
                        onConfirm: _rejectBooking,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Reject',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  //

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Widget _buildUserInfoCard() {
    final userId = _bookingData?['userId'] ?? _bookingData?['authId'];
    final userName = _bookingData?['userName'] ?? 'User Name';
    final userMobile = _bookingData?['userMobile'] ?? 'No contact';

    // If we lack the ID needed to query the 'users' collection, return the default card immediately.
    if (userId == null) {
      return _buildUserInfoContent(
        userName: userName,
        userMobile: userMobile,
        profileImageUrl: null,
      );
    }

    // Use FutureBuilder to fetch the profile image URL from the 'users' collection
    return FutureBuilder<DocumentSnapshot>(
      // Assuming the user document path is 'users/[userId]'
      future: _firestore.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String? profileImageUrl;

        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.exists) {
          // Safely extract the profile_image field
          profileImageUrl = (snapshot.data!.data() as Map<String, dynamic>?)?['profile_image'];
        }

        // The content is built regardless of the fetch status, showing image if available
        return _buildUserInfoContent(
          userName: userName,
          userMobile: userMobile,
          profileImageUrl: profileImageUrl,
          isImageLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }

// Helper widget for consistent card structure
  Widget _buildUserInfoContent({
    required String userName,
    required String userMobile,
    String? profileImageUrl,
    bool isImageLoading = false,
  }) {
    final bool hasValidImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: SizedBox(
        height: 80,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Avatar/Image Logic
                    CircleAvatar(
                      backgroundColor: Colors.yellow,
                      radius: 24,
                      child: isImageLoading
                          ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        strokeWidth: 2,
                      )
                          : hasValidImage
                          ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: profileImageUrl,
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                          placeholder: (context, url) => Container(color: Colors.yellow, child: const Center(child: Icon(Icons.person, color: Colors.black, size: 24))),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.person,
                        color: Colors.black,
                        size: 24,
                      ), // Default icon
                    ),
                    const SizedBox(width: 12),
                    // User Details
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userMobile,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Call Button
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Ensure _makePhoneCall is defined in your state class
                    _makePhoneCall(userMobile);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    backgroundColor: Colors.green,
                    elevation: 4,
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }







  Widget _buildCarDetailsCard() {
    return Card(
      color: Colors.grey[800],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Car Details',
              style: GoogleFonts.poppins(
                color: Colors.yellow,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: _bookingData!['carImage1'] ?? 'https://via.placeholder.com/300x150',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: Colors.grey[700],
                  child: const Center(
                    child: Icon(Icons.directions_car, color: Colors.grey, size: 80),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.directions_car, 'Car Name', _bookingData!['carName'] ?? 'Not provided'),
            _buildDetailRow(Icons.event_seat, 'Seats', _bookingData!['seats']?.toString() ?? 'Not provided'),
            _buildDetailRow(Icons.subscriptions, 'Subscription', _bookingData!['subscription'] ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Card(
      color: Colors.grey[800],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: GoogleFonts.poppins(
                color: Colors.yellow,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.info, 'Status', _bookingData!['status'] ?? 'Not provided', isStatus: true),
            _buildDetailRow(Icons.attach_money, 'Total Price', '\₹${_bookingData!['totalPrice']?.toString() ?? 'Not provided'}', isPrice: true),
            _buildDetailRow(Icons.location_on, 'Pickup Location', _bookingData!['fromLocation'] ?? 'Not provided'),
            _buildDetailRow(Icons.place, 'Pickup Address', _bookingData!['fromAddress'] ?? 'Not provided'),
            if (_bookingData!['toLocation'] != null)
              _buildDetailRow(Icons.location_on, 'Dropoff Location', _bookingData!['toLocation']),
            if (_bookingData!['toAddress'] != null)
              _buildDetailRow(Icons.place, 'Dropoff Address', _bookingData!['toAddress']),
            _buildDetailRow(Icons.access_time, 'Pickup Time', _formatTimestamp(_bookingData!['pickUpDateTime'] as Timestamp?)),
            if (_bookingData!['returnDateTime'] != null)
              _buildDetailRow(Icons.access_time, 'Return Time', _formatTimestamp(_bookingData!['returnDateTime'] as Timestamp?)),
            if (_bookingData!['distance'] != null)
              _buildDetailRow(Icons.directions, 'Distance', '${_bookingData!['distance']?.toString() ?? '0'} km'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetailsCard() {
    return Card(
      color: Colors.grey[800],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Details',
              style: GoogleFonts.poppins(
                color: Colors.yellow,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.person, 'Name', _bookingData!['userName'] ?? 'Not provided'),
            _buildDetailRow(Icons.email, 'Email', _bookingData!['userEmail'] ?? 'Not provided'),
            _buildDetailRow(Icons.phone, 'Mobile', _bookingData!['userMobile'] ?? 'Not provided'),
            _buildDetailRow(Icons.card_membership, 'License', _bookingData!['userLicense'] ?? 'Not provided'),
            _buildDetailRow(Icons.location_city, 'City', _bookingData!['userCity'] ?? 'Not provided'),
            _buildDetailRow(Icons.map, 'State', _bookingData!['userState'] ?? 'Not provided'),
            _buildDetailRow(Icons.local_post_office, 'Pin Code', _bookingData!['userPinCode'] ?? 'Not provided'),
            _buildDetailRow(Icons.public, 'Country', _bookingData!['userCountry'] ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isPrice = false, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.yellow, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                isStatus
                    ? Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: value.toLowerCase() == 'accepted'
                        ? Colors.green
                        : value.toLowerCase() == 'rejected'
                        ? Colors.red
                        : Colors.orange,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    : isPrice
                    ? Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.yellow[700],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    : Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}