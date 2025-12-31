import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_service.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserProfilePage({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final ChatService _chatService = ChatService();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
    _loadUserData();
  }

  void _loadUserData() async {
    final userData = await _chatService.getUserProfile(widget.userId);
    if (userData != null) {
      setState(() {
        _userData = userData;
      });
    }
  }

  void _viewFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: Icon(Icons.error, color: Colors.white, size: 50),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall() async {
    final phoneNumber = _userData?['mobile_number'];
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final url = 'tel:$phoneNumber';
      if (await canLaunch(url)) {
        await launch(url);
      }
    }
  }

  void _sendEmail() async {
    final email = _userData?['email'];
    if (email != null && email.isNotEmpty) {
      final url = 'mailto:$email';
      if (await canLaunch(url)) {
        await launch(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = _userData?['profile_image'];
    final name = _userData?['name'] ?? 'Unknown User';
    final email = _userData?['email'] ?? 'No email';
    final phone = _userData?['mobile_number'] ?? 'No phone';
    final bio = _userData?['bio'] ?? 'No bio available';
    final city = _userData?['city'] ?? 'Not specified';
    final country = _userData?['country'] ?? 'Not specified';
    final state = _userData?['state'] ?? 'Not specified';
    final pinCode = _userData?['pin_code'] ?? 'Not specified';
    final licenseNo = _userData?['license_no'] ?? 'Not specified';
    final paymentMethod = _userData?['payment_method'] ?? 'Not specified';
    final dateCreated = _userData?['dateCreated'];
    final dateUpdated = _userData?['dateUpdated'];

    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.yellow),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Profile',
          style: GoogleFonts.poppins(
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Image Section
            GestureDetector(
              onTap: profileImage != null && profileImage.isNotEmpty
                  ? () => _viewFullScreenImage(profileImage)
                  : null,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellow, width: 3),
                ),
                child: ClipOval(
                  child: profileImage != null && profileImage.isNotEmpty
                      ? Image.network(
                    profileImage,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.person, color: Colors.yellow, size: 50),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey[800],
                    child: Icon(Icons.person, color: Colors.yellow, size: 50),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Name
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),

            // Email
            GestureDetector(
              onTap: _sendEmail,
              child: Text(
                email,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.yellow,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Contact Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _makePhoneCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: Icon(Icons.phone),
                  label: Text('Call'),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _sendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: Icon(Icons.email),
                  label: Text('Email'),
                ),
              ],
            ),
            SizedBox(height: 30),

            // User Details Card
            Card(
              color: Color(0xFF1E1E1E),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.yellow.withOpacity(0.3)),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bio
                    _buildDetailItem('Bio', bio, Icons.info),
                    _buildDivider(),

                    // Location Details
                    _buildDetailItem('City', city, Icons.location_city),
                    _buildDivider(),
                    _buildDetailItem('State', state, Icons.map),
                    _buildDivider(),
                    _buildDetailItem('Country', country, Icons.public),
                    _buildDivider(),
                    _buildDetailItem('PIN Code', pinCode, Icons.pin_drop),
                    _buildDivider(),

                    // License
                    _buildDetailItem('License No', licenseNo, Icons.card_membership),
                    _buildDivider(),

                    // Payment Method
                    _buildDetailItem('Payment Method', paymentMethod, Icons.payment),
                    _buildDivider(),

                    // Phone
                    _buildDetailItem('Phone', phone, Icons.phone),
                    _buildDivider(),

                    // Dates
                    if (dateCreated != null)
                      _buildDetailItem(
                        'Member Since',
                        DateFormat('MMM dd, yyyy').format((dateCreated as Timestamp).toDate()),
                        Icons.calendar_today,
                      ),

                    if (dateUpdated != null) ...[
                      _buildDivider(),
                      _buildDetailItem(
                        'Last Updated',
                        DateFormat('MMM dd, yyyy - hh:mm a').format((dateUpdated as Timestamp).toDate()),
                        Icons.update,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.yellow, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[700],
      height: 20,
      thickness: 0.5,
    );
  }
}