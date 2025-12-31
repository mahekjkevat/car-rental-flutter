import 'package:car_rental_admin/all_reviews_page.dart';
import 'package:car_rental_admin/review_data_model.dart';
import 'package:car_rental_admin/utils/custom_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rxdart/rxdart.dart';

class CarDetailsPage extends StatefulWidget {
  final Map<String, dynamic> carData;

  const CarDetailsPage({super.key, required this.carData});

  @override
  _CarDetailsPageState createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  int _currentImageIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final carName = widget.carData['car_name'] ?? 'Unknown';
    print('Car Name: $carName');
    final carBrand = widget.carData['car_brand'] ?? 'Unknown';
    final chassisNo = widget.carData['chassis_no'] ?? 'Not provided';
    final engineNo = widget.carData['engine_no'] ?? 'Not provided';
    final features =
        [
          widget.carData['features1'] ?? '',
          widget.carData['features2'] ?? '',
          widget.carData['features3'] ?? '',
          widget.carData['features4'] ?? '',
          widget.carData['features5'] ?? '',
          widget.carData['features6'] ?? '',
        ].where((f) => f.isNotEmpty).toList();
    final fuelType = widget.carData['fuel_type'] ?? 'Not provided';
    final maxPrice = widget.carData['max_price']?.toString() ?? 'Not provided';
    final noOfSeats =
        widget.carData['no_of_seats']?.toString() ?? 'Not provided';
    final plusPrice =
        widget.carData['plus_price']?.toString() ?? 'Not provided';
    final basicPrice =
        widget.carData['basic_price']?.toString() ?? 'Not provided';
    final randomID = widget.carData['randomID'] ?? 'Not provided';

    final images =
        [
              widget.carData['car_image1'] as String?,
              widget.carData['car_image2'] as String?,
              widget.carData['car_image3'] as String?,
              widget.carData['car_image4'] as String?,
            ]
            .where((image) => image != null && image.isNotEmpty)
            .cast<String>()
            .toList();

