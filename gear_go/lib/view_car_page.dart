import 'package:flutter/material.dart';
import 'package:gear_go/FullScreenImageGallery.dart';
import 'package:gear_go/LeaseAgreementPage.dart';
import 'package:gear_go/car_review_page.dart';
import 'package:gear_go/review_data_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'car_data_model.dart';
import 'location_set_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gear_go/add_update_documents_page.dart';
import 'package:gear_go/view_documents_page.dart';

class ViewCarPage extends StatefulWidget {
  final CarDataModel carData;

  const ViewCarPage({Key? key, required this.carData}) : super(key: key);

  @override
  _ViewCarPageState createState() => _ViewCarPageState();
}

class _ViewCarPageState extends State<ViewCarPage> {
  final PageController _pageController = PageController();
  int currentIndex = 0;
  bool _isImageLoading = false;

  // Add this method to check document verification
  Future<bool> _checkDocumentVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ User not logged in');
      return false;
    }

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .collection('personal_documents')
              .doc('verification_status')
              .get();

      print('📄 Document verification check:');
      print('👤 User ID: ${user.uid}');
      print('📋 Document exists: ${doc.exists}');

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('🔍 Document data: $data');

        bool isVerified = data['verification_status'] == 'approved';
        bool adminApproved = data['admin_approved'] == true;

        print('✅ Verification Status: ${data['verification_status']}');
        print('✅ Admin Approved: ${data['admin_approved']}');
        print('✅ Final Result: ${isVerified && adminApproved}');

        return isVerified && adminApproved;
      } else {
        print('❌ No verification document found');
        return false;
      }
    } catch (e) {
      print('❌ Error checking document verification: $e');
      return false;
    }
  }

  // Add this method to show document required dialog
  void _showDocumentRequiredDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Document Verification Required',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            content: Text(
              'Please complete your document verification and wait for admin approval before booking a car.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('📋 User chose "Later"');
                  Navigator.pop(context);
                },
                child: Text(
                  'Later',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  print('📋 User chose "Verify Now"');
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddUpdateDocumentsPage(),
                    ),
                  );
                },
                child: Text(
                  'Verify Now',
                  style: GoogleFonts.poppins(color: Colors.black,fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        currentIndex = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Matching LocationSetPage
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        // Matching LocationSetPage
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Car Details',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                // Matching LocationSetPage padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageCarousel(),
                    SizedBox(height: 16),
                    _buildCarInfo(),
                    SizedBox(height: 16),
                    FeatureCar(carData: widget.carData),
                  ],
                ),
              ),
            ),
          ),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    List<String> images = [
      widget.carData.carImage1,
      widget.carData.carImage2,
      widget.carData.carImage3,
      widget.carData.carImage4,
    ];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => FullScreenImageGallery(images: images, initialIndex: 0),
          ),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    String imageUrl;
                    switch (index) {
                      case 0:
                        imageUrl = widget.carData.carImage1;
                        break;
                      case 1:
                        imageUrl = widget.carData.carImage2;
                        break;
                      case 2:
                        imageUrl = widget.carData.carImage3;
                        break;
                      case 3:
                        imageUrl = widget.carData.carImage4;
                        break;
                      default:
                        imageUrl = '';
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isImageLoading)
                            LoadingAnimationWidget.dotsTriangle(
                              color: Colors.blue[700]!,
                              size: 50,
                            ),
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (
                              BuildContext context,
                              Widget child,
                              ImageChunkEvent? loadingProgress,
                            ) {
                              if (loadingProgress == null) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted)
                                    setState(() => _isImageLoading = false);
                                });
                                return child;
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted)
                                  setState(() => _isImageLoading = true);
                              });
                              return SizedBox.shrink();
                            },
                            errorBuilder: (context, error, stackTrace) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted)
                                  setState(() => _isImageLoading = false);
                              });
                              return Center(
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              SmoothPageIndicator(
                controller: _pageController,
                count: 4,
                effect: ExpandingDotsEffect(
                  activeDotColor: Colors.blue[700]!,
                  dotHeight: 10,
                  dotWidth: 10,
                  spacing: 8,
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          maxLines: 2,
          widget.carData.carName,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900], // Matching color
          ),
        ),
        Text(
          "Brand : " + widget.carData.carBrand,
          style: GoogleFonts.poppins(fontSize: 19, color: Colors.grey[800]),
        ),
        SizedBox(height: 8),
        Text(
          'This car delivers precision handling and unmatched excitement on the road.',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Info Icon Button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.info_outline, color: Colors.blue[700]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewDocumentsPage()),
                );
              },
            ),
          ),
          SizedBox(width: 12),

          // Expanded NEXT Button
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                print('🚀 NEXT button pressed');
                bool isVerified = await _checkDocumentVerification();
                print('📋 Verification result: $isVerified');

                if (isVerified) {
                  print('✅ Proceeding to LocationSetPage');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => LocationSetPage(
                            documentId: widget.carData.documentId,
                          ),
                    ),
                  );
                } else {
                  print('❌ Document verification required');
                  _showDocumentRequiredDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'NEXT',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCar extends StatefulWidget {
  final CarDataModel carData;

  FeatureCar({Key? key, required this.carData}) : super(key: key);

  @override
  State<FeatureCar> createState() => _FeatureCarState();
}

class _FeatureCarState extends State<FeatureCar> {
  int? _expandedFaqIndex; // Manages which FAQ is expanded

  String _truncateFeature(String feature) {
    const int maxFeatureLength = 15;
    if (feature.length <= maxFeatureLength) return feature;
    return '${feature.substring(0, maxFeatureLength)}...';
  }

  Stream<List<Review>> fetchReviews(String carId) {
    return FirebaseFirestore.instance
        .collection('CarData')
        .doc(carId)
        .collection('Reviews')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Review.fromJson(doc.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    int? _expandedFaqIndex; // Add this line
    return Column(
      children: [
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ratings & Reviews',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900], // Matching color
                  ),
                ),
                SizedBox(height: 12),
                _buildRatingAndReviews(context),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Features',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900], // Matching color
                  ),
                ),
                const SizedBox(height: 10),
                _buildFeatureGrid(context),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAQs',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900], // Matching color
                  ),
                ),
                SizedBox(height: 12),
                FAQsWidget(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Policies and Agreement',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900], // Matching color
                  ),
                ),
                const SizedBox(height: 10),
                PoliciesAgreementWidget(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    List<String> dbFeatures = [
      widget.carData.features1,
      widget.carData.features2,
      widget.carData.features3,
      widget.carData.features4,
      widget.carData.features5,
      widget.carData.features6,
    ];

    List<String> staticFeatures = [
      'Airbags',
      'Reverse Camera',
      'Spare Tyre',
      'Integrated LED Screen',
      'Climate Control',
      'Music System',
    ];

    List<String> allFeatures = dbFeatures + staticFeatures;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue[200]!), // Matching border color
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 4,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: allFeatures.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                right:
                    index % 2 == 0
                        ? BorderSide(color: Colors.blue[200]!)
                        : BorderSide.none,
                bottom:
                    index < allFeatures.length - 2
                        ? BorderSide(color: Colors.blue[200]!)
                        : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 10),
                Icon(Icons.check_circle, color: Colors.blue[700], size: 16),
                // Matching color
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _truncateFeature(allFeatures[index]),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoReviewsWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No Reviews Yet!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to leave a review.',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingAndReviews(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: fetchReviews(widget.carData.documentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error fetching reviews.'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!;
        final reviewCount = reviews.length; // Calculate here

        if (reviews.isEmpty) {
          return _buildNoReviewsWidget();
        }

        // Calculate average rating
        double totalRating = reviews.fold(
          0.0,
          (sum, r) => sum + (r.feedbackRating ?? 0.0),
        );
        double avgRating = totalRating / reviews.length;
        print('Average Rating: $avgRating'); // e.g., 3.5

        // Save to Firestore

        final firestore = FirebaseFirestore.instance;
        firestore.collection('CarData').doc(widget.carData.documentId).update({
          'avg_rating': avgRating,
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAverageRating(avgRating),
            SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: reviews.length,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  return _buildReviewCard(reviews[index]);
                },
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AllReviewsPage(
                            reviewsStream: fetchReviews(
                              widget.carData.documentId,
                            ),
                          ),
                    ),
                  );
                },
                child: Text(
                  'View ALL ($reviewCount) ${reviewCount == 1 ? '' : ''} Reviews ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper to format Timestamp to date string

  Widget _buildAverageRating(double avgRating) {
    // Determine star color based on avgRating
    Color getStarColor(double rating) {
      if (rating <= 1.0) {
        return Colors.red; // For 1.0 or below
      } else if (rating <= 3.0) {
        return Colors.orange; // Between 1.1 and 2.0
      } else {
        return Colors.green; // 3.0 and above
      }
    }

    final starColor = getStarColor(avgRating);

    // Format to 1 decimal place
    double displayRating = double.parse(avgRating.toStringAsFixed(1));
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      shadowColor: Colors.grey[300],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Rating',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            Divider(color: Colors.grey[300], thickness: 1, height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Main rating number
                Text(
                  avgRating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                SizedBox(width: 12),

                // Pass to RatingBarIndicator
                RatingBarIndicator(
                  rating: displayRating,
                  itemBuilder:
                      (context, index) => Icon(Icons.star, color: starColor),
                  itemCount: 5,
                  itemSize: 30.0,
                  direction: Axis.horizontal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final String name = review.userName ?? 'Anonymous';
    final String feedbackLine = review.feedbackLine ?? '';
    final double rating = review.feedbackRating ?? 0.0;
    final DateTime dateTime = review.feedbackTime.toDate();

    String formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        width: 300,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Image.asset(
                  'assets/images/profile.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: 12),
                // Name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Star rating
                RatingBarIndicator(
                  rating: rating,
                  itemBuilder:
                      (context, index) =>
                          Icon(Icons.star, color: Colors.orange),
                  itemCount: 5,
                  itemSize: 20,
                  direction: Axis.horizontal,
                ),
              ],
            ),
            SizedBox(height: 12),
            // Feedback text
            Text(
              feedbackLine,
              style: GoogleFonts.lato(fontSize: 14, color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            // Feedback rating
            Text(
              'Rating: ${rating.toStringAsFixed(1)}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget FAQsWidget() {
    final List<Map<String, String>> faqs = [
      {
        'question': 'How do I book a car?',
        'answer': '''- Simply select the dates and the car of your choice,
- Select the location you want to pick it up from or get it delivered at
- Choose your preferred mode of payment to pay and you are ready to Zoom!''',
      },
      {
        'question': 'What does Fastag enabled mean?',
        'answer': '''FASTag enabled means
- The car will have FAStag installed
- You'll have the option to recharge it if you intend to go through tolls''',
      },
      {
        'question': 'What happens if I return the car with extra fuel?',
        'answer':
            '''We highly recommend returning the car at the same fuel level as it was when you picked it up. Please note that GearGo gives you the freedom to resolve all fuel-related queries directly with the host.''',
      },
      {
        'question': 'Who will recharge the FASTag?',
        'answer':
            '''You will recharge the FASTag as per your usage for the booking. You can reach out to the Host and they'll provide you with the FASTag recharge details.''',
      },
      {
        'question':
            'What happens if I forget my personal belongings in the car?',
        'answer':
            '''GearGo does not take any responsibility for personal belongings left by you in the car.
- Please remove all your personal belongings from the car before ending the trip
- If you end up forgetting any belongings in the car, you may reach out to the host to retrieve it''',
      },
    ];
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _expandedFaqIndex = (_expandedFaqIndex == index) ? null : index;
        });
      },
      children:
          faqs.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, String> faq = entry.value;
            return ExpansionPanel(
              headerBuilder: (context, isExpanded) {
                return ListTile(
                  title: Text(
                    faq['question']!,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
              body: Padding(
                padding: EdgeInsets.all(8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // rounded corners
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      faq['answer']!,
                      style: GoogleFonts.roboto(fontSize: 14),
                    ),
                  ),
                ),
              ),
              isExpanded: _expandedFaqIndex == index,
            );
          }).toList(),
    );
  }
}

Widget PoliciesAgreementWidget() {
  bool agreed = true; // initial value as checked
  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: agreed,
                onChanged: (value) {
                  setState(() {
                    agreed = value!;
                  });
                },
              ),
              Expanded(
                child: Text(
                  'I hereby agree to the terms and conditions of the Lease Agreement with Host',
                  style: TextStyle(color: Colors.black, fontFamily: 'Roboto'),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => LeaseAgreementPage()));
              },
              child: Text(
                'VIEW DETAILS',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
