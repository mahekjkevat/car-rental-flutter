import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RevenueUserDetailsPage extends StatefulWidget {
  final String email;
  final String city;
  final String name;

  const RevenueUserDetailsPage({
    Key? key,
    required this.email,
    required this.city,
    required this.name,
  }) : super(key: key);

  @override
  _RevenueUserDetailsPageState createState() => _RevenueUserDetailsPageState();
}

class _RevenueUserDetailsPageState extends State<RevenueUserDetailsPage> {
  bool isLoading = true;
  Map<String, List<QueryDocumentSnapshot>> cityBookings = {};

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    setState(() {
      isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('car_booking')
          .where('userEmail', isEqualTo: widget.email)
          .get();

      Map<String, List<QueryDocumentSnapshot>> cityMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final bookingCity = (data['userCity'] ?? '').toString().toLowerCase();

        if (cityMap.containsKey(bookingCity)) {
          cityMap[bookingCity]!.add(doc);
        } else {
          cityMap[bookingCity] = [doc];
        }
      }

      setState(() {
        cityBookings = cityMap;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user bookings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatPrice(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Details for ${widget.name}',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.yellow,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
        ),
      )
          : cityBookings.isEmpty
          ? Center(
        child: Text(
          'No bookings found for this user.',
          style: GoogleFonts.poppins(color: Colors.red, fontSize: 18),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(8),
        children: cityBookings.entries.map((entry) {
          final cityName = entry.key;
          final bookings = entry.value;
          final totalCityPrice = bookings.fold<double>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['totalPrice'] ?? 0);
          });
          return ExpansionTile(
            title: Text(
              'City: ${cityName[0].toUpperCase()}${cityName.substring(1)}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              'Total: ₹${formatPrice(totalCityPrice)}',
              style: GoogleFonts.poppins(color: Colors.green),
            ),
            backgroundColor: Colors.white.withOpacity(0.1),
            children: bookings.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final carName = data['carName'] ?? '';
              final pickUp =
              (data['pickUpDateTime'] as Timestamp?)?.toDate();
              final returnDate =
              (data['returnDateTime'] as Timestamp?)?.toDate();
              final price = (data['totalPrice'] ?? 0).toDouble();

              final dateFormat = DateFormat('MMM d, yyyy');
              final bookingDates = (pickUp != null && returnDate != null)
                  ? '${dateFormat.format(pickUp)} - ${dateFormat.format(returnDate)}'
                  : 'N/A';

              return ListTile(
                title: Text(
                  carName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  bookingDates,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                  ),
                ),
                trailing: Text(
                  '₹${formatPrice(price)}',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}