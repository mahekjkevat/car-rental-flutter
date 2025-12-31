import 'package:car_rental_admin/utils/active_booking_user_tracking.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AcceptedBookingsPage extends StatefulWidget {
  const AcceptedBookingsPage({super.key});

  @override
  _AcceptedBookingsPageState createState() => _AcceptedBookingsPageState();
}

class _AcceptedBookingsPageState extends State<AcceptedBookingsPage> {
  bool showAllRecent = false;
  bool showAllOlder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Bookings',style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),),
        backgroundColor: Colors.white.withOpacity(0.1),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.1),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        elevation: 0,

        centerTitle: false,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/car.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collectionGroup('car_booking')
                      .where('status', isEqualTo: 'accepted')
                      .orderBy('pickUpDateTime', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  print('Error fetching bookings: ${snapshot.error}');
                  return const Center(child: Text('Error fetching data'));
                }

                final bookings = snapshot.data?.docs ?? [];

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text('No accepted bookings found'),
                  );
                }

                List<Map<String, dynamic>> bookingList =
                    bookings.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['reference'] = doc.reference;
                      data['pickupDateTime'] = data['pickUpDateTime'];
                      return data;
                    }).toList();

                final now = DateTime.now();

                // Helper for month name
                String _monthName(int month) {
                  const months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec',
                  ];
                  return months[month - 1];
                }

                // Prepare sections
                List<Map<String, dynamic>> todayList = [];
                List<Map<String, dynamic>> yesterdayList = [];
                Map<String, List<Map<String, dynamic>>> pastDaysMap = {};
                List<Map<String, dynamic>> olderList = [];

                for (var booking in bookingList) {
                  final pickupTimestamp = booking['pickupDateTime'];
                  if (pickupTimestamp == null) continue;

                  DateTime pickupDate;
                  if (pickupTimestamp is Timestamp) {
                    pickupDate = pickupTimestamp.toDate();
                  } else if (pickupTimestamp is DateTime) {
                    pickupDate = pickupTimestamp;
                  } else {
                    continue;
                  }

                  final dateOnly = DateTime(
                    pickupDate.year,
                    pickupDate.month,
                    pickupDate.day,
                  );
                  final diffDays = now.difference(dateOnly).inDays;

                  final isToday =
                      diffDays == 0 &&
                      pickupDate.day == now.day &&
                      pickupDate.month == now.month &&
                      pickupDate.year == now.year;

                  final isYesterday =
                      diffDays == 1 &&
                      pickupDate.day == now.subtract(Duration(days: 1)).day &&
                      pickupDate.month ==
                          now.subtract(Duration(days: 1)).month &&
                      pickupDate.year == now.subtract(Duration(days: 1)).year;

                  if (isToday) {
                    todayList.add(booking);
                  } else if (isYesterday) {
                    yesterdayList.add(booking);
                  } else if (diffDays > 1 && diffDays <= 365) {
                    String label =
                        "${_monthName(pickupDate.month)} ${pickupDate.day}";
                    if (!pastDaysMap.containsKey(label)) {
                      pastDaysMap[label] = [];
                    }
                    pastDaysMap[label]!.add(booking);
                  } else {
                    olderList.add(booking);
                  }
                }

                List<Widget> sections = [];

                void addSection(
                  String title,
                  List<dynamic> bookings, {
                  bool limit = true,
                }) {
                  if (bookings.isEmpty) return;
                  sections.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                  int maxDisplay = bookings.length;
                  int displayCount = maxDisplay;
                  if (limit) {
                    if (title == 'Today' || title == 'Yesterday') {
                      displayCount =
                          showAllRecent
                              ? maxDisplay
                              : (maxDisplay < 2 ? maxDisplay : 2);
                    } else if (title == 'Older') {
                      displayCount =
                          showAllOlder
                              ? maxDisplay
                              : (maxDisplay < 2 ? maxDisplay : 2);
                    } else {
                      displayCount = maxDisplay;
                    }
                  }
                  for (int i = 0; i < displayCount; i++) {
                    final booking = bookings[i];
                    sections.add(_buildBookingCard(booking));
                  }
                  if (limit && bookings.length > displayCount) {
                    sections.add(
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (title == 'Today' || title == 'Yesterday') {
                              showAllRecent = true;
                            } else if (title == 'Older') {
                              showAllOlder = true;
                            }
                          });
                        },
                        child: Text(
                          'More',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    );
                  }
                }

                addSection('Today', todayList);
                addSection('Yesterday', yesterdayList);

                // Sort past days descending
                List<String> sortedPastLabels =
                    pastDaysMap.keys.toList()..sort((a, b) {
                      final aParts = a.split(' ');
                      final bParts = b.split(' ');
                      final aMonth = _monthNumber(aParts[0]);
                      final bMonth = _monthNumber(bParts[0]);
                      final aDay = int.parse(aParts[1]);
                      final bDay = int.parse(bParts[1]);
                      final aDate = DateTime(now.year, aMonth, aDay);
                      final bDate = DateTime(now.year, bMonth, bDay);
                      return bDate.compareTo(aDate);
                    });

                for (var label in sortedPastLabels) {
                  addSection(label, pastDaysMap[label]!);
                }

                // Add older bookings
                addSection('Older', olderList);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sections,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _monthNumber(String monthName) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[monthName] ?? 1;
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final carName = booking['carName'] ?? 'Unknown';
    final brand = booking['car_brand'] ?? 'Not provided';
    final totalPrice = booking['totalPrice']?.toString() ?? 'Not provided';
    final status = booking['status'] ?? 'Unknown';
    final carImage1 = booking['carImage1'] ?? 'assets/images/car.png';

    final bool locationStatus = booking['location_Status'] ?? false;
    final String? latString = booking['location_latitude'];
    final String? lonString = booking['location_longitude'];

    final double? locationLatitude = latString != null
        ? double.tryParse(latString)
        : null;

    final double? locationLongitude = lonString != null
        ? double.tryParse(lonString)
        : null;

    // Extract pickupDateTime
    final pickUpTimestamp = booking['pickUpDateTime'];
    String pickUpDateStr = 'N/A';
    if (pickUpTimestamp != null) {
      DateTime dateTime;
      if (pickUpTimestamp is Timestamp) {
        dateTime = pickUpTimestamp.toDate();
      } else if (pickUpTimestamp is DateTime) {
        dateTime = pickUpTimestamp;
      } else {
        dateTime = DateTime.now();
      }
      pickUpDateStr = '${dateTime.toLocal().toString().split('.').first}';
    }

    return GestureDetector(
      onTap: () {
        print('Navigating to documentReference: ${booking['reference']?.path}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveBookingUserTracking(
              documentReference: booking['reference'],
            ),
          ),
        );
      },
      child: Card(
        color: Colors.grey[900],
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              // Car Image and details
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      carImage1,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.yellow,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.car_repair, size: 80),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Brand: $brand',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Distance: ${booking['distance'] ?? 'N/A'} km, Seats: ${booking['seats']}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Pickup: $pickUpDateStr',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '₹$totalPrice',
                          style: GoogleFonts.poppins(
                            color: Colors.yellow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    status,
                    style: GoogleFonts.poppins(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Show location status or map
              if (locationStatus)
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Location is Active',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else if (locationLatitude != null && locationLongitude != null)
              // You can keep the map code here if needed in future
              // For now, just show "Location not active"
                Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Location is Inactive',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
              // No location data
                SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }}
