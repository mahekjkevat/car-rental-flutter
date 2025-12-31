import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chart_detail_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.7, curve: Curves.easeInOut)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        title: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Reports',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(
                    color: Colors.yellow.withOpacity(0.6),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.grey[900]!.withOpacity(0.9),
                ],
              ),
            ),
          ),
          _isLoading
              ? Center(child: _buildLoadingDialog())
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Analyze your car rental business',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _chartData.length,
                  itemBuilder: (context, index) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.2 * (index + 1)),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Interval(0.1 * index, 0.7 + 0.1 * index,
                              curve: Curves.easeOutCubic),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildChartCard(
                          context,
                          _chartData[index]['title'],
                          _chartData[index]['icon'],
                          _chartData[index]['chartType'],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDialog() {
    return Container(
      padding: const EdgeInsets.all(30.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
            strokeWidth: 6.0,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Reports...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, IconData icon, int chartType) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChartDetailPage(chartType: chartType),
          ),
        );
      },
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.grey[800]!.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: _getSquareChartPreview(chartType),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: Colors.yellow, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view details',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getSquareChartPreview(int chartType) {
    switch (chartType) {
      case 0: // User Distribution
        return BarChart(
          BarChartData(
            barGroups: [
              BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 5, color: Colors.yellow, width: 12)]),
              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 8, color: Colors.yellow, width: 12)]),
              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 3, color: Colors.yellow, width: 12)]),
            ],
            maxY: 10,
            titlesData: FlTitlesData(show: false),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
          ),
        );
      case 1: // Revenue Trend
        return LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 100),
                  FlSpot(1, 150),
                  FlSpot(2, 200),
                  FlSpot(3, 130),
                  FlSpot(4, 180),
                ],
                color: Colors.green,
                dotData: FlDotData(show: false),
                barWidth: 2,
                isCurved: true,
              ),
            ],
            titlesData: FlTitlesData(show: false),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(enabled: false),
          ),
        );
      case 2: // Car Utilization
        return PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(value: 60, color: Colors.blue, radius: 40, title: '', showTitle: false),
              PieChartSectionData(value: 40, color: Colors.red, radius: 40, title: '', showTitle: false),
            ],
            sectionsSpace: 2,
            centerSpaceRadius: 20,
            pieTouchData: PieTouchData(enabled: false),
          ),
        );
      case 3: // Booking Trends by City
        return BarChart(
          BarChartData(
            barGroups: [
              BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 50, color: Colors.purple, width: 12)]),
              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 70, color: Colors.purple, width: 12)]),
              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 40, color: Colors.purple, width: 12)]),
            ],
            maxY: 100,
            titlesData: FlTitlesData(show: false),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
          ),
        );
      case 4: // Sales by City and Car Brand (Horizontal Bar Chart Preview)
        return BarChart(
          BarChartData(
            barGroups: [
              BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 10, color: Colors.orange, width: 8)]),
              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 15, color: Colors.deepOrange, width: 8)]),
              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 8, color: Colors.orangeAccent, width: 8)]),
            ],
            maxY: 20,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(show: false),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        );
      case 5: // Profit Margin
        return PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(value: 70, color: Colors.teal, radius: 40, title: '', showTitle: false),
              PieChartSectionData(value: 30, color: Colors.pink, radius: 40, title: '', showTitle: false),
            ],
            sectionsSpace: 2,
            centerSpaceRadius: 20,
            pieTouchData: PieTouchData(enabled: false),
          ),
        );
      case 6: // Weekly Booking Trends (Line Chart Preview)
        return LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 5),
                  FlSpot(1, 8),
                  FlSpot(2, 12),
                  FlSpot(3, 9),
                ],
                color: Colors.lime,
                dotData: FlDotData(show: false),
                barWidth: 2,
                isCurved: true,
              ),
            ],
            titlesData: FlTitlesData(show: false),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(enabled: false),
          ),
        );
      default:
        return Container();
    }
  }

  final List<Map<String, dynamic>> _chartData = [
    {'title': 'User Distribution', 'icon': Icons.bar_chart, 'chartType': 0},
    {'title': 'Weekly Booking Trends', 'icon': Icons.calendar_month, 'chartType': 6},
    {'title': 'Revenue Trend', 'icon': Icons.show_chart, 'chartType': 1},
    {'title': 'Profit Margin per Vehicle Type', 'icon': Icons.attach_money, 'chartType': 2},
    {'title': 'Booking by City and Car Brand', 'icon': Icons.car_rental, 'chartType': 4},
  ];
}