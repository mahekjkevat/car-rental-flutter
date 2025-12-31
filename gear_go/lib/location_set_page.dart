import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'car_data_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pay_booking.dart';

class LocationSetPage extends StatefulWidget {
  final String documentId;

  const LocationSetPage({super.key, required this.documentId});

  @override
  State<LocationSetPage> createState() => _LocationSetPageState();
}

class _LocationSetPageState extends State<LocationSetPage> {
  String fromLocation = "Select From Location";
  String toLocation = "Select To Location";
  String? fromAddress;
  String? toAddress;
  LatLng? fromLatLng;
  LatLng? toLatLng;
  String selectedRentType = "Self-Driver";

  DateTime pickUpDate = DateTime.now();
  DateTime returnDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay pickUpTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay returnTime = const TimeOfDay(hour: 10, minute: 0);

  double distance = 0.0;
  late MapController mapController;
  CarDataModel? carData;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _fetchCarData();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    setState(() {
      pickUpDate = DateTime(now.year, now.month, now.day + 1); // Tomorrow
      returnDate = pickUpDate.add(const Duration(days: 1));
      pickUpTime = TimeOfDay(hour: 10, minute: 0);
      returnTime = TimeOfDay(hour: 10, minute: 0);
    });
  }

  String _truncateAddress(String? address) {
    if (address == null || address.isEmpty) return "Select Location";
    return address.length > 25 ? "${address.substring(0, 22)}..." : address;
  }

  Future<void> _fetchCarData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('CarData')
          .doc(widget.documentId)
          .get();
      if (doc.exists) {
        setState(() {
          carData = CarDataModel.fromJson(
            doc.data() as Map<String, dynamic>,
            widget.documentId,
          );
        });
      }
    } catch (e) {
      _showCustomToast("Error fetching car data", false);
    }
  }

  void _calculateDistance() {
    if (fromLatLng != null && toLatLng != null) {
      final Distance distanceCalculator = Distance();
      setState(() {
        distance = distanceCalculator.as(
          LengthUnit.Kilometer,
          fromLatLng!,
          toLatLng!,
        );
      });
      _autoSetReturnTime();
    }
  }

  void _autoSetReturnTime() {
    int travelSeconds = (distance * 50).round();
    DateTime pickUpDateTime = DateTime(
      pickUpDate.year,
      pickUpDate.month,
      pickUpDate.day,
      pickUpTime.hour,
      pickUpTime.minute,
    );
    DateTime estimatedReturnTime = pickUpDateTime.add(
      Duration(seconds: travelSeconds + 5 * 3600),
    );
    setState(() {
      returnDate = estimatedReturnTime;
      returnTime = TimeOfDay(
        hour: estimatedReturnTime.hour,
        minute: estimatedReturnTime.minute,
      );
    });
  }

  void _showCustomToast(String message, bool isSuccess) {
    // Using your custom toast - adjust based on your CustomToast implementation
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  Future<void> _showLocationDialog(BuildContext context, bool isFrom) async {
    LatLng initialPosition = LatLng(21.124857, 73.112610);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      isFrom ? "📍 Pick-Up Location" : "📍Drop-Off Location",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Current Location Button
                    GestureDetector(
                      onTap: () async {
                        var status = await Permission.location.request();
                        if (status.isGranted) {
                          try {
                            Position position = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high,
                            );
                            List<Placemark> placemarks = await placemarkFromCoordinates(
                              position.latitude,
                              position.longitude,
                            );

                            String address = placemarks.isNotEmpty
                                ? "${placemarks[0].street}, ${placemarks[0].locality}, ${placemarks[0].country}"
                                : "Current Location";

                            setState(() {
                              if (isFrom) {
                                fromAddress = address;
                                fromLatLng = LatLng(position.latitude, position.longitude);
                                fromLocation = _truncateAddress(address);
                              } else {
                                toAddress = address;
                                toLatLng = LatLng(position.latitude, position.longitude);
                                toLocation = _truncateAddress(address);
                              }
                              _calculateDistance();
                            });

                            _showCustomToast("📍 Current location set!", true);
                            Navigator.pop(context); // Auto close after selection
                          } catch (e) {
                            _showCustomToast("❌ Failed to get location", false);
                          }
                        } else {
                          _showCustomToast("📍 Location permission required", false);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.my_location, color: Colors.blue[700], size: 20),
                            SizedBox(width: 10),
                            Text("Use Current Location", style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.blue[900],
                            )),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Map Section
                    Expanded(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            mapController: mapController,
                            options: MapOptions(
                              initialCenter: initialPosition,
                              initialZoom: 12.0,
                              minZoom: 10.0,
                              maxZoom: 18.0,
                              onTap: (tapPosition, point) async {
                                try {
                                  List<Placemark> placemarks = await placemarkFromCoordinates(
                                    point.latitude, point.longitude,
                                  );

                                  String address = placemarks.isNotEmpty
                                      ? "${placemarks[0].street}, ${placemarks[0].locality}, ${placemarks[0].country}"
                                      : "Selected Location";

                                  setState(() {
                                    if (isFrom) {
                                      fromAddress = address;
                                      fromLatLng = point;
                                      fromLocation = _truncateAddress(address);
                                    } else {
                                      toAddress = address;
                                      toLatLng = point;
                                      toLocation = _truncateAddress(address);
                                    }
                                    _calculateDistance();
                                  });

                                  _showCustomToast("📍 Location selected!", true);
                                  Navigator.pop(context); // Auto close after selection
                                } catch (e) {
                                  String fallbackAddress = "Location (${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)})";
                                  setState(() {
                                    if (isFrom) {
                                      fromAddress = fallbackAddress;
                                      fromLatLng = point;
                                      fromLocation = _truncateAddress(fallbackAddress);
                                    } else {
                                      toAddress = fallbackAddress;
                                      toLatLng = point;
                                      toLocation = _truncateAddress(fallbackAddress);
                                    }
                                    _calculateDistance();
                                  });
                                  _showCustomToast("📍 Location selected!", true);
                                  Navigator.pop(context); // Auto close after selection
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  if (fromLatLng != null && isFrom)
                                    Marker(
                                      point: fromLatLng!,
                                      width: 40, height: 40,
                                      child: Icon(Icons.location_pin, color: Colors.blue[700], size: 40),
                                    ),
                                  if (toLatLng != null && !isFrom)
                                    Marker(
                                      point: toLatLng!,
                                      width: 40, height: 40,
                                      child: Icon(Icons.location_pin, color: Colors.redAccent, size: 40),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Close Button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Close", style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold,
                      )),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectPickUpDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final maxDate = DateTime(now.year, now.month, now.day + 14);

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: pickUpDate.isBefore(tomorrow) ? tomorrow : pickUpDate,
      firstDate: tomorrow,
      lastDate: maxDate,
    );

    if (picked != null) {
      setState(() {
        pickUpDate = picked;
        if (returnDate.isBefore(pickUpDate)) {
          returnDate = pickUpDate.add(const Duration(days: 1));
        }
        _validatePickUpTime();
      });
    }
  }

  Future<void> _selectReturnDate() async {
    DateTime firstDate = pickUpDate;
    DateTime lastDate = pickUpDate.add(const Duration(days: 14));

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: returnDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() => returnDate = picked);
    }
  }

  void _validatePickUpTime() {
    final now = DateTime.now();
    final pickUpDateTime = DateTime(
        pickUpDate.year, pickUpDate.month, pickUpDate.day,
        pickUpTime.hour, pickUpTime.minute
    );

    // If pick-up is today, ensure time is at least 2 hours from now
    if (pickUpDate.day == now.day && pickUpDate.month == now.month && pickUpDate.year == now.year) {
      final minTime = now.add(const Duration(hours: 2));
      if (pickUpDateTime.isBefore(minTime)) {
        setState(() {
          pickUpTime = TimeOfDay(hour: minTime.hour, minute: minTime.minute);
        });
        _showCustomToast("⏰ Pick-up time set to at least 2 hours from now", true);
      }
    }
  }

  Future<void> _pickTime({required bool isPickUp}) async {
    TimeOfDay initialTime = isPickUp ? pickUpTime : returnTime;

    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      // Basic time validation
      if (picked.hour < 7) {
        _showCustomToast("⏰ Time cannot be before 07:00 AM", false);
        return;
      }

      DateTime selectedDateTime = DateTime(
          pickUpDate.year, pickUpDate.month, pickUpDate.day,
          picked.hour, picked.minute
      );

      // Enhanced time validation
      final now = DateTime.now();
      if (selectedDateTime.isBefore(now)) {
        _showCustomToast("⏰ Cannot select past time", false);
        return;
      }

      // If pick-up is today, ensure at least 2 hours gap
      if (isPickUp && pickUpDate.day == now.day &&
          pickUpDate.month == now.month && pickUpDate.year == now.year) {
        final minTime = now.add(const Duration(hours: 2));
        if (selectedDateTime.isBefore(minTime)) {
          _showCustomToast("⏰ Pick-up must be at least 2 hours from now", false);
          return;
        }
      }

      setState(() {
        if (isPickUp) {
          pickUpTime = picked;
        } else {
          returnTime = picked;
        }
      });
    }
  }

  // UI Components
  Widget _buildCarInfoCard() {
    return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    carData!.carImage1.isNotEmpty ? carData!.carImage1 : 'https://via.placeholder.com/150',
                    width: 120, height: 80, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.error, color: Colors.red),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(carData!.carName, style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900],
                      )),
                      Text(carData!.carBrand, style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.grey[800],
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildLocationField(String label, String? address, bool isFrom) {
    return GestureDetector(
      onTap: () => _showLocationDialog(context, isFrom),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
          border: Border.all(color: Colors.blue[200]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(isFrom ? Icons.location_on : Icons.flag, color: Colors.blue[600], size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(_truncateAddress(address), style: GoogleFonts.poppins(
                fontSize: 14, color: address == null ? Colors.grey[600] : Colors.grey[800],
              )),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.blue[700], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeField(String date, String time, VoidCallback onDateTap, VoidCallback onTimeTap) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onDateTap,
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue[700], size: 18),
                  SizedBox(width: 8),
                  Text(date, style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
            ),
          ),
          Container(height: 30, width: 1, color: Colors.grey[300]),
          SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTimeTap,
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.blue[700], size: 18),
                  SizedBox(width: 8),
                  Text(time, style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBooking(DateTime pickUpDateTime) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showCustomToast("🔐 Please sign in to make a booking", false);
      return;
    }

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('car_booking')
        .add({
      'pickUpDateTime': Timestamp.fromDate(pickUpDateTime),
      'from': fromAddress,
      'to': toAddress,
      'carId': widget.documentId,
      'createdAt': Timestamp.now(),
    });
  }

  void _proceedToPayment() {
    if (fromAddress == null || toAddress == null) {
      _showCustomToast("📍 Please select both locations!", false);
      return;
    }

    DateTime pickUpDateTime = DateTime(
      pickUpDate.year, pickUpDate.month, pickUpDate.day,
      pickUpTime.hour, pickUpTime.minute,
    );

    DateTime returnDateTime = DateTime(
      returnDate.year, returnDate.month, returnDate.day,
      returnTime.hour, returnTime.minute,
    );

    // Enhanced validation
    final now = DateTime.now();
    final minPickUpTime = now.add(const Duration(hours: 2));

    if (pickUpDateTime.isBefore(minPickUpTime)) {
      _showCustomToast("⏰ Pick-up must be at least 2 hours from now", false);
      return;
    }

    if (pickUpDateTime.isAfter(returnDateTime)) {
      _showCustomToast("⏰ Pick-up time must be before return time!", false);
      return;
    }

    _saveBooking(pickUpDateTime);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayBooking(
          documentId: widget.documentId,
          fromLocation: fromLocation,
          toLocation: toLocation,
          fromAddress: fromAddress!,
          toAddress: toAddress!,
          pickUpDateTime: pickUpDateTime,
          returnDateTime: returnDateTime,
          coverDistance: distance,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Book Your Car", style: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
        )),
        centerTitle: true,
      ),
      body: carData == null ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCarInfoCard(),
                  SizedBox(height: 24),

                  // Location Section
                  Text("📍 Your Journey", style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900],
                  )),
                  SizedBox(height: 16),
                  _buildLocationField("From", fromAddress, true),
                  SizedBox(height: 12),
                  _buildLocationField("To", toAddress, false),
                  SizedBox(height: 24),

                  // Date & Time Section
                  Text("📅 Pick-Up & Return", style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900],
                  )),
                  SizedBox(height: 16),
                  _buildDateTimeField(
                    DateFormat('d MMM, yyyy').format(pickUpDate),
                    pickUpTime.format(context),
                    _selectPickUpDate,
                        () => _pickTime(isPickUp: true),
                  ),
                  SizedBox(height: 12),
                  _buildDateTimeField(
                    DateFormat('d MMM, yyyy').format(returnDate),
                    returnTime.format(context),
                    _selectReturnDate,
                        () => _pickTime(isPickUp: false),
                  ),
                ],
              ),
            ),
          ),

          // Continue Button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: ElevatedButton(
              onPressed: _proceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("CONTINUE", style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold,
                  )),
                  SizedBox(width: 8),
                  Text("(${distance.toStringAsFixed(1)} km)", style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.white70,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}