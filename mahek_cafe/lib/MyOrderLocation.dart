import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'order_model.dart';import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Explicitly import and alias the Order model to avoid ambiguity
import 'order_model.dart' as order_model;

// Distance calculation utility
double calculateDistance(LatLng start, LatLng end) {
  // flutter_map's LatLng has a distance utility from latlong2 package
  return const Distance().as(LengthUnit.Kilometer, start, end);
}

// Function to decode OSRM polyline (precision 5)
List<LatLng> decodePolyline(String encoded) {
  List<LatLng> points = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    points.add(LatLng(lat / 1E5, lng / 1E5));
  }
  return points;
}

class MyOrderLocation extends StatefulWidget {
  final String orderId; // To fetch the Order from Firestore
  final Order? order; // Optional direct order object


  const MyOrderLocation({super.key, required this.orderId, this.order});

  @override
  State<MyOrderLocation> createState() => _MyOrderLocationState();
}

class _MyOrderLocationState extends State<MyOrderLocation> {
  // Constants
  static const double _deliverySpeedKmh = 50.0;
  static const int _periodicUpdateSeconds = 2; // Fetch delivery boy location every 2 seconds
  static const int _maxRetries = 5;
  static const Duration _initialBackoff = Duration(seconds: 1);
  static const Duration _maxBackoff = Duration(seconds: 10);

  // State variables
  LatLng? _destinationLocation;
  LatLng? _deliveryBoyLocation;
  LatLng? _currentDeviceLocation;
  double? _distance;
  String? _homeAddress;
  String? _deliveryBoyAddress;
  String? _estimatedDeliveryDuration;
  bool _isLoading = true;
  bool _isBlinking = false;
  Timer? _timer;
  bool _hasNetwork = true;
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  bool _documentNotFound = false;
  bool _snackbarShown = false;
  List<LatLng> _routePoints = [];

  // Hardcoded delivery man details
  final String deliveryManName = "Mahek Kevat";
  final String deliveryManPhone = "+919876543210";

  // Exponential backoff configuration
  int _retryAttempt = 0;


  // Cache for last known order data
  order_model.Order? _cachedOrder;

