import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

// Class to hold the data returned from the map page
class LocationResult {
  final String address;
  final double latitude;
  final double longitude;

  LocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class MapSelectionPage extends StatefulWidget {
  // Initial location (e.g., center of Bilimora if no location saved)
  final LatLng initialLocation;

  const MapSelectionPage({super.key, required this.initialLocation});

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  // MapController is used to control the map's state and camera.
  final MapController _mapController = MapController();
  // Flag to ensure we don't try to access map properties before it's ready.
  bool _isMapReady = false;

  LatLng? _selectedPoint;
  String _currentAddressDisplay = 'Move the map marker to select your location.';
  bool _isLoading = false;

  final Color primaryBrown = const Color(0xFF6D4C41);
  final Color accentOrange = const Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialLocation;

    // --- FIX: Proactively ask for location permission right away ---
    _askLocationPermission();

    // This ensures the map is rendered and the controller's camera is initialized
    // before we access _mapController.camera.center for initial geocoding.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
        // Now it's safe to access _mapController.camera.center for the first time
        _reverseGeocode(_mapController.camera.center);
      }
    });
  }

  // New method to proactively check and request permissions when the page loads
  Future<void> _askLocationPermission() async {
    // Temporarily set loading state while checking permission
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Clear loading state after checking permission
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    // If still denied, inform the user why the feature might not work
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission is required to use the "Set My Location" button.', style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Dispose the controller when the state is removed
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Convert LatLng to human-readable address
  Future<void> _reverseGeocode(LatLng point) async {
    // Only proceed if the map is ready
    if (!_isMapReady) return;

    setState(() {
      _isLoading = true;
      _currentAddressDisplay = 'Fetching address...';
    });

    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        // Construct a simple, clean address
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
        ].where((e) => e != null && (e as String).isNotEmpty).join(', ');

        if(mounted) {
          setState(() {
            _currentAddressDisplay = address;
            _selectedPoint = point;
          });
        }
      } else {
        if(mounted) {
          setState(() {
            _currentAddressDisplay = 'Address not found for this location.';
          });
        }
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _currentAddressDisplay = 'Error fetching address.';
        });
      }
      print('Geocoding error: $e');
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Center map on current device location
  Future<void> _getCurrentLocation() async {
    // Only proceed if the map is ready and not already loading
    if (!_isMapReady || _isLoading) return;

    try {
      if(mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Re-check and re-request if permission was denied, in case the user retries
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Check if permission is still denied after the request
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission is required to find your current location.', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
          // If denied, stop here and clear loading state
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng newCenter = LatLng(position.latitude, position.longitude);

      // Use map controller to move the camera (requires map to be ready)
      // This will trigger the onMapEvent: MapEventMoveEnd which calls _reverseGeocode(newCenter).
      _mapController.move(newCenter, _mapController.camera.zoom);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get current location: ${e.toString()}', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Clear loading state after location attempt. (If location is successfully moved, _reverseGeocode clears loading)
      if(mounted && _currentAddressDisplay.startsWith('Error') == false) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Delivery Location',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Flutter Map Widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 15.0,
              // Update selected point when map is moved
              onMapEvent: (event) {
                // Ensure map is ready and event is move end before geocoding
                if (_isMapReady && event is MapEventMoveEnd) {
                  _reverseGeocode(event.camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.coffe_app',
              ),
              // Marker in the center of the screen
              // ONLY render MarkerLayer if the map is ready (_isMapReady is true)
              if (_isMapReady)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      // Now safely accessing mapController.camera.center
                      point: _mapController.camera.center,
                      child: Icon(
                        Icons.location_pin,
                        color: accentOrange,
                        size: 50.0,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Floating Action Button for Current Location
          Positioned(
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'currentLocation',
              backgroundColor: accentOrange,
              // Disable if loading or map not ready
              onPressed: _isLoading || !_isMapReady ? null : _getCurrentLocation,
              child: _isLoading
                  ? const Center(
                  child: SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          // Bottom Bar for Address Display and Confirmation Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Selected Address:',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, color: primaryBrown),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentAddressDisplay,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold, color: accentOrange),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedPoint != null && !_isLoading
                        ? () {
                      // Confirms the result and pops the page, returning the location data
                      Navigator.pop(
                        context,
                        LocationResult(
                          address: _currentAddressDisplay,
                          latitude: _selectedPoint!.latitude,
                          longitude: _selectedPoint!.longitude,
                        ),
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentOrange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                    ),
                    child: Text(
                      'SET MY LOCATION',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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