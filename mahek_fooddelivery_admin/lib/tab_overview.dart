// file: lib/tab_overview.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Using fl_chart for the sales trend graph

// Mock Data structure for the main dashboard cards
class OverviewCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  OverviewCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class TabOverview extends StatelessWidget {
  TabOverview({super.key});

  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightCardColor = const Color(0xFFFFFFFF);
  final Color chartLineColor = const Color(0xFF1D5D9B); // A blue color for the line

  // Hardcoded mock data to simulate the cards from the image
  final List<OverviewCardData> cardData = [
    OverviewCardData(
      title: 'Total Orders',
      value: '2,010',
      icon: Icons.shopping_bag_outlined,
      color: const Color(0xFF1D5D9B), // Blue
    ),
    OverviewCardData(
      title: 'Total Revenue',
      value: '₹ 89,500',
      icon: Icons.attach_money,
      color: const Color(0xFFE47C73), // Reddish/Orange
    ),
    OverviewCardData(
      title: 'Avg. Order Value',
      value: '₹ 44.53',
      icon: Icons.receipt_long,
      color: const Color(0xFF333333), // Dark Gray/Black
    ),
    OverviewCardData(
      title: 'Total Customers',
      value: '1,500',
      icon: Icons.group_outlined,
      color: const Color(0xFF1A5319), // Greenish/Dark Green
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid for the main data cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cardData.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cards per row
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.2, // Taller cards
            ),
            itemBuilder: (context, index) {
              return _buildOverviewCard(cardData[index]);
            },
          ),

          const SizedBox(height: 30),

          // --- CHART SECTION: Weekly Sales Trend ---
          Text(
            'Weekly Sales Trend',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: secondaryDarkColor,
            ),
          ),
          const SizedBox(height: 15),

          // Container for the Line Chart
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            height: 300,
            decoration: BoxDecoration(
              color: lightCardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildSalesChart(), // Displaying the chart here
          ),

          const SizedBox(height: 30),

          // Secondary Section Title (e.g., Charts or Recent Activity)
          Text(
            'Recent Orders & Activity',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: secondaryDarkColor,
            ),
          ),
          const SizedBox(height: 15),

          // Placeholder for the main activity area (List)
          Container(
            height: 300,
            decoration: BoxDecoration(
                color: lightCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt, size: 50, color: primaryAppColor.withOpacity(0.5)),
                const SizedBox(height: 10),
                Text(
                  'Detailed Recent Activity List Goes Here',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(OverviewCardData data) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: data.color, // Use the color from the data model
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  data.icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              // Overflow/Action Icon
              const Icon(
                Icons.more_vert,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),

          // Value (Main Number)
          Text(
            data.value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          // Title
          Text(
            data.title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // --- FL_CHART IMPLEMENTATION ---
  Widget _buildSalesChart() {
    return LineChart(
      LineChartData(
        // Grid setup (Horizontal lines only)
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        // Title setup (Labels on X and Y axis)
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            // FIX: Removed showTitle: false
            sideTitles: SideTitles(),
          ),
          topTitles: const AxisTitles(
            // FIX: Removed showTitle: false
            sideTitles: SideTitles(),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              // FIX: Removed showTitle: true
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: bottomTitleWidgets, // Passes TitleMeta implicitly
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              // FIX: Removed showTitle: true
              interval: 20000, // Show labels every 20,000
              getTitlesWidget: leftTitleWidgets, // Passes TitleMeta implicitly
              reservedSize: 42,
            ),
          ),
        ),
        // Border setup (Only bottom and left borders visible)
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: secondaryDarkColor.withOpacity(0.3), width: 1),
            left: BorderSide(color: secondaryDarkColor.withOpacity(0.3), width: 1),
            right: const BorderSide(color: Colors.transparent),
            top: const BorderSide(color: Colors.transparent),
          ),
        ),
        // Line data (Mock weekly sales trend)
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 10000), // Monday
              FlSpot(1, 25000), // Tuesday
              FlSpot(2, 60000), // Wednesday (Peak)
              FlSpot(3, 40000), // Thursday
              FlSpot(4, 75000), // Friday (Higher Peak)
              FlSpot(5, 55000), // Saturday
              FlSpot(6, 30000), // Sunday
            ],
            isCurved: true,
            gradient: LinearGradient(
              colors: [chartLineColor, primaryAppColor.withOpacity(0.6)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  chartLineColor.withOpacity(0.3),
                  chartLineColor.withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        // Axis limits
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 80000,
        lineTouchData: const LineTouchData(enabled: true),
      ),
    );
  }

  // Helper widget for Bottom Titles (Days of Week)
  // FIX: Signature is correct (requires TitleMeta)
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Color(0xFF333333),
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Mon', style: style);
        break;
      case 1:
        text = const Text('Tue', style: style);
        break;
      case 2:
        text = const Text('Wed', style: style);
        break;
      case 3:
        text = const Text('Thu', style: style);
        break;
      case 4:
        text = const Text('Fri', style: style);
        break;
      case 5:
        text = const Text('Sat', style: style);
        break;
      case 6:
        text = const Text('Sun', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(
      meta: meta,
      space: 8.0,
      child: text,
    );
  }

  // Helper widget for Left Titles (Revenue)
  // FIX: Signature is correct (requires TitleMeta)
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Color(0xFF333333),
    );
    String text;
    // Format the number to show 'K' (thousands) for better readability
    if (value == 0) {
      text = '0';
    } else if (value == 20000) {
      text = '20K';
    } else if (value == 40000) {
      text = '40K';
    } else if (value == 60000) {
      text = '60K';
    } else if (value == 80000) {
      text = '80K';
    } else {
      return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }
}