import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class FullScreenMapPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String title;
  final DocumentReference? documentReference;

  const FullScreenMapPage({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.documentReference,
  }) : super(key: key);

  @override
  _FullScreenMapPageState createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  final MapController _mapController = MapController();
  double _zoomLevel = 16.0;
  Position? _currentPosition;
  bool _showTooltip = false;
  bool _isLoading = true;
  Timer? _refreshTimer;
  bool _isIconRed = true;
  Map<String, dynamic>? _vehicleData;
  List<LatLng> _routePoints = [];

  // OpenRouteService API key
  final String _apiKey = '5b3ce3597851110001cf6248b924a25dcd164677aae1ffb2401e279f';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationRefresh();
    print('Initial Vehicle Location: Lat=${widget.latitude}, Lon=${widget.longitude}');
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    setState(() {
      _isLoading = true;
    });

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _isLoading = false;
      print('My Location: Lat=${position.latitude}, Lon=${position.longitude}');
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _zoomLevel,
      );
    });

    // Fetch route after getting current location
    if (_vehicleData != null || widget.latitude != null) {
      await _fetchRoute();
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentPosition == null) return;

    final startLat = _currentPosition!.latitude;
    final startLon = _currentPosition!.longitude;
    final endLat = _vehicleData?['location_latitude'] != null
        ? double.tryParse(_vehicleData!['location_latitude']) ?? widget.latitude
        : widget.latitude;
    final endLon = _vehicleData?['location_longitude'] != null
        ? double.tryParse(_vehicleData!['location_longitude']) ?? widget.longitude
        : widget.longitude;

    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$_apiKey&start=$startLon,$startLat&end=$endLon,$endLat',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        setState(() {
          _routePoints = coordinates
              .map((coord) => LatLng(coord[1], coord[0])) // OpenRouteService returns [lon, lat]
              .toList();
        });
      } else {
        print('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  void _startLocationRefresh() {
    if (widget.documentReference == null) return;

    _refreshTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      try {
        final docSnapshot = await widget.documentReference!.get();
        if (docSnapshot.exists) {
          setState(() {
            _vehicleData = docSnapshot.data() as Map<String, dynamic>;
            _isIconRed = !_isIconRed;
          });
          // Print only the specified fields
          print('Refreshed Vehicle Data:');
          print('location_Status: ${_vehicleData?['location_Status'] ?? 'Unknown'}');
          print('location_latitude: ${_vehicleData?['location_latitude'] ?? 'Not provided'}');
          print('location_longitude: ${_vehicleData?['location_longitude'] ?? 'Not provided'}');
          print('location_timestamp: ${_vehicleData?['location_timestamp'] is Timestamp ? _formatTimestamp(_vehicleData!['location_timestamp']) : 'Not provided'}');

          // Refresh route when vehicle data updates
          await _fetchRoute();
        }
      } catch (e) {
        print('Error refreshing location: $e');
      }
    });
  }

  double getRangeInKM() {
    if (_currentPosition == null) return 0.0;
    final myLocation = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final vehicleLocation = LatLng(
      _vehicleData?['location_latitude'] != null
          ? double.tryParse(_vehicleData!['location_latitude']) ?? widget.latitude
          : widget.latitude,
      _vehicleData?['location_longitude'] != null
          ? double.tryParse(_vehicleData!['location_longitude']) ?? widget.longitude
          : widget.longitude,
    );
    final distanceInMeters = Distance().as(LengthUnit.Meter, myLocation, vehicleLocation);
    return distanceInMeters / 1000;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not provided';
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
  }

  @override
  Widget build(BuildContext context) {
    final rangeKM = getRangeInKM().toStringAsFixed(2);
    final vehicleLat = _vehicleData?['location_latitude'] ?? widget.latitude.toString();
    final vehicleLon = _vehicleData?['location_longitude'] ?? widget.longitude.toString();
    final locationStatus = _vehicleData?['location_Status']?.toString() ?? 'Unknown';
    final locationTimestamp = _vehicleData?['location_timestamp'] is Timestamp
        ? _formatTimestamp(_vehicleData!['location_timestamp'])
        : 'Not provided';

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade900,
                Colors.purple.shade600,
                Colors.teal.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: 24,
            ),
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: EdgeInsets.all(1),
            child: IconButton(
              icon: Icon(
                Icons.location_on,
                color: _isIconRed ? Colors.redAccent : Colors.white,
                size: 31,
              ),
              onPressed: () {
                setState(() {
                  _showTooltip = !_showTooltip;
                });
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              setState(() {
                _showTooltip = !_showTooltip;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                _vehicleData?['location_latitude'] != null
                    ? double.tryParse(_vehicleData!['location_latitude']) ?? widget.latitude
                    : widget.latitude,
                _vehicleData?['location_longitude'] != null
                    ? double.tryParse(_vehicleData!['location_longitude']) ?? widget.longitude
                    : widget.longitude,
              ),
              initialZoom: _zoomLevel,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.yourappname',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: LatLng(
                      _vehicleData?['location_latitude'] != null
                          ? double.tryParse(_vehicleData!['location_latitude']) ?? widget.latitude
                          : widget.latitude,
                      _vehicleData?['location_longitude'] != null
                          ? double.tryParse(_vehicleData!['location_longitude']) ?? widget.longitude
                          : widget.longitude,
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: _isIconRed ? Colors.red : Colors.blue,
                      size: 40,
                    ),
                  ),
                  if (_currentPosition != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      child: Icon(Icons.home, color: Colors.blue, size: 40),
                    ),
                ],
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ],
          ),
          if (_showTooltip)
            Positioned(
              top: kToolbarHeight + 12,
              right: 12,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[850],
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🚗 Vehicle Location",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Text(
                        "Lat: ${vehicleLat.toString().length > 8 ? vehicleLat.toString().substring(0, 8) : vehicleLat}",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Text(
                        "Lon: ${vehicleLon.toString().length > 8 ? vehicleLon.toString().substring(0, 8) : vehicleLon}",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Text(
                        "Status: $locationStatus",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Text(
                        "Time: $locationTimestamp",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "📡 My Location",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Text(
                        "Lat: ${_currentPosition?.latitude.toStringAsFixed(6) ?? '--'}",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Text(
                        "Lon: ${_currentPosition?.longitude.toStringAsFixed(6) ?? '--'}",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              color: Colors.grey[900]?.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.route, color: Colors.orangeAccent, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Range: $rangeKM KM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _zoomLevel = (_zoomLevel - 1).clamp(1.0, 18.0);
                                  _mapController.move(
                                    LatLng(
                                      _currentPosition?.latitude ?? widget.latitude,
                                      _currentPosition?.longitude ?? widget.longitude,
                                    ),
                                    _zoomLevel,
                                  );
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _zoomLevel = (_zoomLevel + 1).clamp(1.0, 18.0);
                                  _mapController.move(
                                    LatLng(
                                      _currentPosition?.latitude ?? widget.latitude,
                                      _currentPosition?.longitude ?? widget.longitude,
                                    ),
                                    _zoomLevel,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.grey[300],
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        backgroundColor: Colors.grey[600],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      SizedBox(height: 20),
                      Icon(
                        Icons.directions_car,
                        color: Colors.red,
                        size: 50,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Please wait...",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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