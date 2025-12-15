import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'order_model.dart';
import 'package:http/http.dart' as http;

// --- Consistent Color Definitions ---
const Color primaryOrange = Color(0xFFE65100);
const Color brownColor = Color(0xFF795548);
const Color grayText = Color(0xFF757575);
const Color darkGrayText = Color(0xFF5A5A5A);
const Color lightBackground = Colors.white;

class CheckMyOrder extends StatefulWidget {
  final String orderId;
  final Order? order;

  const CheckMyOrder({super.key, required this.orderId, this.order});

  @override
  State<CheckMyOrder> createState() => _CheckMyOrderState();
}

class _CheckMyOrderState extends State<CheckMyOrder> {
  late Future<Order?> _orderFuture;
  Position? _currentPosition;
  String _currentAddress = "Fetching location...";
  bool _isTracking = false;
  Timer? _locationTimer;
  Timer? _fetchLocationTimer;
  MapController _mapController = MapController();
  LatLng? _deliveryScooterPosition;
  double _distance = 0.0;
  int _etaMinutes = 0;
  String? _firestoreDocumentId;
  double _speed = 0.0;
  bool _isIconBlinking = false;
  Timer? _blinkTimer;

  List<LatLng> _routePoints = [];
  Timer? _routeUpdateTimer;

  @override
  void initState() {
    super.initState();
    print('🔄 CheckMyOrder initState called for order: ${widget.orderId}');
    _orderFuture = _fetchOrderDetails();
    _requestLocationPermission();
    _startBlinkAnimation();
  }

  @override
  void dispose() {
    print('🛑 CheckMyOrder dispose called - stopping all timers');
    _stopLocationTracking();
    _locationTimer?.cancel();
    _fetchLocationTimer?.cancel();
    _blinkTimer?.cancel();
    _routeUpdateTimer?.cancel();
    super.dispose();
  }

