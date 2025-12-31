import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsPage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailsPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final name = userData['name'] ?? 'Unknown';
    final email = userData['email'] ?? 'No email';
    final licenseNo = userData['license_no'] ?? 'Not provided';
    final mobileNumber = userData['mobile_number'] ?? 'Not provided';
    final pinCode = userData['pin_code'] ?? 'Not provided';
    final state = userData['state'] ?? 'Not provided';
    final profileImage = userData['profile_image'];
    final dateCreated = (userData['dateCreated'] as Timestamp?)?.toDate().toString() ?? 'Not provided';
    final dateUpdated = (userData['dateUpdated'] as Timestamp?)?.toDate().toString() ?? 'Not provided';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image with 25% opacity, full screen
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/car.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Foreground content
          Column(
            children: [
              // AppBar-like header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'User Details',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32, // Increased font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scrollable content taking full remaining height
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      Center(
                        child: GestureDetector( // <-- ADDED: GestureDetector for tap
                          onTap: () {
                            // Only navigate if a valid profileImage URL exists
                            if (profileImage != null && profileImage.toString().isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImagePage(
                                    imageUrl: profileImage,
                                  ),
                                ),
                              );
                            }
                          },
                          child: profileImage != null && profileImage.toString().isNotEmpty
                              ? ClipOval(
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: Image.network(
                                profileImage,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.black,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.black,
                                    child: const Icon(Icons.person, color: Colors.white, size: 60),
                                  );
                                },
                              ),
                            ),
                          )
                              : const CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.black,
                            child: Icon(Icons.person, color: Colors.white, size: 60),
                          ),
                        ), // <-- END: GestureDetector
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28, // Increased font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          email,
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 18, // Increased font size
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Details Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('License No', licenseNo),
                            _buildDetailRow('Mobile Number', mobileNumber),
                            _buildDetailRow('Pin Code', pinCode),
                            _buildDetailRow('State', state),
                            _buildDetailRow('Date Created', dateCreated),
                            _buildDetailRow('Date Updated', dateUpdated),
                          ],
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0), // Slightly more spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              color: Colors.yellow,
              fontSize: 18, // Increased font size
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18, // Increased font size
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// NEW WIDGET FOR FULL-SCREEN IMAGE VIEW
// -----------------------------------------------------------------------------

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        // Using a close icon for the full-screen view
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer( // Allows panning and zooming of the image
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain, // Ensures the image fits within the screen
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
              );
            },
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