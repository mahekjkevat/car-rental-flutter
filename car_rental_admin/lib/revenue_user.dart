import 'package:car_rental_admin/revenue_user_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RevenueUserPage extends StatefulWidget {
  const RevenueUserPage({Key? key}) : super(key: key);

  @override
  _RevenueUserPageState createState() => _RevenueUserPageState();
}

class _RevenueUserPageState extends State<RevenueUserPage> {
  bool isLoading = true;
  List<UserRevenue> userRevenues = [];
  Map<String, List<UserRevenue>> userRevenuesByCity = {}; // For city-wise
  String selectedCity = '';

  @override
  void initState() {
    super.initState();
    fetchUserRevenues();
  }

  Future<void> fetchUserRevenues() async {
    setState(() {
      isLoading = true;
    });
    try {
      final bookingsSnapshot =
      await FirebaseFirestore.instance.collectionGroup('car_booking').get();

      Map<String, UserRevenue> userMap = {};

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userEmail = (data['userEmail'] ?? '').toString().toLowerCase();
        final userName = data['userName'] ?? '';
        final userCity = data['userCity'] ?? '';
        final totalPrice = (data['totalPrice'] ?? 0).toDouble();

        if (userEmail.isEmpty) continue;

        if (userMap.containsKey(userEmail)) {
          userMap[userEmail]!.totalRevenue += totalPrice;
        } else {
          userMap[userEmail] = UserRevenue(
            email: userEmail,
            name: userName,
            city: userCity,
            totalRevenue: totalPrice,
          );
        }
      }

      // Group by city
      Map<String, List<UserRevenue>> cityMap = {};
      for (var user in userMap.values) {
        final cityKey = user.city.trim().toUpperCase();
        cityMap.putIfAbsent(cityKey, () => []).add(user);
      }

      setState(() {
        userRevenues = userMap.values.toList();
        userRevenuesByCity = cityMap;
        // Default select first city if available
        selectedCity = cityMap.keys.isNotEmpty ? cityMap.keys.first : '';
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user revenues: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Updated formatting function
  String formatPrice(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 tabs
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          title: Text(
            'User Revenue Summary',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.yellow,
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.yellow,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            labelStyle: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: 'All Users'),
              Tab(text: 'By City'),
            ],
          ),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: TabBarView(
          children: [
            // Tab 1: All Users
            isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            )
                : userRevenues.isEmpty
                ? Center(
              child: Text(
                'No booking data available.',
                style:
                GoogleFonts.poppins(color: Colors.red, fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: userRevenues.length,
              itemBuilder: (context, index) {
                final user = userRevenues[index];
                return Card(
                  color: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RevenueUserDetailsPage(
                            email: user.email,
                            city: user.city,
                            name: user.name,
                          ),
                        ),
                      );
                    },
                    title: Text(
                      '${user.name}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Email:\n${user.email}\nCity: ${user.city}',
                      style: GoogleFonts.poppins(color: Colors.grey[300]),
                    ),
                    trailing: Text(
                      '₹${formatPrice(user.totalRevenue)}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Tab 2: By City
            userRevenuesByCity.isEmpty
                ? Center(
              child: Text(
                'No city data available.',
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 18),
              ),
            )
                : Column(
              children: [
                // Dropdown to select city
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    dropdownColor: Colors.grey[900],
                    value: selectedCity,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    iconSize: 24,
                    elevation: 16,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                    onChanged: (String? newCity) {
                      if (newCity != null) {
                        setState(() {
                          selectedCity = newCity;
                        });
                      }
                    },
                    items: userRevenuesByCity.keys
                        .map<DropdownMenuItem<String>>((String cityKey) {
                      return DropdownMenuItem<String>(
                        value: cityKey,
                        child: Text(cityKey),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: userRevenuesByCity[selectedCity]?.length ?? 0,
                    itemBuilder: (context, index) {
                      final user = userRevenuesByCity[selectedCity]![index];
                      return Card(
                        color: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RevenueUserDetailsPage(
                                  email: user.email,
                                  city: user.city,
                                  name: user.name,
                                ),
                              ),
                            );
                          },
                          title: Text(
                            '${user.name}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'Email: ${user.email}\nCity: ${user.city}',
                            style: GoogleFonts.poppins(color: Colors.grey[300]),
                          ),
                          trailing: Text(
                            '₹${formatPrice(user.totalRevenue)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserRevenue {
  final String email;
  final String name;
  final String city;
  double totalRevenue;

  UserRevenue({
    required this.email,
    required this.name,
    required this.city,
    required this.totalRevenue,
  });
}