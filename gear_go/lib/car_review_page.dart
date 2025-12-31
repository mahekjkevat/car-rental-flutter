import 'package:flutter/material.dart';
import 'package:gear_go/review_data_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class AllReviewsPage extends StatelessWidget {
  final Stream<List<Review>> reviewsStream;

  const AllReviewsPage({Key? key, required this.reviewsStream}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Reviews',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        iconTheme: IconThemeData(color: Colors.white), // Back icon color
        // Optional: set the text style for the entire AppBar
        toolbarTextStyle: TextStyle(color: Colors.white),
      ),
      body: StreamBuilder<List<Review>>(
        stream: reviewsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading reviews.'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data!;
          if (reviews.isEmpty) {
            return Center(child: Text('No reviews yet.'));
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              final name = review.userName ?? 'Anonymous';
              final feedback = review.feedbackLine ?? '';
              final rating = review.feedbackRating ?? 0.0;
              final date = review.feedbackTime.toDate();
              final formattedDate = '${date.day}/${date.month}/${date.year}';

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4, // Add shadow effect
                shadowColor: Colors.black38,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage('assets/images/profile.png'),
                            radius: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(formattedDate, style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey[600]!)),
                              ],
                            ),
                          ),
                          RatingBarIndicator(
                            rating: rating,
                            itemBuilder: (context, index) => Icon(Icons.star, color: Colors.orange),
                            itemCount: 5,
                            itemSize: 20,
                            direction: Axis.horizontal,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        feedback,
                        style: GoogleFonts.lato(fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Text('Rating: ${rating.toStringAsFixed(1)}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]!)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}