  void _startBlinkAnimation() {
    _blinkTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (_isTracking) {
        setState(() {
          _isIconBlinking = !_isIconBlinking;
        });
      }
    });
  }

  Future<void> _fetchRoute() async {
    if (_currentPosition == null || _deliveryScooterPosition == null) {
      return;
    }

    try {
      print('🛣️ Fetching route from OSRM...');

      final startLng = _currentPosition!.longitude;
      final startLat = _currentPosition!.latitude;
      final endLng = _deliveryScooterPosition!.longitude;
      final endLat = _deliveryScooterPosition!.latitude;

      final url = 'http://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final routePoints = coordinates.map<LatLng>((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          setState(() {
            _routePoints = routePoints;
          });

          print('✅ Route fetched with ${_routePoints.length} points');
        }
      } else {
        print('❌ Failed to fetch route: ${response.statusCode}');
        // Fallback to straight line if route service fails
        _setStraightLineRoute();
      }
    } catch (e) {
      print('❌ Error fetching route: $e');
      // Fallback to straight line
      _setStraightLineRoute();
    }
  }

  void _setStraightLineRoute() {
    if (_currentPosition != null && _deliveryScooterPosition != null) {
      setState(() {
        _routePoints = [
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          _deliveryScooterPosition!,
        ];
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    print('📍 Requesting location permission...');
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('📍 Permission requested: $permission');
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Location permission permanently denied');
      _showToast('Location permission is required for live tracking');
      return;
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      print('✅ Location permission granted');
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    print('📍 Getting current location...');
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('📍 Current position: ${position.latitude}, ${position.longitude}');

      // Calculate speed if we have previous position
      if (_currentPosition != null) {
        final double distanceMoved = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        final double timeDiff = 3.0; // 3 seconds between updates
        final double speedMs = distanceMoved / timeDiff;
        final double speedKmh = speedMs * 3.6;

        setState(() {
          _speed = speedKmh;
        });
      }

      setState(() {
        _currentPosition = position;
      });

      await _getAddressFromLatLng(position);

      // Only update database if we have the correct document ID and tracking is on
      if (_firestoreDocumentId != null && _isTracking) {
        await _updateUserLocationInDatabase(position);
      }

    } catch (e) {
      print('❌ Error getting location: $e');
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      print('🏠 Getting address from coordinates...');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street ?? ""}, ${place.locality ?? ""}, ${place.postalCode ?? ""}, ${place.country ?? ""}';

        print('🏠 Address found: $address');

        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      print('❌ Error getting address: $e');
      setState(() {
        _currentAddress = "Unable to fetch address";
      });
    }
  }

  Future<void> _updateUserLocationInDatabase(Position position) async {
    try {
      print('💾 Updating USER location in database...');

      // Search in user orders subcollections first
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      bool updateSuccess = false;

      for (final userDoc in usersSnapshot.docs) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .collection('orders')
              .doc(_firestoreDocumentId!)
              .update({
            'userLatitude': position.latitude, // NEW FIELD
            'userLongitude': position.longitude, // NEW FIELD
            'userLocationUpdatedAt': FieldValue.serverTimestamp(),
          });
          updateSuccess = true;
          print('✅ User location updated in user: ${userDoc.id}');
          break;
        } catch (e) {
          print('⚠️ Not found in user: ${userDoc.id}');
        }
      }

      // If not found in user subcollections, try main orders collection
      if (!updateSuccess) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(_firestoreDocumentId!)
            .update({
          'userLatitude': position.latitude,
          'userLongitude': position.longitude,
          'userLocationUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ User location updated in main orders collection');
      }

      _showToast('📍 Your location updated');

    } catch (e) {
      print('❌ Error updating user location in database: $e');
    }
  }

  // Update the fetch delivery location to also fetch route
  Future<void> _fetchDeliveryScooterLocation() async {
    try {
      print('🛵 Fetching delivery scooter location from database...');

      if (_firestoreDocumentId == null) {
        print('❌ Cannot fetch location - no document ID available');
        return;
      }

      DocumentSnapshot? orderDoc;

      // Search in user orders subcollections first
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      for (final userDoc in usersSnapshot.docs) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('orders')
            .doc(_firestoreDocumentId!)
            .get();

        if (doc.exists) {
          orderDoc = doc;
          print('✅ Order found in user: ${userDoc.id}');
          break;
        }
      }

      // If not found, try main orders collection
      if (orderDoc == null) {
        orderDoc = await FirebaseFirestore.instance
            .collection('orders')
            .doc(_firestoreDocumentId!)
            .get();
      }

      if (orderDoc.exists) {
        final data = orderDoc.data() as Map<String, dynamic>;
        final double lat = (data['deliveryScooterLatitude'] as num?)?.toDouble() ?? 0.0;
        final double lng = (data['deliveryScooterLongitude'] as num?)?.toDouble() ?? 0.0;

        print('🛵 Delivery scooter location: $lat, $lng');

        setState(() {
          _deliveryScooterPosition = LatLng(lat, lng);
        });

        _calculateDistanceAndETA();

        // Fetch route when delivery location updates
        await _fetchRoute();

        // Show toast when delivery location updates
        _showToast('🛵 Delivery location updated');

      } else {
        print('❌ Order document not found in any collection: $_firestoreDocumentId');
      }
    } catch (e) {
      print('❌ Error fetching delivery scooter location: $e');
    }
  }

  void _calculateDistanceAndETA() {
    if (_currentPosition != null && _deliveryScooterPosition != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _deliveryScooterPosition!.latitude,
        _deliveryScooterPosition!.longitude,
      );

      // Convert meters to kilometers
      final distanceKm = distance / 1000;

      // Improved ETA calculation based on speed and distance
      double eta = 0.0;
      if (_speed > 0) {
        eta = (distanceKm / (_speed / 60)).toInt().toDouble(); // time in minutes
      } else {
        // Default ETA if speed is 0
        eta = (distanceKm * 2 + 10).toInt().toDouble();
      }

      // Ensure minimum ETA of 5 minutes
      eta = eta < 5 ? 5 : eta;

      print('📏 Distance: ${distanceKm.toStringAsFixed(2)} km, ETA: ${eta.toInt()} minutes, Speed: ${_speed.toStringAsFixed(1)} km/h');

      setState(() {
        _distance = distanceKm;
        _etaMinutes = eta.toInt();
      });
    } else {
      print('📏 Cannot calculate distance - missing position data');
    }
  }

  void _startLocationTracking() {
    print('🚀 Starting location tracking...');
    setState(() {
      _isTracking = true;
      _isIconBlinking = true;
    });

    _showToast('🚀 Live tracking started');

    // Get initial locations
    _getCurrentLocation();
    _fetchDeliveryScooterLocation();

    // Update USER location every 3 seconds
    _locationTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      print('🔄 USER Location update cycle started');
      await _getCurrentLocation();
    });

    // Fetch DELIVERY location every 3 seconds (read only)
    _fetchLocationTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      print('🔄 DELIVERY Location fetch cycle started');
      await _fetchDeliveryScooterLocation();
    });

    // Update route every 10 seconds
    _routeUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await _fetchRoute();
    });
  }

  void _stopLocationTracking() {
    print('🛑 Stopping location tracking...');
    _locationTimer?.cancel();
    _fetchLocationTimer?.cancel();
    _routeUpdateTimer?.cancel();
    setState(() {
      _isTracking = false;
      _isIconBlinking = false;
    });
    _showToast('🛑 Tracking stopped');
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: primaryOrange,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  Future<Order?> _fetchOrderDetails() async {
    print('📦 Fetching order details for: ${widget.orderId}');

    if (widget.order != null) {
      print('✅ Using provided order object');
      _firestoreDocumentId = widget.orderId;
      print('🔑 Firestore document ID: $_firestoreDocumentId');
      return widget.order;
    }

    try {
      print('🔍 Searching for order in user subcollections...');

      // Search in user orders subcollections
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      for (final userDoc in usersSnapshot.docs) {
        final orderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('orders')
            .doc(widget.orderId)
            .get();

        if (orderDoc.exists) {
          _firestoreDocumentId = orderDoc.id;
          print('✅ Order found in user: ${userDoc.id}');
          print('🔑 Firestore Document ID: $_firestoreDocumentId');

          return Order.fromFirestore(orderDoc);
        }
      }

      // If not found in user subcollections, try main orders collection
      print('🔄 Trying main orders collection as fallback...');
      final mainOrderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (mainOrderDoc.exists) {
        _firestoreDocumentId = widget.orderId;
        print('✅ Order found in main orders collection');
        return Order.fromFirestore(mainOrderDoc);
      }

      print('❌ Order not found in any collection');
      return null;

    } catch (e) {
      print('❌ Error fetching order: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6D4C41),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Live Order Tracking',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isTracking ? Icons.location_on : Icons.location_off,
              color: _isTracking ? primaryOrange : grayText,
            ),
            onPressed: _isTracking ? _stopLocationTracking : _startLocationTracking,
          ),
        ],
      ),
      body: FutureBuilder<Order?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryOrange),
                  SizedBox(height: 16),
                  Text(
                    'Loading order details...',
                    style: TextStyle(color: grayText),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Order not found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: grayText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check if order exists in database',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: grayText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Go Back',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final order = snapshot.data!;
          return _buildTrackingInterface(order);
        },
      ),
    );
  }

  Widget _buildTrackingInterface(Order order) {
    return Column(
      children: [
        // Map Section - Fixed height
        Expanded(
          flex: 6,
          child: _buildMapSection(order),
        ),

        // Tracking Info Section - Fixed height with scroll
        Expanded(
          flex: 4,
          child: _buildTrackingInfoSection(order),
        ),
      ],
    );
  }

  Widget _buildMapSection(Order order) {
    // Use current position as default location, fallback to device location
    LatLng defaultLocation = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(20.7630, 72.9691); // Fallback static location

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: defaultLocation,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.mahek_cafe',
                ),

                // Polyline Layer - Show actual road route
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: _isIconBlinking ? Colors.red.withOpacity(0.8) : Colors.black.withOpacity(0.6),
                        strokeWidth: _isIconBlinking ? 5.0 : 4.0,
                        borderColor: _isIconBlinking ? Colors.red : Colors.black,
                        borderStrokeWidth: 1.0,
                      ),
                    ],
                  ),

                // Delivery Scooter Marker with blinking effect
                if (_deliveryScooterPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 60.0,
                        height: 80.0,
                        point: _deliveryScooterPosition!,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isIconBlinking ? primaryOrange.withOpacity(0.8) : primaryOrange,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.delivery_dining,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Delivery Man',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: darkGrayText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                // Current Location Marker with blinking effect
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 60.0,
                        height: 80.0,
                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isIconBlinking ? Colors.red.withOpacity(0.8) : Colors.red,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_pin_circle,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                order.userName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: darkGrayText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Speed Indicator
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.speed, size: 16, color: primaryOrange),
                SizedBox(width: 6),
                Text(
                  '${_speed.toStringAsFixed(0)} km/h',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Distance Indicator
        if (_currentPosition != null && _deliveryScooterPosition != null)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                      Icons.linear_scale,
                      size: 16,
                      color: _isIconBlinking ? Colors.red : Colors.black
                  ),
                  SizedBox(width: 6),
                  Text(
                    '${_distance.toStringAsFixed(1)} km',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _isIconBlinking ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrackingInfoSection(Order order) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery Person Info
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(Icons.person, color: primaryOrange, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mahek Kevat',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: brownColor,
                        ),
                      ),
                      Text(
                        'Delivery Partner',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.speed, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        '${_speed.toStringAsFixed(0)} km/h',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2),

          // ETA and Distance in one row
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryOrange.withOpacity(0.15), primaryOrange.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryOrange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ETA Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, color: primaryOrange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ETA',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryOrange,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$_etaMinutes min',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: brownColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Estimated Arrival',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: grayText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical divider
                Container(
                  width: 1,
                  height: 60,
                  color: primaryOrange.withOpacity(0.3),
                ),

                // Distance Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Distance',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: darkGrayText,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.place, color: primaryOrange, size: 20),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_distance.toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: primaryOrange,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Away from you',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: grayText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 5),

          // Address Cards
          Row(
            children: [
              Expanded(
                child: _buildAddressCard(
                  icon: Icons.delivery_dining,
                  title: 'Delivery Address',
                  address: order.deliveryBoyLiveAddress,
                  color: primaryOrange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildAddressCard(
                  icon: Icons.person_pin_circle,
                  title: 'Your Location',
                  address: _currentAddress,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          SizedBox(height: 5),

          // Tracking Control Button - Always visible at bottom
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTracking ? _stopLocationTracking : _startLocationTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.red : primaryOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                shadowColor: primaryOrange.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isTracking ? Icons.stop : Icons.play_arrow,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    _isTracking ? 'STOP TRACKING' : 'START LIVE TRACKING',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildAddressCard({
    required IconData icon,
    required String title,
    required String address,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: darkGrayText,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            address,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: grayText,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}