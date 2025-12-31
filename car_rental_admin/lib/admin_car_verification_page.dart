import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_car_detail_page.dart'; // Assuming CarDetailPage is in add_car_detail_page.dart or similar file
import 'package:cached_network_image/cached_network_image.dart'; // Added for better image loading

// --- THEME DEFINITIONS matching AdminDocumentVerificationPage (Black/Yellow theme) ---
const Color _primaryBackgroundColor = Colors.black; // General background
const Color _appBarColor = Colors.black; // AppBar background
const Color _accentColor = Colors.yellow; // Yellow for accents, pending status, buttons
const Color _textColor = Colors.white; // Primary text color
const Color _secondaryTextColor = Colors.grey; // Secondary text color
const Color _successColor = Color(0xFF4CAF50); // Green for Success/Approved status
const Color _rejectColor = Color(0xFFF44336); // Red for Reject status
// -----------------------------------------------------------------------------------

class AdminCarVerificationPage extends StatefulWidget {
  @override
  _AdminCarVerificationPageState createState() => _AdminCarVerificationPageState();
}

class _AdminCarVerificationPageState extends State<AdminCarVerificationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBackgroundColor, // Applied dark theme background
      appBar: AppBar(
        backgroundColor: _appBarColor, // Applied dark theme AppBar color
        elevation: 0,
        title: Text(
          'Car Verification',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _accentColor, // Applied yellow accent to title
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.yellow),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accentColor, // Applied yellow accent to indicator
          labelColor: _accentColor, // Applied yellow accent to selected label
          unselectedLabelColor: _secondaryTextColor, // Applied grey to unselected label
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Verified'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingCars(),
          _buildVerifiedCars(),
          _buildRejectedCars(),
        ],
      ),
    );
  }

  Widget _buildPendingCars() {
    // Note: The collectionGroup query requires composite indexes in Firestore for 'my_cars' and 'status'
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collectionGroup('my_cars')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          // Placeholder for index link printing as per original code comment
          print('\n--- FIRESTORE QUERY ERROR DETECTED ---');
          print('Error Message: ${snapshot.error}');
          print('-------------------------------------------\n');

          return _buildErrorState('Error loading cars: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No pending car requests');
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            // Extract the user ID (assuming the structure /Users/{userId}/my_cars/{carId})
            final userId = doc.reference.parent.parent!.id;

            return _buildCarCard(userId, data, doc.reference);
          },
        );
      },
    );
  }

  Widget _buildVerifiedCars() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collectionGroup('my_cars')
          .where('status', isEqualTo: 'verified')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading cars: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No verified cars');
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.reference.parent.parent!.id;

            return _buildVerifiedCarCard(userId, data);
          },
        );
      },
    );
  }

  Widget _buildRejectedCars() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collectionGroup('my_cars')
          .where('status', isEqualTo: 'rejected')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading cars: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No rejected cars');
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.reference.parent.parent!.id;

            return _buildRejectedCarCard(userId, data);
          },
        );
      },
    );
  }

  Widget _buildCarCard(String userId, Map<String, dynamic> data, DocumentReference docRef) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('Users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildCarCardSkeleton();
        }

        Map<String, dynamic>? userData;
        String userName = 'Unknown User';
        String userEmail = 'N/A';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          userName = userData?['name'] ?? 'Unknown User';
          userEmail = userData?['email'] ?? 'N/A';
        }

        return Card(
          elevation: 8, // Slightly higher elevation for dark theme
          color: Colors.transparent, // Important for showing the container's decoration
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _accentColor.withOpacity(0.2), width: 1.5), // Subtle border
          ),
          margin: EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              // Dark gradient for the card
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.05), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _accentColor, // Yellow circle
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, color: _primaryBackgroundColor, size: 30), // Black icon
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textColor, // White text
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _secondaryTextColor, // Grey text
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _accentColor, // Yellow for PENDING tag
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PENDING',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _primaryBackgroundColor, // Black text on yellow background
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Car Info
                  _buildCarInfo(data),
                  SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _viewCarDetails(userId, data, userData, docRef: docRef),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor, // Yellow button
                            foregroundColor: _primaryBackgroundColor, // Black text
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Review Car',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarInfo(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryBackgroundColor, // Inner container background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withOpacity(0.5)), // Accent border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentColor.withOpacity(0.7)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage( // Using CachedNetworkImage for better performance
                    imageUrl: data['car_image1'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(child: CircularProgressIndicator(color: _accentColor)),
                    errorWidget: (context, url, error) => Container(
                      color: _secondaryTextColor.withOpacity(0.1),
                      child: Icon(Icons.car_repair, color: _secondaryTextColor),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['car_name'] ?? 'Unknown Car',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textColor, // White text
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      data['car_brand'] ?? 'No Brand',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _secondaryTextColor, // Grey text
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '₹${data['basic_price'] ?? '0'}/day',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8BC34A), // Light Green for price
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: _secondaryTextColor.withOpacity(0.3)), // Subtle divider
          SizedBox(height: 8),
          Row(
            children: [
              _buildInfoItem(Icons.location_on, data['village'] ?? 'N/A'),
              SizedBox(width: 16),
              _buildInfoItem(Icons.phone, data['mobile'] ?? 'N/A'),
              SizedBox(width: 16),
              _buildInfoItem(Icons.event_seat, '${data['no_of_seats'] ?? '0'} seats'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _accentColor), // Yellow icon
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _secondaryTextColor, // Grey text
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedCarCard(String userId, Map<String, dynamic> data) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('Users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildCarCardSkeleton();
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'Unknown User';
        // final userEmail = userData?['email'] ?? 'N/A'; // Unused in this card

        return Card(
          elevation: 6,
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _successColor.withOpacity(0.4), width: 1.5),
          ),
          margin: EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              // Dark gradient for the card
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.05), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  // Car Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _successColor.withOpacity(0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: data['car_image1'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator(color: _successColor)),
                        errorWidget: (context, url, error) => Container(
                          color: _secondaryTextColor.withOpacity(0.1),
                          child: Icon(Icons.car_repair, color: _secondaryTextColor),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['car_name'] ?? 'Unknown Car',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textColor, // White text
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _secondaryTextColor, // Grey text
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '₹${data['basic_price'] ?? '0'}/day',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _successColor, // Green text
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Verified on: ${_formatTimestamp(data['verified_at'])}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _secondaryTextColor, // Grey text
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _successColor, // Green for VERIFIED tag
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'VERIFIED',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _primaryBackgroundColor, // Black text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRejectedCarCard(String userId, Map<String, dynamic> data) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('Users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildCarCardSkeleton();
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'Unknown User';

        return Card(
          elevation: 6,
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _rejectColor.withOpacity(0.4), width: 1.5),
          ),
          margin: EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              // Dark gradient for the card
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.05), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _rejectColor.withOpacity(0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: data['car_image1'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator(color: _rejectColor)),
                        errorWidget: (context, url, error) {
                          return Container(
                            color: _secondaryTextColor.withOpacity(0.1),
                            child: Icon(Icons.car_repair, color: _secondaryTextColor),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['car_name'] ?? 'Unknown Car',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textColor, // White text
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _secondaryTextColor, // Grey text
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Rejected: ${data['rejection_reason'] ?? 'No reason provided'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _rejectColor, // Red text
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _rejectColor, // Red for REJECTED tag
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'REJECTED',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _primaryBackgroundColor, // Black text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _viewCarDetails(String userId, Map<String, dynamic> data, Map<String, dynamic>? userData, {DocumentReference? docRef}) {
    // Note: CarDetailPage is expected to be defined in 'add_car_detail_page.dart' or imported elsewhere.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarDetailPage(
          userId: userId,
          userData: userData ?? {},
          carData: data,
          docRef: docRef,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _accentColor), // Yellow loading indicator
          SizedBox(height: 20),
          Text(
            'Loading cars...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _textColor, // White text
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: _rejectColor), // Red error icon
          SizedBox(height: 20),
          Text(
            'Error loading cars',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _rejectColor, // Red text
            ),
          ),
          SizedBox(height: 10),
          Text(
            error,
            style: GoogleFonts.poppins(color: _secondaryTextColor), // Grey text
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.car_repair, size: 60, color: _secondaryTextColor), // Grey icon
          SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _secondaryTextColor, // Grey text
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCardSkeleton() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: _secondaryTextColor.withOpacity(0.3), radius: 25),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: _secondaryTextColor.withOpacity(0.3),
                ),
                SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 14,
                  color: _secondaryTextColor.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
    }
    return 'N/A';
  }
}
