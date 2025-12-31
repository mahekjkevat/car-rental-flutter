import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class ChartDetailPage extends StatefulWidget {
  final int chartType;

  const ChartDetailPage({super.key, required this.chartType});

  @override
  _ChartDetailPageState createState() => _ChartDetailPageState();
}

class _ChartDetailPageState extends State<ChartDetailPage> {
  late Future<dynamic> _chartDataFuture;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Use a map to store loading states for each chart type
  final Map<int, bool> _isLoading = {
    0: false,
    1: false,
    2: false,
    3: false,
    4: false,
    5: false,
    6: false,
  };

  // Use a map to store chart data for each chart type
  final Map<int, dynamic> _chartData = {
    0: null,
    1: null,
    2: null,
    3: null,
    4: null,
    5: null,
    6: null,
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _isLoading[widget.chartType] = true;
    });

    Future<dynamic>? future; // declare nullable
    if (widget.chartType == 0) {
      future = _fetchUserData();
    } else if (widget.chartType == 1) {
      _loadRevenueData(); // call method that sets data and loading
      future = null; // no need to assign
    } else if (widget.chartType == 2) {
      future = _fetchProfitMarginData(); // <-- call for profit margin data
    } else if (widget.chartType == 3) {
      future = _fetchBookingData();
    } else if (widget.chartType == 4) {
      future = _fetchSalesByCityAndCarBrandData();
    } else if (widget.chartType == 6) {
      future = _fetchWeeklyBookingData(_selectedYear, _selectedMonth);
    } else {
      future = Future.value(null);
    }
    _chartDataFuture =
        future != null
            ? future
                .then((data) {
                  setState(() {
                    _chartData[widget.chartType] = data;
                    _isLoading[widget.chartType] = false;
                  });
                  return data;
                })
                .catchError((error) {
                  setState(() {
                    _isLoading[widget.chartType] = false;
                  });
                  throw error;
                })
            : Future.value(null);
  }

  Future<Map<String, int>> _fetchUserData() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('Users').get();

      final Map<String, int> cityUserCounts = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final userCity = data['city'];

        if (userCity != null && userCity is String && userCity.isNotEmpty) {
          final normalizedCity = userCity.trim().toUpperCase();
          cityUserCounts.update(
            normalizedCity,
            (currentCount) => currentCount + 1,
            ifAbsent: () => 1,
          );
        }
      }

      return cityUserCounts;
    } catch (e) {
      print('Error fetching User Distribution data: $e');
      if (e.toString().contains('indexes') ||
          e.toString().contains('index required')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showIndexRequiredDialog('User Distribution', 'Users', 'city:asc');
        });
      }
      rethrow;
    }
  }

  Future<Map<String, int>> _fetchBookingData() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collectionGroup('car_booking').get();

      final Map<String, int> cityBookingCounts = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final userCity = data['userCity'];

        if (userCity != null && userCity is String && userCity.isNotEmpty) {
          final normalizedCity = userCity.trim().toUpperCase();
          cityBookingCounts.update(
            normalizedCity,
            (currentCount) => currentCount + 1,
            ifAbsent: () => 1,
          );
        }
      }

      return cityBookingCounts;
    } catch (e) {
      print('Error fetching Booking Trends data: $e');
      if (e.toString().contains('indexes') ||
          e.toString().contains('index required')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showIndexRequiredDialog(
            'Booking Trends',
            'car_booking',
            'userCity:asc',
            isCollectionGroup: true,
          );
        });
      }
      rethrow;
    }
  }

  Future<Map<String, Map<String, int>>>
  _fetchSalesByCityAndCarBrandData() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collectionGroup('car_booking').get();

      final Map<String, Map<String, int>> salesData = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final userCity = data['userCity'] as String?;
        final carBrand = data['car_brand'] as String?;

        if (userCity != null &&
            userCity.isNotEmpty &&
            carBrand != null &&
            carBrand.isNotEmpty) {
          final normalizedCity = userCity.trim().toUpperCase();
          final normalizedCarBrand = carBrand.trim().toUpperCase();

          salesData.putIfAbsent(normalizedCity, () => {});

          salesData[normalizedCity]!.update(
            normalizedCarBrand,
            (currentCount) => currentCount + 1,
            // Assuming each document represents one sale/booking
            ifAbsent: () => 1,
          );
        }
      }

      return salesData;
    } catch (e) {
      print('Error fetching Sales by City and Car Brand data: $e');
      if (e.toString().contains('indexes') ||
          e.toString().contains('index required')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showIndexRequiredDialog(
            'Sales by City and Car Brand',
            'car_booking',
            'userCity:asc,car_brand:asc',
            isCollectionGroup: true,
          );
        });
      }
      rethrow;
    }
  }

  Future<Map<int, int>> _fetchWeeklyBookingData(int year, int month) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      final querySnapshot =
          await FirebaseFirestore.instance
              .collectionGroup('car_booking')
              .where(
                'bookingTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where(
                'bookingTime',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
              )
              .get();

      final Map<int, int> weeklyBookingCounts = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final bookingTime = data['bookingTime'] as Timestamp?;

        if (bookingTime != null) {
          final dateTime = bookingTime.toDate();
          final weekNumber = _getWeekOfMonth(dateTime);

          weeklyBookingCounts.update(
            weekNumber,
            (currentCount) => currentCount + 1,
            ifAbsent: () => 1,
          );
        }
      }

      final numberOfWeeks = _getNumberOfWeeksInMonth(year, month);
      for (int i = 1; i <= numberOfWeeks; i++) {
        weeklyBookingCounts.putIfAbsent(i, () => 0);
      }

      return weeklyBookingCounts;
    } catch (e) {
      print('Error fetching Weekly Booking data: $e');
      if (e.toString().contains('indexes') ||
          e.toString().contains('index required')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showIndexRequiredDialog(
            'Weekly Booking Trends',
            'car_booking',
            'bookingTime:asc',
            isCollectionGroup: true,
          );
        });
      }
      rethrow;
    }
  }

  void _loadRevenueData() async {
    setState(() {
      _isLoading[1] = true;
    });
    final data = await _fetchRevenueTrend();
    setState(() {
      _chartData[1] = data;
      _isLoading[1] = false;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchRevenueTrend() async {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final totalMonths = now.month; // Up to current month

    for (int m = 1; m <= totalMonths; m++) {
      final start = DateTime(now.year, m, 1);
      final end = DateTime(now.year, m + 1, 0);
      final query =
          await FirebaseFirestore.instance
              .collectionGroup('car_booking')
              .where(
                'bookingTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where(
                'bookingTime',
                isLessThanOrEqualTo: Timestamp.fromDate(end),
              )
              .get();

      double totalRevenue = 0;
      for (var doc in query.docs) {
        final dataMap = doc.data() as Map<String, dynamic>;
        totalRevenue += (dataMap['totalPrice'] ?? 0);
      }

      data.add({
        'x': m.toDouble(),
        'revenue': totalRevenue,
        'label': DateFormat('MMM').format(start),
      });
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> _fetchProfitMarginData() async {
    print('Fetching profit margin data...');
    final querySnapshot =
        await FirebaseFirestore.instance.collectionGroup('car_booking').get();
    print('Total documents fetched: ${querySnapshot.docs.length}');

    if (querySnapshot.docs.isEmpty) {
      print('No documents found.');
      return [];
    }

    Map<String, List<num>> vehicleProfitData = {};
    Map<String, double> vehicleTotalRevenue = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      final carBrand = data['car_brand'] as String? ?? 'unknown';
      final totalPrice = (data['totalPrice'] ?? 0).toDouble();

      final vehicleType = getVehicleTypeFromBrand(carBrand);
      print(
        'Document ID: ${doc.id} | Brand: $carBrand | Type: $vehicleType | Price: $totalPrice',
      );

      final costPrice = getCostPriceForVehicleType(vehicleType);
      vehicleProfitData
          .putIfAbsent(vehicleType, () => [])
          .add(totalPrice - costPrice);
      vehicleTotalRevenue.update(
        vehicleType,
        (sum) => sum + totalPrice,
        ifAbsent: () => totalPrice,
      );
    }

    // Calculate margins
    List<Map<String, dynamic>> result = [];
    vehicleProfitData.forEach((vehicleType, profits) {
      if (profits.isEmpty) return;
      final totalProfit = profits.reduce((a, b) => a + b);
      final count = profits.length;
      final avgProfit = totalProfit / count;
      final totalRevenue = vehicleTotalRevenue[vehicleType] ?? 0;
      final avgSalePrice = getAverageSalePrice(vehicleType);
      final profitMarginPercent = (avgProfit / avgSalePrice) * 100;

      print('Type: $vehicleType | Margin: $profitMarginPercent');

      result.add({
        'vehicleType': vehicleType,
        'profitMargin': profitMarginPercent,
      });
    });

    print('Finished processing profit margin data.');
    return result;
  } // Example: map vehicle type to cost price

  double getCostPriceForVehicleType(String vehicleType) {
    switch (vehicleType) {
      case 'sedan':
        return 20000;
      case 'suv':
        return 30000;
      case 'hatchback':
        return 18000;
      case 'luxury':
        return 50000;
      case 'other':
        return 20000;
      default:
        return 20000;
    }
  }

  // Example: map vehicle type to average sale price
  double getAverageSalePrice(String vehicleType) {
    switch (vehicleType) {
      case 'sedan':
        return 25000;
      case 'suv':
        return 40000;
      case 'hatchback':
        return 20000;
      case 'luxury':
        return 60000;
      case 'other':
        return 25000;
      default:
        return 25000;
    }
  }

  Widget _buildProfitMarginChart(List<Map<String, dynamic>> data) {
    final vehicleTypes = data.map((e) => e['vehicleType'] as String).toList();
    final margins = data.map((e) => e['profitMargin'] as double).toList();

    final maxY =
        (margins.isNotEmpty ? margins.reduce((a, b) => a > b ? a : b) : 0) *
        1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average Profit Margin by Vehicle Type',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        // Wrap the chart in a horizontal SingleChildScrollView
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: vehicleTypes.length * 100.0 + 50,
            // Adjust width based on number of bars
            height: 400,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: List.generate(vehicleTypes.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: margins[index],
                        color: Colors.green,
                        width: 20,
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < vehicleTypes.length) {
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              vehicleTypes[index],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                    axisNameWidget: Text(
                      'Vehicle Type',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    axisNameSize: 16,
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget:
                          (value, meta) => Text(
                            value.toStringAsFixed(1) + '%',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                    ),
                    axisNameWidget: Text(
                      'Profit Margin (%)',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    axisNameSize: 16,
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
                        strokeWidth: 1,
                      ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
                    width: 1,
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final vehicleType = vehicleTypes[group.x.toInt()];
                      final profitMargin = rod.toY.toStringAsFixed(2);
                      return BarTooltipItem(
                        '$vehicleType\n',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: '$profitMargin%',
                            style: GoogleFonts.poppins(
                              color: Colors.yellow,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                    tooltipRoundedRadius: 8.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Optional: add some padding or a scrollbar indicator
      ],
    );
  }

  String getVehicleTypeFromBrand(String carBrand) {
    final brand = carBrand.toLowerCase();

    if (brand.contains('kia') )
    {
      return 'kia';
    }
    else if (brand.contains('toyota')) {
      return 'toyoto';
    } else if (brand.contains('ford') ||
        brand.contains('chevrolet') ||
        brand.contains('mazda')) {
      return 'sedan';
    } else if (brand.contains('bmw') ||
        brand.contains('mercedes') ||
        brand.contains('audi') ||
        brand.contains('luxury')) {
      return 'luxury';
    } else if (brand.contains('suv') ||
        brand.contains('jeep') ||
        brand.contains('mahindra')) {
      return 'suv';
    } else {
      return 'other';
    }
  }

  void _showIndexRequiredDialog(
    String chartName,
    String collection,
    String fields, {
    bool isCollectionGroup = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final indexUrl =
            'https://console.firebase.google.com/project/geargo-e4cad/firestore/indexes?create_manual=collection${isCollectionGroup ? 'GroupId' : 'Id'}=${collection}%26fields=${fields.replaceAll(':', '%253A').replaceAll(',', '%252C')}';

        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Firebase Index Required',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'To display the "$chartName" chart, you need to create a specific index in your Firebase Firestore database.',
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
                const SizedBox(height: 15),
                Text(
                  'Required Index:',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Collection ${isCollectionGroup ? 'Group' : ''} ID: $collection',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                Text(
                  'Fields: $fields',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                const SizedBox(height: 15),
                Text(
                  'You can create this index manually in the Firebase console or by clicking the link below:',
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse(indexUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      print('Could not launch $indexUrl');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not open the Firebase console link.',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Create Index in Firebase Console',
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: GoogleFonts.poppins(color: Colors.yellow),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstDayOfWeek =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final firstDayOfYear =
        firstDayOfMonth.difference(DateTime(firstDayOfMonth.year, 1, 1)).inDays;
    return ((dayOfYear - firstDayOfYear + firstDayOfWeek) / 7).ceil();
  }

  int _getNumberOfWeeksInMonth(int year, int month) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    return _getWeekOfMonth(lastDayOfMonth);
  }

  Color _getColorForCarBrand(String brand, List<String> allCarBrands) {
    final index = allCarBrands.indexOf(brand);
    if (index != -1) {
      return Colors.primaries[index % Colors.primaries.length];
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
        title: Text(
          _getChartTitle(widget.chartType),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed View',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.chartType == 6) _buildMonthSelector(),
            SizedBox(height: 400, child: _buildChartContent(widget.chartType)),
            if (widget.chartType == 0) _buildUserDistributionSummary(),
            if (widget.chartType == 3) _buildBookingTrendsSummary(),
            if (widget.chartType == 4) _buildSalesByCityAndCarBrandSummary(),
            if (widget.chartType == 6) _buildWeeklyBookingSummary(),
          ],
        ),
      ),
    );
  }

  String _getChartTitle(int chartType) {
    switch (chartType) {
      case 0:
        return 'User Distribution by City';
      case 1:
        return 'Revenue Trend';
      case 2:
        return 'Profit Margin per Vehicle Type';
      case 3:
        return 'Booking Trends by City';
      case 4:
        return 'Booking by City and Car Brand';
      case 5:
        return 'Weekly Booking Trends';
      case 6:
        return 'Weekly Booking Trends';
      default:
        return 'Chart';
    }
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            setState(() {
              if (_selectedMonth == 1) {
                _selectedMonth = 12;
                _selectedYear--;
              } else {
                _selectedMonth--;
              }
              _fetchData();
            });
          },
        ),
        Text(
          DateFormat(
            'MMMM yyyy',
          ).format(DateTime(_selectedYear, _selectedMonth)),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onPressed: () {
            final now = DateTime.now();
            final nextMonth = DateTime(_selectedYear, _selectedMonth + 1);
            if (nextMonth.isBefore(now.copyWith(day: 1))) {
              setState(() {
                if (_selectedMonth == 12) {
                  _selectedMonth = 1;
                  _selectedYear++;
                } else {
                  _selectedMonth++;
                }
                _fetchData();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildChartContent(int chartType) {
    if (_isLoading[chartType] == true) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
        ),
      );
    } else if (_chartData[chartType] == null ||
        (_chartData[chartType] is Map &&
            (_chartData[chartType] as Map).isEmpty)) {
      return Center(
        child: Text(
          'No data available.',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    } else {
      switch (chartType) {
        case 0:
          final cityUserCounts = _chartData[chartType] as Map<String, int>;
          final cityNames = cityUserCounts.keys.toList();
          final userCounts = cityUserCounts.values.toList();

          final maxY =
              userCounts.isNotEmpty
                  ? userCounts.reduce((a, b) => a > b ? a : b).toDouble() * 1.2
                  : 1.0;

          return BarChart(
            BarChartData(
              barGroups: List.generate(cityNames.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: userCounts[index].toDouble(),
                      color: Colors.yellow,
                      width: 20,
                    ),
                  ],
                );
              }),
              maxY: maxY,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    'City',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < cityNames.length) {
                        return SideTitleWidget(
                          meta: meta, // Explicitly set axisSide
                          space: 8.0,
                          child: Text(
                            cityNames[index],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Container();
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Users',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget:
                        (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                    reservedSize: 40,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
                  width: 1,
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final cityName = cityNames[groupIndex];
                    final userCount = rod.toY.toInt();
                    return BarTooltipItem(
                      '$cityName\n',
                      GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: userCount.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.yellow,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );

        case 3:
          final cityBookingCounts = _chartData[chartType] as Map<String, int>;
          final cityNames = cityBookingCounts.keys.toList();
          final bookingCounts = cityBookingCounts.values.toList();

          final maxY =
              bookingCounts.isNotEmpty
                  ? bookingCounts.reduce((a, b) => a > b ? a : b).toDouble() *
                      1.2
                  : 1.0;

          return BarChart(
            BarChartData(
              barGroups: List.generate(cityNames.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: bookingCounts[index].toDouble(),
                      color: Colors.purple,
                      width: 20,
                    ),
                  ],
                );
              }),
              maxY: maxY,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    'City',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < cityNames.length) {
                        return SideTitleWidget(
                          meta: meta, // Explicitly set axisSide
                          space: 8.0,
                          child: Text(
                            cityNames[index],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Container();
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Bookings',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget:
                        (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                    reservedSize: 40,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
                  width: 1,
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final cityName = cityNames[groupIndex];
                    final bookingCount = rod.toY.toInt();
                    return BarTooltipItem(
                      '$cityName\n',
                      GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: bookingCount.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.yellow,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );

        case 4: // Sales by City and Car Brand (Grouped Vertical Bar Chart)
          final salesData =
              _chartData[chartType] as Map<String, Map<String, int>>;

          final cities = salesData.keys.toList();
          final allCarBrands =
              salesData.values
                  .expand((cityData) => cityData.keys)
                  .toSet()
                  .toList()
                ..sort();

          // Calculate the maximum sales count for any single brand in any city
          int maxBrandSales = 0;
          salesData.values.forEach((cityData) {
            cityData.values.forEach((salesCount) {
              if (salesCount > maxBrandSales) {
                maxBrandSales = salesCount;
              }
            });
          });
          final maxY = maxBrandSales.toDouble() * 1.2; // Add some padding

          // Define the width of each bar and the space between bars within a group
          const double barWidth = 8;
          const double barSpace = 2;
          // Calculate the total width of a group of bars (for one city)
          final double groupWidth =
              (barWidth * allCarBrands.length) +
              (barSpace * (allCarBrands.length - 1));
          // Define the space between groups (between cities)
          const double groupSpace = 20;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColorLegend(allCarBrands),
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    barGroups: List.generate(cities.length, (cityIndex) {
                      final cityName = cities[cityIndex];
                      final citySales = salesData[cityName]!;

                      final barRods = List<BarChartRodData>.generate(
                        allCarBrands.length,
                        (brandIndex) {
                          final carBrand = allCarBrands[brandIndex];
                          final salesCount = citySales[carBrand] ?? 0;
                          final color = _getColorForCarBrand(
                            carBrand,
                            allCarBrands,
                          );

                          return BarChartRodData(
                            toY: salesCount.toDouble(),
                            color: color,
                            width: barWidth,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          );
                        },
                      );

                      return BarChartGroupData(
                        x: cityIndex,
                        barsSpace: barSpace,
                        barRods: barRods,
                      );
                    }),
                    alignment: BarChartAlignment.center,
                    // Align groups to center
                    maxY: maxY,
                    minY: 0,
                    groupsSpace: groupSpace,
                    // Space between city groups
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        axisNameWidget: Text(
                          'City',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        axisNameSize: 20,
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < cities.length) {
                              return SideTitleWidget(
                                meta: meta, // Explicitly set axisSide
                                space: 8.0,
                                child: Text(
                                  cities[index],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return Container();
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                          'Booking Count',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        axisNameSize: 20,
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget:
                              (value, meta) => Text(
                                value.toInt().toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[800]!.withAlpha(
                            (255 * 0.5).round(),
                          ),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
                        width: 1,
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final cityName = cities[groupIndex];
                          final carBrand =
                              allCarBrands[rodIndex]; // rodIndex corresponds to the brand index within the group
                          final salesCount = rod.toY.toInt();
                          return BarTooltipItem(
                            '$cityName\n',
                            GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '$carBrand: $salesCount',
                                style: GoogleFonts.poppins(
                                  color: Colors.yellow,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                        tooltipRoundedRadius: 8.0,
                      ),
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 150),
                  swapAnimationCurve: Curves.linear,
                ),
              ),
            ],
          );
        case 1:
          final revenueData = _chartData[1] as List<Map<String, dynamic>>;

          // Prepare spots for the line chart
          final spots =
              revenueData
                  .map(
                    (data) => FlSpot(
                      (data['x'] as num).toDouble(),
                      (data['revenue'] as num).toDouble(),
                    ),
                  )
                  .toList();

          // Determine maxY for scaling
          final maxY =
              revenueData.isNotEmpty
                  ? revenueData
                          .map((d) => d['revenue'] as num)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2
                  : 1.0;

          // Extract labels
          final labels =
              revenueData.map((data) => data['label'] as String).toList();

          // Identify indices for labels (show only first occurrence of each month)
          final Set<int> labelIndices = {};
          final Set<String> seenMonths = {};
          for (int i = 0; i < labels.length; i++) {
            final month = labels[i];
            if (!seenMonths.contains(month)) {
              labelIndices.add(i);
              seenMonths.add(month);
            }
          }
          return Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Revenue Line Chart',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Line chart showing revenue trend over months.\n\n'
                  'X-Axis: Months (Jan to Dec)\n'
                  'Y-Axis: Revenue (formatted as currency)',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400,
                  child: Stack(
                    children: [
                      LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: maxY,
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final index = spot.spotIndex;
                                  final dataPoint = revenueData[index];
                                  return LineTooltipItem(
                                    'Month: ${dataPoint['label']}\nRevenue: \₹${spot.y.toInt()}',
                                    GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            drawHorizontalLine: true,
                            horizontalInterval: maxY / 5,
                            getDrawingHorizontalLine:
                                (value) => FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                ),
                            getDrawingVerticalLine:
                                (value) => FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 &&
                                      index < revenueData.length) {
                                    if (labelIndices.contains(index)) {
                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 8,
                                        child: Text(
                                          revenueData[index]['label'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  String formatted = '';
                                  if (value >= 1000) {
                                    formatted =
                                        '${(value / 1000).toStringAsFixed(0)}k';
                                  } else {
                                    formatted = value.toInt().toString();
                                  }
                                  return Text(
                                    formatted,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.blue.shade800,
                              barWidth: 4,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, bar, index) =>
                                        FlDotCirclePainter(
                                          radius: 4,
                                          color: Colors.white,
                                          strokeWidth: 2,
                                          strokeColor: Colors.blue.shade700,
                                        ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.shade200.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Optional axis annotations
                      Positioned(
                        top: 8,
                        left: 16,
                        child: Text(
                          'X: Months (Jan to Dec)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 16,
                        child: Text(
                          'Y: Revenue (USD)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Note: Touch a point to see detailed revenue.\nCurrency format is used for Y-axis.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        case 2:
          final profitData = _chartData[2] as List<Map<String, dynamic>>?;

          if (profitData == null || profitData.isEmpty) {
            return Center(
              child: Text(
                'Loading profit margin data...',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfitMarginChart(profitData),
              const SizedBox(height: 16),
              // Description below the chart
              Text(
                'This bar chart displays the average profit margin (%) for each vehicle type. '
                'The X-axis shows different vehicle types, and the Y-axis shows the profit margin as a percentage.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          );
        case 5:
          return Center(
            child: Text(
              'Chart 5 is a placeholder.',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        case 6: // Weekly Booking Trends (Bar Chart)
          final weeklyBookingCounts = _chartData[chartType] as Map<int, int>;
          final weeks = weeklyBookingCounts.keys.toList()..sort();
          final bookingCounts =
              weeks.map((week) => weeklyBookingCounts[week]!).toList();

          final maxY =
              bookingCounts.isNotEmpty
                  ? bookingCounts.reduce((a, b) => a > b ? a : b).toDouble() *
                      1.2
                  : 1.0;

          return BarChart(
            BarChartData(
              barGroups: List.generate(weeks.length, (index) {
                return BarChartGroupData(
                  x: weeks[index],
                  barRods: [
                    BarChartRodData(
                      toY: bookingCounts[index].toDouble(),
                      color: Colors.lime,
                      width: 20,
                    ),
                  ],
                );
              }),
              maxY: maxY,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Week of the Month',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final weekNumber = value.toInt();
                      if (weeks.contains(weekNumber)) {
                        return SideTitleWidget(
                          meta: meta, // Explicitly set axisSide
                          space: 8.0,
                          child: Text(
                            'Week $weekNumber',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Container();
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Bookings',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget:
                        (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                    reservedSize: 40,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.grey[800]!.withAlpha((255 * 0.5).round()),
                  width: 1,
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final weekNumber = group.x.toInt();
                    final bookingCount = rod.toY.toInt();
                    return BarTooltipItem(
                      'Week $weekNumber\n',
                      GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: bookingCount.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.yellow,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                  tooltipRoundedRadius: 8.0,
                ),
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 150),
            swapAnimationCurve: Curves.linear,
          );

        default:
          return Container();
      }
    }
  }

  List<FlSpot> _generateStepSpots(List<FlSpot> originalSpots) {
    if (originalSpots.isEmpty) return [];
    List<FlSpot> stepSpots = [originalSpots.first];

    for (int i = 1; i < originalSpots.length; i++) {
      final prev = originalSpots[i - 1];
      final curr = originalSpots[i];

      stepSpots.add(FlSpot(curr.x, prev.y)); // horizontal
      stepSpots.add(curr); // vertical
    }

    return stepSpots;
  }

  Widget _buildUserDistributionSummary() {
    final cityUserCounts = _chartData[0];
    if (cityUserCounts == null ||
        (cityUserCounts is Map && cityUserCounts.isEmpty)) {
      return Container();
    }

    final sortedCities =
        (cityUserCounts as Map<String, int>).entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text(
          'User Distribution Summary by City',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'This chart shows the number of registered users in each city. Cities on the X-axis represent the location, and the height of each bar on the Y-axis indicates the total user count for that city.',
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 8),
        Divider(),
        const SizedBox(height: 8),
        Text(
          'Top User Cities:',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedCities.length > 5 ? 5 : sortedCities.length,
          itemBuilder: (context, index) {
            final entry = sortedCities[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${entry.value} users',
                    style: GoogleFonts.poppins(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (sortedCities.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '...and ${sortedCities.length - 5} more cities.',
              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingTrendsSummary() {
    final cityBookingCounts = _chartData[3];
    if (cityBookingCounts == null ||
        (cityBookingCounts is Map && cityBookingCounts.isEmpty)) {
      return Container();
    }

    final sortedCities =
        (cityBookingCounts as Map<String, int>).entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text(
          'Booking Summary by City',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'This chart shows the total number of car bookings for each city where rentals have occurred. Cities on the X-axis represent the location, and the height of each bar on the Y-axis indicates the total booking count for that city.',
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 15),
        Text(
          'Top Booking Cities:',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedCities.length > 5 ? 5 : sortedCities.length,
          itemBuilder: (context, index) {
            final entry = sortedCities[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${entry.value} bookings',
                    style: GoogleFonts.poppins(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (sortedCities.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '...and ${sortedCities.length - 5} more cities.',
              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSalesByCityAndCarBrandSummary() {
    final salesData = _chartData[4];
    if (salesData == null || (salesData is Map && salesData.isEmpty)) {
      return Container();
    }

    final cities = (salesData as Map<String, Map<String, int>>).keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text(
          'Booking Summary by City and Car Brand',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Divider(),
        const SizedBox(height: 8),
        Text(
          'This chart shows the number of sales for each car brand within different cities. Cities are on the X-axis, and the height of each bar on the Y-axis represents the sales count for various car brands in that city.',
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 15),
        Text(
          'Booking Details by City:',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Divider(),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cities.length,
          itemBuilder: (context, index) {
            final cityName = cities[index];
            final citySales = salesData[cityName]!;
            final sortedBrands =
                citySales.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cityName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedBrands.length,
                  itemBuilder: (context, brandIndex) {
                    final brandEntry = sortedBrands[brandIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2.0,
                        horizontal: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            brandEntry.key,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${brandEntry.value} sales',
                            style: GoogleFonts.poppins(
                              color: Colors.yellow,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeeklyBookingSummary() {
    final weeklyBookingCounts = _chartData[6];
    if (weeklyBookingCounts == null ||
        (weeklyBookingCounts is Map && weeklyBookingCounts.isEmpty)) {
      return Container();
    }

    final weeks = (weeklyBookingCounts as Map<int, int>).keys.toList()..sort();
    final totalBookings = weeklyBookingCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Weekly Booking Summary',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'This chart shows the total number of car bookings for each week of the selected month. The X-axis represents the week number within the month, and the height of each bar on the Y-axis indicates the total booking count for that week.',
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 15),
        Text(
          'Total Bookings in ${DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth))}              Total : $totalBookings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),
        Divider(),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: weeks.length,
          itemBuilder: (context, index) {
            final weekNumber = weeks[index];
            final bookingCount = weeklyBookingCounts[weekNumber]!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Week $weekNumber',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$bookingCount bookings',
                    style: GoogleFonts.poppins(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildColorLegend(List<String> allCarBrands) {
    if (allCarBrands.isEmpty) return Container();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Car Brand Colors:',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: List.generate(allCarBrands.length, (index) {
              final brand = allCarBrands[index];
              final color = _getColorForCarBrand(brand, allCarBrands);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    brand,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
