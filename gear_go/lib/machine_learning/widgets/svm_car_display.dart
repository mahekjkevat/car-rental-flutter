import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:card_loading/card_loading.dart';
import '../../car_data_model.dart';
import '../car_recommendation_model.dart';
import '../recommendation_utils.dart';
import 'svm_car_card.dart';

class SVMCarDisplay extends StatefulWidget {
  final List<CarDataModel> allCars;
  final Function(CarDataModel) onCarTap;
  final Function(CarDataModel) onFavoriteToggle;
  final Set<String> favoriteCarIds;

  const SVMCarDisplay({
    Key? key,
    required this.allCars,
    required this.onCarTap,
    required this.onFavoriteToggle,
    required this.favoriteCarIds,
  }) : super(key: key);

  @override
  _SVMCarDisplayState createState() => _SVMCarDisplayState();
}

class _SVMCarDisplayState extends State<SVMCarDisplay> {
  late Future<List<CarRecommendation>> _recommendationsFuture;
  int _bookingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadBookingCount();
  }

  void _loadRecommendations() {
    print('🔄 CarDisplay: Loading recommendations...');
    setState(() {
      _recommendationsFuture = RecommendationUtils.getPersonalizedRecommendations(limit: 6);
    });
  }

  void _loadBookingCount() async {
    final bookings = await RecommendationUtils.getUserBookingHistory();
    setState(() {
      _bookingCount = bookings.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with explanation
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue[700], size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Recommended For You',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: _loadRecommendations,
                    icon: Icon(Icons.refresh, color: Colors.blue[700], size: 28),
                    tooltip: 'Refresh recommendations',
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                RecommendationUtils.getRecommendationExplanation(_bookingCount),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (_bookingCount > 0) ...[
                SizedBox(height: 4),
                Text(
                  'Based on $_bookingCount booking${_bookingCount == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Recommendations list
        Expanded(
          child: FutureBuilder<List<CarRecommendation>>(
            future: _recommendationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingSkeleton();
              }

              if (snapshot.hasError) {
                print('❌ CarDisplay: Error in FutureBuilder: ${snapshot.error}');
                return _buildErrorWidget(snapshot.error.toString());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyWidget();
              }

              final recommendations = snapshot.data!;
              return _buildRecommendationsList(recommendations);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (_, index) => CardLoading(
        height: 200,
        width: double.infinity,
        borderRadius: BorderRadius.circular(16),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 12),
          Text(
            'Unable to load recommendations',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Error: $error',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_motion, color: Colors.blue, size: 48),
          SizedBox(height: 12),
          Text(
            'No personalized recommendations yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Complete a few car bookings to get -powered recommendations tailored to your preferences.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          if (_bookingCount == 0)
            Text(
              '💡 Tip: Book cars you like to help the learn your preferences!',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList(List<CarRecommendation> recommendations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        final isFavorite = widget.favoriteCarIds.contains(
          recommendation.car.documentId,
        );

        return SVMCarCard(
          recommendation: recommendation,
          onTap: () => widget.onCarTap(recommendation.car),
          onFavoriteToggle: () => widget.onFavoriteToggle(recommendation.car),
          isFavorite: isFavorite,
        );
      },
    );
  }
}