    Stream<List<Review>> fetchReviewsByCarId(String carId) {
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          carName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Colors.yellow.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background with gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/car.png',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Container(color: Colors.black),
                ),
              ),
            ),
          ),
          // Foreground content
          _isLoading
              ? _buildLoadingOverlay()
              : AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    // Image Slider
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.95),
                            Colors.black.withOpacity(0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AnimatedScale(
                            scale: _isLoading ? 0.9 : 1.0,
                            duration: const Duration(milliseconds: 400),
                            child: Stack(
                              children: [
                                CarouselSlider(
                                  options: CarouselOptions(
                                    height: 300.0,
                                    autoPlay: images.length > 1,
                                    enlargeCenterPage: true,
                                    viewportFraction: 0.85,
                                    enableInfiniteScroll: images.length > 1,
                                    onPageChanged: (index, reason) {
                                      setState(
                                        () => _currentImageIndex = index,
                                      );
                                    },
                                  ),
                                  items:
                                      images.isNotEmpty
                                          ? images.take(4).map((image) {
                                            return Builder(
                                              builder: (BuildContext context) {
                                                return AnimatedScale(
                                                  scale:
                                                      _currentImageIndex ==
                                                              images.indexOf(
                                                                image,
                                                              )
                                                          ? 1.0
                                                          : 0.95,
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    child: CachedNetworkImage(
                                                      imageUrl: image,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      fadeInDuration:
                                                          const Duration(
                                                            milliseconds: 300,
                                                          ),
                                                      placeholder:
                                                          (context, url) =>
                                                              _buildShimmerPlaceholder(),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => const Icon(
                                                            Icons
                                                                .directions_car,
                                                            color: Colors.grey,
                                                            size: 140,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }).toList()
                                          : [
                                            Builder(
                                              builder: (BuildContext context) {
                                                return ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Container(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.directions_car,
                                                        color: Colors.grey,
                                                        size: 140,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                ),
                                // Car name overlay
                                Positioned(
                                  bottom: 10,
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.7),
                                          Colors.black.withOpacity(0.5),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$carName',
                                      style: GoogleFonts.poppins(
                                        color: Colors.yellow,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          AnimatedSmoothIndicator(
                            activeIndex: _currentImageIndex,
                            count:
                                images.isNotEmpty
                                    ? images.length.clamp(1, 4)
                                    : 1,
                            effect: const WormEffect(
                              dotColor: Colors.grey,
                              activeDotColor: Colors.yellow,
                              dotHeight: 12,
                              dotWidth: 12,
                              spacing: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable Details
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 25.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "See ALL Reviews" clickable text
                            // Inside your CarDetailsPage class, in the onTap handler for "See ALL Reviews"
                            GestureDetector(
                              onTap: () async {
                                Fluttertoast.showToast(
                                  msg: "Loading Reviews...$carName",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.black87,
                                  textColor: Colors.white,
                                );

                                try {
                                  // Query CarData collection for the document with matching car_name
                                  final querySnapshot =
                                      await FirebaseFirestore.instance
                                          .collection('CarData')
                                          .where('car_name', isEqualTo: carName)
                                          .limit(
                                            1,
                                          ) // assuming car_name is unique, or take the first match
                                          .get();

                                  if (querySnapshot.docs.isEmpty) {
                                    // No car found with that name
                                    Fluttertoast.showToast(
                                      msg: "Car data not found.",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AllReviewsPage(
                                              reviews: [],
                                              noReviews: true,
                                            ),
                                      ),
                                    );
                                    return;
                                  }

                                  final carDocId =
                                      querySnapshot
                                          .docs
                                          .first
                                          .id; // get the document ID

                                  // Check if reviews exist
                                  final reviewsSnapshot =
                                      await FirebaseFirestore.instance
                                          .collection('CarData')
                                          .doc(carDocId)
                                          .collection('Reviews')
                                          .get();

                                  if (reviewsSnapshot.docs.isEmpty) {
                                    // No reviews
                                    Fluttertoast.showToast(
                                      msg: "No reviews found for $carName.",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      backgroundColor: Colors.grey[800],
                                      textColor: Colors.white,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AllReviewsPage(
                                              reviews: [],
                                              noReviews: true,
                                            ),
                                      ),
                                    );
                                  } else {
                                    // Fetch reviews
                                    final reviewsList =
                                        reviewsSnapshot.docs
                                            .map(
                                              (doc) => Review.fromJson(
                                                doc.data()
                                                    as Map<String, dynamic>,
                                              ),
                                            )
                                            .toList();

                                    final reviewsMap =
                                        reviewsList
                                            .map((rev) => rev.toJson())
                                            .toList();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AllReviewsPage(
                                              reviews: reviewsList,
                                              noReviews: false,
                                            ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('Error fetching reviews: $e');
                                  Fluttertoast.showToast(
                                    msg: "Error loading reviews.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                  );
                                }
                              },

                              child: Align(
                                alignment: Alignment.center,
                                child: Text.rich(
                                  TextSpan(
                                    text: 'See ALL Reviews',
                                    style: GoogleFonts.poppins(
                                      color: Colors.yellow,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Colors
                                              .yellow, // Ensures the underline is yellow
                                      decorationThickness:
                                          2, // Optional: for a thicker underline
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Basic Info Card
                            _buildDetailCard(
                              title: 'Basic Information',
                              icon: Icons.directions_car,
                              children: [
                                _buildDetailRow('Name', carName),
                                _buildDetailRow('Brand', carBrand),
                                _buildDetailRow('Fuel Type', fuelType),
                                _buildDetailRow('No. of Seats', noOfSeats),
                              ],
                              delay: 100,
                            ),
                            const SizedBox(height: 25),
                            // Technical Specs Card
                            _buildDetailCard(
                              title: 'Technical Specifications',
                              icon: Icons.build,
                              children: [
                                _buildDetailRow('Chassis No.', chassisNo),
                                _buildDetailRow('Engine No.', engineNo),
                                _buildDetailRow('Random ID', randomID),
                              ],
                              delay: 200,
                            ),
                            const SizedBox(height: 25),
                            // Features Card
                            if (features.isNotEmpty)
                              _buildDetailCard(
                                title: 'Features',
                                icon: Icons.star,
                                children: [
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children:
                                        features
                                            .asMap()
                                            .entries
                                            .map(
                                              (entry) => _buildFeatureChip(
                                                'Feature ${entry.key + 1}',
                                                entry.value,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                                delay: 300,
                              ),
                            const SizedBox(height: 25),
                            // Pricing Card
                            _buildDetailCard(
                              title: 'Pricing',
                              icon: Icons.attach_money,
                              children: [
                                _buildDetailRow('Basic Price', '\₹$basicPrice'),
                                _buildDetailRow('Max Price', '\₹$maxPrice'),
                                _buildDetailRow('Plus Price', '\₹$plusPrice'),
                              ],
                              delay: 400,
                            ),
                            const SizedBox(height: 40),
                            // Back Button
                            Center(
                              child: GradientButton(
                                onPressed: () => Navigator.pop(context),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.arrow_back,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Back',
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required int delay,
  }) {
    return AnimatedOpacity(
      opacity: _isLoading ? 0.0 : 1.0,
      duration: Duration(milliseconds: 600 + delay),
      child: AnimatedScale(
        scale: _isLoading ? 0.95 : 1.0,
        duration: Duration(milliseconds: 600 + delay),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.yellow.withOpacity(0.2),
                Colors.black.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.yellow, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.yellow,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.yellow,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, String value) {
    return Chip(
      label: Text(
        value,
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.yellow.withOpacity(0.8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Stack(
      children: [
        Container(color: Colors.grey[900]),
        AnimatedContainer(
          duration: const Duration(milliseconds: 1500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          onEnd: () => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(25.0),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                strokeWidth: 8.0,
              ),
              const SizedBox(height: 15),
              AnimatedOpacity(
                opacity: _isLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Loading Car Details...',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color> colors;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.colors = const [Colors.yellow, Colors.amber],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          elevation: 8,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.yellow.withOpacity(0.5),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey;
            }
            return null;
          }),
        ),
        child: AnimatedScale(
          scale: onPressed != null ? 1.0 : 0.95,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: onPressed != null ? colors : [Colors.grey, Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
