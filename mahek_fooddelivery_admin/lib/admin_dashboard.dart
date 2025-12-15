import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahek_fooddelivery_admin/ImageKit.dart';
import 'package:mahek_fooddelivery_admin/admin_all_customer_list.dart';
import 'package:mahek_fooddelivery_admin/customersPage.dart';
import 'package:mahek_fooddelivery_admin/orders_management_page.dart';
import 'package:mahek_fooddelivery_admin/partners_page.dart';
import 'package:mahek_fooddelivery_admin/products_page.dart';
import 'package:mahek_fooddelivery_admin/restaurant_page.dart';
import 'admin_complaints.dart';
import 'admin_details_page.dart';
import 'admin_reports_page.dart';
import 'delivery_orders_page.dart';
import 'tab_overview.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Theme colors (kept the same as requested)
  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightBackgroundColor = const Color(0xFFF0F4F8);

  String _adminName = 'Loading...';
  String _adminEmail = 'loading...';
  String? _adminProfileImage;
  String? _adminPhone;
  String? _adminRole;

  // --- State for Navigation ---
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  // List of pages/screens for the body
  final List<Widget> _pages = [
    TabOverview(), // 0: Dashboard Home
    const CustomersPage(), // 1: Customers
    const RestaurantPage(), // 2: Restaurants
    const OrdersManagementPage(), // 3: Orders
    const ProductsPage(), // 4: Products
    const PartnersPage(), // 5: Partners
    const AdminReportsPage(), // 6: Reports
    const AdminComplaintsPage(), // 7: Complaints
    const DeliveryOrdersPage(), // 8: Delivery
  ];

  // List of titles corresponding to the pages
  final List<String> _pageTitles = [
    'Dashboard Overview',
    'Customer Management',
    'Restaurant Approvals',
    'Order Management',
    'Product Catalog',
    'Partner Network',
    'System Reports',
    'Customer Complaints',
    'Delivery Orders',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAdminInfo();
  }

  Future<void> _fetchAdminInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch admin details from Firestore
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get();

        if (adminDoc.exists) {
          final data = adminDoc.data();
          setState(() {
            _adminName = data?['name'] ?? 'Admin';
            _adminEmail = user.email ?? 'No email';
            _adminProfileImage = data?['img_url'];
            _adminPhone = data?['phone'];
            _adminRole = data?['role'] ?? 'Administrator';
          });
        } else {
          // If admin document doesn't exist, use basic user info
          setState(() {
            _adminName = 'Admin';
            _adminEmail = user.email ?? 'No email';
          });
        }
      } catch (e) {
        print('Error fetching admin info: $e');
        setState(() {
          _adminName = 'Admin';
          _adminEmail = user.email ?? 'No email';
        });
      }
    } else {
      setState(() {
        _adminEmail = 'Not Authenticated';
      });
    }
  }

  void _onDrawerItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  void _showAdminDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDetailsPage(
          adminName: _adminName,
          adminEmail: _adminEmail,
          profileImage: _adminProfileImage,
          phone: _adminPhone,
          role: _adminRole,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () => _onDrawerItemTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? primaryAppColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: isSelected ? primaryAppColor : secondaryDarkColor.withOpacity(0.7),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryAppColor : secondaryDarkColor,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Custom Drawer Header
            UserAccountsDrawerHeader(
              accountName: Text(
                _adminName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                _adminEmail,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                backgroundImage: _adminProfileImage != null
                    ? NetworkImage(_adminProfileImage!)
                    : null,
                child: _adminProfileImage == null
                    ? Icon(
                  Icons.person_pin_circle_rounded,
                  size: 40,
                  color: primaryAppColor,
                )
                    : null,
              ),
              decoration: BoxDecoration(
                color: primaryAppColor,
                gradient: LinearGradient(
                  colors: [primaryAppColor, primaryAppColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(30),
                ),
              ),
              margin: EdgeInsets.zero,
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(index: 0, icon: Icons.dashboard_rounded, title: _pageTitles[0]),
                  _buildDrawerItem(index: 1, icon: Icons.people_alt_rounded, title: _pageTitles[1]),
                  _buildDrawerItem(index: 2, icon: Icons.store_mall_directory_rounded, title: _pageTitles[2]),
                  _buildDrawerItem(index: 3, icon: Icons.list_alt_rounded, title: _pageTitles[3]),
                  _buildDrawerItem(index: 4, icon: Icons.local_dining_rounded, title: _pageTitles[4]),
                  _buildDrawerItem(index: 5, icon: Icons.handshake_rounded, title: _pageTitles[5]),
                  _buildDrawerItem(index: 6, icon: Icons.bar_chart_rounded, title: _pageTitles[6]),
                  _buildDrawerItem(index: 7, icon: Icons.warning_rounded, title: _pageTitles[7]),
                  _buildDrawerItem(index: 8, icon: Icons.delivery_dining_rounded, title: _pageTitles[8]),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Divider(color: Colors.grey.shade300, height: 1),
            ),
            _buildDrawerItem(
              index: -1,
              icon: Icons.logout_rounded,
              title: 'Logout',
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: lightBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _pageTitles[_selectedIndex],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, size: 28),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          // Admin Profile Button
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 28),
            onPressed: _showAdminDetails,
            tooltip: 'Admin Profile',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AdminAllCustomerList()));
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }
}