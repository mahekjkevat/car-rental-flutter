import 'package:car_rental_admin/UsersPage.dart';
import 'package:car_rental_admin/bottom_navigation_bar/all_cars_page.dart';
import 'package:car_rental_admin/reports_page.dart';
import 'package:car_rental_admin/revenue_user.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_car_verification_page.dart';
import 'admin_document_verification_page.dart';
import 'bottom_navigation_bar/add_car_page.dart';
import 'chat/admin_chat_list_page.dart';

// Define the black/yellow color scheme to match AdminDocumentVerificationPage
const Color _primaryColor = Colors.black; // Used for AppBar and primary background
const Color _accentColor = Colors.yellow; // Used for accents, icons, and highlights
const Color _backgroundColor = Colors.black; // General page background
const Color _cardColor = Color(0xFF1C1C1C); // Dark grey for tile backgrounds (slight contrast)
const Color _textColor = Colors.white; // Primary text color on dark backgrounds
const Color _secondaryTextColor = Colors.grey; // Secondary text color


class ToolsPage extends StatelessWidget {
  const ToolsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Pure black background
      appBar: AppBar(
        backgroundColor: _primaryColor, // Black AppBar
        elevation: 0, // Flat design
        title: Text(
          'Admin Command Center', // Updated title for a professional feel
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _accentColor, // Yellow accent for title
          ),
        ),
        centerTitle: true,
      ),
      body: Column( // Use Column to separate fixed header from scrollable content
        children: [
          // Fixed Header Card (NOT SCROLLABLE)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: _buildHeaderCard(context), // Pass context here
          ),

          const SizedBox(height: 12), // Reduced vertical space

          // Tools List Title/Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification & Management',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _secondaryTextColor,
                  ),
                ),
                Divider(color: _accentColor.withOpacity(0.3), height: 16, thickness: 1),
              ],
            ),
          ),

          // Scrollable Tools List (Takes up remaining height)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  ...tools.map((tool) => _buildToolListTile(tool, context)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NOTE: Context is required for navigation, so it is passed here.
  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.2), // Subtle yellow glow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Tappable Logo Image
            GestureDetector(
              onTap: () {
                // Navigate to FullScreenAssetPage on tap
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FullScreenAssetPage(
                      assetPath: 'assets/images/app_logo.jpeg',
                    ),
                  ),
                );
              },
              child: Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1), // Yellow tint
                  shape: BoxShape.circle,
                  border: Border.all(color: _accentColor, width: 2), // Yellow border
                ),
                child: Image.asset(
                  'assets/images/app_logo.jpeg', // <-- Updated Image Path
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title text
            Text(
              'Car Rental Admin',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor, // White text
              ),
            ),
            const SizedBox(height: 8),
            // Description text
            Text(
              'Your central hub for managing the entire car rental ecosystem.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _secondaryTextColor, // Grey text
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New List Tile Widget for the updated UI
  Widget _buildToolListTile(ToolItem tool, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        color: _cardColor, // Dark grey background for contrast
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _navigateToPage(tool, context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                // Icon (Left side, prominent)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tool.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tool.color.withOpacity(0.7), width: 1),
                  ),
                  child: Icon(
                    tool.icon,
                    color: tool.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textColor, // White
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tool.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _secondaryTextColor, // Grey
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Chevron (Right side, accented)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: _accentColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPage(ToolItem tool, BuildContext context) {
    if (tool.page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => tool.page!),
      );
    }
  }
}

class ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? page;

  ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.page,
  });
}

// List of all admin tools
final List<ToolItem> tools = [
  ToolItem(
    title: 'Document Verification',
    subtitle: 'Approve or reject user documents',
    icon: Icons.verified_user,
    color: _accentColor, // Yellow (Highest priority)
    page: AdminDocumentVerificationPage(),
  ),
  ToolItem(
    title: 'Car Verification',
    subtitle: 'Verify customer car details and images',
    icon: Icons.car_repair,
    color: Colors.orange,
    page: AdminCarVerificationPage(),
  ),
  ToolItem(
    title: 'Car Inventory',
    subtitle: 'Manage and view all registered vehicles',
    icon: Icons.inventory,
    color: const Color(0xFFFF5722), // Deep Orange
    page: AllCarsPage(),
  ),
  ToolItem(
    title: 'Add Car',
    subtitle: 'Manually add new vehicles to the fleet',
    icon: Icons.directions_car,
    color: const Color(0xFF4CAF50), // Green
    page: AddCarPage(),
  ),
  ToolItem(
    title: 'Reports',
    subtitle: 'Detailed business insights and analytics',
    icon: Icons.analytics,
    color: const Color(0xFF9C27B0), // Purple
    page: ReportsPage(),
  ),
  ToolItem(
    title: 'Revenue & Users',
    subtitle: 'Overview of financial performance and users',
    icon: Icons.attach_money,
    color: const Color(0xFF009688), // Teal
    page: RevenueUserPage(),
  ),
  ToolItem(
    title: 'Customer Chats',
    subtitle: 'Handle real-time customer and host inquiries',
    icon: Icons.chat,
    color: _accentColor,
    page: AdminChatListPage(),
  ),
  ToolItem(
    title: 'User Management',
    subtitle: 'Monitor and modify customer accounts',
    icon: Icons.people,
    color: const Color(0xFF3F51B5), // Indigo
    page: UsersPage(),
  ),
  // ToolItem(
  //   title: 'Settings',
  //   subtitle: 'Configure application parameters',
  //   icon: Icons.settings,
  //   color: Colors.grey,
  //   page: Container(),
  // ),
];

// -----------------------------------------------------------------------------
// NEW WIDGET: FullScreenAssetPage for displaying the asset image
// -----------------------------------------------------------------------------

class FullScreenAssetPage extends StatelessWidget {
  final String assetPath;

  const FullScreenAssetPage({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer( // Allows panning and zooming of the image
          boundaryMargin: const EdgeInsets.all(20.0),
          minScale: 0.1,
          maxScale: 4.0,
          child: Image.asset( // Use Image.asset for local files
            assetPath,
            fit: BoxFit.contain, // Ensures the image fits within the screen
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 100),
              );
            },
          ),
        ),
      ),
    );
  }
}