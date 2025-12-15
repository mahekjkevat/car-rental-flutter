import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'partner_model.dart';

class PartnerLocationMapPage extends StatefulWidget {
  final Partner partner;

  const PartnerLocationMapPage({super.key, required this.partner});

  @override
  State<PartnerLocationMapPage> createState() => _PartnerLocationMapPageState();
}

class _PartnerLocationMapPageState extends State<PartnerLocationMapPage> with TickerProviderStateMixin { // CHANGED: SingleTickerProviderStateMixin -> TickerProviderStateMixin
  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);

  late MapController _mapController;
  LatLng? _partnerLocation;
  String? _partnerAddress;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _locationActive = false;
  late AnimationController _animationController;

  late Timer _locationTimer;
  bool _isBlinking = false;
  late AnimationController _blinkAnimationController;

  // Default location (Bilimora, Gujarat as fallback)
  final LatLng _defaultLocation = const LatLng(20.7730355, 72.9591415);


// Update the initState method
  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Blinking animation controller
    _blinkAnimationController = AnimationController(
      vsync: this, // CHANGED: Now using TickerProviderStateMixin
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _animationController = AnimationController(
      vsync: this, // CHANGED: Now using TickerProviderStateMixin
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _loadPartnerLocation();

    // Start auto-refresh timer
    _startAutoRefresh();
  }


// Add this method to start auto-refresh
  void _startAutoRefresh() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _refreshLocationSilent();
      }
    });
  }
// Update the dispose method to cancel timer
  @override
  void dispose() {
    _locationTimer.cancel();
    _blinkAnimationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

// Add this method for silent refresh (without loading states)
  Future<void> _refreshLocationSilent() async {
    try {
      final locationDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(widget.partner.id)
          .collection('my_location')
          .doc('current_location')
          .get();

      if (locationDoc.exists) {
        final data = locationDoc.data();
        final double? lat = data?['deliveryScooterLatitude']?.toDouble();
        final double? lng = data?['deliveryScooterLongitude']?.toDouble();
        final String? address = data?['address'];
        final bool status = data?['deliveryScooterStatus'] ?? false;

        if (lat != null && lng != null) {
          final newLocation = LatLng(lat, lng);

          // Check if location actually changed
          final locationChanged = _partnerLocation == null ||
              _partnerLocation!.latitude != lat ||
              _partnerLocation!.longitude != lng;

          final addressChanged = _partnerAddress != address;
          final statusChanged = _locationActive != status;

          if (locationChanged || addressChanged || statusChanged) {
            if (mounted) {
              setState(() {
                _partnerLocation = newLocation;
                _partnerAddress = address;
                _locationActive = status;
              });

              // Trigger blink effect
              _triggerBlink();

              // Smoothly move map to new location
              _mapController.move(_partnerLocation!, 15.0);
            }

            print('🔄 Location Updated - ${DateTime.now().toIso8601String()}');
            print('📍 New Coordinates: $lat, $lng');
            print('🏠 Address: $address');
            print('🔋 Status: ${status ? 'Active' : 'Inactive'}');
            print('---');
          }
        }
      }
    } catch (e) {
      print('❌ Auto-refresh error: $e');
    }
  }

// Add blink effect method
  void _triggerBlink() {
    if (mounted) {
      setState(() {
        _isBlinking = true;
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isBlinking = false;
          });
        }
      });
    }
  }

  Future<void> _loadPartnerLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(widget.partner.id)
          .collection('my_location')
          .doc('current_location')
          .get();

      if (locationDoc.exists) {
        final data = locationDoc.data();
        final double? lat = data?['deliveryScooterLatitude']?.toDouble();
        final double? lng = data?['deliveryScooterLongitude']?.toDouble();
        final String? address = data?['address'];
        final bool status = data?['deliveryScooterStatus'] ?? false;

        if (lat != null && lng != null) {
          setState(() {
            _partnerLocation = LatLng(lat, lng);
            _partnerAddress = address;
            _locationActive = status;
          });

          // Animate map to partner location
          _mapController.move(_partnerLocation!, 15.0);
        } else {
          _setDefaultLocation();
        }
      } else {
        _setDefaultLocation();
      }
    } catch (e) {
      print('Error loading partner location: $e');
      _setDefaultLocation();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _partnerLocation = _defaultLocation;
      _partnerAddress = '6074-B, Bilimora, Gujarat, 396321';
      _locationActive = false;
    });
    _mapController.move(_defaultLocation, 15.0);
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadPartnerLocation();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _openInMaps() async {
    if (_partnerLocation == null) return;

    final url = 'https://www.google.com/maps/search/?api=1&query=${_partnerLocation!.latitude},${_partnerLocation!.longitude}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open maps', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _locationActive ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _locationActive ? 'Active' : 'Inactive',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _locationActive ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfoCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.person_pin_circle,
                  color: primaryAppColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: secondaryDarkColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Address Section
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              title: 'Full Address',
              value: _partnerAddress ?? 'Address not available',
            ),

            const SizedBox(height: 12),

            // Coordinates Section
            Row(
              children: [
                Expanded(
                  child: _buildCoordinateCard(
                    'Latitude',
                    _partnerLocation?.latitude.toStringAsFixed(6) ?? 'N/A',
                    Icons.explore_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCoordinateCard(
                    'Longitude',
                    _partnerLocation?.longitude.toStringAsFixed(6) ?? 'N/A',
                    Icons.explore_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status and Action Section
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _locationActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _locationActive ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _locationActive ? Icons.check_circle : Icons.circle_outlined,
                        size: 14,
                        color: _locationActive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _locationActive ? 'Live Tracking' : 'Offline',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _locationActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Open in Maps Button
                ElevatedButton.icon(
                  onPressed: _openInMaps,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAppColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: secondaryDarkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinateCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: primaryAppColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryAppColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partner Location',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Text(
              widget.partner.name,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          // Auto-refresh status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isRefreshing ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Auto',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          if (_isRefreshing)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Icon(
                    Icons.refresh,
                    color: Colors.white.withOpacity(_animationController.value),
                  );
                },
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshLocation,
              tooltip: 'Refresh Location',
            ),
          _buildStatusIndicator(),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFF96D0A)),
            SizedBox(height: 16),
            Text(
              'Loading Partner Location...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _partnerLocation ?? _defaultLocation,
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.mahek.delivery.admin',
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _partnerLocation ?? _defaultLocation,
                    width: 70,
                    height: 70,
                    child: AnimatedBuilder(
                      animation: _blinkAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _isBlinking ? _blinkAnimationController.value : 1.0,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _locationActive ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_pin,
                                  color: _locationActive ? Colors.red : Colors.grey,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _locationActive ? Colors.red : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.partner.name.split(' ').first,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildLocationInfoCard(),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer indicator
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryAppColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '3s',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          FloatingActionButton(
            onPressed: _refreshLocation,
            backgroundColor: primaryAppColor,
            foregroundColor: Colors.white,
            child: _isRefreshing
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}