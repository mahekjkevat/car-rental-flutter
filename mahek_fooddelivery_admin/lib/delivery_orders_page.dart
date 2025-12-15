import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Mock Data Structures ---

enum DriverStatus { onDuty, offDuty, delivering }

class Driver {
  final String id;
  final String name;
  final DriverStatus status;
  final int activeOrders;

  Driver({
    required this.id,
    required this.name,
    required this.status,
    required this.activeOrders,
  });
}

class DeliveryOrder {
  final String orderId;
  final String address;
  final String assignedDriverId; // Links to Driver.id
  final double distance;
  final String customerName;

  DeliveryOrder({
    required this.orderId,
    required this.address,
    required this.assignedDriverId,
    required this.distance,
    required this.customerName,
  });
}

// --- Main Widget ---

class DeliveryOrdersPage extends StatefulWidget {
  const DeliveryOrdersPage({super.key});

  @override
  State<DeliveryOrdersPage> createState() => _DeliveryOrdersPageState();
}

class _DeliveryOrdersPageState extends State<DeliveryOrdersPage> {
  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightCardColor = const Color(0xFFFFFFFF);

  // Mock Data
  List<Driver> _drivers = [
    Driver(id: 'D001', name: 'Vivek Sharma', status: DriverStatus.delivering, activeOrders: 2),
    Driver(id: 'D002', name: 'Pooja Singh', status: DriverStatus.onDuty, activeOrders: 0),
    Driver(id: 'D003', name: 'Karan Mehra', status: DriverStatus.offDuty, activeOrders: 0),
    Driver(id: 'D004', name: 'Anil Kumar', status: DriverStatus.delivering, activeOrders: 1),
    Driver(id: 'D005', name: 'Ritu Varma', status: DriverStatus.onDuty, activeOrders: 0),
    Driver(id: 'D006', name: 'Sunita D.', status: DriverStatus.onDuty, activeOrders: 0),
    Driver(id: 'D007', name: 'Ganesh T.', status: DriverStatus.offDuty, activeOrders: 0),
  ];

  List<DeliveryOrder> _activeDeliveries = [
    DeliveryOrder(orderId: '#1001', customerName: 'Ritesh Varma', address: 'B-20, Vihar Road, Ahmedabad', assignedDriverId: 'D001', distance: 1.5),
    DeliveryOrder(orderId: '#1004', customerName: 'Priya Sharma', address: '14, Silver Lane, Gandhinagar', assignedDriverId: 'D001', distance: 2.8),
    DeliveryOrder(orderId: '#1008', customerName: 'Mohit Patel', address: 'Plot 45, High Street, Surat', assignedDriverId: 'D004', distance: 0.9),
  ];

  // State to track the currently selected driver for the map view
  Driver? _selectedDriver;

  @override
  void initState() {
    super.initState();
    // Select the first delivering driver by default
    _selectedDriver = _drivers.firstWhere(
          (d) => d.status == DriverStatus.delivering,
      orElse: () => _drivers.firstWhere(
            (d) => d.status == DriverStatus.onDuty,
        orElse: () => _drivers.first,
      ),
    );
  }

  // Helper to map status to UI properties
  (String, Color) _getStatusDisplay(DriverStatus status) {
    switch (status) {
      case DriverStatus.onDuty:
        return ('On Duty', Colors.green.shade600);
      case DriverStatus.offDuty:
        return ('Off Duty', Colors.grey.shade500);
      case DriverStatus.delivering:
        return ('Delivering', primaryAppColor);
    }
  }

  // Find delivery orders for the selected driver
  List<DeliveryOrder> _getOrdersForDriver(String driverId) {
    return _activeDeliveries.where((order) => order.assignedDriverId == driverId).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the screen is large enough for the two-panel view
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 800;

        // The main layout remains the same for responsiveness
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLargeScreen
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Driver List Panel (Left) ---
              SizedBox(
                width: 380, // Slightly wider for better presentation
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Delivery Personnel'),
                      Expanded(child: _buildDriverList()),
                      _buildDriverSummaryBar(), // Summary bar at the bottom
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // --- 2. Map & Summary Panel (Right) ---
              Expanded(
                child: _buildMapAndSummary(),
              ),
            ],
          )
              : SingleChildScrollView(
            child: Column(
              children: [
                // Driver List Panel (for small screens)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Delivery Personnel'),
                      _buildDriverList(),
                      _buildDriverSummaryBar(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Map & Summary Panel (for small screens)
                _buildMapAndSummary(),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI Components ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: secondaryDarkColor,
        ),
      ),
    );
  }

  Widget _buildDriverList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: _drivers.length,
      itemBuilder: (context, index) {
        final driver = _drivers[index];
        final (statusText, statusColor) = _getStatusDisplay(driver.status);
        final isSelected = driver.id == _selectedDriver?.id;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDriver = driver;
            });
          },
          // Custom container for selection look
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryAppColor.withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: primaryAppColor, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                // Driver Avatar/Initials
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor,
                  child: Text(
                    driver.name[0],
                    style: GoogleFonts.poppins(color: lightCardColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),

                // Name, ID, and Orders Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: secondaryDarkColor,
                        ),
                      ),
                      Text(
                        'ID: ${driver.id} • ${driver.activeOrders} Active Orders',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                // Status Indicator (Dot + Text)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverSummaryBar() {
    final onDutyCount = _drivers.where((d) => d.status == DriverStatus.onDuty || d.status == DriverStatus.delivering).length;
    final offDutyCount = _drivers.length - onDutyCount;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: secondaryDarkColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryChip('Total Drivers', _drivers.length, Colors.white),
          _buildSummaryChip('On Duty', onDutyCount, Colors.greenAccent),
          _buildSummaryChip('Off Duty', offDutyCount, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMapAndSummary() {
    if (_selectedDriver == null) {
      return Center(
        child: Text(
          'Select a driver to view their active routes.',
          style: GoogleFonts.poppins(color: Colors.grey.shade500),
        ),
      );
    }

    final driverOrders = _getOrdersForDriver(_selectedDriver!.id);

    return SingleChildScrollView(
      child: Column(
        children: [
          // --- Map Placeholder (Upper Card) ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              height: 350, // Fixed height for map area
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Live Map View\nTracking Route for ${_selectedDriver!.name}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: secondaryDarkColor.withOpacity(0.6), fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Summary of Active Deliveries (Lower Card) ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Active Deliveries (${_selectedDriver!.name})'),
                  if (driverOrders.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'No active deliveries currently assigned.',
                          style: GoogleFonts.poppins(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else
                    ...driverOrders.map((order) => _buildOrderSummaryTile(order)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryTile(DeliveryOrder order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon for visual cue
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Icon(Icons.pin_drop_outlined, color: primaryAppColor, size: 24),
          ),
          const SizedBox(width: 12),

          // Order Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.customerName} (${order.orderId})',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: secondaryDarkColor),
                ),
                const SizedBox(height: 2),
                Text(
                  order.address,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Distance
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              '${order.distance.toStringAsFixed(1)} km',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: primaryAppColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
