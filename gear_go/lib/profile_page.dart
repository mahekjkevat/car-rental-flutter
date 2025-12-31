import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gear_go/MyCarRent.dart';
import 'package:gear_go/chat/customer_chat_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n/app_localizations.dart';

import 'EditProfilePage.dart';
import 'FavouritesPage.dart';
import 'HelpPage.dart';
import 'main.dart';
import 'settings_page.dart';
import 'application_information.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:async';

// main.dart or any other Dart file
import 'package:gear_go/my_files/my_values.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userName;
  String? userEmail;
  String? profileImageUrl;
  String? bio;
  bool isLoading = true;
  Timer? _timer;

  // Current app version (static from your code)
  final String currentVersion = MyValues.version; // Change double to String

  // final String currentVersion = '2.1'; // Change double to String

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkForUpdate();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchUserData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
    });
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email;
      try {
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .get();
        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            userName = userDoc.data()!['name'];
            profileImageUrl = userDoc.data()!['profile_image'];
            bio = userDoc.data()!['bio'];
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      print('🔍 Checking for updates...');
      print('📱 Current App Version (from Dart file): $currentVersion');

      // Fetch version data from Firestore
      QuerySnapshot versionSnapshot =
          await FirebaseFirestore.instance
              .collection('VersionUpdate')
              .limit(1)
              .get();

      if (versionSnapshot.docs.isNotEmpty) {
        var versionData =
            versionSnapshot.docs.first.data() as Map<String, dynamic>;

        // Convert the number to string
        String latestVersion = (versionData['version'] ?? 2.1).toString();
        String updateTitle = versionData['title'] ?? 'New Update Available';
        String updateDescription =
            versionData['description'] ??
            'A new version is available for download.';
        String updateDetails = versionData['update_details'] ?? '';
        String updateLink = versionData['update_link'] ?? '';

        print('📊 Firestore Version: $latestVersion');
        print('📝 Update Title: $updateTitle');
        print('📄 Update Description: $updateDescription');
        print('📄 Update Details: $updateDetails');
        print('🔗 Update Link: $updateLink');

        // Check if update is available
        bool isUpdateAvailable = _isUpdateAvailable(
          currentVersion,
          latestVersion,
        );
        print('🔄 Update Available: $isUpdateAvailable');

        if (isUpdateAvailable) {
          print('🚨 Showing update dialog - versions do not match!');
          // Show custom update dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCustomUpdateDialog(
              latestVersion: latestVersion,
              title: updateTitle,
              description: updateDescription,
              updateDetails: updateDetails,
              updateLink: updateLink,
            );
          });
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
      int currentNum =
          i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      int latestNum = int.tryParse(latestParts[i]) ?? 0;

      print('  Part $i: Current=$currentNum, Latest=$latestNum');

      if (latestNum > currentNum) {
        print(
          '  ➡️ Update needed: Latest part $latestNum > Current part $currentNum',
        );
        return true;
      } else if (latestNum < currentNum) {
        print(
          '  ⬅️ No update: Latest part $latestNum < Current part $currentNum',
        );
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
    List<String> features =
        parsedDetails
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();

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
              Icon(Icons.system_update_alt, color: Colors.blue[700], size: 50),
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
                        children:
                            features.map((feature) {
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
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        title: Text(
          localizations.profile,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: Colors.white),
            onSelected: (String value) {
              Locale newLocale;
              switch (value) {
                case 'en':
                  newLocale = Locale('en');
                  break;
                case 'hi':
                  newLocale = Locale('hi');
                  break;
                case 'gu':
                  newLocale = Locale('gu');
                  break;
                default:
                  newLocale = Locale('en');
              }
              MyApp.setLocale(context, newLocale);
            },
            itemBuilder:
                (BuildContext context) => [
                  PopupMenuItem(value: 'en', child: Text('English')),
                  PopupMenuItem(value: 'hi', child: Text('Hindi')),
                  PopupMenuItem(value: 'gu', child: Text('Gujarati')),
                ],
          ),
        ],
      ),
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: isLoading,
            child: AnimatedOpacity(
              opacity: isLoading ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.blue[100],
                                  child: CircleAvatar(
                                    radius: 38,
                                    backgroundImage:
                                        profileImageUrl != null &&
                                                profileImageUrl!.isNotEmpty
                                            ? NetworkImage(profileImageUrl!)
                                            : AssetImage(
                                                  'assets/images/profile_placeholder.png',
                                                )
                                                as ImageProvider,
                                    child:
                                        (profileImageUrl == null ||
                                                profileImageUrl!.isEmpty)
                                            ? Icon(
                                              Icons.person,
                                              color: Colors.blue[800],
                                              size: 40,
                                            )
                                            : null,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName ?? localizations.loading,
                                      style: GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      userEmail ?? localizations.loading,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => EditProfilePage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                localizations.editProfile,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // App Info Card
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.blue[50]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info,
                                color: Colors.blue[700],
                                size: 24,
                              ),
                            ),
                            title: Text(
                              'App Information',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                            subtitle: Text(
                              'Version $currentVersion',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blue[600],
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => ApplicationInformationPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Options List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildOptionTile(
                            context,
                            localizations.favourites,
                            Icons.favorite,
                            FavouritesPage(),
                          ),
                          _buildOptionTile(
                            context,
                            localizations.help,
                            Icons.help,
                            HelpPage(),
                          ),
                          _buildOptionTile(
                            context,
                            localizations.settings,
                            Icons.settings,
                            SettingsPage(),
                          ),
                          _buildOptionTile(
                            context,
                            localizations.my_car,
                            Icons.car_rental,
                            MyCarRent(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Center(
              child: LoadingAnimationWidget.dotsTriangle(
                color: Colors.blue[700]!,
                size: 60,
              ),
            ),
        ],
      ),
      // Add this FloatingActionButton to allow quick access to customer chat.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => CustomerChatPage()),
          );
        },
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_bubble_outline, size: 28),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue[700], size: 24),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.blue[600],
            size: 18,
          ),
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (_) => page));
          },
        ),
      ),
    );
  }
}
