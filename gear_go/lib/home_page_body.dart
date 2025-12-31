// lib/CarListPage.dart
import 'package:flutter/material.dart';
import 'package:gear_go/car_brand_category.dart';
import 'package:gear_go/search_filter_complex_code.dart';
import 'package:gear_go/filter_car_complex.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:card_loading/card_loading.dart';
import 'ViewCarFilterPage.dart';
import 'car_data_model.dart';
import 'custom_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CarListPage extends StatefulWidget {
  final int selectedIndex;
  final List<Widget> pages;

  const CarListPage({
    super.key,
    required this.selectedIndex,
    required this.pages,
  });

  @override
  _CarListPageState createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<CarDataModel> _cars = [];
  List<CarDataModel> _filteredCars = [];
  bool _isLoading = true;
  bool _isSearching = false;
  Set<String> _favoriteCarIds = {};

  // Location variables
  String _selectedFromLocation = 'Bardoli';
  String? _selectedToLocation;
  final List<String> _toLocations = [
    'Navsari',
    'Mahuva',
    'Surat',
    'Bilimora',
    'Sachin',
    'Tarsadi'
  ];

  // Date variables
  DateTime? _selectedPickupDate;
  DateTime? _selectedReturnDate;

  @override
  void initState() {
    super.initState();
    _fetchCars();
    // Sort locations alphabetically
    _toLocations.sort();
  }

  Future<void> _fetchCars() async {
    try {
      DateTime startTime = DateTime.now();
      var snapshot = await _firestore.collection('CarData').get();
      DateTime endTime = DateTime.now();
      int fetchDuration = endTime.difference(startTime).inMilliseconds;

      setState(() {
        _cars = snapshot.docs.map((doc) => CarDataModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        )).toList();
        _filteredCars = _cars; // Initialize filtered cars with all cars

        if (fetchDuration < 1000) {
          Future.delayed(Duration(milliseconds: 1000 - fetchDuration), () {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          });
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      print("Error fetching cars: $e");
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: "Error fetching cars: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }


  Future<void> _checkAvailabilityAndSearch() async {
    if (_selectedToLocation == null) {
      Fluttertoast.showToast(
        msg: "Please select destination location",
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_selectedPickupDate == null || _selectedReturnDate == null) {
      Fluttertoast.showToast(
        msg: "Please select pickup and return dates",
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_selectedReturnDate!.isBefore(_selectedPickupDate!)) {
      Fluttertoast.showToast(
        msg: "Return date cannot be before pickup date",
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      print('🔍 Starting availability check...');
      print('📍 From: $_selectedFromLocation');
      print('📍 To: $_selectedToLocation');
      print('📅 Pickup: $_selectedPickupDate');
      print('📅 Return: $_selectedReturnDate');

      // Get all users
      final usersSnapshot = await _firestore.collection('Users').get();
      print('👥 Total users found: ${usersSnapshot.docs.length}');

      Set<String> bookedCarIds = {};

      // Check each user's bookings
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        print('🔍 Checking bookings for user: $userId');

        try {
          final bookingsSnapshot = await _firestore
              .collection('Users')
              .doc(userId)
              .collection('car_booking')
              .get();

          print('📋 Found ${bookingsSnapshot.docs.length} bookings for user $userId');

          for (final bookingDoc in bookingsSnapshot.docs) {
            final bookingData = bookingDoc.data();
            final carDocId = bookingData['documentId'] as String?;
            final status = bookingData['status'] as String?;

            // Skip if no car document ID or if booking is cancelled/completed
            if (carDocId == null ||
                status == 'Cancelled' ||
                status == 'Completed' ||
                status == 'Rejected') {
              continue;
            }

            final pickupTimestamp = bookingData['pickUpDateTime'] as Timestamp?;
            final returnTimestamp = bookingData['returnDateTime'] as Timestamp?;

            if (pickupTimestamp != null && returnTimestamp != null) {
              final bookedPickup = pickupTimestamp.toDate();
              final bookedReturn = returnTimestamp.toDate();

              // Check for date overlap
              final hasOverlap = (_selectedPickupDate!.isBefore(bookedReturn) ||
                  _selectedPickupDate!.isAtSameMomentAs(bookedReturn)) &&
                  (_selectedReturnDate!.isAfter(bookedPickup) ||
                      _selectedReturnDate!.isAtSameMomentAs(bookedPickup));

              if (hasOverlap) {
                bookedCarIds.add(carDocId);
                print('🚫 Car $carDocId is booked during selected dates');
              }
            }
          }
        } catch (e) {
          print('❌ Error checking bookings for user $userId: $e');
        }
      }

      print('📊 Total booked cars found: ${bookedCarIds.length}');
      print('🚗 Available cars: ${_cars.length - bookedCarIds.length}');

      // Filter available cars
      final availableCars = _cars.where((car) => !bookedCarIds.contains(car.documentId)).toList();

      setState(() {
        _filteredCars = availableCars;
        _isSearching = false;
      });

      if (availableCars.isEmpty) {
        _showNotAvailableDialog();
      } else {
        // Navigate to ViewCarFilterPage with available cars and search criteria
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewCarFilterPage(
              availableCars: availableCars,
              fromLocation: _selectedFromLocation,
              toLocation: _selectedToLocation!,
              pickupDate: _selectedPickupDate!,
              returnDate: _selectedReturnDate!,
              favoriteCarIds: _favoriteCarIds,
            ),
          ),
        );

        Fluttertoast.showToast(
          msg: "Found ${availableCars.length} available vehicles",
          backgroundColor: Colors.green,
        );
      }

    } catch (e) {
      print('❌ Error during availability check: $e');
      setState(() {
        _isSearching = false;
      });
      Fluttertoast.showToast(
        msg: "Error checking availability: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  void _showNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text("Not Available"),
          ],
        ),
        content: Text(
          "No vehicles available for the selected dates and locations. "
              "Please try different dates or locations.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPickupDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)), // 1 year from now
    );
    if (picked != null) {
      setState(() {
        _selectedPickupDate = picked;
        // Reset return date if it's before the new pickup date
        if (_selectedReturnDate != null && _selectedReturnDate!.isBefore(picked)) {
          _selectedReturnDate = null;
        }
      });
    }
  }

  Future<void> _selectReturnDate() async {
    if (_selectedPickupDate == null) {
      Fluttertoast.showToast(
        msg: "Please select pickup date first",
        backgroundColor: Colors.orange,
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPickupDate!.add(Duration(days: 1)),
      firstDate: _selectedPickupDate!,
      lastDate: _selectedPickupDate!.add(Duration(days: 5)), // Max 5 days from pickup
    );
    if (picked != null) {
      setState(() {
        _selectedReturnDate = picked;
      });
    }
  }

  void _showAddToFavoritesDialog(BuildContext context, CarDataModel car) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[50]!, Colors.white],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.blue[200],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Header
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Add to Favorites",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Car Preview
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              car.carImage1,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: Colors.blue[50],
                                child: Icon(Icons.car_rental, color: Colors.blue, size: 40),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            car.carName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Save this car for quick access later",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.blue[300]!),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final user = _auth.currentUser;
                              if (user != null) {
                                try {
                                  await _firestore
                                      .collection('Users')
                                      .doc(user.uid)
                                      .collection('Favourites')
                                      .add({
                                    'carDocumentId': car.documentId,
                                    'carName': car.carName,
                                    'addedAt': FieldValue.serverTimestamp(),
                                  });
                                  Navigator.pop(context);
                                  CustomToast.show(
                                    context: context,
                                    message: "⭐ Added to Favorites!",
                                    duration: Duration(seconds: 2),
                                    textColor: Colors.white,
                                    gradientColors: [Colors.blue, Colors.lightBlue],
                                  );
                                } catch (e) {
                                  print("Error: $e");
                                  Fluttertoast.showToast(
                                    msg: "Failed to add to favorites.",
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                  );
                                }
                              } else {
                                Fluttertoast.showToast(
                                  msg: "Please log in to add to favorites.",
                                  backgroundColor: Colors.orange,
                                  textColor: Colors.white,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              elevation: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite, size: 20, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Add',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.blue[50],
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: 6,
          itemBuilder: (_, __) => CardLoading(
            height: 240,
            width: double.infinity,
            borderRadius: BorderRadius.circular(20),
            margin: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );
    }

    if (widget.selectedIndex != 0) {
      return widget.pages[widget.selectedIndex];
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[900]!, Colors.blue[700]!],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Find Your Perfect Ride",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "${_cars.length} vehicles available for rent",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 20),

                // Search Bar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SearchFilterComplexCode()),
                    );
                    Fluttertoast.showToast(
                      msg: "You Can Search depend Your Choice!!",
                    );
                  },
                  child: Container(
                    height: 56,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.blue[600], size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Search vehicles...",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => FilterCarComplex()),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[600]!, Colors.blue[400]!],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Car Brand Category
          CarBrandCategory(),

// Search Card - Compact Professional Design
          Card(
            margin: EdgeInsets.all(12),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.blue[50]!],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: "Rent cars in ",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: "Bardoli",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Compact Location Row
                    Row(
                      children: [
                        // From Location
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.navigation, color: Colors.blue[600], size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "From",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.blue[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _selectedFromLocation,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[900],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // To Location Dropdown
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedToLocation,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down, color: Colors.blue[600], size: 18),
                                hint: Text(
                                  "To",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                items: _toLocations.map((location) {
                                  return DropdownMenuItem<String>(
                                    value: location,
                                    child: Text(
                                      location,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedToLocation = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Compact Date Selection
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectPickupDate,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.blue[600], size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Pickup",
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.blue[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _selectedPickupDate == null
                                              ? "Select Date"
                                              : "${_selectedPickupDate!.day}/${_selectedPickupDate!.month}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: _selectedPickupDate == null
                                                ? Colors.grey[500]
                                                : Colors.blue[900],
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectReturnDate,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.blue[600], size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Return",
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.blue[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _selectedReturnDate == null
                                              ? "Select Date"
                                              : "${_selectedReturnDate!.day}/${_selectedReturnDate!.month}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: _selectedReturnDate == null
                                                ? Colors.grey[500]
                                                : Colors.blue[900],
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Search Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Colors.blue[700]!, Colors.blue[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSearching ? null : _checkAvailabilityAndSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: Size(double.infinity, 0),
                        ),
                        child: _isSearching
                            ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 18),
                            SizedBox(width: 6),
                            Text(
                              "FIND CARS",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
    );
  }
}