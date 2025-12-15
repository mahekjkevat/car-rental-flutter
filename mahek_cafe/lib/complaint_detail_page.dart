import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'complaint_model.dart';

class ComplaintDetailPage extends StatelessWidget {
  final Complaint complaint;

  const ComplaintDetailPage({super.key, required this.complaint});

  final Color primaryColor = const Color(0xFFE65100); // Orange color
  final Color secondaryColor = const Color(0xFF333333); // Dark color

  // Helper to format the status badge color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade600;
      case 'in progress':
        return Colors.blue.shade600;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Helper to format the status text icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.watch_later_outlined;
      case 'in progress':
        return Icons.history_toggle_off_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Helper to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Helper for a detail section row
  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: secondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(complaint.status);
    final statusIcon = _getStatusIcon(complaint.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complaint Details',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Complaint Title and Status
              Text(
                complaint.title,
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: secondaryColor),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 18, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${complaint.status}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 30, thickness: 1.5),

              // 2. Complaint Type & ID
              _buildDetailRow(
                'Complaint Type',
                complaint.complaintType,
                Icons.category_rounded,
              ),
              _buildDetailRow(
                'Reference ID',
                complaint.id,
                Icons.fingerprint_rounded,
              ),
              _buildDetailRow(
                'Submitted On',
                _formatDate(complaint.createdAt),
                Icons.access_time_filled_rounded,
              ),
              if (complaint.updatedAt != null)
                _buildDetailRow(
                  'Last Updated',
                  _formatDate(complaint.updatedAt!),
                  Icons.update_rounded,
                ),

              // 3. Detailed Description
              const SizedBox(height: 10),
              Text(
                'Full Description',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: secondaryColor),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  complaint.description,
                  style: GoogleFonts.poppins(fontSize: 16, height: 1.5, color: secondaryColor.withOpacity(0.9)),
                ),
              ),

              // 4. Attached Images
              if (complaint.imageUrls.isNotEmpty) ...[
                const Divider(height: 30, thickness: 1.5),
                Text(
                  'Attached Images (${complaint.imageUrls.length})',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: secondaryColor),
                ),
                const SizedBox(height: 15),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: complaint.imageUrls.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final imageUrl = complaint.imageUrls[index];
                    // Create a unique Hero tag for a smooth animation
                    final heroTag = 'complaint-image-${complaint.id}-$index';

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: GestureDetector(
                        onTap: () {
                          // NAVIGATE to the FullScreenImageViewer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageViewer(
                                imageUrl: imageUrl,
                                heroTag: heroTag,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: heroTag, // Attach the Hero tag here
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade300,
                              child: const Center(child: Icon(Icons.image_outlined, color: Colors.white70)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.red.shade100,
                              child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}


class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag; // To enable the smooth Hero transition

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a black background for a typical photo viewer experience
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // White back button
      ),
      extendBodyBehindAppBar: true, // Allows the image to go under the AppBar

      body: Center(
        child: Hero(
          tag: heroTag, // Match the tag from the source widget
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain, // Ensure the entire image fits on screen
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }
}
