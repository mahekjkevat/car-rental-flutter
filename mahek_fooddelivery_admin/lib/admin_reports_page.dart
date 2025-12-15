import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

// --- Theme Colors and Constants (Copied from previous files for consistency) ---
final Color primaryAppColor = const Color(0xFFF96D0A); // Vibrant Orange/Red
final Color secondaryDarkColor = const Color(0xFF333333); // Dark text/icons
final Color lightBackgroundColor = const Color(0xFFF0F4F8); // Light background

// --- Dummy Data Structures for Charts ---

class SalesData {
  final String name;
  final List<FlSpot> spots;
  final List<BarChartGroupData> barGroups;
  final List<PieChartSectionData> pieSections;
  final double totalValue;
  final Color color;

  SalesData({
    required this.name,
    required this.spots,
    required this.barGroups,
    required this.pieSections,
    required this.totalValue,
    required this.color,
  });

  // Factory to generate dummy data for 6 individuals
  static List<SalesData> generateDummyData() {
    final names = ['Ketan', 'Jayesh', 'Priya', 'Rohan', 'Sneha', 'Vivek'];
    final baseColors = [
      Colors.blue,
      Colors.green,
      primaryAppColor,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    List<SalesData> dataList = [];
    for (int i = 0; i < 6; i++) {
      final color = baseColors[i];
      final seed = i * 10.0;
      double totalValue = 0;

      // 1. Line Chart Spots (Monthly Sales Trend)
      final spots = List.generate(6, (j) {
        final y = (seed + j * 5) * (1.0 + (i % 3) * 0.1) + (j % 2 == 0 ? 5 : -5);
        totalValue += y;
        return FlSpot((j + 1).toDouble(), y);
      });

      // 2. Bar Chart Groups (Weekly Order Count)
      final barGroups = List.generate(4, (j) {
        final y = (20 + i * 5 - j * 2).toDouble();
        return BarChartGroupData(
          x: j,
          barRods: [
            BarChartRodData(
              toY: y,
              color: color,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      });

      // 3. Pie Chart Sections (Category Breakdown)
      final pieValues = [25.0 + i, 35.0 - i, 40.0];
      final pieSections = [
        PieChartSectionData(
          color: color.withOpacity(0.8),
          value: pieValues[0],
          title: 'Veg',
          radius: 40,
          titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        PieChartSectionData(
          color: color.withOpacity(0.6),
          value: pieValues[1],
          title: 'Non-Veg',
          radius: 40,
          titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        PieChartSectionData(
          color: color.withOpacity(0.4),
          value: pieValues[2],
          title: 'Drinks',
          radius: 40,
          titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];

      dataList.add(SalesData(
        name: names[i],
        spots: spots,
        barGroups: barGroups,
        pieSections: pieSections,
        totalValue: totalValue,
        color: color,
      ));
    }
    return dataList;
  }
}

// --- Main Reports Page Widget ---

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyData = SalesData.generateDummyData();

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Header and Title
          SliverAppBar(
            title: Text(
              'Food Admin Reports',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            backgroundColor: primaryAppColor,
            foregroundColor: Colors.white,
            floating: true,
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Performance Overview (Name Wise)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              centerTitle: false,
            ),
          ),

          // 2. Chart Grid View
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 500.0, // Max width of each chart card
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 1.25, // Aspect ratio (width/height)
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final data = dummyData[index];
                  // Alternate between chart types for visual variety
                  if (index % 3 == 0) {
                    return _buildChartCard(
                      title: '${data.name}\'s Monthly Sales',
                      subtitle: 'Total Value: ₹${data.totalValue.toStringAsFixed(0)}',
                      chart: _buildLineChart(data),
                      color: data.color,
                    );
                  } else if (index % 3 == 1) {
                    return _buildChartCard(
                      title: '${data.name}\'s Weekly Orders',
                      subtitle: 'Last 4 Weeks Performance',
                      chart: _buildBarChart(data),
                      color: data.color,
                    );
                  } else {
                    return _buildChartCard(
                      title: '${data.name}\'s Category Share',
                      subtitle: 'Food Item Breakdown',
                      chart: _buildPieChart(data),
                      color: data.color,
                    );
                  }
                },
                childCount: dummyData.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Chart Card Wrapper ---

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget chart,
    required Color color,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Subtitle
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: secondaryDarkColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            // Chart Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0),
                child: chart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Line Chart (Monthly Sales) ---

  Widget _buildLineChart(SalesData data) {
    // Moved to final to resolve const_map_key_not_primitive_equality error
    final labels = { 1.0: 'Jan', 2.0: 'Feb', 3.0: 'Mar', 4.0: 'Apr', 5.0: 'May', 6.0: 'Jun' };

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: 6,
        minY: 0,
        maxY: data.spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2,
        titlesData: FlTitlesData(
          show: true,
          // Removed 'showTotalValue: false' to fix undefined_named_parameter error
          rightTitles: const AxisTitles(sideTitles: SideTitles()),
          topTitles: const AxisTitles(sideTitles: SideTitles()),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                // Simplified month labels
                final text = labels[value] ?? '';
                return SideTitleWidget(meta: meta, child: Text(text, style: GoogleFonts.inter(fontSize: 10)));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value.toInt() % 50 != 0) return const SizedBox();
                return Text('₹${value.toInt()}', style: GoogleFonts.inter(fontSize: 10));
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.spots,
            isCurved: true,
            color: data.color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: data.color, strokeWidth: 1, strokeColor: Colors.white)),
            belowBarData: BarAreaData(
              show: true,
              color: data.color.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Bar Chart (Weekly Orders) ---

  Widget _buildBarChart(SalesData data) {
    // Moved to final to resolve const_map_key_not_primitive_equality error
    final labels = { 0.0: 'Wk 1', 1.0: 'Wk 2', 2.0: 'Wk 3', 3.0: 'Wk 4' };

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 30, // Fixed max Y for better comparison
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          // Removed 'showTotalValue: false' to fix undefined_named_parameter error
          rightTitles: const AxisTitles(sideTitles: SideTitles()),
          topTitles: const AxisTitles(sideTitles: SideTitles()),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final text = labels[value] ?? '';
                return SideTitleWidget(meta: meta, child: Text(text, style: GoogleFonts.inter(fontSize: 10)));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value.toInt() % 10 != 0) return const SizedBox();
                return Text('${value.toInt()}', style: GoogleFonts.inter(fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 10, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
        barGroups: data.barGroups,
      ),
    );
  }

  // --- 3. Pie Chart (Category Share) ---

  Widget _buildPieChart(SalesData data) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PieChart(
            PieChartData(
              sections: data.pieSections,
              centerSpaceRadius: 45,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.pieSections.map((section) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: section.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${section.title} (${section.value.toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(fontSize: 12, color: secondaryDarkColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
