import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DebugInfoDialog extends StatelessWidget {
  final Map<String, dynamic> debugInfo;

  const DebugInfoDialog({Key? key, required this.debugInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report, color: Colors.blue, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'AI Recommendation Debug Info',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              _buildStatusCard(),
              SizedBox(height: 15),

              _buildDataCard(),
              SizedBox(height: 15),

              _buildPreferencesCard(),
              SizedBox(height: 15),

              _buildCountsCard(),
              SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isTrained = debugInfo['isTrained'] ?? false;
    final userBookings = debugInfo['userBookings'] ?? 0;

    return Card(
      color: isTrained ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isTrained ? Icons.check_circle : Icons.warning,
                  color: isTrained ? Colors.green : Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  isTrained ? '✅ Engine Trained Successfully' : '⚠️ Engine Not Trained',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTrained ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('User Bookings: $userBookings'),
            Text('Training Status: ${isTrained ? "COMPLETED" : "PENDING"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard() {
    final trainingDataSize = debugInfo['trainingDataSize'] ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Training Data', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Training Samples: $trainingDataSize'),
            Text('Data Source: Firebase Firestore'),
            Text('Collections: Users/{uid}/car_booking'),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    final preferences = debugInfo['preferences'] ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 User Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            if (preferences['preferred_brands'] != null)
              Text('Brands: ${preferences['preferred_brands'].join(', ')}'),
            if (preferences['preferred_fuel_types'] != null)
              Text('Fuel: ${preferences['preferred_fuel_types'].join(', ')}'),
            if (preferences['preferred_seats_range'] != null)
              Text('Seats: ${preferences['preferred_seats_range'].join('-')}'),
            if (preferences['preferred_price_range'] != null)
              Text('Price: ₹${preferences['preferred_price_range'][2]?.toStringAsFixed(0) ?? 'N/A'} avg'),
            if (preferences['preferred_car_types'] != null)
              Text('Types: ${preferences['preferred_car_types'].join(', ')}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCountsCard() {
    final counts = debugInfo['counts'] ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📈 Booking Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Total Bookings: ${counts['total_bookings'] ?? 0}'),
            Text('Completed: ${counts['completed_bookings'] ?? 0}'),
            Text('Accepted: ${counts['accepted_bookings'] ?? 0}'),
          ],
        ),
      ),
    );
  }
}