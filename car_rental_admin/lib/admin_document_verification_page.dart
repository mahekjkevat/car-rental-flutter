import 'package:car_rental_admin/user_document_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Added for potential image use in cards

// Define the colors from the HomePageBody for consistent theming
const Color _primaryBackgroundColor = Colors.black;
const Color _appBarColor = Colors.black;
const Color _accentColor = Colors.yellow;
const Color _textColor = Colors.white;
const Color _secondaryTextColor = Colors.grey;

  class AdminDocumentVerificationPage extends StatefulWidget {
  @override
  _AdminDocumentVerificationPageState createState() => _AdminDocumentVerificationPageState();
}

class _AdminDocumentVerificationPageState extends State<AdminDocumentVerificationPage> with SingleTickerProviderStateMixin {
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
      // Updated: Use dark background color from HomePageBody
      backgroundColor: _primaryBackgroundColor,
      appBar: AppBar(
        // Updated: Use dark AppBar color from HomePageBody
        backgroundColor: _appBarColor,
        elevation: 0,
        title: Text(
          'Document Verification',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _accentColor), // Yellow for icons
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          // Updated: Use accent color for indicator
          indicatorColor: _accentColor,
          labelColor: _accentColor,
          unselectedLabelColor: _secondaryTextColor,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 16),
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
          _buildPendingDocuments(),
          _buildVerifiedDocuments(),
          _buildRejectedDocuments(),
        ],
      ),
    );
  }

  // --- Document Stream Builders (Conceptual logic remains the same) ---

  Widget _buildPendingDocuments() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collectionGroup('personal_documents')
          .where('verification_status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading documents: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No pending verification requests');
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.reference.parent.parent!.id;

            // ⭐️ Print Statement retained for debugging
            print('List Index: $index, Firestore Document ID: ${doc.id}');

            return _buildUserVerificationCard(userId, data, doc.reference);
          },
        );
      },
    );
  }

  Widget _buildVerifiedDocuments() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collectionGroup('personal_documents')
          .where('verification_status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading documents: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No verified documents');
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.reference.parent.parent!.id;

            return _buildVerifiedUserCard(userId, data);
          },
        );
      },
    );
  }

  Widget _buildRejectedDocuments() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collectionGroup('personal_documents')
          .where('verification_status', isEqualTo: 'rejected')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading documents: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No rejected documents');
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.reference.parent.parent!.id;

            return _buildRejectedUserCard(userId, data);
          },
        );
      },
    );
  }

  // --- Card Builders (Updated Theme/UI) ---

  Widget _buildUserVerificationCard(String userId, Map<String, dynamic> data, DocumentReference docRef) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('Users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildUserCardSkeleton();
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'Unknown User';
        final userEmail = userData?['email'] ?? 'N/A';

        return _buildUserCard(
          userName: userName,
          userEmail: userEmail,
          data: data,
          onTap: () => _viewUserDocuments(userId, data, userData, docRef: docRef),
          statusColor: Colors.orange, // Pending status
          statusText: 'PENDING',
        );
      },
    );
  }

  Widget _buildVerifiedUserCard(String userId, Map<String, dynamic> data) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('Users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildUserCardSkeleton();
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'Unknown User';
        final userEmail = userData?['email'] ?? 'N/A';

        return _buildUserCard(
          userName: userName,
          userEmail: userEmail,
          data: data,
          onTap: () {}, // No action for verified/rejected cards, as in original logic
          statusColor: Colors.green, // Verified status
          statusText: 'VERIFIED',
          subText: 'Verified on: ${_formatTimestamp(data['admin_verified_at'])}',
        );
      },
    );
  }

  Widget _buildRejectedUserCard(String userId, Map<String, dynamic> data) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('Users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildUserCardSkeleton();
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'Unknown User';
        final userEmail = userData?['email'] ?? 'N/A';

        return _buildUserCard(
          userName: userName,
          userEmail: userEmail,
          data: data,
          onTap: () {}, // No action for verified/rejected cards, as in original logic
          statusColor: Colors.red, // Rejected status
          statusText: 'REJECTED',
          subText: 'Reason: ${data['rejection_reason'] ?? 'No reason provided'}',
        );
      },
    );
  }

  // Refactored Card to use HomePage's dark/semi-transparent UI style
  Widget _buildUserCard({
    required String userName,
    required String userEmail,
    required Map<String, dynamic> data,
    required VoidCallback onTap,
    required Color statusColor,
    required String statusText,
    String? subText,
  }) {
    // Determine if action button is needed (only for PENDING)
    final bool showActionButton = statusText == 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // Matches the semi-transparent dark container style of HomePage
        color: _textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    // Icon color related to status for distinction
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: _primaryBackgroundColor, size: 30),
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
                      if (subText != null) ...[
                        SizedBox(height: 8),
                        Text(
                          subText,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: statusColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: _primaryBackgroundColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Document Summary (Only for Pending to save space on Verified/Rejected)
            if (showActionButton) ...[
              _buildDocumentSummary(data),
              SizedBox(height: 16),
            ],

            // Action Button (Only for PENDING)
            if (showActionButton)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        // Updated: Use yellow accent for the button (like HomePage)
                        backgroundColor: _accentColor,
                        foregroundColor: _primaryBackgroundColor,
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
                            'Review Documents',
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
    );
  }

  // Refactored Document Summary to fit dark theme
  Widget _buildDocumentSummary(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Semi-transparent dark background for nested container
        color: _textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _accentColor,
            ),
          ),
          SizedBox(height: 12),
          _buildDocumentItem('Driver License', data['dl_number']),
          _buildDocumentItem('Aadhar Card', data['aadhar_number']),
          _buildDocumentItem('PAN Card', data['pan_number']),
        ],
      ),
    );
  }

  // Refactored Document Item to fit dark theme
  Widget _buildDocumentItem(String label, String? value) {
    final bool isProvided = value != null;
    final Color itemColor = isProvided ? Colors.greenAccent : _secondaryTextColor;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: itemColor, size: 16),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _secondaryTextColor,
            ),
          ),
          Expanded(
            child: Text(
              isProvided ? '••••${value!.substring(value.length - 4)}' : 'Not provided',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: itemColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Utility Functions (Theme Updated) ---

  void _viewUserDocuments(
      String userId,
      Map<String, dynamic> data,
      Map<String, dynamic>? userData,
      {DocumentReference? docRef}
      ) {
    final userName = userData?['name'] ?? 'Unknown User';
    print('Redirecting to UserDocumentDetailPage for User ID: $userId, Name: $userName');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDocumentDetailPage(
          userId: userId,
          userData: userData ?? {},
          documentData: data,
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
          CircularProgressIndicator(color: _accentColor),
          SizedBox(height: 20),
          Text(
            'Loading documents...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    // Print statement retained for debugging
    print('================================================================');
    print('🚨 FIREBASE ERROR DETECTED: $error');
    print('If this error mentions a missing index, you need to create one manually.');
    print('1. Go to your Firebase Console.');
    print('2. Navigate to "Firestore Database" -> "Indexes".');
    print('3. Create the compound index suggested by the error message.');
    print('================================================================');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          SizedBox(height: 20),
          Text(
            'Error loading documents',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.redAccent,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'A database error occurred. Check the terminal for details.',
            style: GoogleFonts.poppins(color: _secondaryTextColor),
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
          Icon(Icons.description, size: 60, color: _secondaryTextColor.withOpacity(0.5)),
          SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCardSkeleton() {
    // Skeleton matches the semi-transparent dark container style
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

  // Not used in the refactored card but kept for completeness
  final _userNameStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: _textColor,
  );

  final _userEmailStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: _secondaryTextColor,
  );
}