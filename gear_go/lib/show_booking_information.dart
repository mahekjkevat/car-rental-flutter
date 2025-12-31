import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'MyBooking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingInformation extends StatelessWidget {
  final Map<String, dynamic>? recentBooking;

  const BookingInformation({super.key, required this.recentBooking});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/HomePage');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          elevation: 0,
          title: Text(
            'Booking Request',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: recentBooking == null
            ? const Center(
          child: Text(
            'No booking details available.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Booking Request Sent Card
              Center(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[700]!, Colors.orange[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 60,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Request Sent!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Your rental request is pending approval.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Status Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Status',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            recentBooking!['status'] ?? 'Pending',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        recentBooking!['status'] == 'confirmed'
                            ? Icons.check_circle
                            : Icons.pending,
                        color: Colors.white,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Payment Status Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[700]!, Colors.purple[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Status',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            recentBooking!['payment_method'] ?? 'Pending Payment',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        recentBooking!['payment_method'] == 'RazorPay'
                            ? Icons.payment
                            : Icons.payment_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ),
              // Car Details Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          recentBooking!['carImage1'] ??
                              'https://via.placeholder.com/150',
                          width: 120,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                          const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 80,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recentBooking!['carName'] ?? 'Not Found',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Booked on: ${DateFormat('d MMM yyyy, HH:mm').format((recentBooking!['bookingTime'] as Timestamp).toDate())}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Trip Details Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _buildDetailSection('Trip Details', [
                    _buildHistoryRow(
                      "From",
                      recentBooking!['fromAddress'] ?? 'Not Found',
                      Icons.location_on,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "To",
                      recentBooking!['toAddress'] ?? 'Not Found',
                      Icons.location_off,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Pick-Up",
                      DateFormat('d MMM yyyy, HH:mm').format(
                        (recentBooking!['pickUpDateTime'] as Timestamp)
                            .toDate(),
                      ),
                      Icons.calendar_today,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Return",
                      DateFormat('d MMM yyyy, HH:mm').format(
                        (recentBooking!['returnDateTime'] as Timestamp)
                            .toDate(),
                      ),
                      Icons.calendar_today,
                      iconColor: Colors.blue[700],
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              // Booking Summary Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _buildDetailSection('Booking Summary', [
                    _buildHistoryRow(
                      "Distance",
                      "${recentBooking!['distance']?.toStringAsFixed(1) ?? 'Not Found'} km",
                      Icons.straighten,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Subscription",
                      recentBooking!['subscription'] ?? 'Not Found',
                      Icons.subscriptions,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Seats",
                      recentBooking!['seats'] ?? 'Not Found',
                      Icons.event_seat,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Total",
                      "₹${recentBooking!['totalPrice']?.toStringAsFixed(2) ?? 'Not Found'}",
                      Icons.attach_money,
                      isBold: true,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Status",
                      recentBooking!['status'] ?? 'Not Found',
                      Icons.info,
                      isBold: true,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Payment Method",
                      recentBooking!['payment_method'] ?? 'Not Found',
                      Icons.payment,
                      isBold: true,
                      iconColor: Colors.blue[700],
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              // User Details Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _buildDetailSection('Your Details', [
                    _buildHistoryRow(
                      "Name",
                      recentBooking!['userName'] ?? 'Not Found',
                      Icons.person,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Email",
                      recentBooking!['userEmail'] ?? 'Not Found',
                      Icons.email,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Mobile Number",
                      recentBooking!['userMobile'] ?? 'Not Found',
                      Icons.phone,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "City",
                      recentBooking!['userCity'] ?? 'Not Found',
                      Icons.location_city,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "State",
                      recentBooking!['userState'] ?? 'Not Found',
                      Icons.location_on,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Country",
                      recentBooking!['userCountry'] ?? 'Not Found',
                      Icons.public,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "License No",
                      recentBooking!['userLicense'] ?? 'Not Found',
                      Icons.badge,
                      iconColor: Colors.blue[700],
                    ),
                    _buildHistoryRow(
                      "Pin Code",
                      recentBooking!['userPinCode'] ?? 'Not Found',
                      Icons.pin_drop,
                      iconColor: Colors.blue[700],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MyBooking()),
                  (Route<dynamic> route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: Colors.blue[900],
            ),
            child: Text(
              'My Rentals',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildHistoryRow(String label, String value, IconData icon,
      {bool isBold = false, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
                color: Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}