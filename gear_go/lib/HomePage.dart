import 'package:flutter/material.dart';
import 'package:gear_go/happiness.dart';
import 'package:gear_go/machine_learning/pages/recommended_cars_page.dart';
import 'package:gear_go/notification_page.dart';
import 'package:gear_go/profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'ChoosePage.dart';
import 'MyRentalRecords.dart';
import 'add_car_page.dart';
import 'home_page_body.dart';
import 'app_info_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userName;
  String? userImage;
  String? userEmail;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    CarListPage(selectedIndex: 0, pages: []),
    MyRentalRecords(),
    RecommendedCarsPage(),
    NotificationPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Add this stream to get unread notification count
  Stream<int> _getUnreadNotificationCount() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Notification')
        .where('status', isNotEqualTo: 'read')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }



  Future<void> _fetchInitialUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          userName = userDoc.data()!['name'];
          userEmail = user.email;
          userImage = userDoc.data()!['profile_image'];
        });
      } else {
        setState(() {
          userName = "User";
          userEmail = "Email not available";
          userImage = null;
        });
      }
    } else {
      setState(() {
        userName = "Guest";
        userEmail = "Email not available";
        userImage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool? shouldExit = await showDialog(
          context: context,
          builder: (context) => ExitConfirmationDialog(),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue[800]!.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              // App Logo with Large Prominent "1st" Badge
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HappinessCelebrationPage()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main App Logo
                      Container(
                        width: 35,
                        height: 35,
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Large "1st" Badge - Prominent and Visible
                      Positioned(
                        top: -15,  // Positioned higher to make it more visible
                        right: -15, // Positioned further right
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber[600]!, Colors.orange[800]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            '1st',
                            style: GoogleFonts.poppins(
                              fontSize: 14,  // Much larger font size
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 15),

              // Welcome Text
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseAuth.instance.currentUser != null
                      ? _firestore
                      .collection('Users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome Back",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Loading...",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Guest",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          data?['name']?.split(' ')[0] ?? "User",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Add Car Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddCarPage()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Add",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),

              // Profile Avatar
              GestureDetector(
                onTap: () {
                  _showUserProfile(context);
                },
                child: Container(
                  padding: EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseAuth.instance.currentUser != null
                        ? _firestore
                        .collection('Users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue[100],
                            child: Icon(
                              Icons.person,
                              color: Colors.blue[800],
                              size: 18,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                            child: Icon(
                              Icons.person,
                              color: Colors.blue[800],
                              size: 18,
                            ),
                          ),
                        );
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final imageUrl = data?['profile_image'];
                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? null
                              : Icon(
                            Icons.person,
                            color: Colors.blue[800],
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.grey[100]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: _pages,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue[900]!.withOpacity(0.4),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutQuart,
                );
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.7),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration:
                        _selectedIndex == 0
                            ? BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            )
                            : null,
                    child: _buildAnimatedIcon(
                      Icons.home_outlined,
                      Icons.home,
                      0,
                    ),
                  ),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration:
                        _selectedIndex == 1
                            ? BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            )
                            : null,
                    child: _buildAnimatedIcon(
                      Icons.car_rental_outlined,
                      Icons.car_rental,
                      1,
                    ),
                  ),
                  label: "Bookings",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration:
                        _selectedIndex == 2
                            ? BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            )
                            : null,
                    child: _buildAnimatedIcon(
                      Icons.auto_awesome_outlined,
                      Icons.auto_awesome,
                      2,
                    ),
                  ),
                  label: "Recommendation",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: _selectedIndex == 3
                        ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                      ),
                    )
                        : null,
                    child: Stack(
                      children: [
                        _buildAnimatedIcon(
                          Icons.notifications_outlined,
                          Icons.notifications,
                          3,
                        ),
                        // Unread notification badge
                        StreamBuilder<int>(
                          stream: _getUnreadNotificationCount(),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            if (count == 0) {
                              return SizedBox.shrink();
                            }
                            return Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  count > 9 ? '9+' : count.toString(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  label: "Alerts",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration:
                        _selectedIndex == 4
                            ? BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            )
                            : null,
                    child: _buildAnimatedIcon(
                      Icons.person_outlined,
                      Icons.person,
                      4,
                    ),
                  ),
                  label: "Profile",
                ),
              ],
              selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(
    IconData outlineIcon,
    IconData filledIcon,
    int index,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child:
            _selectedIndex == index
                ? Icon(
                  filledIcon,
                  size: 24,
                  color: Colors.white,
                  key: ValueKey('filled_$index'),
                )
                : Icon(
                  outlineIcon,
                  size: 24,
                  color: Colors.white.withOpacity(0.8),
                  key: ValueKey('outline_$index'),
                ),
      ),
    );
  }

  Future<void> _showUserProfile(BuildContext context) async {
    await showPopupCard<String>(
      context: context,
      builder: (context) {
        return PopupCard(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.blue[200]!, width: 1),
          ),
          color: Colors.white,
          elevation: 12,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Avatar
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseAuth.instance.currentUser != null
                          ? _firestore
                              .collection('Users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .snapshots()
                          : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue[100],
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.blue[200],
                          child: Icon(
                            Icons.person,
                            color: Colors.blue[800],
                            size: 40,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue[100],
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage:
                              AssetImage(
                                    'assets/images/profile_placeholder.png',
                                  )
                                  as ImageProvider,
                        ),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final imageUrl = data?['profile_image'];
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[100],
                      child: CircleAvatar(
                        radius: 46,
                        backgroundImage:
                            imageUrl != null && imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : AssetImage(
                                      'assets/images/profile_placeholder.png',
                                    )
                                    as ImageProvider,
                      ),
                    );
                  },
                ),
                SizedBox(height: 10),


                // User Name
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseAuth.instance.currentUser != null
                          ? _firestore
                              .collection('Users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .snapshots()
                          : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Loading...',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.blue[900],
                        ),
                      );
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Text(
                        'User',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.blue[900],
                        ),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    return Text(
                      data?['name'] ?? 'User',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.blue[900],
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),

                SizedBox(height: 8),
                Text(
                  userEmail ?? "Email not available",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color:
                        userEmail != null ? Colors.grey[700] : Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 20),
                Divider(color: Colors.blue[200], height: 1),
                SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  "Confirm Log Out",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                content: Text(
                                  "Are you sure you want to log out?",
                                  style: GoogleFonts.poppins(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (context) => ChoosePage(),
                                        ),
                                        (Route<dynamic> route) => false,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      "Log Out",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold

                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout, size: 18,color: Colors.white,),
                            SizedBox(width: 8),
                            Text(
                              'Log Out',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      offset: const Offset(-16, 80),
      alignment: Alignment.topRight,
      useSafeArea: true,
      dimBackground: true,
    );
  }
}

class ExitConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 12,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.blue[900]!.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[700],
                size: 50,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Exit App?",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Are you sure you want to exit the app?",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                    ),
                    child: Text(
                      'Stay',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                    ),
                    child: Text(
                      'Exit',
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
          ],
        ),
      ),
    );
  }
}
