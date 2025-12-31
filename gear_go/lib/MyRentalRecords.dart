import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'CancelledBookingView.dart';
import 'HomePage.dart';
import 'PendingBookingView.dart';
import 'l10n/app_localizations.dart'; // Ensure this import is included

import 'AccepetedBookingCarViewPage.dart';
import 'CompletedBookingDetailsPage.dart';
import 'car_booking_model.dart';
import 'main.dart';

// Extension for localization to get status string
extension AppLocalizationsExtension on AppLocalizations {
  String getStatusString(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return this.accepted;
      case 'Pending':
        return this.pending;
      case 'completed':
        return this.completed;
      case 'cancelled':
        return this.cancelled;
      case 'active':
        return this.active;
      default:
        return status; // fallback
    }
  }
}

class MyRentalRecords extends StatefulWidget {
  const MyRentalRecords({super.key});

  @override
  State<MyRentalRecords> createState() => _MyRentalRecordsState();
}

class _MyRentalRecordsState extends State<MyRentalRecords> {
  final List<String> _statuses = ['All', 'accepted', 'pending', 'completed', 'cancelled', 'confirmed'];  String _selectedStatus = 'All';
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<DocumentSnapshot> _allBookings = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';


  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  @override
  void initState() {
    super.initState();
    _setupBookingsStream();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  void _setupBookingsStream() {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _bookingsSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(_currentUserId)
        .collection('car_booking')
        .orderBy('bookingTime', descending: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      setState(() {
        _allBookings = snapshot.docs;
        _isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error in bookings stream: $error');
    });
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_currentUserId)
          .collection('car_booking')
          .orderBy('bookingTime', descending: true)
          .get();

      setState(() {
        _allBookings = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching bookings: $e');
    }
  }

  List<DocumentSnapshot> _getFilteredAndSearchedBookings() {
    List<DocumentSnapshot> filteredBookings = _allBookings;

    if (_selectedStatus != 'All') {
      filteredBookings = filteredBookings.where((booking) {
        final data = booking.data() as Map<String, dynamic>;
        return data['status']?.toString().toLowerCase() == _selectedStatus.toLowerCase();
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredBookings = filteredBookings.where((booking) {
        final data = booking.data() as Map<String, dynamic>;
        final carName = data['carName']?.toString().toLowerCase() ?? '';
        final bookingId = data['bookingId']?.toString().toLowerCase() ?? '';
        final searchQueryLower = _searchQuery.toLowerCase();
        return carName.contains(searchQueryLower) || bookingId.contains(searchQueryLower);
      }).toList();
    }

    return filteredBookings;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          backgroundColor: Colors.blue[600],
          title: Text(localizations.helpSupport),
        ),
        body: Center(
          child: Text(
            localizations.pleaseLogin ?? 'Please log in to view your rental records.',
            style: GoogleFonts.poppins(color: Colors.black),
          ),
        ),
      );
    }

    final filteredBookings = _getFilteredAndSearchedBookings();

    return WillPopScope(
      onWillPop: () async {
        // Navigate to HomePage when back button/gesture is pressed
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
        );
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            localizations.myRentalRecords,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.blue[700]),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
                    (route) => false,
              );
            },
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.language, color: Colors.blue[700]),
              onSelected: (String value) {
                Locale newLocale;
                switch (value) {
                  case 'en':
                    newLocale = Locale('en');
                    break;
                  case 'hi':
                    newLocale = Locale('hi');
                    break;
                  case 'gu':
                    newLocale = Locale('gu');
                    break;
                  default:
                    newLocale = Locale('en');
                }
                MyApp.setLocale(context, newLocale);
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(value: 'en', child: Text('English')),
                PopupMenuItem(value: 'hi', child: Text('Hindi')),
                PopupMenuItem(value: 'gu', child: Text('Gujarati')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizations.searchBookings ?? 'Search bookings...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.blue[100],
                ),
                style: GoogleFonts.poppins(color: Colors.black),
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: _statuses.map((status) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(localizations.getStatusString(status)),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                      selectedColor: Colors.blue[800],
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectedStatus == status ? Colors.blue[800]! : Colors.blue[200]!,
                        ),
                      ),
                      labelStyle: GoogleFonts.poppins(
                        color: _selectedStatus == status ? Colors.white : Colors.blue[600],
                        fontWeight: _selectedStatus == status ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
                : filteredBookings.isEmpty
                ? Expanded(
              child: Center(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? '${localizations.noResultsFor} "$_searchQuery".'
                      : '${localizations.noRentalsFound} $_selectedStatus.',
                  style: GoogleFonts.poppins(color: Colors.blue[600]),
                ),
              ),
            )
                : Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchBookings,
                color: Colors.blue,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    return _buildBookingCard(filteredBookings[index], localizations);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(DocumentSnapshot booking, AppLocalizations localizations) {
    final data = booking.data() as Map<String, dynamic>;
    final bookingId = booking.id;

    final isLate = (data['status'] == 'Active' &&
        data['endDate'] != null &&
        DateFormat('dd MMM, yyyy').parse(data['endDate']).isBefore(DateTime.now()));

    final status = data['status']?.toString() ?? '';
    final carBooking = CarBooking.fromFirestore(data, bookingId);

    final Timestamp bookingTimestamp = data['bookingTime'] as Timestamp;
    final DateTime bookingDateTime = bookingTimestamp.toDate();
    final formattedBookingDate = DateFormat('dd MMM, yyyy').format(bookingDateTime);

    final String fromAddress = data['fromAddress'] ?? 'N/A';
    final String truncatedAddress =
    fromAddress.length > 25 ? '${fromAddress.substring(0, 25)}...' : fromAddress;

    return GestureDetector(
      onTap: () {
        final lowerStatus = status.toLowerCase().trim();
        print('Booking status: $status, lowerStatus: $lowerStatus');

        switch (lowerStatus) {
          case 'completed':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompletedBookingDetailsPage(booking: carBooking),
              ),
            );
            break;
          case 'accepted':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AcceptedBookingCarViewPage(booking: carBooking),
              ),
            );
            break;
          case 'pending':  // Changed to lowercase
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PendingBookingView(booking: carBooking),
              ),
            );
            break;
          case 'cancelled':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CancelledBookingView(booking: carBooking),
              ),
            );
            break;
          case 'confirmed':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AcceptedBookingCarViewPage(booking: carBooking),
              ),
            );
            break;
          default:
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Unknown booking status: $status"),
                ),
              );
            }
            break;
        }
      },
      child: Card(
        color: Colors.white,
        elevation: 8,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'car-image-$bookingId',
                child: _buildCurvedCarImage(data['carImage1']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['carName'] ?? 'Unknown Car',
                            style: GoogleFonts.poppins(
                              color: Colors.blue[800],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusChip(status, isLate, localizations),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          localizations.bookedOn,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          formattedBookingDate,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          localizations.price,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '\₹${data['totalPrice']?.toStringAsFixed(2) ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          localizations.from,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            truncatedAddress,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
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
    );
  }

  Widget _buildCurvedCarImage(String? imageUrl) {
    final borderRadius = BorderRadius.circular(16);
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: borderRadius,
        ),
        child: Icon(Icons.directions_car, size: 50, color: Colors.blue[400]),
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 100,
          height: 100,
          color: Colors.blue[100],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 100,
          height: 100,
          color: Colors.blue[100],
          child: Icon(Icons.error, color: Colors.blue[600]),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isLate, AppLocalizations localizations) {
    final lowerStatus = status.toLowerCase().trim();
    print('Booking status: $status, lowerStatus: $lowerStatus');
    IconData iconData;
    Color iconColor;
    Color textColor;

    switch (lowerStatus) {
      case 'accepted':
        iconData = Icons.check_circle_outline;
        iconColor = Colors.indigo;
        textColor = Colors.indigo;
        break;
      case 'pending':
        iconData = Icons.schedule;
        iconColor = Colors.amber;
        textColor = Colors.amber;
        break;
      case 'completed':
        iconData = Icons.task_alt;
        iconColor = Colors.green;
        textColor = Colors.green;
        break;
      case 'cancelled':
        iconData = Icons.cancel;
        iconColor = Colors.red;
        textColor = Colors.red;
        break;
        case 'confirmed':
        iconData = Icons.swipe_right;
        iconColor = Colors.cyan;
        textColor = Colors.cyan;
        break;
      default:
        iconData = Icons.info_outline;
        iconColor = Colors.grey;
        textColor = Colors.grey;
        break;
    }

    if (isLate) {
      iconData = Icons.access_time_filled;
      iconColor = Colors.orange[800]!;
      textColor = Colors.orange[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            isLate ? localizations.late : localizations.getStatusString(status),
            style: GoogleFonts.poppins(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}