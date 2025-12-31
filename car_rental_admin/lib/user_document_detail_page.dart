import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'EmailService.dart';
// Removed: import 'admin_document_verification_page.dart';

// --- THEME DEFINITIONS (Directly applied UI and look from ToolsPage/AdminPage) ---
// Standardized variable names and colors for consistency
const Color _primaryColor = Colors.black; // Used for AppBar and primary background
const Color _accentColor = Colors.yellow; // Used for accents, icons, pending status
const Color _backgroundColor = Colors.black; // General page background
const Color _textColor = Colors.white; // Primary text color on dark backgrounds
const Color _secondaryTextColor = Colors.grey; // Secondary text color on dark backgrounds
const Color _successColor = Color(0xFF4CAF50); // Green for Success/Approved status
const Color _rejectColor = Color(0xFFF44336); // Red for Reject status

// ----------------------------------------------------------------------
// WIDGET FOR FULLSCREEN ZOOM
// ----------------------------------------------------------------------
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context), // Close on tap
        child: SizedBox.expand(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              key: Key(imageUrl),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// USER DOCUMENT DETAIL PAGE
// ----------------------------------------------------------------------

class UserDocumentDetailPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> documentData;
  final DocumentReference? docRef;

  const UserDocumentDetailPage({
    Key? key,
    required this.userId,
    required this.userData,
    required this.documentData,
    this.docRef,
  }) : super(key: key);

  @override
  _UserDocumentDetailPageState createState() => _UserDocumentDetailPageState();
}

