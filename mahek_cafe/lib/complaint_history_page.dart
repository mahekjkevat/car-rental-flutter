import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'complaint_model.dart';
import 'complaint_page.dart';
import 'complaint_detail_page.dart';

class ComplaintHistoryPage extends StatelessWidget {
  const ComplaintHistoryPage({super.key});

  // Define the primary color for consistency
  final Color primaryColor = const Color(0xFFE65100);

  // Helper to format date
  String _formatDate(DateTime date) {
    // Corrected format
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // NEW: Updated _buildComplaintCard to be tappable
  Widget _buildComplaintCard(BuildContext context, Complaint complaint) {
    final statusColor = _getStatusColor(complaint.status);

    return GestureDetector(
      onTap: () {
        // NAVIGATE to the ComplaintDetailPage when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComplaintDetailPage(complaint: complaint),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      complaint.status,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Type
              Text(
                complaint.complaintType,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              // Description Snippet
              Text(
                complaint.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Submission Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (complaint.imageUrls.isNotEmpty)
                    Text(
                      '${complaint.imageUrls.length} image(s) attached',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    'Submitted: ${_formatDate(complaint.createdAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Complaint History', style: GoogleFonts.poppins())),
        body: const Center(child: Text('Please login to view complaints')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Complaints',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      'No complaints submitted yet!',
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ));
          }

          final complaints = snapshot.data!.docs
              .map((doc) => Complaint.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              return _buildComplaintCard(context, complaints[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ComplaintPage()),
          );
        },
        label: Text('New Complaint', style: GoogleFonts.poppins(color: Colors.white)),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        backgroundColor: primaryColor,
        elevation: 6,
      ),
    );
  }
}
