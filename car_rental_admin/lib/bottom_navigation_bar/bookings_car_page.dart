import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import '../user_booking_details_page.dart';
import 'CompletedBookingsPage.dart';

class BookingsAndCarsPage extends StatelessWidget {
  const BookingsAndCarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image with 25% opacity
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
          // Foreground content
          SafeArea(
            child: Column(
              // Use a Column to hold fixed headers and scrollable content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed Headers
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookings',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Manage your fleet and bookings',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellowAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const CompletedBookingsPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Show Completed Bookings',
                              style: GoogleFonts.poppins(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Recent Bookings',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable Booking List
                Expanded(
                  // Expanded makes the ListView take the remaining space
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collectionGroup('car_booking')
                            .orderBy(
                              'bookingTime',
                              descending: true,
                            ) // Order by booking time
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
                        return const Center(child: Text('No bookings found'));
                      }

                      // Group bookings by date
                      final Map<String, List<DocumentSnapshot>>
                      groupedBookings = {};
                      for (var booking in bookings) {
                        final timestamp = booking['bookingTime'] as Timestamp?;
                        if (timestamp != null) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            timestamp.millisecondsSinceEpoch,
                          );
                          final formattedDate = DateFormat(
                            'MMM,d',
                          ).format(date); // Format as Apr,17

                          // Determine if it's today or yesterday
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final yesterday = today.subtract(
                            const Duration(days: 1),
                          );
                          final bookingDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );

                          String displayDate;
                          if (bookingDate == today) {
                            displayDate = 'Today';
                          } else if (bookingDate == yesterday) {
                            displayDate = 'Yesterday';
                          } else {
                            displayDate = formattedDate;
                          }

                          if (groupedBookings.containsKey(displayDate)) {
                            groupedBookings[displayDate]!.add(booking);
                          } else {
                            groupedBookings[displayDate] = [booking];
                          }
                        }
                      }

                      // Sort the dates to display 'Today' and 'Yesterday' first, then by date
                      final sortedDates = groupedBookings.keys.toList();
                      sortedDates.sort((a, b) {
                        if (a == 'Today') return -1;
                        if (b == 'Today') return 1;
                        if (a == 'Yesterday') return -1;
                        if (b == 'Yesterday') return 1;
                        // For other dates, sort in descending order
                        try {
                          final dateTimeA = DateFormat('MMM,d').parse(a);
                          final dateTimeB = DateFormat('MMM,d').parse(b);
                          return dateTimeB.compareTo(dateTimeA);
                        } catch (e) {
                          // Handle cases where the date format might be unexpected
                          return 0;
                        }
                      });

                      return ListView.builder(
                        // This ListView is now the scrollable part
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        // Add horizontal padding here
                        itemCount: sortedDates.length,
                        itemBuilder: (context, dateIndex) {
                          final date = sortedDates[dateIndex];
                          final bookingsForDate = groupedBookings[date]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  date,
                                  style: GoogleFonts.poppins(
                                    color: Colors.yellow,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                // Keep this for the inner list
                                itemCount: bookingsForDate.length,
                                itemBuilder: (context, bookingIndex) {
                                  final booking =
                                      bookingsForDate[bookingIndex].data()
                                          as Map<String, dynamic>;
                                  final carName =
                                      booking['carName'] ?? 'Unknown';
                                  final brand =
                                      booking['car_brand'] ?? 'Not provided';
                                  final totalPrice =
                                      booking['totalPrice']?.toString() ??
                                      'Not provided';
                                  final status = booking['status'] ?? 'Unknown';
                                  final carImage1 =
                                      booking['carImage1'] ??
                                      'assets/images/car.png';
                                  final distance =
                                      booking['distance']?.toString() ?? 'N/A';
                                  final seats = booking['seats'] ?? 'N/A';
                                  final documentReference =
                                      bookingsForDate[bookingIndex].reference;

                                  return GestureDetector(
                                    onTap: () {
                                      print(
                                        'Navigating to documentReference: ${documentReference.path}',
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  UserBookingDetailsPage(
                                                    documentReference:
                                                        documentReference,
                                                  ),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      color: Colors.grey[900],
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl: carImage1,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (
                                                      context,
                                                      url,
                                                    ) => const CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.yellow),
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => const CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.yellow),
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    carName,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    'Brand: $brand',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.grey[400],
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Distance: $distance km, Seats: $seats',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color:
                                                                  Colors.grey,
                                                              fontSize: 13,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    '₹$totalPrice',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.yellow,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              status,
                                              style: GoogleFonts.poppins(
                                                color:
                                                    status == 'Pending'
                                                        ? Colors.orange
                                                        : status == 'accepted'
                                                        ? Colors.green
                                                        : Colors.red,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
