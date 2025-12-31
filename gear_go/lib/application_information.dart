import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'my_files/my_values.dart';

class ApplicationInformationPage extends StatefulWidget {
  const ApplicationInformationPage({super.key});

  @override
  State<ApplicationInformationPage> createState() => _ApplicationInformationPageState();
}

class _ApplicationInformationPageState extends State<ApplicationInformationPage> {
  // Static current app version
  final String currentVersion = MyValues.version; // Change double to String

  @override
  void initState() {
    super.initState();
    // Check for updates when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      print('🔍 ApplicationInformationPage: Checking for updates...');
      print('📱 Current App Version: $currentVersion');

      // Fetch version data from Firestore
      QuerySnapshot versionSnapshot = await FirebaseFirestore.instance
          .collection('VersionUpdate')
          .limit(1)
          .get();

      if (versionSnapshot.docs.isNotEmpty) {
        var versionData = versionSnapshot.docs.first.data() as Map<String, dynamic>;
        String latestVersion = (versionData['version'] ?? 2.1).toString();
        String updateTitle = versionData['title'] ?? 'New Update Available';
        String updateDescription = versionData['description'] ?? 'A new version is available for download.';
        String updateDetails = versionData['update_details'] ?? '';
        String updateLink = versionData['update_link'] ?? '';

        print('📊 Firestore Version: $latestVersion');

        // Check if update is available
        bool isUpdateAvailable = _isUpdateAvailable(currentVersion, latestVersion);
        print('🔄 Update Available: $isUpdateAvailable');

        if (isUpdateAvailable) {
          print('🚨 Showing update dialog from ApplicationInformationPage');
          _showCustomUpdateDialog(
            latestVersion: latestVersion,
            title: updateTitle,
            description: updateDescription,
            updateDetails: updateDetails,
            updateLink: updateLink,
          );
        } else {
          print('✅ Versions match - No update needed');
        }
      } else {
        print('⚠️ No version data found in Firestore');
      }
    } catch (e) {
      print("❌ Error checking for update: $e");
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    print('🔍 Comparing versions: Current=$current, Latest=$latest');

    // Simple version comparison
    List<String> currentParts = current.split('.');
    List<String> latestParts = latest.split('.');

    for (int i = 0; i < latestParts.length; i++) {
      int currentNum = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      int latestNum = int.tryParse(latestParts[i]) ?? 0;

      print('  Part $i: Current=$currentNum, Latest=$latestNum');

      if (latestNum > currentNum) {
        print('  ➡️ Update needed: Latest part $latestNum > Current part $currentNum');
        return true;
      } else if (latestNum < currentNum) {
        print('  ⬅️ No update: Latest part $latestNum < Current part $currentNum');
        return false;
      }
    }

    print('  ✅ Versions are equal');
    return false;
  }

