import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'DamageReportModel.dart';

// --- NEW DATA MODEL CLASS ---
class CarDamageReportData {
  final String description;
  final String damageType;
  final String status;
  final String imageUrl;
  final String userName;
  final String userMobile;
  final String userProfileImageUrl;
  final String carDetails;
  final String reportDate;

  const CarDamageReportData({
    required this.description,
    required this.damageType,
    required this.status,
    required this.imageUrl,
    required this.userName,
    required this.userMobile,
    required this.userProfileImageUrl,
    required this.carDetails,
    required this.reportDate,
  });

  factory CarDamageReportData.fromFirestore(Map<String, dynamic> data) {
    final String description = data['description'] ?? 'N/A';
    final String damageType = data['damageType'] ?? 'N/A';
    final String status = data['status'] ?? 'N/A';
    final String imageUrl =
        data['imageurl'] ??
        'https://via.placeholder.com/600x400/CCCCCC/808080?text=No+Image';
    final String userProfileImageUrl =
        data['user']?['profileImageUrl'] ??
        'https://via.placeholder.com/150/0000FF/FFFFFF?text=User';
    final String userName = data['userName'] ?? 'N/A';
    final String userMobile = data['userMobile'] ?? 'N/A';
    final String carDetails = '${data['licensePlate'] ?? 'N/A'}';
    final String reportDate =
        data['reportTime'] != null
            ? DateFormat(
              'MMM d · hh:mm a',
            ).format((data['reportTime'] as Timestamp).toDate())
            : 'N/A';

    return CarDamageReportData(
      description: description,
      damageType: damageType,
      status: status,
      imageUrl: imageUrl,
      userName: userName,
      userMobile: userMobile,
      userProfileImageUrl: userProfileImageUrl,
      carDetails: carDetails,
      reportDate: reportDate,
    );
  }
}

// -----------------------------

class CarDamageReport extends StatelessWidget {
  final DamageReportModel reportModel;

  const CarDamageReport({super.key, required this.reportModel});

  @override
  Widget build(BuildContext context) {
    if (reportModel.damageReportId == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.blue[900],
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          title: Text(
            'Damage Report',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'No Issue Found',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No damage report was submitted for this booking.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String damageReportPath =
        '/Users/${reportModel.userId}/car_booking/${reportModel.carBookingId}/damage_report/${reportModel.damageReportId}';

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
        ),
        title: Text(
          'Damage Report',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.doc(damageReportPath).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final reportData = CarDamageReportData.fromFirestore(data);

            final Color statusColor =
                reportData.status == 'Pending'
                    ? Colors.orange
                    : reportData.status == 'Resolved'
                    ? Colors.green
                    : Colors.white;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: reportData.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.yellow,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            context,
                            'Description',
                            reportData.description,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            'Damage Type',
                            reportData.damageType,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            'Status',
                            reportData.status,
                            statusColor: statusColor,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            'Licence',
                            reportData.carDetails,
                            statusColor: statusColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blueAccent,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reportData.userName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  reportData.userMobile,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  reportData.reportDate,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    'Damage Report Not Available',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The requested report could not be found.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: statusColor ?? Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
