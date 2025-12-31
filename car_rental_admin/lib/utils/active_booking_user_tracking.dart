import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Map dependencies
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'FullScreenMapPage.dart';
import 'custom_toast.dart';

class ActiveBookingUserTracking extends StatefulWidget {
  final DocumentReference documentReference;

  const ActiveBookingUserTracking({Key? key, required this.documentReference})
      : super(key: key);

  @override
  _ActiveBookingUserTrackingState createState() =>
      _ActiveBookingUserTrackingState();
}

class _ActiveBookingUserTrackingState extends State<ActiveBookingUserTracking> {
  bool _isLoading = true;
  Map<String, dynamic>? _bookingData;
  bool _hasInternet = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((results) {
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
          'Active Running Tracking',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),      body: Stack(
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
                  child: _isLoading
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
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          margin:
                          EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                            title: Text(
                              _bookingData!['userName'] ??
                                  'User Name',
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
                              onPressed: () => _makePhoneCall(
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
                        Center(
                          child: ElevatedButton(
                            onPressed: _showReviewOptions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            child: Text(
                              'Finish Rental',
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
              _bookingData!['carImage1'] ?? 'https://via.placeholder.com/300x150',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
              const Center(child: Icon(Icons.directions_car, size: 100)),
            ),
            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              color: Colors.black.withOpacity(0.2),
              margin: EdgeInsets.symmetric(vertical: 1),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [
                    _buildMap(),
                    // Button below the map
                    SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.black,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ).copyWith(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (states) => Colors.transparent,
                          ),
                          shadowColor: MaterialStateProperty.all(Colors.black54),
                        ),
                        onPressed: () {
                          final latStr = _bookingData?['location_latitude'];
                          final lonStr = _bookingData?['location_longitude'];
                          final double? latitude = _parseCoordinate(latStr);
                          final double? longitude = _parseCoordinate(lonStr);

                          if (latitude != null && longitude != null) {
                            print('My Location: Lat=$latitude, Lon=$longitude');
                            print('Vehicle Location: Lat=$latitude, Lon=$longitude');

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenMapPage(
                                  latitude: latitude,
                                  longitude: longitude,
                                  title: 'Track Car - Flutter MAP',
                                  documentReference: widget.documentReference, // Pass documentReference
                                ),
                              ),
                            );
                          }
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.blue.shade600, Colors.pinkAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Container(
                            constraints: BoxConstraints(minWidth: 100,maxHeight: 50),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_location_alt_sharp, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Open Full Screen Map',
                                  style: GoogleFonts.tillana(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    ),

                  ],
                )
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
            _buildDetailRow(
              Icons.location_on,
              'Location Status',
              _bookingData!['location_Status'] != null
                  ? (_bookingData!['location_Status']
                  ? 'Active'
                  : 'Inactive')
                  : 'Not provided',
            ),
            // Parse latitude and longitude strings into doubles
            _buildDetailRow(
              Icons.wrong_location_rounded,
              'Latitude',
              _bookingData!['location_latitude'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.wrong_location_sharp,
              'Longitude',
              _bookingData!['location_longitude'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.access_time,
              'Location Timestamp',
              _bookingData!['location_timestamp'] != null
                  ? _formatTimestamp(_bookingData!['location_timestamp']
              as Timestamp?)
                  : 'Not provided',
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
                      color: isStatus
                          ? (value.toLowerCase() == 'accepted'
                          ? Colors.green
                          : value.toLowerCase() == 'rejected'
                          ? Colors.red
                          : Colors.orange)
                          : isPrice
                          ? Colors.yellow[700]
                          : Colors.white,
                      fontWeight:
                      isStatus || isPrice ? FontWeight.w600 : FontWeight.normal,
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
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Complete Rental', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              // Update the booking status to 'completed' and feedback_status to true
              await widget.documentReference.update({
                'status': 'completed',
                'feedback_status': true,
                'location_latitude':'',
                'location_longitude':'',
                'location_timestamp':null,
                'location_Status':false,
              });
              // Optionally, show a confirmation message
              CustomToast.show(
                context,
                message: 'Rental marked as completed. Customer can now provide own Feedback.',
              );
              // Refresh data if needed
              await _fetchBookingData();
            },
          ),
        ],
      ),
    );
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
              Text(message, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20)),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text('OK', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
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

  // Build Map Widget
  Widget _buildMap() {
    final latStr = _bookingData?['location_latitude'];
    final lonStr = _bookingData?['location_longitude'];
    final locStatus = _bookingData?['location_Status'];

    final double? latitude = _parseCoordinate(latStr);
    final double? longitude = _parseCoordinate(lonStr);

    if (latitude == null || longitude == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'GPS is Not Active',
                style: GoogleFonts.racingSansOne(
                  fontSize: 20,
                  color: Colors.yellow,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );    }

    return GestureDetector(
      onTap: () {
        // Check if location sharing is off
        if (locStatus == null || locStatus == false) {
          Fluttertoast.showToast(
            msg: "Location are Not Sharing by the Vehicle or Off",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return; // Don't navigate
        }

        // Print your own latitude & longitude
        print('Your Location: Lat=$latitude, Lon=$longitude');

        // Print vehicle's latitude & longitude
        print('Vehicle Location: Lat=$latitude, Lon=$longitude');

        // Navigate to fullscreen map page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenMapPage(
              latitude: latitude,
              longitude: longitude,
              title: 'Car Tracking', // pass title if needed
            ),
          ),
        );
      },
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(top: 8),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(latitude, longitude),
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.yourappname',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 30,
                  height: 30,
                  point: LatLng(latitude, longitude),
                  child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }}