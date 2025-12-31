import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gear_go/machine_learning/recommendation_utils.dart';

class DebugInfoPage extends StatefulWidget {
  const DebugInfoPage({Key? key}) : super(key: key);

  @override
  _DebugInfoPageState createState() => _DebugInfoPageState();
}

class _DebugInfoPageState extends State<DebugInfoPage> {
  Map<String, dynamic> _debugInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    final info = await RecommendationUtils.getEngineStatus();
    setState(() {
      _debugInfo = info;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Recommendation Analysis',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDebugInfo,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(),
            SizedBox(height: 20),
            _buildEngineStatusCard(),
            SizedBox(height: 16),
            _buildTrainingDataCard(),
            SizedBox(height: 16),
            _buildUserPreferencesCard(),
            SizedBox(height: 16),
            _buildBookingStatisticsCard(),
            SizedBox(height: 16),
            _buildAlgorithmDetailsCard(),
            SizedBox(height: 16),
            _buildRecommendationSummaryCard(),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Analyzing Engine Data...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gathering insights from your booking history',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[600]!, Colors.purple[600]!],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.psychology, size: 50, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Recommendation Engine',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Real-time Machine Learning Analysis',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineStatusCard() {
    final isTrained = _debugInfo['isTrained'] ?? false;
    final userBookings = _debugInfo['userBookings'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isTrained ? Colors.green[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTrained ? Colors.green[200]! : Colors.orange[200]!,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isTrained ? Colors.green[100] : Colors.orange[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTrained ? Icons.check_circle : Icons.schedule,
                    color: isTrained ? Colors.green[600] : Colors.orange[600],
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Engine Status',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('Training Status',
                isTrained ? 'TRAINED SUCCESSFULLY' : 'PENDING TRAINING',
                isTrained ? Colors.green[600]! : Colors.orange[600]!),
            _buildInfoRow('User Bookings', '$userBookings bookings', Colors.blue[600]!),
            _buildInfoRow('Data Source', 'Firebase Firestore', Colors.purple[600]!),
            if (isTrained) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.green[600], size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ready to provide personalized recommendations!',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingDataCard() {
    final trainingDataSize = _debugInfo['trainingDataSize'] ?? 0;
    final userBookings = _debugInfo['userBookings'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[200]!, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.data_usage, color: Colors.blue[600], size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  'Training Data',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildProgressIndicator('Data Collection', trainingDataSize, userBookings),
            SizedBox(height: 12),
            _buildInfoRow('Training Samples', '$trainingDataSize samples', Colors.blue[600]!),
            _buildInfoRow('Data Quality', trainingDataSize >= 3 ? 'Good' : 'Limited',
                trainingDataSize >= 3 ? Colors.green[600]! : Colors.orange[600]!),
            _buildInfoRow('Collection', 'Users/{uid}/car_booking', Colors.purple[600]!),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPreferencesCard() {
    final preferences = _debugInfo['preferences'] ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple[200]!, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.thumb_up, color: Colors.purple[600], size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  'User Preferences',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (preferences['preferred_brands'] != null && preferences['preferred_brands'].isNotEmpty)
              _buildPreferenceItem('🚗 Brands', preferences['preferred_brands'].join(', ')),

            if (preferences['preferred_fuel_types'] != null && preferences['preferred_fuel_types'].isNotEmpty)
              _buildPreferenceItem('⛽ Fuel Types', preferences['preferred_fuel_types'].join(', ')),

            if (preferences['preferred_seats_range'] != null)
              _buildPreferenceItem('👥 Seats Range', '${preferences['preferred_seats_range'][0]}-${preferences['preferred_seats_range'][1]} seats'),

            if (preferences['preferred_price_range'] != null)
              _buildPreferenceItem('💰 Price Range', '₹${preferences['preferred_price_range'][0]?.toStringAsFixed(0)}-₹${preferences['preferred_price_range'][1]?.toStringAsFixed(0)}'),

            if (preferences['preferred_car_types'] != null && preferences['preferred_car_types'].isNotEmpty)
              _buildPreferenceItem('🎯 Car Types', preferences['preferred_car_types'].join(', ')),

            if (preferences['avg_booking_price'] != null)
              _buildPreferenceItem('📊 Avg Booking', '₹${preferences['avg_booking_price']?.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingStatisticsCard() {
    final counts = _debugInfo['counts'] ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange[200]!, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bar_chart, color: Colors.orange[600], size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  'Booking Statistics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    counts['total_bookings']?.toString() ?? '0',
                    Colors.blue[600]!,
                    Icons.list_alt,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    counts['completed_bookings']?.toString() ?? '0',
                    Colors.green[600]!,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Accepted',
                    counts['accepted_bookings']?.toString() ?? '0',
                    Colors.orange[600]!,
                    Icons.thumb_up,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Success Rate',
                    counts['total_bookings'] != null && counts['total_bookings'] > 0
                        ? '${((counts['completed_bookings'] ?? 0) / counts['total_bookings'] * 100).toStringAsFixed(0)}%'
                        : '0%',
                    Colors.purple[600]!,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgorithmDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal[200]!, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.science, color: Colors.teal[600], size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  'Algorithm Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            _buildTechItem('🤖 Algorithm', 'Support Vector Machine'),
            _buildTechItem('📊 Features', 'Brand, Fuel, Seats, Price, Type'),
            _buildTechItem('⚖️ Weights', 'Dynamic preference-based scoring'),
            _buildTechItem('🎯 Accuracy', 'Improves with more bookings'),
            _buildTechItem('🔄 Training', 'Real-time from booking history'),

            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'The SVM algorithm analyzes your booking patterns to predict cars you\'ll love!',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.teal[800],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSummaryCard() {
    final isTrained = _debugInfo['isTrained'] ?? false;
    final trainingDataSize = _debugInfo['trainingDataSize'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo[50]!, Colors.deepPurple[50]!],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.indigo[200]!, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.summarize, color: Colors.indigo[600], size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  'Recommendation Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (isTrained && trainingDataSize >= 3) ...[
              _buildSummaryItem('✅', 'Engine Status', 'Fully Operational'),
              _buildSummaryItem('📈', 'Data Quality', 'Excellent for predictions'),
              _buildSummaryItem('🎯', 'Personalization', 'Highly Tailored'),
              _buildSummaryItem('🚀', 'Ready for', 'Smart Recommendations'),

              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '🌟 Excellent! Your SVM engine is fully trained and ready to provide personalized car recommendations based on your booking history.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.indigo[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isTrained) ...[
              _buildSummaryItem('⚠️', 'Engine Status', 'Basic Training Complete'),
              _buildSummaryItem('📊', 'Data Quality', 'Needs more bookings'),
              _buildSummaryItem('🎯', 'Personalization', 'Moderate'),
              _buildSummaryItem('💡', 'Suggestion', 'Book more cars for better accuracy'),
            ] else ...[
              _buildSummaryItem('❌', 'Engine Status', 'Not Trained'),
              _buildSummaryItem('📊', 'Data Quality', 'Insufficient data'),
              _buildSummaryItem('🎯', 'Personalization', 'Not available'),
              _buildSummaryItem('💡', 'Suggestion', 'Complete your first booking'),
            ],
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, int current, int total) {
    final percentage = total > 0 ? (current / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$current/$total',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.blue[100],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          borderRadius: BorderRadius.circular(10),
          minHeight: 8,
        ),
        SizedBox(height: 4),
        Text(
          '${(percentage * 100).toStringAsFixed(0)}% complete',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(String icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(String icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 16)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String emoji, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.indigo[600],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}