  void _showCustomUpdateDialog({
    required String latestVersion,
    required String title,
    required String description,
    required String updateDetails,
    required String updateLink,
  }) {
    // Parse escape sequences and split by actual newlines
    String parsedDetails = updateDetails.replaceAll(r'\n', '\n');
    List<String> features = parsedDetails.split('\n').where((line) => line.trim().isNotEmpty).toList();

    showDialog(
      context: context,
      barrierDismissible: false, // User must take action
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(
                Icons.system_update_alt,
                color: Colors.blue[700],
                size: 50,
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'New Features and Improvements:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 120, // Fixed height for scrollable content
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: features.map((feature) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature.trim(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Version:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currentVersion,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Version:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        latestVersion,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Exit App Button
            TextButton(
              onPressed: () {
                print('🚪 User chose to exit app');
                // Exit the app
                SystemNavigator.pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Exit App',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Update Button
            ElevatedButton(
              onPressed: () {
                print('🔄 User chose to update app');
                // Launch the update link
                if (updateLink.isNotEmpty && updateLink != 'this is a LINK') {
                  _launchUpdateLink(updateLink);
                } else {
                  print('❌ No valid update link provided');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Update link not available'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Update Now',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUpdateLink(String url) async {
    try {
      print('🌐 Launching update URL: $url');
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        print('❌ Could not launch URL: $url');
        // If Play Store link doesn't work, try with market://
        if (url.contains('play.google.com')) {
          String marketUrl = url.replaceFirst(
            'https://play.google.com/store/apps/details?id=',
            'market://details?id=',
          );
          print('🔄 Trying market URL: $marketUrl');
          if (await canLaunchUrl(Uri.parse(marketUrl))) {
            await launchUrl(Uri.parse(marketUrl));
          } else {
            throw 'Could not launch market URL';
          }
        } else {
          throw 'Could not launch URL';
        }
      }
    } catch (e) {
      print("❌ Error launching URL: $e");
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch update link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Information',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('VersionUpdate')
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue[700],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading app information',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildDefaultContent();
          }

          var versionData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          return _buildContentWithData(versionData);
        },
      ),
    );
  }

  Widget _buildContentWithData(Map<String, dynamic> versionData) {
    String version = (versionData['version'] ?? 2.1).toString();
    String updateTitle = versionData['title'] ?? 'Gear Go';
    String updateDescription = versionData['description'] ?? 'Car Rental Application';
    String updateDetails = versionData['update_details'] ?? '';
    String updateLink = versionData['update_link'] ?? '';
    Timestamp? updateDate = versionData['update_date'] as Timestamp?;

    // Parse features from update_details
    String parsedDetails = updateDetails.replaceAll(r'\n', '\n');
    List<String> features = parsedDetails.split('\n').where((line) => line.trim().isNotEmpty).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Header Card
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    updateTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    updateDescription,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Version $currentVersion', // Show static current version
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_isUpdateAvailable(currentVersion, version))
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.update, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Update Available: $version',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // App Description
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: Colors.blue[700], size: 24),
                      SizedBox(width: 12),
                      Text(
                        'About Gear Go',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gear Go is a comprehensive car rental application that provides users with a seamless experience for renting vehicles. Our platform connects car owners with potential renters, making car rental easy, secure, and convenient.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Features from Firestore
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.blue[700], size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Latest Features',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (features.isNotEmpty && features[0].isNotEmpty)
                    ...features.map((feature) => _buildFeatureItem(feature.trim())).toList()
                  else
                    Column(
                      children: [
                        _buildFeatureItem('No features available in this update'),
                      ],
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Update Information
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.update, color: Colors.blue[700], size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Update Information',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: Colors.green),
                    title: Text(
                      'Last Updated',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      updateDate != null
                          ? _formatTimestamp(updateDate)
                          : 'September 28, 2025 at 4:27:57 PM UTC+5:30',
                    ),
                  ),
                  if (updateLink.isNotEmpty && updateLink != 'this is a LINK')
                    ListTile(
                      leading: Icon(Icons.link, color: Colors.blue),
                      title: Text(
                        'Update Link',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text('Tap to open update'),
                      onTap: () => _launchURL(updateLink),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Contact & Support
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.contact_support, color: Colors.blue[700], size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Contact & Support',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildContactItem(
                    'Email',
                    'mahekjkevat@gmail.com',
                    Icons.email,
                    onTap: () => _launchURL('mailto:mahekjkevat@gmail.com'),
                  ),
                  _buildContactItem(
                    'GitHub',
                    'github.com/MAHEKKEVAT',
                    Icons.code,
                    onTap: () => _launchURL('https://github.com/MAHEKKEVAT/car_rental_flutter_app.git'),
                  ),
                  _buildContactItem(
                    'Phone',
                    '+91 95378 03676',
                    Icons.phone,
                    onTap: () => _launchURL('tel:+919537803676'),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Header Card
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gear Go',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Car Rental Application',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Version $currentVersion',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Default features when no data is available
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.blue[700], size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Features and Functionality',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildFeatureItem('Easy Car Booking - Book your favorite car in just few taps'),
                  _buildFeatureItem('Secure Payments - Multiple secure payment options available'),
                  _buildFeatureItem('Real-time Tracking - Track your rental status in real-time'),
                  _buildFeatureItem('24/7 Support - Round the clock customer support'),
                  _buildFeatureItem('Wide Vehicle Selection - Choose from various car categories'),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Contact & Support
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.contact_support, color: Colors.blue[700], size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Contact & Support',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildContactItem(
                    'Email',
                    'mahekjkevat@gmail.com',
                    Icons.email,
                    onTap: () => _launchURL('mailto:mahekjkevat@gmail.com'),
                  ),
                  _buildContactItem(
                    'GitHub',
                    'github.com/MAHEKKEVAT',
                    Icons.code,
                    onTap: () => _launchURL('https://github.com/MAHEKKEVAT/car_rental_flutter_app.git'),
                  ),
                  _buildContactItem(
                    'Phone',
                    '+91 95378 03676',
                    Icons.phone,
                    onTap: () => _launchURL('tel:+919537803676'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String featureText) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              featureText,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String type, String value, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[600]),
      title: Text(
        type,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(value),
      onTap: onTap,
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}