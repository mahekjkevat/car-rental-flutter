import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appwrite/appwrite.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class AddUpdateDocumentsPage extends StatefulWidget {
  @override
  _AddUpdateDocumentsPageState createState() => _AddUpdateDocumentsPageState();
}

class _AddUpdateDocumentsPageState extends State<AddUpdateDocumentsPage> {
  final ImagePicker _picker = ImagePicker();

  // Appwrite configuration
  Client client = Client();
  late Storage storage;
  final String _appwriteProjectId = '67e8384a0024f79666ba';
  final String _appwriteBucketId = '67e98ce6003722774617';

  // Document files
  XFile? _dlFront;
  XFile? _dlBack;
  XFile? _aadharFront;
  XFile? _aadharBack;
  XFile? _panFront;

  // Document numbers
  TextEditingController _dlController = TextEditingController();
  TextEditingController _aadharController = TextEditingController();
  TextEditingController _panController = TextEditingController();

  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;

  // Existing document URLs
  String? _existingDlFrontUrl;
  String? _existingDlBackUrl;
  String? _existingAadharFrontUrl;
  String? _existingAadharBackUrl;
  String? _existingPanFrontUrl;

  // User info for email
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    // Initialize Appwrite
    client
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject(_appwriteProjectId);
    storage = Storage(client);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Load user profile data
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['name'] ?? 'User';
            _userEmail = userData['email'] ?? user.email ?? '';
          });
        }

        // Load existing documents
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('personal_documents')
            .doc('verification_status')
            .get();

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          setState(() {
            _dlController.text = data['dl_number'] ?? '';
            _aadharController.text = data['aadhar_number'] ?? '';
            _panController.text = data['pan_number'] ?? '';

            _existingDlFrontUrl = data['dl_front_url'];
            _existingDlBackUrl = data['dl_back_url'];
            _existingAadharFrontUrl = data['aadhar_front_url'];
            _existingAadharBackUrl = data['aadhar_back_url'];
            _existingPanFrontUrl = data['pan_front_url'];
          });
        }
      } catch (e) {
        print('Error loading data: $e');
      }
    }
    setState(() => _isLoading = false);
  }

  // Upload image to Appwrite Storage
  Future<String?> _uploadImage(XFile image, String documentType) async {
    try {
      final inputFile = InputFile.fromPath(path: image.path);
      final file = await storage.createFile(
        bucketId: _appwriteBucketId,
        fileId: ID.unique(),
        file: inputFile,
      );
      final imageUrl = 'https://cloud.appwrite.io/v1/storage/buckets/${file.bucketId}/files/${file.$id}/view?project=$_appwriteProjectId';
      return imageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  // Full Screen Image View
  void _showFullScreenImage(XFile? imageFile, String? imageUrl, String title) {
    if (imageFile == null && imageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Stack(
          children: [
            // Image Container
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageFile != null
                    ? Image.file(File(imageFile.path), fit: BoxFit.contain)
                    : Image.network(imageUrl!, fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
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
                          Icon(Icons.error, color: Colors.white, size: 50),
                          SizedBox(height: 10),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Close Button
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Title
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
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

  Widget _buildImageContainer(String label, XFile? image, String? existingImageUrl, VoidCallback onTap, VoidCallback onView) {
    bool hasImage = image != null || existingImageUrl != null;

    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            // Image Container
            GestureDetector(
              onTap: hasImage ? onView : onTap,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasImage ? Colors.blue[700]! : Colors.grey[300]!,
                    width: hasImage ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: hasImage ? Colors.blue[50]! : Colors.grey[50],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasImage)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[700]!, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: image != null
                              ? Image.file(File(image.path), fit: BoxFit.cover)
                              : Image.network(existingImageUrl!, fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.error, color: Colors.red, size: 30);
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Icon(Icons.photo_library, size: 40, color: Colors.grey[400]),
                      ),

                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasImage ? Colors.blue[700]! : Colors.grey[600]!,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      hasImage ? '✓ Uploaded' : 'Tap to upload',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: hasImage ? Colors.blue[700]! : Colors.grey[600],
                        fontWeight: hasImage ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),

            // Action Buttons
            Row(
              children: [
                // Update/Add Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(hasImage ? Icons.edit : Icons.add_photo_alternate, size: 12),
                        SizedBox(width: 4),
                        Text(
                          hasImage ? 'Update' : 'Add',
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 4),

                // View Button (only when image exists)
                if (hasImage)
                  Container(
                    width: 40,
                    child: ElevatedButton(
                      onPressed: onView,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Icon(Icons.visibility, size: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required List<XFile?> images,
    required List<String> labels,
    required List<VoidCallback> onTapCallbacks,
    required TextEditingController controller,
    required String validationHint,
    required int maxLength,
    required String regexPattern,
    required List<String?> existingImageUrls,
  }) {
    bool allImagesUploaded = images.every((image) => image != null) ||
        existingImageUrls.every((url) => url != null);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: allImagesUploaded ? Colors.green : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      allImagesUploaded ? Icons.verified : Icons.pending_actions,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: allImagesUploaded ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      allImagesUploaded ? 'COMPLETED' : 'PENDING',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Image containers in row
              Row(
                children: List.generate(labels.length, (index) {
                  return _buildImageContainer(
                    labels[index],
                    images[index],
                    existingImageUrls[index],
                    onTapCallbacks[index],
                        () => _showFullScreenImage(images[index], existingImageUrls[index], '${title} - ${labels[index]}'),
                  );
                }),
              ),
              SizedBox(height: 20),

              // Text field for document number
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${title.split(' ')[0]} Number',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      maxLength: maxLength,
                      decoration: InputDecoration(
                        hintText: validationHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[200]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        counterText: '',
                        suffixIcon: controller.text.isNotEmpty && _validateField(controller.text, maxLength, regexPattern)
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: GoogleFonts.poppins(fontSize: 16),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 4),
                    if (controller.text.isNotEmpty)
                      Text(
                        _validateField(controller.text, maxLength, regexPattern)
                            ? '✓ Valid format'
                            : '✗ Invalid format',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _validateField(controller.text, maxLength, regexPattern)
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
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

  bool _validateField(String value, int maxLength, String regexPattern) {
    if (value.length != maxLength) return false;
    if (regexPattern.isNotEmpty) {
      return RegExp(regexPattern).hasMatch(value);
    }
    return true;
  }

  Future<void> _pickImage(int documentType, {bool fromGallery = false}) async {
    final XFile? image = await _picker.pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        switch (documentType) {
          case 1: _dlFront = image; break;
          case 2: _dlBack = image; break;
          case 3: _aadharFront = image; break;
          case 4: _aadharBack = image; break;
          case 5: _panFront = image; break;
        }
      });
    }
  }

  void _showImageSourceDialog(int documentType) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Image Source',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(documentType, fromGallery: false);
                  },
                ),
                _buildSourceButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(documentType, fromGallery: true);
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: IconButton(
            icon: Icon(icon, size: 30, color: Colors.blue[700]),
            onPressed: onTap,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.blue[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // DL Validation: Exactly 16 characters including spaces/hyphens
  bool _validateDL(String dl) {
    return dl.length == 16;
  }

  // Aadhar Validation: Exactly 12 digits
  bool _validateAadhar(String aadhar) {
    return aadhar.length == 12 && RegExp(r'^\d+$').hasMatch(aadhar);
  }

  // PAN Validation: Exactly 10 characters in format ABCDE1234F
  bool _validatePAN(String pan) {
    return pan.length == 10 && RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan);
  }

  bool _allDocumentsValid() {
    bool imagesValid = _dlFront != null || _existingDlFrontUrl != null;
    imagesValid &= _dlBack != null || _existingDlBackUrl != null;
    imagesValid &= _aadharFront != null || _existingAadharFrontUrl != null;
    imagesValid &= _aadharBack != null || _existingAadharBackUrl != null;
    imagesValid &= _panFront != null || _existingPanFrontUrl != null;

    bool numbersValid = _validateDL(_dlController.text) &&
        _validateAadhar(_aadharController.text) &&
        _validatePAN(_panController.text);

    return imagesValid && numbersValid;
  }

  Future<void> _sendCustomerEmail() async {
    try {
      final success = await EmailService.sendEmail(
        recipientEmail: _userEmail,
        subject: '🚗 GearGo - Document Verification Request Submitted Successfully!',
        htmlBody: '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Document Verification</title></head>
<body style="font-family: Arial, sans-serif;">
  <div style="max-width: 600px; margin: 0 auto; background: #f8f9fa;">
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; color: white;">
      <h1>🚗 GearGo</h1>
      <p>Car Rental Service</p>
    </div>
    <div style="padding: 30px;">
      <h2>Dear $_userName,</h2>
      <p>Thank you for submitting your document verification request to GearGo!</p>
      
      <div style="background: white; padding: 20px; border-radius: 10px; margin: 20px 0;">
        <h3>📋 Verification Request Details</h3>
        <p><strong>Documents Submitted:</strong></p>
        <ul>
          <li>Driver's License: ${_dlController.text.isNotEmpty ? _dlController.text.toUpperCase() : 'Not provided'}</li>
          <li>Aadhar Card: ${_aadharController.text.isNotEmpty ? '•••• ${_aadharController.text.substring(_aadharController.text.length - 4)}' : 'Not provided'}</li>
          <li>PAN Card: ${_panController.text.isNotEmpty ? _panController.text.toUpperCase() : 'Not provided'}</li>
        </ul>
        <p><strong>Status:</strong> Pending Admin Verification</p>
        <p><strong>Submitted:</strong> ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}</p>
      </div>
      
      <p>Our admin team will review your documents and verify them within 24-48 hours.</p>
      <p>You will receive a notification once your documents are verified.</p>
      
      <div style="background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 20px 0;">
        <h4>📝 Next Steps:</h4>
        <p>• Admin verification process</p>
        <p>• Document validation check</p>
        <p>• Verification status update</p>
      </div>
      
      <p>If you have any questions, please contact our support team.</p>
      <p>Best regards,<br><strong>GearGo Team</strong></p>
    </div>
  </div>
</body>
</html>
        ''',
      );
      if (success) {
        print('✅ Customer email sent successfully to $_userEmail');
      } else {
        print('❌ Failed to send customer email');
      }
    } catch (e) {
      print('❌ Customer email error: $e');
    }
  }

  Future<void> _sendAdminNotification() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create admin notification
      await FirebaseFirestore.instance
          .collection('admin_notifications')
          .add({
        'type': 'document_verification',
        'user_id': user.uid,
        'user_name': _userName,
        'user_email': _userEmail,
        'dl_number': _dlController.text.toUpperCase(),
        'aadhar_number': _aadharController.text,
        'pan_number': _panController.text.toUpperCase(),
        'status': 'pending',
        'submitted_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Admin notification created successfully');
    } catch (e) {
      print('❌ Error creating admin notification: $e');
    }
  }

  Future<void> _saveDocuments() async {
    if (!_allDocumentsValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload all documents and enter valid numbers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Upload new images to Appwrite, use existing ones if not updated
      String? dlFrontUrl = _dlFront != null ? await _uploadImage(_dlFront!, 'dl_front') : _existingDlFrontUrl;
      String? dlBackUrl = _dlBack != null ? await _uploadImage(_dlBack!, 'dl_back') : _existingDlBackUrl;
      String? aadharFrontUrl = _aadharFront != null ? await _uploadImage(_aadharFront!, 'aadhar_front') : _existingAadharFrontUrl;
      String? aadharBackUrl = _aadharBack != null ? await _uploadImage(_aadharBack!, 'aadhar_back') : _existingAadharBackUrl;
      String? panFrontUrl = _panFront != null ? await _uploadImage(_panFront!, 'pan_front') : _existingPanFrontUrl;

      // Save to Firestore with admin verification fields
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('personal_documents')
          .doc('verification_status')
          .set({
        'dl_number': _dlController.text.toUpperCase(),
        'aadhar_number': _aadharController.text,
        'pan_number': _panController.text.toUpperCase(),
        'dl_front_url': dlFrontUrl,
        'dl_back_url': dlBackUrl,
        'aadhar_front_url': aadharFrontUrl,
        'aadhar_back_url': aadharBackUrl,
        'pan_front_url': panFrontUrl,
        'document_status': 'pending', // Changed from boolean to string status
        'verification_status': 'pending', // New field for admin verification
        'admin_approved': false, // New field for admin confirmation
        'admin_verified_by': null, // Will be set by admin
        'admin_verified_at': null, // Will be set by admin
        'document_time': FieldValue.serverTimestamp(),
        'last_updated': FieldValue.serverTimestamp(),
        'submission_count': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Send admin notification
      await _sendAdminNotification();

      // Send customer email
      await _sendCustomerEmail();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Documents submitted successfully! Verification request sent to admin.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Show success dialog
      _showSuccessDialog();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error saving documents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.verified_user, size: 60, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Request Submitted!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '📋 Your document verification request has been submitted successfully!',
              style: GoogleFonts.poppins(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '📧 Confirmation email sent to:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: GoogleFonts.poppins(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              '⏳ Our admin team will review your documents within 24-48 hours.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue[700]),
              SizedBox(height: 20),
              Text(
                'Loading your documents...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        title: Text('Document Verification', style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: ListView(
              children: [
                // Header Info
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, size: 40, color: Colors.blue[700]),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Document Verification',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Upload all required documents for admin verification',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                _buildDocumentCard(
                  title: "Driver's License",
                  images: [_dlFront, _dlBack],
                  labels: ['Front Side', 'Back Side'],
                  onTapCallbacks: [
                        () => _showImageSourceDialog(1),
                        () => _showImageSourceDialog(2),
                  ],
                  controller: _dlController,
                  validationHint: '16 characters (e.g., DL0420110169641)',
                  maxLength: 16,
                  regexPattern: r'^[A-Z0-9\s\-]{16}$',
                  existingImageUrls: [_existingDlFrontUrl, _existingDlBackUrl],
                ),
                SizedBox(height: 20),
                _buildDocumentCard(
                  title: "Aadhar Card",
                  images: [_aadharFront, _aadharBack],
                  labels: ['Front Side', 'Back Side'],
                  onTapCallbacks: [
                        () => _showImageSourceDialog(3),
                        () => _showImageSourceDialog(4),
                  ],
                  controller: _aadharController,
                  validationHint: '12 digits (e.g., 123456789012)',
                  maxLength: 12,
                  regexPattern: r'^\d{12}$',
                  existingImageUrls: [_existingAadharFrontUrl, _existingAadharBackUrl],
                ),
                SizedBox(height: 20),
                _buildDocumentCard(
                  title: "PAN Card",
                  images: [_panFront],
                  labels: ['Front Side'],
                  onTapCallbacks: [
                        () => _showImageSourceDialog(5),
                  ],
                  controller: _panController,
                  validationHint: '10 characters (e.g., ABCDE1234F)',
                  maxLength: 10,
                  regexPattern: r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
                  existingImageUrls: [_existingPanFrontUrl],
                ),
                SizedBox(height: 100), // Extra space for bottom button
              ],
            ),
          ),

          // Save Button at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _allDocumentsValid() && !_isSaving ? _saveDocuments : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _allDocumentsValid() ? Colors.green : Colors.grey[400],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Submitting...',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'SUBMIT FOR VERIFICATION',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
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
          ),
        ],
      ),
    );
  }
}

// Email Service Class (Keep your existing EmailService class as is)
class EmailService {
  static final String gmailEmail = 'hetpaa0208@gmail.com';
  static final String appPassword = 'vbcqbtomhsrjelcs';

  static Future<bool> sendEmail({
    required String recipientEmail,
    required String subject,
    required String htmlBody,
    String? textBody,
  }) async {
    try {
      // Your existing email sending implementation
      print('📧 Email sent to: $recipientEmail');
      print('📝 Subject: $subject');
      return true; // Simulate success for now
    } catch (e) {
      print('❌ Email error: $e');
      return false;
    }
  }
}