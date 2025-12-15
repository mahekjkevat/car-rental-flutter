// lib/restaurant_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'restaurant_model.dart'; // Import the model
import 'EmailService.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailsPage({super.key, required this.restaurant});

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  // Theme colors matching the customersPage
  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color backgroundColor = const Color(0xFFF7F7F7);

  // --- Firestore Update Logic ---


  Future<void> _updateRestaurantStatus(String newStatus) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(),
    );

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurant.id)
          .get();

      String currentStatus = 'unknown';
      if (docSnapshot.exists) {
        currentStatus = docSnapshot.data()?['status'] ?? 'unknown';
      }

      if (currentStatus.toLowerCase() == newStatus.toLowerCase()) {
        if (context.mounted) {
          Navigator.of(context).pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Restaurant is already ${newStatus.toLowerCase()}.'),
              backgroundColor: Colors.blue.shade700,
            ),
          );
        }
        return;
      }

      final restaurantRef = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurant.id);

      // Perform the update
      await restaurantRef.update({
        'status': newStatus.toLowerCase(),
        'isApproved': newStatus.toLowerCase() == 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send email notification
      await _sendStatusEmail(newStatus.toLowerCase());

      if (context.mounted) {
        Navigator.of(context).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${widget.restaurant.name} status updated to $newStatus successfully!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update status. Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      print('Firestore Error: $e');
    }
  }


  Future<void> _sendStatusEmail(String newStatus) async {
    final subject = newStatus == 'approved'
        ? '🎉 Welcome to Mahek Delivery - Restaurant Application Approved!'
        : newStatus == 'rejected'
        ? '❌ Mahek Delivery - Restaurant Application Update'
        : '⏳ Mahek Delivery - Application Status Update';

    final bodyText = newStatus == 'approved'
        ? 'We are pleased to inform you that your restaurant "${widget.restaurant.name}" has been approved! You can now start receiving orders through the Mahek Delivery platform. Your Restaurant ID is: ${widget.restaurant.resId}'
        : newStatus == 'rejected'
        ? 'After careful review, we regret to inform you that your restaurant application for "${widget.restaurant.name}" has not been approved at this time. Please contact our support team for more information.'
        : 'Your restaurant application for "${widget.restaurant.name}" is currently under review. We will notify you once a decision has been made.';

    final buttonText = newStatus == 'approved'
        ? 'Get Started'
        : newStatus == 'rejected'
        ? 'Contact Support'
        : 'View Details';

    // Create email HTML content
    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$subject</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #F96D0A 0%, #FF8C42 100%);
            padding: 30px 20px;
            text-align: center;
            color: white;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
            font-weight: bold;
        }
        .content {
            padding: 30px;
        }
        .message {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #F96D0A;
            margin: 20px 0;
        }
        .restaurant-info {
            background-color: #fff8f4;
            border: 1px solid #F96D0A;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }
        .button {
            display: block;
            width: 200px;
            margin: 30px auto;
            padding: 15px 30px;
            background: linear-gradient(135deg, #F96D0A 0%, #FF8C42 100%);
            color: white;
            text-decoration: none;
            border-radius: 25px;
            text-align: center;
            font-weight: bold;
            font-size: 16px;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #666;
            border-top: 1px solid #e9ecef;
        }
        .status-badge {
            display: inline-block;
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: bold;
            margin: 10px 0;
            text-transform: uppercase;
        }
        .approved { background-color: #d4edda; color: #155724; }
        .rejected { background-color: #f8d7da; color: #721c24; }
        .pending { background-color: #fff3cd; color: #856404; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏪 Mahek Delivery Restaurant</h1>
            <p>Restaurant Application Update</p>
        </div>
        
        <div class="content">
            <h2>$subject</h2>
            <p>Dear Restaurant Owner,</p>
            
            <div class="restaurant-info">
                <strong>Restaurant:</strong> ${widget.restaurant.name}<br>
                <strong>Restaurant ID:</strong> ${widget.restaurant.resId}<br>
                <strong>Application Date:</strong> ${DateFormat('dd MMM yyyy').format(widget.restaurant.createdAt)}
            </div>
            
            <div class="message">
                <p>$bodyText</p>
            </div>

            <div style="text-align: center;">
                <div class="status-badge ${newStatus}">
                    Status: $newStatus
                </div>
            </div>
            
            <a href="#" class="button">$buttonText</a>
            
            <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0; font-size: 12px; color: #856404;">
                <strong>🔒 Important Notice:</strong><br>
                • This is an automated message from Mahek Delivery<br>
                • Please do not reply to this email<br>
                • Contact support for any questions or concerns
            </div>
            
            <p>Best regards,<br><strong>Mahek Delivery Team</strong></p>
        </div>
        
        <div class="footer">
            <p>&copy; ${DateTime.now().year} Mahek Delivery. All rights reserved.</p>
            <p>This is an automated message. Please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>
''';

    // Send email using EmailService
    final emailSent = await EmailService.sendEmail(
      recipientEmail: widget.restaurant.email,
      subject: subject,
      htmlBody: htmlBody,
    );

    if (emailSent) {
      print('✅ Status email sent successfully to ${widget.restaurant.email}');
    } else {
      print('❌ Failed to send status email to ${widget.restaurant.email}');
    }
  }



  void _showConfirmationDialog(String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == 'approved' ? 'Approve Restaurant' : 'Reject Restaurant',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        content: Text(
          status == 'approved'
              ? 'Are you sure you want to approve "${widget.restaurant.name}"? They will be able to start receiving orders immediately.'
              : 'Are you sure you want to reject "${widget.restaurant.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: const Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateRestaurantStatus(status);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              status == 'approved' ? 'Approve' : 'Reject',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }  // --- UI Builder Methods ---

  // Custom Section Header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: secondaryDarkColor,
        ),
      ),
    );
  }

  // Detail Row using a structured ListTile for better alignment and padding
  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: primaryAppColor, size: 24),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: secondaryDarkColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: valueColor ?? secondaryDarkColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Action Button (Improved look and feel)


  Widget _buildActionButton(String label, String status, Color color, String currentStatus) {
    bool isCurrentStatus = currentStatus.toLowerCase() == status.toLowerCase();

    return Expanded(
      child: ElevatedButton(
        onPressed: isCurrentStatus ? null : () => _showConfirmationDialog(status),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentStatus ? Colors.grey.shade400 : color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: isCurrentStatus ? 0 : 5,
          disabledBackgroundColor: Colors.grey.shade400,
          disabledForegroundColor: Colors.white70,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to listen to real-time changes in the restaurant's document
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.restaurant.id)
            .snapshots(),
        builder: (context, snapshot) {
          // Fallback to the initial widget data if no stream data yet
          Restaurant restaurant = widget.restaurant;

          if (snapshot.hasData && snapshot.data!.exists) {
            // If stream has data, use the latest data from the snapshot
            restaurant = Restaurant.fromFirestore(snapshot.data!);
          } else if (snapshot.hasError) {
            // Show error but still display the initial data
            // TODO: Consider showing a banner or dialog for the error
          }

          // The current status from the live data
          String currentStatus = restaurant.status;

          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: primaryAppColor,
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(restaurant.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 1. Status Header Card
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: restaurant.statusColor, width: 2), // Stronger border
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Review Status',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: secondaryDarkColor.withOpacity(0.7)
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentStatus.toUpperCase(),
                                style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: restaurant.statusColor
                                ),
                              ),
                            ],
                          ),
                          Icon(
                              currentStatus.toLowerCase() == 'approved' ? Icons.verified_user :
                              currentStatus.toLowerCase() == 'rejected' ? Icons.gavel :
                              Icons.access_time_filled,
                              color: restaurant.statusColor,
                              size: 40
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 2. Action Buttons Section

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Approval Management',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: secondaryDarkColor
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildActionButton('Approve', 'approved', Colors.green.shade600, currentStatus),
                            const SizedBox(width: 8),
                            _buildActionButton('Reject', 'rejected', Colors.red.shade600, currentStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 3. Contact Details
                  _buildSectionHeader('Contact and Location'),
                  _buildDetailRow(Icons.vpn_key_outlined, 'Restaurant ID (res_id)', restaurant.resId),
                  _buildDetailRow(Icons.email_outlined, 'Email', restaurant.email),
                  _buildDetailRow(Icons.phone_outlined, 'Phone', restaurant.phone),
                  _buildDetailRow(Icons.location_on_outlined, 'Address', restaurant.address),

                  // 4. Metadata
                  _buildSectionHeader('Metadata'),
                  _buildDetailRow(
                    Icons.calendar_month_outlined,
                    'Date Joined',
                    restaurant.formattedJoinDate,
                    valueColor: Colors.grey.shade600,
                  ),
                  _buildDetailRow(
                    Icons.history_toggle_off_outlined,
                    'Last Updated',
                    DateFormat('dd MMM yyyy HH:mm').format(restaurant.updatedAt),
                    valueColor: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          );
        }
    );
  }
}

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFF96D0A),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Updating Restaurant Status...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we update the status and send notifications',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Color(0xFF333333).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