class _UserDocumentDetailPageState extends State<UserDocumentDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // This controller holds the final combined rejection reason
  final TextEditingController _rejectionController = TextEditingController();
  bool _isProcessing = false;

  // Pre-defined rejection reasons for the dropdown
  final List<String> _rejectionReasons = [
    'Image is blurred or unreadable',
    'Document is expired',
    'Name/Details mismatch with account',
    'Incomplete document sides provided',
    'Other (Please specify in text box)',
  ];

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.documentData['verification_status'] == 'pending';

    return Scaffold(
      backgroundColor: _backgroundColor, // Black theme background
      appBar: AppBar(
        backgroundColor: _primaryColor, // Black theme primary
        elevation: 4, // Added elevation for consistency
        title: Text(
          'Document Verification',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _accentColor, // Yellow accent for title
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _accentColor), // Yellow for icons
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Body is now just the scrollable content
      body: SingleChildScrollView(
        // Add bottom padding only if the action buttons are present
        padding: EdgeInsets.fromLTRB(16, 16, 16, isPending ? 100 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoCard(),
            SizedBox(height: 20),
            _buildDocumentSection(
              'Driver\'s License',
              widget.documentData['dl_front_url'],
              widget.documentData['dl_back_url'],
              widget.documentData['dl_number'],
            ),
            SizedBox(height: 20),
            _buildDocumentSection(
              'Aadhar Card',
              widget.documentData['aadhar_front_url'],
              widget.documentData['aadhar_back_url'],
              widget.documentData['aadhar_number'],
            ),
            SizedBox(height: 20),
            _buildDocumentSection(
              'PAN Card',
              widget.documentData['pan_front_url'],
              null,
              widget.documentData['pan_number'],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
      // ⭐️ Action Buttons are fixed at the bottom
      bottomNavigationBar: isPending ? _buildActionButtons() : null,
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900, // ⭐️ Dark Card Background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentColor.withOpacity(0.5), width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.2), // Yellow tint background
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: _accentColor, size: 35), // Yellow icon
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userData['name'] ?? 'Unknown User',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor, // White text on dark card
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.userData['email'] ?? 'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _secondaryTextColor, // Grey secondary text on dark card
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.documentData['verification_status']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.documentData['verification_status']?.toString().toUpperCase() ?? 'PENDING',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentSection(String title, String? frontImageUrl, String? backImageUrl, String? number) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade900, // ⭐️ Dark Card Background
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: _accentColor, size: 24), // Yellow Icon
                SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor, // White text on dark card
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (number != null && number.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.2), // Yellow tint
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accentColor, width: 1.5), // Yellow border
                ),
                child: Row(
                  children: [
                    Icon(Icons.numbers, color: _textColor, size: 20), // White Icon
                    SizedBox(width: 8),
                    Text(
                      'Number: ',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _textColor, // White text on tinted background
                      ),
                    ),
                    Text(
                      number,
                      style: GoogleFonts.poppins(
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 16),
            Row(
              children: [
                if (frontImageUrl != null)
                  Expanded(
                    child: _buildDocumentImage('Front Side', frontImageUrl),
                  ),
                if (frontImageUrl != null && backImageUrl != null) SizedBox(width: 12),
                if (backImageUrl != null)
                  Expanded(
                    child: _buildDocumentImage('Back Side', backImageUrl),
                  ),
                if (frontImageUrl == null && backImageUrl == null)
                  Expanded(
                    child: _buildNoImagePlaceholder('No images uploaded'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentImage(String label, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, _, __) => FullScreenImageViewer(imageUrl: imageUrl),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: _accentColor, width: 2), // Yellow border
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade800, // Dark image container
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: _accentColor, // Yellow loading indicator
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: _rejectColor, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Failed to load',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _rejectColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '$label (Tap to Zoom)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textColor, // White text on dark background
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder(String text) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: _secondaryTextColor, width: 2), // Grey border
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade900, // Dark placeholder background
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 50, color: _secondaryTextColor),
          SizedBox(height: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // Fixed Action Buttons (bottomNavigationBar content)
  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: _backgroundColor, // Black background
        border: Border(top: BorderSide(color: Colors.grey.shade700, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _approveDocuments,
              style: ElevatedButton.styleFrom(
                backgroundColor: _successColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isProcessing
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'APPROVE',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _showRejectionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _rejectColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'REJECT',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveDocuments() async {
    setState(() => _isProcessing = true);
    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      final now = Timestamp.now();

      await widget.docRef!.update({
        'verification_status': 'approved',
        'admin_approved': true,
        'admin_verified_by': adminUser?.uid,
        'admin_verified_at': now,
        'last_updated': now,
      });

      // ⭐️ Email Logic: Send approval email
      await _sendApprovalEmail();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Documents approved successfully!'),
          backgroundColor: _successColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error approving documents: $e'),
          backgroundColor: _rejectColor,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ⭐️ Enhanced Rejection Dialog with Dropdown and enforced input (includes overflow fix)
  void _showRejectionDialog() {
    // Local state for the dialog
    String? selectedReason;
    final rejectionDetailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to allow the dialog UI to update when the fields change
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            // Logic to disable REJECT button until both fields are valid
            final isRejectEnabled = selectedReason != null && rejectionDetailsController.text.trim().isNotEmpty;

            return AlertDialog(
              backgroundColor: Colors.white, // Keep background white for input contrast
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _rejectColor, width: 2)),
              title: Text(
                'Reject Documents',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: _rejectColor,
                ),
              ),
              // ⭐️ Layout Fix: Constrained width via a Container and ListView to prevent overflow
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9, // Ensures width respects screen size
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      'Select the primary issue and provide specific details:',
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                    SizedBox(height: 16),

                    // Dropdown for Rejection Reason (MANDATORY)
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      decoration: InputDecoration(
                        labelText: 'Select Issue',
                        labelStyle: TextStyle(color: Colors.grey),
                        fillColor: Colors.grey[100],
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor)), // Yellow border
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor.withOpacity(0.5))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 2)), // Black focus border
                      ),
                      dropdownColor: Colors.white,
                      style: GoogleFonts.poppins(color: Colors.black),
                      items: _rejectionReasons.map((String reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason, style: GoogleFonts.poppins(color: Colors.black)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateLocal(() {
                          selectedReason = newValue;
                        });
                      },
                    ),

                    SizedBox(height: 16),

                    // Text Field for Detailed Issue (MANDATORY)
                    TextField(
                      controller: rejectionDetailsController,
                      onChanged: (text) {
                        setStateLocal(() {}); // Rebuild to check validation for button state
                      },
                      maxLines: 3,
                      style: GoogleFonts.poppins(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Write specific details (MANDATORY)',
                        hintStyle: TextStyle(color: Colors.grey),
                        fillColor: Colors.grey[100],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _accentColor), // Yellow border
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _accentColor.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primaryColor, width: 2), // Black focus border
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Display close and REJECT
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CLOSE', style: GoogleFonts.poppins(color: Colors.grey[700])),
                ),
                ElevatedButton(
                  // ⭐️ The REJECT button is DISABLED if not select issue AND not write text
                  onPressed: isRejectEnabled ? () {
                    // Combine the reason and details into the internal controller
                    _rejectionController.text = 'Reason: $selectedReason\nDetails: ${rejectionDetailsController.text.trim()}';
                    Navigator.pop(context); // Close dialog
                    _rejectDocuments(); // Execute rejection logic
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRejectEnabled ? _rejectColor : Colors.grey,
                  ),
                  child: Text(
                    'REJECT',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _rejectDocuments() async {
    setState(() => _isProcessing = true);

    final rejectionReason = _rejectionController.text.trim();

    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      final now = Timestamp.now();

      await widget.docRef!.update({
        'verification_status': 'rejected',
        'admin_approved': false,
        'rejection_reason': rejectionReason,
        'admin_verified_by': adminUser?.uid,
        'admin_verified_at': now,
        'last_updated': now,
      });

      // ⭐️ Email Logic: Send rejection email
      await _sendRejectionEmail();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📝 Documents rejected with feedback.'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error rejecting documents: $e'),
          backgroundColor: _rejectColor,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
      _rejectionController.clear(); // Clear controller after use
    }
  }

  // --- Utility methods (unchanged or restored) ---

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return _successColor;
      case 'rejected':
        return _rejectColor;
      default:
        return _accentColor; // Pending status uses yellow accent
    }
  }

  // Placeholder for your existing EmailService logic (needed to compile)
  Future<void> _sendApprovalEmail() async {
    // This is a placeholder for your actual email service call.
    try {
      final success = await EmailService.sendEmail(
        recipientEmail: widget.userData['email'] ?? 'test@example.com',
        subject: '🎉 GearGo - Your Documents Have Been Verified!',
        htmlBody: '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Document Approved</title></head>
<body style="font-family: Arial, sans-serif;">
  <div style="max-width: 600px; margin: 0 auto; background: #222;">
    <div style="background: linear-gradient(135deg, #000 0%, #FFC107 100%); padding: 30px; text-align: center; color: white;">
      <h1 style="color: #000;">🚗 GearGo</h1>
      <p style="color: #000;">Car Rental Service</p>
    </div>
    <div style="padding: 30px; background: #121212; color: #fff;">
      <h2>Dear ${widget.userData['name'] ?? 'User'},</h2>
      <p>Great news! Your documents have been successfully verified by our admin team.</p>

      <div style="background: #333; padding: 20px; border-radius: 10px; margin: 20px 0; border: 1px solid #FFC107;">
        <h3>✅ Verification Status: APPROVED</h3>
        <p><strong>Approved Documents:</strong></p>
        <ul>
          <li>Driver's License: ${widget.documentData['dl_number']?.toUpperCase() ?? 'Not provided'}</li>
          <li>Aadhar Card: •••• ${widget.documentData['aadhar_number']?.substring(widget.documentData['aadhar_number'].length > 4 ? widget.documentData['aadhar_number'].length - 4 : 0) ?? 'Not provided'}</li>
          <li>PAN Card: ${widget.documentData['pan_number']?.toUpperCase() ?? 'Not provided'}</li>
        </ul>
        <p><strong>Approved On:</strong> ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}</p>
      </div>

      <p>You can now book cars instantly on GearGo!</p>

      <div style="background: #1e3a1e; color: #a5d6a5; padding: 15px; border-radius: 8px; margin: 20px 0;">
        <h4>🎊 What's Next?</h4>
        <p>• Browse available cars</p>
        <p>• Book your preferred vehicle</p>
        <p>• Enjoy your ride!</p>
      </div>

      <p>Thank you for choosing GearGo!</p>
      <p>Best regards,<br><strong>GearGo Team</strong></p>
    </div>
  </div>
</body>
</html>
        ''',
      );

      if (!success) {
        print('Failed to send approval email');
      }
    } catch (e) {
      print('Error sending approval email: $e');
    }
  }

  Future<void> _sendRejectionEmail() async {
    // This is a placeholder for your actual email service call.
    try {
      final success = await EmailService.sendEmail(
        recipientEmail: widget.userData['email'] ?? 'test@example.com',
        subject: '📝 GearGo - Document Verification Update',
        htmlBody: '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Document Rejected</title></head>
<body style="font-family: Arial, sans-serif;">
  <div style="max-width: 600px; margin: 0 auto; background: #222;">
    <div style="background: linear-gradient(135deg, #000 0%, #FFC107 100%); padding: 30px; text-align: center; color: white;">
      <h1 style="color: #000;">🚗 GearGo</h1>
      <p style="color: #000;">Car Rental Service</p>
    </div>
    <div style="padding: 30px; background: #121212; color: #fff;">
      <h2>Dear ${widget.userData['name'] ?? 'User'},</h2>
      <p>We've reviewed your submitted documents and need some additional information.</p>

      <div style="background: #333; padding: 20px; border-radius: 10px; margin: 20px 0; border: 1px solid #FFC107;">
        <h3>📋 Verification Status: NEEDS REVISION</h3>
        <p><strong>Admin Feedback:</strong></p>
        <div style="background: #444; color: #FFC107; padding: 15px; border-radius: 8px;">
          <p><em>"${_rejectionController.text.trim()}"</em></p>
        </div>
        <p><strong>Reviewed On:</strong> ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}</p>
      </div>

      <div style="background: #444; padding: 15px; border-radius: 8px; margin: 20px 0;">
        <h4>🔧 Next Steps:</h4>
        <p>• Please review the admin feedback above</p>
        <p>• Update your documents in the app</p>
        <p>• Resubmit for verification</p>
      </div>

      <p>If you have any questions, please contact our support team.</p>

      <p>Best regards,<br><strong>GearGo Team</strong></p>
    </div>
  </div>
  </div>
</body>
</html>
        ''',
      );

      if (!success) {
        print('Failed to send rejection email');
      }
    } catch (e) {
      print('Error sending rejection email: $e');
    }
  }
}
