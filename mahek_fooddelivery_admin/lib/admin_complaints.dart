import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// --- Theme Colors and Constants (Copied from previous files for consistency) ---
final Color primaryAppColor = const Color(0xFFF96D0A); // Vibrant Orange/Red
final Color secondaryDarkColor = const Color(0xFF333333); // Dark text/icons
final Color lightBackgroundColor = const Color(0xFFF0F4F8); // Light background

// --- Data Structure for Complaints ---

enum ComplaintStatus { New, InProgress, Resolved }

class Complaint {
  final String id;
  final String user;
  final String subject;
  final String message;
  final ComplaintStatus status;
  final DateTime timestamp;

  Complaint({
    required this.id,
    required this.user,
    required this.subject,
    required this.message,
    required this.status,
    required this.timestamp,
  });

  // Helper to get color based on status
  Color get statusColor {
    switch (status) {
      case ComplaintStatus.New:
        return primaryAppColor;
      case ComplaintStatus.InProgress:
        return Colors.blue.shade600;
      case ComplaintStatus.Resolved:
        return Colors.green.shade600;
    }
  }

  // Helper to get status text
  String get statusText {
    switch (status) {
      case ComplaintStatus.New:
        return 'NEW';
      case ComplaintStatus.InProgress:
        return 'IN PROGRESS';
      case ComplaintStatus.Resolved:
        return 'RESOLVED';
    }
  }

  // Factory to generate dummy data
  static List<Complaint> generateDummyComplaints() {
    return [
      Complaint(
        id: 'CMP001',
        user: 'Aarav Sharma',
        subject: 'Order #3457 wrong item delivered.',
        message: 'I received a paneer dish instead of the chicken tikka I ordered. Please issue a refund or redeliver.',
        status: ComplaintStatus.New,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Complaint(
        id: 'CMP002',
        user: 'Diya Patel',
        subject: 'Late Delivery (Order #3452)',
        message: 'The driver was 45 minutes late, and the food was cold when it arrived.',
        status: ComplaintStatus.InProgress,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      ),
      Complaint(
        id: 'CMP003',
        user: 'Rishi Kapoor',
        subject: 'Billing discrepancy for Order #3440.',
        message: 'The total amount charged was higher than the one shown on the app during checkout.',
        status: ComplaintStatus.Resolved,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Complaint(
        id: 'CMP004',
        user: 'Siya Verma',
        subject: 'Driver behavior complaint (ID: DRV102)',
        message: 'The delivery driver was rude upon drop-off and did not follow instructions.',
        status: ComplaintStatus.New,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Complaint(
        id: 'CMP005',
        user: 'Kunal Joshi',
        subject: 'Restaurant quality issue (Restaurant ID: RES05)',
        message: 'The food from "Spice Grill" was undercooked and caused stomach upset.',
        status: ComplaintStatus.InProgress,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
  }
}

// --- Main Complaints Page Widget ---

class AdminComplaintsPage extends StatelessWidget {
  const AdminComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final complaints = Complaint.generateDummyComplaints();

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Header and Title
          SliverAppBar(
            title: Text(
              'Customer Complaints',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            backgroundColor: primaryAppColor,
            foregroundColor: Colors.white,
            floating: true,
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Total Open Cases: ${complaints.where((c) => c.status != ComplaintStatus.Resolved).length}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              centerTitle: false,
            ),
          ),

          // 2. Complaints List
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final complaint = complaints[index];
                  return _buildComplaintCard(complaint);
                },
                childCount: complaints.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Complaint List Item Card ---

  Widget _buildComplaintCard(Complaint complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // Use InkWell for a nice tap effect, simulating opening the complaint details
        onTap: () {
          // In a real app, this would navigate to a detailed view
          print('Tapped on Complaint: ${complaint.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: ID, Status, and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${complaint.id}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Row(
                    children: [
                      // Status Dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: complaint.statusColor,
                          shape: BoxShape.circle,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      // Status Text
                      Text(
                        complaint.statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: complaint.statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),

              // Row 2: Subject and User
              Text(
                complaint.subject,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: secondaryDarkColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Filed by: ${complaint.user}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryDarkColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),

              // Row 3: Short Message Preview
              Text(
                complaint.message.length > 100
                    ? '${complaint.message.substring(0, 100)}...'
                    : complaint.message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Row 4: Timestamp
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Filed: ${DateFormat('MMM d, hh:mm a').format(complaint.timestamp)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
