// file: lib/partner_details_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahek_fooddelivery_admin/partner_location_map_page.dart';
import 'partner_model.dart';
import 'EmailService.dart';

class PartnerDetailsPage extends StatelessWidget {
  final Partner partner;

  const PartnerDetailsPage({super.key, required this.partner});

  Future<void> _updatePartnerStatus(BuildContext context, bool isApproved) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingDialog(),
      );

      // Update status in Firestore
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(partner.id)
          .update({
        'isApproved': isApproved,
        'status': isApproved ? 'approved' : 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send email notification
      await _sendStatusEmail(isApproved);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        context.showSuccessToast(
            isApproved
                ? 'Partner approved successfully!'
                : 'Partner rejected successfully!'
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      }

    } catch (e) {
      print('❌ Error updating partner status: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
        context.showErrorToast('Failed to update partner status. Please try again.');
      }
    }
  }

  Future<void> _sendStatusEmail(bool isApproved) async {
    final subject = isApproved
        ? '🎉 Welcome to Mahek Delivery - Partner Application Approved!'
        : '❌ Mahek Delivery - Partner Application Update';

    final bodyText = isApproved
        ? 'We are pleased to inform you that your partner application has been approved! You can now start accepting delivery orders through the Mahek Delivery Partner app. Your Partner ID is: ${partner.id}'
        : 'After careful review, we regret to inform you that your partner application has not been approved at this time. Please contact our support team for more information.';

    final buttonText = isApproved ? 'Get Started' : 'Contact Support';

    // Create email HTML content directly
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
        .security-note {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
            font-size: 12px;
            color: #856404;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Mahek Delivery Partner</h1>
            <p>Partner Application Update</p>
        </div>
        
        <div class="content">
            <h2>$subject</h2>
            <p>Dear ${partner.name},</p>
            
            <div class="message">
                <p>$bodyText</p>
            </div>

            <div style="text-align: center; margin: 20px 0;">
                <strong>Partner ID:</strong> ${partner.id}<br>
                <strong>Application Date:</strong> ${partner.formattedJoinDateTime}
            </div>
            
            <a href="#" class="button">$buttonText</a>
            
            <div class="security-note">
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

    // Send email using EmailService directly
    final emailSent = await EmailService.sendEmail(
      recipientEmail: partner.email,
      subject: subject,
      htmlBody: htmlBody,
    );

    if (emailSent) {
      print('✅ Status Email sent successfully to ${partner.email}');
    } else {
      print('❌ Failed to send status Email to ${partner.email}');
    }
  }
  void _showConfirmationDialog(BuildContext context, bool isApproved) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isApproved ? 'Approve Partner' : 'Reject Partner',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        content: Text(
          isApproved
              ? 'Are you sure you want to approve ${partner.name} as a delivery partner? They will be able to start accepting orders immediately.'
              : 'Are you sure you want to reject ${partner.name}\'s application? This action cannot be undone.',
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
              _updatePartnerStatus(context, isApproved);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isApproved ? 'Approve' : 'Reject',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Partner Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Edit functionality
            },
            tooltip: 'Edit Partner',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            _buildProfileHeader(),
            const SizedBox(height: 20),

            // Personal Information
            _buildInfoSection(
              title: 'Personal Information',
              icon: Icons.person_outline,
              children: [
                _buildInfoRow(Icons.badge_outlined, 'Full Name', partner.name),
                _buildInfoRow(Icons.email_outlined, 'Email Address', partner.email),
                _buildInfoRow(Icons.phone_android, 'Phone Number', partner.mobileNumber),
                _buildInfoRow(Icons.location_on_outlined, 'Address', partner.address ?? 'Not provided'),
                _buildInfoRow(Icons.location_city_outlined, 'City', partner.city),
              ],
            ),
            const SizedBox(height: 20),

            // Professional Information
            _buildInfoSection(
              title: 'Professional Information',
              icon: Icons.work_outline,
              children: [
                _buildInfoRow(Icons.qr_code, 'Partner ID', partner.id),
                _buildInfoRow(Icons.delivery_dining, 'Vehicle Type', partner.vehicleType ?? 'Not specified'),
                _buildInfoRow(Icons.credit_card, 'License Number', partner.licenseNumber ?? 'Not provided'),
                _buildInfoRow(Icons.event_note, 'Join Date', partner.formattedJoinDateTime),
                _buildStatusRow(Icons.check_circle_outlined, 'Account Status', partner.isApproved ? 'Approved' : 'Pending',
                    partner.isApproved ? Colors.green : Colors.orange),
              ],
            ),
            const SizedBox(height: 20),

            // Performance Stats
            _buildStatsSection(),
            const SizedBox(height: 20),

            // Actions
            _buildActionButtons(context),
            const SizedBox(height: 80), // Added spacing for FAB
          ],
        ),
      ),
      // Floating Action Button (Location Tracking)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartnerLocationMapPage(partner: partner),
            ),
          );
        },
        icon: const Icon(Icons.location_on_outlined),
        label: const Text('View Location'),
        backgroundColor: const Color(0xFFF96D0A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Image and Name
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFF96D0A).withOpacity(0.1),
              backgroundImage: partner.profileImageUrl != null
                  ? NetworkImage(partner.profileImageUrl!)
                  : null,
              child: partner.profileImageUrl == null
                  ? Icon(Icons.person, size: 40, color: const Color(0xFFF96D0A))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              partner.name,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              partner.email,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // Status and Rating Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHeaderStat('Status', partner.statusText, partner.statusColor),
                _buildHeaderStat('Rating', '${partner.rating ?? 0.0}/5.0', Colors.amber),
                _buildHeaderStat('Orders', partner.ordersCompleted.toString(), Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFFF96D0A)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFF96D0A).withOpacity(0.8)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color.withOpacity(0.8)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, size: 20, color: const Color(0xFFF96D0A)),
                const SizedBox(width: 8),
                Text(
                  'Performance Statistics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildStatCard('Total Orders', '${partner.ordersCompleted}', Icons.shopping_bag_outlined, Colors.blue),
                _buildStatCard('Total Earnings', '₹${partner.totalEarnings ?? 0}', Icons.attach_money, Colors.green),
                _buildStatCard('Success Rate', '${((partner.ordersCompleted / (partner.ordersCompleted + 5)) * 100).toStringAsFixed(1)}%', Icons.star_rate, Colors.amber),
                _buildStatCard('Active Hours', '8.5h', Icons.access_time, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Contact action
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Message action (now also on FAB)
                    },
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: partner.isApproved
                        ? () => _showConfirmationDialog(context, false)
                        : () => _showConfirmationDialog(context, true),
                    icon: Icon(partner.isApproved ? Icons.block : Icons.check_circle, size: 18),
                    label: Text(partner.isApproved ? 'Deactivate' : 'Approve'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: partner.isApproved ? Colors.red : Colors.green,
                      side: BorderSide(color: partner.isApproved ? Colors.red : Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

// Loading Dialog Widget
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
              'Updating Partner Status...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we update the status',
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

// Extension for Toast Messages
extension ToastExtension on BuildContext {
  void showSuccessToast(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showErrorToast(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showWarningToast(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}