  @override
  void initState() {
    super.initState();
    print('1 MyOrderLocation Page is Here');
    print('Widget ID: ${widget.orderId} - InitState at ${DateTime.now().toIso8601String()}');
    _checkNetworkConnectivity();
    _askLocationPermission();
    _fetchOrderDataWithRetry();
    _startPeriodicUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
        _getCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _askLocationPermission() async {
    print('3 _askLocationPermission work - Starting');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission is required for current location features.', style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
          ),
        );
      }
      print('3 _askLocationPermission work - Failed: Permission denied');
    } else {
      await _getCurrentLocation();
      print('3 _askLocationPermission work - Success');
    }
  }

  Future<void> _getCurrentLocation() async {
    print('4 _getCurrentLocation work - Starting');
    if (!_isMapReady) {
      print('4 _getCurrentLocation work - Failed: Map not ready');
      return;
    }

    try {
      // NOTE: We no longer set _isLoading to true here, as Firebase fetch manages the main loading state.
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentDeviceLocation = LatLng(position.latitude, position.longitude);

        if (_destinationLocation == null && _cachedOrder != null) {
          _destinationLocation = LatLng(_cachedOrder!.latitude, _cachedOrder!.longitude);
        } else if (_destinationLocation == null) {
          _destinationLocation = _currentDeviceLocation;
        }

        // Only attempt map move if data is loaded, otherwise _fetchOrderDataWithRetry will handle it.
        if (_isMapReady && !_isLoading) {
          if (_deliveryBoyLocation != null && _destinationLocation != null) {
            final centerLat = (_destinationLocation!.latitude + _deliveryBoyLocation!.latitude) / 2;
            final centerLon = (_destinationLocation!.longitude + _deliveryBoyLocation!.longitude) / 2;
            _mapController.move(LatLng(centerLat, centerLon), 13.0);
          } else if (_currentDeviceLocation != null) {
            _mapController.move(_currentDeviceLocation!, 15.0);
          }
        }

        _updateDistance();
        _calculateEta();
      });
      await _updateHomeAddressFromLocation(_currentDeviceLocation!);
      print('4 _getCurrentLocation work - Success');
    } catch (e) {
      print('Error getting current location: $e');
      print('4 _getCurrentLocation work - Failed: $e');
      if (mounted && !_snackbarShown) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get current location: $e', style: GoogleFonts.poppins())),
        );
        _snackbarShown = true;
      }
    }
  }

  Future<void> _updateHomeAddressFromLocation(LatLng location) async {
    print('5 _updateHomeAddressFromLocation work - Starting');
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        setState(() {
          _homeAddress =
          '${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}, ${placemarks.first.postalCode ?? ''}, ${placemarks.first.country ?? ''}';
        });
        print('5 _updateHomeAddressFromLocation work - Success');
      } else {
        print('5 _updateHomeAddressFromLocation work - Failed: No placemarks found');
      }
    } catch (e) {
      print('Error getting home address: $e');
      print('5 _updateHomeAddressFromLocation work - Failed: $e');
      setState(() {
        _homeAddress = 'Location not available';
      });
    }
  }

  Future<void> _checkNetworkConnectivity() async {
    print('6 _checkNetworkConnectivity work - Starting');
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasNetwork = connectivityResult != ConnectivityResult.none;
    });
    if (!_hasNetwork) {
      if (mounted && !_snackbarShown) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No internet connection. Using cached data if available.', style: GoogleFonts.poppins())),
        );
        _snackbarShown = true;
      }
      print('6 _checkNetworkConnectivity work - Failed: No network');
      _useCachedData();
    } else {
      print('6 _checkNetworkConnectivity work - Success');
      if (_snackbarShown) {
        _snackbarShown = false; // Reset snackbar flag when network is back
      }
    }
  }

  Future<void> _fetchOrderDataWithRetry() async {
    print('2 Firebase Connect - Starting');
    print('7 _fetchOrderDataWithRetry work - Starting');
    if (!_hasNetwork) {
      print('7 _fetchOrderDataWithRetry work - Failed: No network');
      _useCachedData();
      return;
    }

    int backoffSeconds = (1 << _retryAttempt) * _initialBackoff.inSeconds;
    Duration backoff = Duration(seconds: backoffSeconds.clamp(1, _maxBackoff.inSeconds));

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get(GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        final order_model.Order order = order_model.Order.fromFirestore(doc);
        _cachedOrder = order; // Cache the order data
        print('8 orders collection get print all');
        print(order.toString());
        print("Fetched order data successfully at ${DateTime.now().toIso8601String()}.");

        final destination = _currentDeviceLocation ?? LatLng(order.latitude, order.longitude);

        setState(() {
          _deliveryBoyLocation = LatLng(order.deliveryScooterLatitude, order.deliveryScooterLongitude);
          _destinationLocation = destination;
          _homeAddress = order.deliveryAddress;
          _updateDistance();
          _calculateEta();
          _retryAttempt = 0;
          _isLoading = false; // Disable loading screen here after successful fetch
          _documentNotFound = false;
        });
        await _updateDeliveryBoyAddress();
        await _fetchRoutePoints();
        print('7 _fetchOrderDataWithRetry work - Success');
        print('2 Firebase Connect - Success');
      } else {
        _handleDocumentNotFound();
        print('7 _fetchOrderDataWithRetry work - Failed: Document not found');
      }
    } catch (e) {
      print('Error fetching order data: $e');
      print('2 Firebase Connect - Failed: $e');
      if (_retryAttempt < _maxRetries) {
        _retryAttempt++;
        await Future.delayed(backoff);
        await _fetchOrderDataWithRetry();
      } else {
        _handleDocumentNotFound();
        print('7 _fetchOrderDataWithRetry work - Failed after retries: $e');
        _useCachedData();
      }
    }
  }

  void _useCachedData() {
    if (_cachedOrder != null && mounted) {
      final destination = _currentDeviceLocation ?? LatLng(_cachedOrder!.latitude, _cachedOrder!.longitude);

      setState(() {
        _deliveryBoyLocation = LatLng(_cachedOrder!.deliveryScooterLatitude, _cachedOrder!.deliveryScooterLongitude);
        _destinationLocation = destination;
        _homeAddress = _cachedOrder!.deliveryAddress;
        _updateDistance();
        _calculateEta();
        _isLoading = false; // Disable loading screen
        _documentNotFound = false;
      });
      _updateDeliveryBoyAddress();
      _fetchRoutePoints();
      if (!_snackbarShown) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Using cached order data due to network issues.', style: GoogleFonts.poppins())),
        );
        _snackbarShown = true;
      }
    } else {
      _handleDocumentNotFound();
    }
  }

  Future<void> _fetchRoutePoints() async {
    if (_destinationLocation == null || _deliveryBoyLocation == null) {
      setState(() {
        _routePoints = [];
      });
      return;
    }

    // Only fetch route if locations are available
    final start = '${_deliveryBoyLocation!.longitude},${_deliveryBoyLocation!.latitude}';
    final end = '${_destinationLocation!.longitude},${_destinationLocation!.latitude}';
    // OSRM routing service for shortest path (driving profile is generally good for road distance)
    final url = 'https://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=polyline';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final encodedPolyline = data['routes'][0]['geometry'] as String;
          setState(() {
            _routePoints = decodePolyline(encodedPolyline);
          });
        } else {
          setState(() {
            _routePoints = []; // Use straight line fallback in PolylineLayer
          });
          print('Failed to fetch route: No routes found in response.');
        }
      } else {
        print('Failed to fetch route: ${response.statusCode}');
        setState(() {
          _routePoints = []; // Use straight line fallback in PolylineLayer
        });
      }
    } catch (e) {
      print('Error fetching route: $e');
      setState(() {
        _routePoints = []; // Use straight line fallback in PolylineLayer
      });
    }
  }

  void _handleDocumentNotFound() {
    print('Order document does not exist for ID: ${widget.orderId}. Using live location as fallback at ${DateTime.now().toIso8601String()}.');
    if (mounted) {
      // Fallback locations to at least show something on the map
      setState(() {
        _deliveryBoyLocation = LatLng(21.124858, 73.11261); // Fallback delivery boy
        _destinationLocation = _currentDeviceLocation ?? LatLng(20.763, 72.9691); // Fallback destination
        _updateDistance();
        _calculateEta();
        _isLoading = false; // Disable loading screen
        _documentNotFound = true;
      });
      if (!_snackbarShown) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order not found. Using fallback location data.', style: GoogleFonts.poppins())),
        );
        _snackbarShown = true;
      }
      _updateDeliveryBoyAddress();
      _fetchRoutePoints();
    }
  }

  Future<void> _updateDeliveryBoyAddress() async {
    if (_deliveryBoyLocation != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _deliveryBoyLocation!.latitude,
          _deliveryBoyLocation!.longitude,
        );
        if (placemarks.isNotEmpty) {
          setState(() {
            _deliveryBoyAddress =
            '${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}, ${placemarks.first.postalCode ?? ''}, ${placemarks.first.country ?? ''}';
          });
        }
      } catch (e) {
        print('Error getting delivery boy address: $e');
        setState(() {
          _deliveryBoyAddress = 'Location not available';
        });
      }
    }
  }

  void _updateDistance() {
    if (_destinationLocation != null && _deliveryBoyLocation != null) {
      setState(() {
        _distance = calculateDistance(_destinationLocation!, _deliveryBoyLocation!);
      });
    }
  }

  void _calculateEta() {
    if (_distance != null) {
      // Time in hours = Distance (km) / Speed (km/h)
      double timeInHours = _distance! / _deliverySpeedKmh;
      // Time in minutes = Time in hours * 60
      int timeInMinutes = (timeInHours * 60).round();

      String durationString;
      if (timeInMinutes < 1) {
        durationString = 'Less than a minute';
      } else if (timeInMinutes < 60) {
        durationString = '$timeInMinutes minutes';
      } else {
        int hours = timeInMinutes ~/ 60;
        int minutes = timeInMinutes % 60;
        durationString = '${hours}h ${minutes}m';
      }

      setState(() {
        _estimatedDeliveryDuration = durationString;
      });
    } else {
      setState(() {
        _estimatedDeliveryDuration = 'Calculating...';
      });
    }
  }

  void _startPeriodicUpdates() {
    _timer = Timer.periodic(const Duration(seconds: _periodicUpdateSeconds), (timer) async {
      if (mounted && !_documentNotFound) {
        setState(() {
          _isBlinking = !_isBlinking;
        });
        await _checkNetworkConnectivity();
        await _fetchOrderDataWithRetry(); // Fetches and updates delivery boy location

        _updateDistance();
        _calculateEta();
        await _fetchRoutePoints(); // Fetch route on every update

        if (_destinationLocation != null && _deliveryBoyLocation != null) {
          print('Destination Location: Lat: ${_destinationLocation!.latitude}, Lon: ${_destinationLocation!.longitude} at ${DateTime.now().toIso8601String()}');
          print('Delivery Boy Location: Lat: ${_deliveryBoyLocation!.latitude}, Lon: ${_deliveryBoyLocation!.longitude} at ${DateTime.now().toIso8601String()}');
        }
      } else if (_documentNotFound) {
        _timer?.cancel();
      }
    });
  }

  // UPDATED: This now builds the loading card for when data is not ready
  Widget _buildLoadingCard() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(30.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFFE65100),
                strokeWidth: 5,
              ),
              const SizedBox(height: 20),
              Text(
                "Please Wait...",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6D4C41),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method for the floating speed card
  Widget _buildSpeedCard() {
    return Positioned(
      top: 20,
      left: 20,
      child: Card(
        color: Colors.white.withOpacity(0.9),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            children: [
              Text(
                '${_deliverySpeedKmh.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE65100),
                ),
              ),
              Text(
                'km/h',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the map center based on available locations
    LatLng mapCenter = LatLng(20.763, 72.9691); // Default fallback center
    double initialZoom = 10.0;

    if (_deliveryBoyLocation != null && _destinationLocation != null) {
      final centerLat = (_destinationLocation!.latitude + _deliveryBoyLocation!.latitude) / 2;
      final centerLon = (_destinationLocation!.longitude + _deliveryBoyLocation!.longitude) / 2;
      mapCenter = LatLng(centerLat, centerLon);
      initialZoom = 12.0; // Zoom closer when both points are known
    } else if (_currentDeviceLocation != null) {
      mapCenter = _currentDeviceLocation!;
      initialZoom = 15.0; // Zoom close to current location
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6D4C41),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Live Tracking Map',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: AnimatedOpacity(
              opacity: _isBlinking ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 500),
              child: const Icon(
                Icons.sync,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      // CRITICAL FIX: Conditionally render the body content.
      // If loading, show the card. If loaded, show the map stack.
      body: _isLoading
          ? _buildLoadingCard()
          : Stack(
        children: [
          // Map is the base layer (Only built when _isLoading is false)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: initialZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fooddeliveryapp.tracking',
                errorImage: const AssetImage('assets/placeholder.png'),
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    // Ensure the list is not empty to prevent the RED screen assertion error.
                    points: _routePoints.isNotEmpty
                        ? _routePoints
                        : (_destinationLocation != null && _deliveryBoyLocation != null && !_documentNotFound
                        ? [_deliveryBoyLocation!, _destinationLocation!] // Straight line fallback
                        : <LatLng>[] // EMPTY list ONLY when no location data is available
                    ),
                    color: const Color(0xFFE65100).withOpacity(0.9),
                    strokeWidth: 6.0,
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.white,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_deliveryBoyLocation != null)
                    Marker(
                      point: _deliveryBoyLocation!,
                      width: 80,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bike_rounded,
                          color: Colors.orange,
                          size: 40,
                        ),
                      ),
                    ),
                  if (_destinationLocation != null)
                    Marker(
                      point: _destinationLocation!,
                      width: 80,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF6D4C41),
                          size: 40,
                        ),
                      ),
                    ),
                  if (_currentDeviceLocation != null)
                    Marker(
                      point: _currentDeviceLocation!,
                      width: 80,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
              CircleLayer(
                circles: [
                  if (_deliveryBoyLocation != null)
                    CircleMarker(
                      point: _deliveryBoyLocation!,
                      radius: 50.0,
                      color: Colors.orange.withOpacity(0.3),
                      borderColor: Colors.orange,
                      borderStrokeWidth: 2.0,
                      useRadiusInMeter: false,
                    ),
                ],
              ),
            ],
          ),

          // Floating Speed Card
          _buildSpeedCard(),

          // Current Location Button
          Positioned(
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'currentLocation',
              backgroundColor: const Color(0xFFE65100),
              onPressed: _isLoading || !_isMapReady ? null : _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deliveryManName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6D4C41),
                            ),
                          ),
                          Text(
                            'Delivery Man',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.message, color: Color(0xFFE65100)),
                            onPressed: () {
                              // Implement message functionality
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.call, color: Color(0xFFE65100)),
                            onPressed: () {
                              // Implement call functionality
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Estimated delivery in ${_estimatedDeliveryDuration ?? 'Loading...'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6D4C41),
                    ),
                  ),
                  Text(
                    'Your order is now on its way to you!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Distance: ${_distance?.toStringAsFixed(2) ?? 'N/A'} km away',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6D4C41),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_deliveryBoyAddress ?? 'Loading...'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF6D4C41),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 5.0),
                          child: SizedBox(
                            height: 20,
                            child: VerticalDivider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 10,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_homeAddress ?? 'Loading...'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF6D4C41),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 8,
                      ),
                      child: Text(
                        'BACK TO TRACKING',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
}