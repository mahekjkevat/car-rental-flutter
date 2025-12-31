import 'package:flutter/material.dart';
import 'package:gear_go/AccepetedBookingCarViewPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'car_booking_model.dart';

class ActiveBooking extends StatefulWidget {
  const ActiveBooking({Key? key}) : super(key: key);

  @override
  _ActiveBookingState createState() => _ActiveBookingState();
}

class _ActiveBookingState extends State<ActiveBooking> {
  bool _isLoading = true;
  List<CarBooking> _acceptedBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchAcceptedBookings();
  }

  Future<void> _fetchAcceptedBookings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _acceptedBookings = [];
        });
        // Optionally, show a message
        return;
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('car_booking')
          .where('status', isEqualTo: 'accepted') // filter for accepted bookings
          .orderBy('bookingTime', descending: true)
          .get();

      List<CarBooking> bookings = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return CarBooking.fromFirestore(data, doc.id);
      }).toList();

      setState(() {
        _acceptedBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _acceptedBookings = [];
      });
      // Optionally, show error toast
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Active Bookings',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[800],
        centerTitle: false, // Title aligned to start (left)
        iconTheme: IconThemeData(color: Colors.white), // Back icon color
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.dotsTriangle(
                color: Colors.blue[700]!,
                size: 60,
              ),
            )
          : _acceptedBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 100, color: Colors.blue[200]),
                      SizedBox(height: 20),
                      Text('No active bookings found.',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _acceptedBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _acceptedBookings[index];
                    return GestureDetector(
                      onTap: () {
                        // You can navigate to detailed view if needed
                        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AcceptedBookingCarViewPage(booking: booking),
  ),
);
                      },
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        margin: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.blue[50]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    booking.carImage1,
                                    width: 100,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 100,
                                      height: 70,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.error, color: Colors.red),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              booking.carName,
                                              style: GoogleFonts.poppins(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[900],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(booking.status).withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              booking.status,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: _getStatusColor(booking.status),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined, color: Colors.blue[600], size: 16),
                                          SizedBox(width: 6),
                                          Text(
                                            DateFormat('d MMM, yyyy')
                                                .format(booking.pickUpDateTime.toDate()),
                                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.attach_money_outlined, color: Colors.blue[700], size: 16),
                                          SizedBox(width: 6),
                                          Text(
                                            '₹${booking.totalPrice.toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, color: Colors.blue[600], size: 16),
                                          SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '${booking.fromAddress} to ${booking.toAddress}',
                                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.grey[600]!;
      case 'Cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}