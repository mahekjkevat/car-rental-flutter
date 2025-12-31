import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'EmailService.dart';

// --- THEME DEFINITIONS (Dark Mode) ---
const Color _backgroundColor = Color(0xFF121212); // Primary background
const Color _cardColor = Color(0xFF1E1E1E); // Card/surface background
const Color _primaryColor = Color(0xFF42A5F5); // Accent Blue (for titles/icons)
const Color _accentColor = Color(0xFFFFC107); // Gold/Yellow (for emphasis/status)
const Color _textColorPrimary = Colors.white;
const Color _textColorSecondary = Color(0xFFB0B0B0); // Light grey for secondary text
const Color _successColor = Color(0xFF4CAF50); // Green for Approve
const Color _rejectColor = Color(0xFFE53935); // Red for Reject

// Rejection Reasons (for chips)
const List<String> _rejectionReasons = [
  "Blurry Images",
  "Low Res Pic",
  "Incomplete Doc",
  "Wrong Model/VIN",
  "Price Error",
  "Incorrect Docs",
];

class CarDetailPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> carData;
  final DocumentReference? docRef;

  const CarDetailPage({
    Key? key,
    required this.userId,
    required this.userData,
    required this.carData,
    this.docRef,
  }) : super(key: key);

  @override
  _CarDetailPageState createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _rejectionController = TextEditingController();
  bool _isProcessing = false;
  String? _selectedRejectionReason; // State for chip selection in dialog

  // --- FUNCTIONALITY: Dialogs and Status Updates ---

  // NOTE: This method now requires confirmation before executing the update logic.
  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirm Car Approval',
            style: GoogleFonts.poppins(color: _textColorPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to approve this listing? The owner will be notified.',
            style: GoogleFonts.poppins(color: _textColorSecondary),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: _textColorSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _successColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 5,
              ),
              child: Text(
                'Approve',
                style: GoogleFonts.poppins(
                  color: _textColorPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                _verifyCar(); // Call the verification logic
              },
            ),
          ],
        );
      },
    );
  }

  // NOTE: This method is updated to include chips and custom text as requested.
  Future<void> _showRejectionDialog() async {
    _rejectionController.clear();
    _selectedRejectionReason = null;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Reject Car Listing',
                style: GoogleFonts.poppins(
                  color: _rejectColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(
                      'Select a primary reason or type custom feedback:',
                      style: GoogleFonts.poppins(color: _textColorSecondary),
                    ),
                    SizedBox(height: 15),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _rejectionReasons.map((reason) {
                        bool isSelected = _selectedRejectionReason == reason;
                        return ChoiceChip(
                          label: Text(reason),
                          selected: isSelected,
                          selectedColor: _rejectColor.withOpacity(0.8),
                          backgroundColor: _textColorSecondary.withOpacity(0.1),
                          labelStyle: GoogleFonts.poppins(
                            color: isSelected ? _textColorPrimary : _textColorSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedRejectionReason = selected ? reason : null;
                              _rejectionController.clear();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    // Custom description field
                    TextField(
                      controller: _rejectionController,
                      style: GoogleFonts.poppins(color: _textColorPrimary),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Type custom feedback here...',
                        labelStyle: GoogleFonts.poppins(color: _textColorSecondary),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _rejectColor, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && _selectedRejectionReason != null) {
                          setState(() {
                            _selectedRejectionReason = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: _textColorSecondary),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rejectColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Reject Listing',
                    style: GoogleFonts.poppins(
                      color: _textColorPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    String customReason = _rejectionController.text.trim();
                    String finalReason = customReason.isNotEmpty
                        ? customReason
                        : (_selectedRejectionReason ?? '');

                    if (finalReason.isNotEmpty) {
                      Navigator.of(dialogContext).pop();
                      _rejectCar(finalReason); // Call rejection logic with the reason
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Please select a reason or enter custom feedback.'),
                        backgroundColor: _rejectColor,
                      ));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // NOTE: _verifyCar updated to be called after confirmation dialog, and takes no arguments.
  Future<void> _verifyCar() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      final now = Timestamp.now();

      await widget.docRef!.update({
        'status': 'verified',
        'verified_at': now,
        'verified_by': adminUser?.uid,
        'last_updated': now,
        'label':widget.userData['name'] ?? 'Unknown User'

        //check label are save or not in the db code

      });

      await _sendVerificationEmail();
      await _addToMainCollection();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Car verified successfully!'),
          backgroundColor: _successColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error verifying car: $e'),
          backgroundColor: _rejectColor,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // NOTE: _rejectCar updated to accept the reason from the new dialog.
  Future<void> _rejectCar(String reason) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      final now = Timestamp.now();

      await widget.docRef!.update({
        'status': 'rejected',
        'rejection_reason': reason, // Use the reason passed from the dialog
        'rejected_at': now,
        'rejected_by': adminUser?.uid,
        'last_updated': now,
      });

      await _sendRejectionEmail(reason); // Pass reason to email service

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📝 Car rejected with feedback.'),
          backgroundColor: _accentColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error rejecting car: $e'),
          backgroundColor: _rejectColor,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // NOTE: _sendVerificationEmail remains largely the same, just updated to use new colors/styling
  Future<void> _sendVerificationEmail() async {
    try {
      final String carName = '${widget.carData['car_name'] ?? 'N/A'} - ${widget.carData['car_brand'] ?? 'N/A'}';
      final success = await EmailService.sendEmail(
        recipientEmail: widget.userData['email'],
        subject: '🎉 GearGo - Your Car Has Been Verified!',
        htmlBody: '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Car Verified</title></head>
<body style="font-family: 'Poppins', Arial, sans-serif; background: #f8f9fa;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
    <div style="background: linear-gradient(135deg, #42A5F5 0%, #0D47A1 100%); padding: 30px; text-align: center; color: white; border-radius: 12px 12px 0 0;">
      <h1 style="margin: 0; font-size: 28px;">🚗 GearGo Verification</h1>
    </div>
    <div style="padding: 30px;">
      <h2 style="color: #4CAF50;">Dear ${widget.userData['name']},</h2>
      <p style="color: #333;">Great news! Your car listing has been successfully **APPROVED** by our admin team.</p>
      
      <div style="border: 1px solid #4CAF50; padding: 20px; border-radius: 10px; margin: 20px 0; background: #f0fff0;">
        <h3 style="color: #4CAF50; margin-top: 0;">✅ Listing Status: APPROVED</h3>
        <p style="color: #333;"><strong>Car:</strong> ${carName}</p>
        <p style="color: #333;">Your car is now **LIVE** and available for bookings!</p>
      </div>
      
      <p style="color: #333;">Thank you for partnering with GearGo!</p>
      <p style="color: #333;">Best regards,<br><strong>GearGo Team</strong></p>
    </div>
  </div>
</body>
</html>
        ''',
      );

      if (!success) {
        print('Failed to send verification email');
      }
    } catch (e) {
      print('Error sending verification email: $e');
    }
  }

  // NOTE: _sendRejectionEmail updated to accept the rejection reason.
  Future<void> _sendRejectionEmail(String reason) async {
    try {
      final String carName = '${widget.carData['car_name'] ?? 'N/A'} - ${widget.carData['car_brand'] ?? 'N/A'}';
      final success = await EmailService.sendEmail(
        recipientEmail: widget.userData['email'],
        subject: '⚠️ GearGo - Revision Needed for Car Listing',
        htmlBody: '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Car Rejected</title></head>
<body style="font-family: 'Poppins', Arial, sans-serif; background: #f8f9fa;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
    <div style="background: linear-gradient(135deg, #42A5F5 0%, #0D47A1 100%); padding: 30px; text-align: center; color: white; border-radius: 12px 12px 0 0;">
      <h1 style="margin: 0; font-size: 28px;">🚗 GearGo Verification</h1>
    </div>
    <div style="padding: 30px;">
      <h2 style="color: #E53935;">Dear ${widget.userData['name']},</h2>
      <p style="color: #333;">We've reviewed your car listing for the **${carName}** and require a revision before approval.</p>
      
      <div style="border: 1px solid #FFC107; padding: 20px; border-radius: 10px; margin: 20px 0; background: #fffde7;">
        <h3 style="color: #FFC107; margin-top: 0;">📋 Revision Required</h3>
        <p style="color: #333;"><strong>Admin Feedback:</strong></p>
        <div style="background: #E53935; color: white; padding: 15px; border-radius: 8px;">
          <p style="margin: 0;"><em>"${reason}"</em></p>
        </div>
      </div>
      
      <p style="color: #333;">Please address the feedback in the app and resubmit your car for verification.</p>
      <p style="color: #333;">Best regards,<br><strong>GearGo Team</strong></p>
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

  // NOTE: This logic remains the same.
  Future<void> _addToMainCollection() async {
    try {
      await _firestore.collection('CarData').doc(widget.carData['randomID']).set({
        ...widget.carData,
        'status': 'verified',
        'verified_at': FieldValue.serverTimestamp(),
        'user_id': widget.userId,
        'avg_rating': 0.0,
        'total_reviews': 0,
        'is_available': true,
      });
    } catch (e) {
      print('Error adding to main collection: $e');
    }
  }

  // --- UI/WIDGET HELPERS ---

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'verified':
        return _successColor;
      case 'rejected':
        return _rejectColor;
      default:
        return _accentColor;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
    }
    return 'N/A';
  }

  // NOTE: Updated UI for dark theme
  Widget _buildUserInfoCard() {
    return Card(
      elevation: 8,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.2),
                border: Border.all(color: _primaryColor, width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: _primaryColor, size: 35),
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
                      color: _textColorPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Email: ${widget.userData['email'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _textColorSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mobile: ${widget.carData['mobile'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _textColorSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.carData['status']),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.carData['status']?.toString().toUpperCase() ?? 'PENDING',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.black,
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
    );
  }

  // NOTE: Updated UI for dark theme
  Widget _buildCarImages() {
    List<String> imageUrls = [
      widget.carData['car_image1'],
      widget.carData['car_image2'],
      widget.carData['car_image3'],
      widget.carData['car_image4'],
    ].where((url) => url != null && url.isNotEmpty).cast<String>().toList();

    return Card(
      elevation: 4,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: _primaryColor, size: 24),
                SizedBox(width: 12),
                Text(
                  'Car Images (Tap to Zoom)',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return _buildCarImage(imageUrls[index], 'Image ${index + 1}');
              },
            ),
          ],
        ),
      ),
    );
  }

  // NOTE: Updated UI for dark theme
  Widget _buildCarImage(String imageUrl, String label) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageUrl, label),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _textColorSecondary.withOpacity(0.2), width: 1),
          color: _cardColor.withOpacity(0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(Icons.broken_image, color: _rejectColor, size: 40),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textColorPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NOTE: Updated UI for dark theme
  Widget _buildCarDetailsCard() {
    return Card(
      elevation: 4,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: _primaryColor, size: 24),
                SizedBox(width: 12),
                Text(
                  'Car Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary,
                  ),
                ),
              ],
            ),
            Divider(color: _textColorSecondary.withOpacity(0.2), height: 30),
            _buildDetailRow('Car Name', widget.carData['car_name'] ?? 'N/A'),
            _buildDetailRow('Brand', widget.carData['car_brand'] ?? 'N/A'),
            _buildDetailRow('Fuel Type', widget.carData['fuel_type'] ?? 'N/A'),
            _buildDetailRow('Seats', '${widget.carData['no_of_seats'] ?? '0'} People'),
            _buildDetailRow('Chassis No', widget.carData['chassis_no'] ?? 'N/A'),
            _buildDetailRow('Engine No', widget.carData['engine_no'] ?? 'N/A'),
            _buildDetailRow('Location', widget.carData['village'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  // NOTE: Updated UI for dark theme
  Widget _buildFeaturesCard() {
    List<String> features = [
      widget.carData['features1'],
      widget.carData['features2'],
      widget.carData['features3'],
      widget.carData['features4'],
      widget.carData['features5'],
      widget.carData['features6'],
    ].where((feature) => feature != null && feature.isNotEmpty).cast<String>().toList();

    return Card(
      elevation: 4,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: _primaryColor, size: 24),
                SizedBox(width: 12),
                Text(
                  'Features',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary,
                  ),
                ),
              ],
            ),
            Divider(color: _textColorSecondary.withOpacity(0.2), height: 30),
            if (features.isEmpty)
              Text(
                'No features specified',
                style: GoogleFonts.poppins(color: _textColorSecondary),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: features.map((feature) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _primaryColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      feature,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // NOTE: Updated UI for dark theme
  Widget _buildPricingCard() {
    return Card(
      elevation: 4,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: _primaryColor, size: 24),
                SizedBox(width: 12),
                Text(
                  'Pricing Plans',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary,
                  ),
                ),
              ],
            ),
            Divider(color: _textColorSecondary.withOpacity(0.2), height: 30),
            _buildPriceRow('Basic Plan', widget.carData['basic_price']),
            _buildPriceRow('Plus Plan', widget.carData['plus_price']),
            _buildPriceRow('Max Plan', widget.carData['max_price']),
          ],
        ),
      ),
    );
  }

  // NOTE: Updated UI for dark theme
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _textColorPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: _textColorSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NOTE: Updated UI for dark theme
  Widget _buildPriceRow(String plan, dynamic price) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            plan,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: _textColorPrimary,
            ),
          ),
          Text(
            '₹${price?.toString() ?? '0'}/day',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: _successColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // NOTE: Fixed button UI (new implementation for bottomNavigationBar)
  Widget _buildActionButtons() {
    // Only show buttons if the car is pending
    if (widget.carData['status'] != 'pending') {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                // Calls confirmation dialog first
                onPressed: _isProcessing ? null : _showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _successColor,
                  foregroundColor: _textColorPrimary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: _isProcessing
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_textColorPrimary),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 20, color: _textColorPrimary),
                    SizedBox(width: 8),
                    Text(
                      'APPROVE CAR',
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
                // Calls rejection dialog first
                onPressed: _isProcessing ? null : _showRejectionDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rejectColor,
                  foregroundColor: _textColorPrimary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, size: 20, color: _textColorPrimary),
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
      ),
    );
  }

  // NOTE: Updated UI for dark theme
  void _showFullScreenImage(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(Icons.broken_image, color: _textColorPrimary, size: 60),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.close, color: _textColorPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: _textColorPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 4,
        title: Text(
          'Car Details Verification',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textColorPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // 1. Action buttons fixed at the bottom
      bottomNavigationBar: widget.carData['status'] == 'pending' ? _buildActionButtons() : null,

      body: _isProcessing
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_accentColor)))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoCard(),
            SizedBox(height: 20),
            _buildCarImages(),
            SizedBox(height: 20),
            _buildCarDetailsCard(),
            SizedBox(height: 20),
            _buildFeaturesCard(),
            SizedBox(height: 20),
            _buildPricingCard(),
            SizedBox(height: 20),
            // Add extra padding at the bottom for content to scroll above the fixed navbar
            SizedBox(height: widget.carData['status'] == 'pending' ? 100 : 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }
}
