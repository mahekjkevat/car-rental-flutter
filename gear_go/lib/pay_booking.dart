import 'package:flutter/material.dart';
import 'package:gear_go/MyBooking.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'CustomNotificationClass.dart';
import 'car_data_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'privacy.dart';
import 'show_booking_information.dart';
import 'EmailService.dart'; // Import your working EmailService

class PayBooking extends StatefulWidget {
  final String documentId;
  final String fromLocation;
  final String toLocation;
  final String fromAddress;
  final String toAddress;
  final DateTime pickUpDateTime;
  final DateTime returnDateTime;
  final double coverDistance;

  const PayBooking({
    super.key,
    required this.documentId,
    required this.fromLocation,
    required this.toLocation,
    required this.fromAddress,
    required this.toAddress,
    required this.pickUpDateTime,
    required this.returnDateTime,
    required this.coverDistance,
  });

  @override
  State<PayBooking> createState() => _PayBookingState();
}

class _PayBookingState extends State<PayBooking> {
  bool isChecked = false;
  String? _errorMessage;
  CarDataModel? carData;
  String? selectedSeats;
  String? selectedSubscription;
  double calculatedPrice = 0.0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchCarData();
    _fetchUserData();
  }

  Future<void> _fetchCarData() async {
    try {
      final doc =
          await _firestore.collection('CarData').doc(widget.documentId).get();
      if (doc.exists) {
        setState(
          () =>
              carData = CarDataModel.fromJson(
                doc.data()! as Map<String, dynamic>,
                widget.documentId,
              ),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error fetching car data: $e",
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('Users').doc(user.uid).get();
        if (!userDoc.exists || userDoc.data() == null) {
          await _firestore.collection('Users').doc(user.uid).set({
            'name': 'No Name',
            'email': 'nogmail@gmail.com',
            'mobile_number': '1234567890',
            'city': 'CITY',
            'country': 'India',
            'state': 'Gujrat',
            'license_no': 'User@Licence2025',
            'pin_code': '1234568789',
            'payment_method': 'RazorPay',
          }, SetOptions(merge: true));
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error fetching user data: $e",
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    }
  }

  void _calculatePrice(String? seats, String? subscription) {
    if (seats != null && subscription != null && carData != null) {
      final pricePerKm =
          subscription == 'BASIC'
              ? carData!.basicPrice.toDouble()
              : subscription == 'PLUS'
              ? carData!.plusPrice.toDouble()
              : carData!.maxPrice.toDouble();
      setState(() {
        calculatedPrice = pricePerKm * widget.coverDistance;
        selectedSeats = seats;
        selectedSubscription = subscription;
      });
    } else {
      setState(() => calculatedPrice = 0);
    }
  }

  Future<Map<String, dynamic>?> _saveCarBooking() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      final carBookingRef = _firestore
          .collection('Users')
          .doc(userId)
          .collection('car_booking');
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      if (!userDoc.exists) {
        await _firestore
            .collection('Users')
            .doc(userId)
            .set({}, SetOptions(merge: true));
      }
      final bookingData = {
        'documentId': widget.documentId,
        'fromLocation': widget.fromLocation,
        'toLocation': widget.toLocation,
        'fromAddress': widget.fromAddress,
        'toAddress': widget.toAddress,
        'pickUpDateTime': Timestamp.fromDate(widget.pickUpDateTime),
        'returnDateTime': Timestamp.fromDate(widget.returnDateTime),
        'subscription': selectedSubscription,
        'seats': selectedSeats,
        'distance': widget.coverDistance,
        'totalPrice': calculatedPrice,
        'bookingTime': Timestamp.now(),
        'status': 'Pending',
        'carImage1': carData!.carImage1,
        'carName': carData!.carName,
        'car_brand': carData!.carBrand,
        'payment_method': 'Pending Payment',
        'userName': userData['name'] ?? 'Not Found',
        'userEmail': userData['email'] ?? 'Not Found',
        'userMobile': userData['mobile_number'] ?? 'Not Found',
        'userCity': userData['city'] ?? 'Not Found',
        'userState': userData['state'] ?? 'Not Found',
        'userCountry': userData['country'] ?? 'Not Found',
        'userLicense': userData['license_no'] ?? 'Not Found',
        'userPinCode': userData['pin_code'] ?? 'Not Found',
        'location_Status': false,
        'cancel_request': 'No',
        'cancel_request_amount': 0.0,
        'cancel_request_date': null,
      };

      final bookingDoc = await carBookingRef.add(bookingData);
      bookingData['id'] = bookingDoc.id;

      // Send emails to both customer and admin using EmailService
      await _sendCustomerEmail(bookingData, userData);
      await _sendAdminEmail(bookingData, userData);

      await _postCarRentalNotification();
      _showReceiptDialog(bookingData);

      CustomNotificationClass.MahekCustomNotification(
        context,
        "Booking Request Sent",
        "Your car rental request has been sent successfully. Payment pending.",
        MyBooking(),
        logoIcon: Icons.info,
      );
      return bookingData;
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error saving booking: $e",
        toastLength: Toast.LENGTH_SHORT,
      );
      return null;
    }
  }

  Future<void> _sendCustomerEmail(
    Map<String, dynamic> bookingData,
    Map<String, dynamic> userData,
  ) async {
    try {
      final customerEmail = userData['email'] ?? 'Not Found';
      final customerName = userData['name'] ?? 'Customer';

      if (customerEmail == 'Not Found' || !customerEmail.contains('@')) {
        print('❌ Invalid customer email: $customerEmail');
        return;
      }

      final customerSubject =
          '🚗 GearGo - Your Car Rental Booking Request Sent to ADMIN!';
      final customerHtml = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Booking Confirmation</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .header h1 { color: white; margin: 0; font-size: 28px; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .button { display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; }
        .info-box { background: white; padding: 20px; border-radius: 10px; margin: 20px 0; border-left: 4px solid #667eea; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚗 GearGo</h1>
        <p style="color: white; margin: 10px 0 0 0;">Car Rental Service</p>
    </div>
    
    <div class="content">
        <h2 style="color: #333;">Dear $customerName,</h2>
        <p style="color: #666;">
            Thank you for choosing GearGo for your car rental needs! We're excited to confirm that we've received your booking request.
        </p>
        
        <div class="info-box">
            <h3 style="color: #333; margin-bottom: 15px;">📋 Booking Details</h3>
            <p><strong>Vehicle:</strong> ${bookingData['carName']} - ${bookingData['car_brand']}</p>
            <p><strong>Subscription Plan:</strong> ${bookingData['subscription']}</p>
            <p><strong>Seats:</strong> ${bookingData['seats']}</p>
            <p><strong>Distance:</strong> ${bookingData['distance']} km</p>
            <p><strong>Total Amount:</strong> ₹${bookingData['totalPrice'].toStringAsFixed(2)}</p>
        </div>
        
        <div class="info-box" style="border-left-color: #28a745;">
            <h3 style="color: #333; margin-bottom: 15px;">📍 Trip Information</h3>
            <p><strong>From:</strong> ${bookingData['fromLocation']} - ${bookingData['fromAddress']}</p>
            <p><strong>To:</strong> ${bookingData['toLocation']} - ${bookingData['toAddress']}</p>
            <p><strong>Pickup:</strong> ${DateFormat('MMM dd, yyyy - HH:mm').format(widget.pickUpDateTime)}</p>
            <p><strong>Return:</strong> ${DateFormat('MMM dd, yyyy - HH:mm').format(widget.returnDateTime)}</p>
        </div>
        
        <div style="background: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <p style="color: #856404; margin: 0;">
                <strong>⏳ Current Status:</strong> Pending Payment<br>
                Your booking is currently pending payment confirmation. Once payment is processed, your booking will be confirmed.
            </p>
        </div>
        
        <p style="color: #666;">
            <strong>📞 Need Assistance?</strong><br>
            If you have any questions or need to modify your booking, please contact our customer support team.
        </p>
        
        <p style="color: #666;">
            Thank you for choosing GearGo! We look forward to serving you.
        </p>
    </div>
    
    <div class="footer">
        <p>Best regards,<br><strong>The GearGo Team</strong></p>
        <p style="font-size: 12px; color: #999;">
            © 2024 GearGo. All rights reserved.<br>
            This email was sent from our Flutter application.
        </p>
    </div>
</body>
</html>
      ''';

      print('📧 Sending customer email to: $customerEmail');
      final success = await EmailService.sendEmail(
        recipientEmail: customerEmail,
        subject: customerSubject,
        htmlBody: customerHtml,
      );

      if (success) {
        print('✅ Customer email sent successfully!');
      } else {
        print('❌ Failed to send customer email');
      }
    } catch (e) {
      print('❌ Error sending customer email: $e');
    }
  }

  Future<void> _sendAdminEmail(
    Map<String, dynamic> bookingData,
    Map<String, dynamic> userData,
  ) async {
    try {
      final adminEmail = 'mahekjkevat@gmail.com';

      final adminSubject = '🔔 New Car Rental Booking Request - GearGo';
      final adminHtml = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>New Booking Alert</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #dc3545 0%, #c82333 100%); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
        .header h1 { color: white; margin: 0; font-size: 28px; }
        .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; }
        .info-box { background: white; padding: 20px; border-radius: 10px; margin: 20px 0; border-left: 4px solid #dc3545; }
    </style>
</head>
<body>
    <div class="header">
        <h1>GearGo Admin Alert</h1>
        <p style="margin: 10px 0 0 0; font-size: 16px;">New Booking Request</p>
    </div>
    
    <div class="content">
        <h2 style="color: #333;">Hello Admin,</h2>
        <p style="color: #666;">
            A new car rental booking request has been received on GearGo.
        </p>
        
        <div class="info-box">
            <h3 style="color: #333; margin-bottom: 15px;">👤 Customer Information</h3>
            <p><strong>Name:</strong> ${userData['name'] ?? 'Not Found'}</p>
            <p><strong>Email:</strong> ${userData['email'] ?? 'Not Found'}</p>
            <p><strong>Mobile:</strong> ${userData['mobile_number'] ?? 'Not Found'}</p>
            <p><strong>Location:</strong> ${userData['city'] ?? 'Not Found'}, ${userData['state'] ?? 'Not Found'}, ${userData['country'] ?? 'Not Found'}</p>
            <p><strong>License:</strong> ${userData['license_no'] ?? 'Not Found'}</p>
        </div>
        
        <div class="info-box" style="border-left-color: #007bff;">
            <h3 style="color: #333; margin-bottom: 15px;">🚗 Vehicle Details</h3>
            <p><strong>Car:</strong> ${bookingData['carName']} - ${bookingData['car_brand']}</p>
            <p><strong>Subscription:</strong> ${bookingData['subscription']}</p>
            <p><strong>Seats:</strong> ${bookingData['seats']}</p>
            <p><strong>Distance:</strong> ${bookingData['distance']} km</p>
            <p><strong>Total Amount:</strong> ₹${bookingData['totalPrice'].toStringAsFixed(2)}</p>
        </div>
        
        <div class="info-box" style="border-left-color: #28a745;">
            <h3 style="color: #333; margin-bottom: 15px;">📍 Trip Details</h3>
            <p><strong>From:</strong> ${bookingData['fromLocation']} - ${bookingData['fromAddress']}</p>
            <p><strong>To:</strong> ${bookingData['toLocation']} - ${bookingData['toAddress']}</p>
            <p><strong>Pickup:</strong> ${DateFormat('MMM dd, yyyy - HH:mm').format(widget.pickUpDateTime)}</p>
            <p><strong>Return:</strong> ${DateFormat('MMM dd, yyyy - HH:mm').format(widget.returnDateTime)}</p>
        </div>
        
        <div style="background: #d4edda; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <p style="color: #155724; margin: 0;">
                <strong>💰 Payment Status:</strong> Pending Payment<br>
                <strong>📊 Booking Status:</strong> Pending
            </p>
        </div>
        
        <p style="color: #666;">
            Please review this booking request and take appropriate action.
        </p>
    </div>
    
    <div style="background: #343a40; padding: 20px; text-align: center; color: white;">
        <p style="margin: 0; font-size: 14px;">Best regards,<br><strong>GearGo System</strong></p>
        <p style="margin: 10px 0 0 0; font-size: 12px; color: #adb5bd;">Automated Notification</p>
    </div>
</body>
</html>
      ''';

      print('📧 Sending admin email to: $adminEmail');
      final success = await EmailService.sendEmail(
        recipientEmail: adminEmail,
        subject: adminSubject,
        htmlBody: adminHtml,
      );

      if (success) {
        print('✅ Admin email sent successfully!');
      } else {
        print('❌ Failed to send admin email');
      }
    } catch (e) {
      print('❌ Error sending admin email: $e');
    }
  }

  Future<void> _postCarRentalNotification() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('Users')
            .doc(userId)
            .collection('Notification')
            .add({
              'title': 'Car Rental Request Sent!',
              'description':
                  'Your ${carData!.carName} rental request has been sent. Payment pending.',
              'time': Timestamp.now(),
            });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error sending notification: $e");
    }
  }

  void _showReceiptDialog(Map<String, dynamic> bookingData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.black.withOpacity(0.8),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
                const SizedBox(height: 16),
                Text(
                  'Processing...',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Car: ${bookingData['carName']?.length > 20 ? '${bookingData['carName']?.substring(0, 17)}...' : bookingData['carName'] ?? 'Not Found'}',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'People: ${bookingData['seats'] ?? 'Not Found'}',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
                Text(
                  'Total: ₹${(bookingData['totalPrice'] ?? 0).toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '📧 Sending notifications...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingInformation(recentBooking: bookingData),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Confirm Your Booking",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body:
          carData == null
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
              : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationCard(),
                      const SizedBox(height: 10),
                      _buildSubscriptionOptions(),
                      const SizedBox(height: 10),
                      _buildFuelAndSeats(),
                      const SizedBox(height: 10),
                      _buildUserDetailsCard(),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: _buildBottomCard(),
    );
  }

  Widget _buildLocationCard() => Card(
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Trip Details",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          _buildLocationRow("From", widget.fromAddress, widget.pickUpDateTime),
          const SizedBox(height: 8),
          _buildLocationRow("To", widget.toAddress, widget.returnDateTime),
        ],
      ),
    ),
  );

  Widget _buildLocationRow(
    String label,
    String address,
    DateTime dateTime,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            address.length > 25 ? "${address.substring(0, 22)}..." : address,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      Text(
        DateFormat('d MMM, HH:mm').format(dateTime),
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.blueAccent,
        ),
      ),
    ],
  );

  Widget _buildSubscriptionOptions() => Card(
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Subscription Plans",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubscriptionButton(
                'BASIC',
                Colors.green,
                carData!.basicPrice.toDouble(),
              ),
              _buildSubscriptionButton(
                'PLUS',
                Colors.orange,
                carData!.plusPrice.toDouble(),
              ),
              _buildSubscriptionButton(
                'MAX',
                Colors.red,
                carData!.maxPrice.toDouble(),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildSubscriptionButton(String plan, Color color, double price) {
    final isSelected = selectedSubscription == plan;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSubscription = plan;
          _calculatePrice(selectedSeats, selectedSubscription);
        });
        Fluttertoast.showToast(
          msg: "$plan plan selected!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.grey, width: 2),
        ),
        child: Column(
          children: [
            Text(
              plan,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
            Text(
              '₹${price.toStringAsFixed(2)}/km',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelAndSeats() => Card(
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSpecCard(
            Icons.local_gas_station,
            'Fuel',
            carData!.fuelType,
            Colors.blueAccent,
          ),
          _buildSeatDropdown(),
        ],
      ),
    ),
  );

  Widget _buildSpecCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) => Container(
    width: 120,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 24),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _buildSeatDropdown() => Container(
    width: 150,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color:
          selectedSeats == null
              ? Colors.grey[200]
              : Colors.blueAccent.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: selectedSeats == null ? Colors.grey : Colors.blueAccent,
      ),
    ),
    child: Column(
      children: [
        Icon(
          Icons.chair,
          color: selectedSeats == null ? Colors.black54 : Colors.blueAccent,
          size: 24,
        ),
        Text(
          'Seats',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: selectedSeats == null ? Colors.grey[700] : Colors.blueAccent,
          ),
        ),
        DropdownButton<String>(
          value: selectedSeats,
          hint: Text(
            'Select',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
          items: List.generate(
            carData!.noOfSeats,
            (index) => DropdownMenuItem<String>(
              value: (index + 1).toString(),
              child: Text(
                '${index + 1} Seats',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ),
          onChanged:
              (value) => setState(() {
                selectedSeats = value;
                _calculatePrice(selectedSeats, selectedSubscription);
              }),
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
          icon: Icon(
            Icons.arrow_drop_down,
            color: selectedSeats == null ? Colors.black54 : Colors.blueAccent,
          ),
          underline: const SizedBox(),
        ),
      ],
    ),
  );

  Widget _buildUserDetailsCard() =>
      FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future:
            _firestore
                .collection('Users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .get(),
        builder: (context, snapshot) {
          final name = snapshot.data?.data()?['name'] ?? 'Not Found';
          final email = snapshot.data?.data()?['email'] ?? 'Not Found';
          final mobileNumber =
              snapshot.data?.data()?['mobile_number'] ?? 'Not Found';
          final city = snapshot.data?.data()?['city'] ?? 'Not Found';
          final state = snapshot.data?.data()?['state'] ?? 'Not Found';
          final country = snapshot.data?.data()?['country'] ?? 'Not Found';
          final licenseNo = snapshot.data?.data()?['license_no'] ?? 'Not Found';
          final pinCode = snapshot.data?.data()?['pin_code'] ?? 'Not Found';

          if (snapshot.hasError) {
            Fluttertoast.showToast(
              msg: "Error fetching user data: ${snapshot.error}",
            );
          }

          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Details",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow("Name", name),
                  _buildDetailRow("Email", email),
                  _buildDetailRow("Mobile Number", mobileNumber),
                  _buildDetailRow("City", city),
                  _buildDetailRow("State", state),
                  _buildDetailRow("Country", country),
                  _buildDetailRow("License No", licenseNo),
                  _buildDetailRow("Pin Code", pinCode),
                ],
              ),
            ),
          );
        },
      );

  Widget _buildDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
        ),
      ],
    ),
  );

  Widget _buildBottomCard() {
    final isButtonEnabled =
        isChecked && selectedSubscription != null && selectedSeats != null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isChecked,
                onChanged:
                    (value) => setState(() => isChecked = value ?? false),
                checkColor: Colors.white,
                activeColor: Colors.green,
              ),
              GestureDetector(
                onTap: () {
                  setState(() => isChecked = !isChecked);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Policy()),
                  );
                },
                child: Text(
                  'Terms and Conditions',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          if (_errorMessage case String message?)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          const Divider(),
          const SizedBox(height: 2),
          Text(
            "Booking Summary",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            "Distance",
            "${widget.coverDistance.toStringAsFixed(1)} km",
          ),
          _buildSummaryRow(
            "Subscription",
            selectedSubscription ?? 'Not selected',
          ),
          _buildSummaryRow("Seats", selectedSeats ?? 'Not selected'),
          const Divider(color: Colors.grey, thickness: 1),
          _buildSummaryRow(
            "Total",
            "₹${calculatedPrice.toStringAsFixed(2)}",
            isTotal: true,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${calculatedPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              ElevatedButton(
                onPressed:
                    isButtonEnabled
                        ? () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (_) => const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.yellow,
                                    ),
                                  ),
                                ),
                          );
                          await Future.delayed(const Duration(seconds: 1));
                          Navigator.pop(context);
                          _saveCarBooking();
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'Book Now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.black : Colors.grey[700],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.green[700] : Colors.grey[700],
              ),
            ),
          ],
        ),
      );
}
