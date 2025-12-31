import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'CustomNotificationClass.dart';
import 'HomePage.dart';


class AddDamageReportUser extends StatefulWidget {
  final String carBookingId;

  const AddDamageReportUser({super.key, required this.carBookingId});

  @override
  State<AddDamageReportUser> createState() => _AddDamageReportUserState();
}

class _AddDamageReportUserState extends State<AddDamageReportUser> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedDamageType;
  File? _damageImage;
  bool _isLoading = true; // Set to true initially to show loading indicator
  String? _userName;
  String? _userMobile;

  // New state variables to handle existing report
  DocumentSnapshot? _existingReport;
  String? _existingImageUrl;
  bool _hasExistingReport = false;

  final ImagePicker _picker = ImagePicker();

  // Appwrite configuration
  Client client = Client();
  late Storage storage;
  final String _appwriteProjectId = '67e8384a0024f79666ba';
  final String _appwriteBucketId = '67e98ce6003722774617';

  final List<String> _damageTypes = [
    'Scratch',
    'Dent',
    'Broken Glass',
    'Puncture',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize Appwrite client and storage
    client
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject(_appwriteProjectId);
    storage = Storage(client);

    // Call the function to load the existing report and user data
    _loadDamageReportAndUserData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // A single function to load both user data and existing damage report
  Future<void> _loadDamageReportAndUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        // Use a custom message box instead of ScaffoldMessenger for consistency

        CustomNotificationClass.MahekCustomNotification(
          context,
          "Error",
          "User not authenticated.",
          HomePage(),
          logoIcon: Icons.check_circle,
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch user details
      final userDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .collection('car_booking')
              .doc(widget.carBookingId)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          setState(() {
            _userName = data?['userName'];
            _userMobile = data?['userMobile'];
          });
        }
      }

      // Check for an existing damage report
      final reportDocs =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .collection('car_booking')
              .doc(widget.carBookingId)
              .collection('damage_report')
              .get();

      if (reportDocs.docs.isNotEmpty) {
        // Report exists, load the data
        final reportDoc = reportDocs.docs.first;
        final reportData = reportDoc.data();

        if (mounted) {
          setState(() {
            _hasExistingReport = true;
            _existingReport = reportDoc;
            _selectedDamageType = reportData['damageType'];
            _descriptionController.text = reportData['description'];
            _existingImageUrl = reportData['imageurl'];
          });
        }
      } else {
        // No report exists, set default state
        if (mounted) {
          setState(() {
            _hasExistingReport = false;
            _selectedDamageType = 'Scratch'; // Default damage type
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomNotificationClass.MahekCustomNotification(
          context,
          "Error",
          "Failed to load data: $e",
          const HomePage(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _damageImage = File(pickedFile.path);
        _existingImageUrl =
            null; // Clear existing image URL when a new image is picked
      });
    }
  }

  // Upload image to Appwrite Storage
  Future<String?> _uploadImage() async {
    if (_damageImage == null) return null;

    try {
      final inputFile = InputFile.fromPath(path: _damageImage!.path);
      final file = await storage.createFile(
        bucketId: _appwriteBucketId,
        fileId: ID.unique(),
        file: inputFile,
      );
      final imageUrl =
          'https://cloud.appwrite.io/v1/storage/buckets/${file.bucketId}/files/${file.$id}/view?project=$_appwriteProjectId';
      return imageUrl;
    } catch (e) {
      if (mounted) {
        CustomNotificationClass.MahekCustomNotification(
          context,
          "Error",
          "Failed to upload image: $e",
          const HomePage(),
        );
      }
      return null;
    }
  }

  // Submit or update the damage report to Firestore
  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate() &&
        (_damageImage != null || _existingImageUrl != null)) {
      if (_userName == null || _userMobile == null) {
        CustomNotificationClass.MahekCustomNotification(
          context,
          "Error",
          "User data not available. Please try again.",
          const HomePage(),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl = _existingImageUrl;
        if (_damageImage != null) {
          imageUrl = await _uploadImage();
          if (imageUrl == null) {
            throw Exception('Image upload failed.');
          }
        }

        final user = FirebaseAuth.instance.currentUser;
        final reportData = {
          'damageType': _selectedDamageType,
          'description': _descriptionController.text,
          'imageurl': imageUrl,
          'reportTime': FieldValue.serverTimestamp(),
          'status': 'pending',
          'userName': _userName,
          'userMobile': _userMobile,
        };

        if (_hasExistingReport) {
          // Update existing report
          await _existingReport!.reference.update(reportData);
          _addNotification(
            "Damage Report Updated",
            "Your damage report for this car has been successfully updated.",
          );
          CustomNotificationClass.MahekCustomNotification(
            context,
            "Success",
            "Damage report updated successfully!",
            const HomePage(),
          );
        } else {
          // Add new report
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user!.uid)
              .collection('car_booking')
              .doc(widget.carBookingId)
              .collection('damage_report')
              .add(reportData);
          _addNotification(
            "Damage Report Submitted",
            "A new damage report has been submitted for your booking.",
          );
          CustomNotificationClass.MahekCustomNotification(
            context,
            "Success",
            "Damage report submitted successfully!",
            const HomePage(),
          );
        }
      } catch (e) {
        if (mounted) {
          CustomNotificationClass.MahekCustomNotification(
            context,
            "Error",
            "Failed to submit report: $e",
            const HomePage(),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      CustomNotificationClass.MahekCustomNotification(
        context,
        "Warning",
        "Please fill all fields and upload an image.",
        const HomePage(),
      );
    }
  }

  // Function to add a notification to Firestore
  Future<void> _addNotification(String title, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String time = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Notification')
          .add({'title': title, 'description': description, 'time': time});
    } catch (e) {
      print('Failed to add notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Damage',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        _hasExistingReport
                            ? 'Update  Existing Damage Report'
                            : 'Report a New Damage',
                        style: GoogleFonts.poppins(
                          color: Colors.blueGrey[900],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Section at the top
                              _buildImageSection(),
                              const SizedBox(height: 10),

                              // Damage Type Dropdown
                              _buildDropdownField(
                                label: 'Damage Type',
                                value: _selectedDamageType,
                                items: _damageTypes,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedDamageType = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a damage type.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),

                              // Description Field
                              _buildInputField(
                                controller: _descriptionController,
                                label: 'Description',
                                hint: 'e.g., "Front bumper scratched"',
                                maxLines: 4,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a description.';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              // Submit/Update button
                              Center(
                                child: ElevatedButton(
                                  onPressed: _submitReport,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _hasExistingReport
                                            ? Colors
                                                .orange[700] // Orange for update
                                            : Colors
                                                .blue[700], // Blue for new report
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    _hasExistingReport
                                        ? 'Update Report'
                                        : 'Report Damage',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Bottom text for status
                    Center(
                      child: Text(
                        _hasExistingReport
                            ? 'A damage report has already been submitted for this booking.'
                            : 'You have not submitted a damage report yet.',
                        style: GoogleFonts.poppins(
                          color: Colors.blueGrey[700],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Helper method for the image section, handles both new and existing images
  Widget _buildImageSection() {
    // Determine which image to show
    Widget imageWidget;
    if (_damageImage != null) {
      imageWidget = Image.file(
        _damageImage!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (_existingImageUrl != null) {
      imageWidget = CachedNetworkImage(
        imageUrl: _existingImageUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      imageWidget = GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue[200]!,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, color: Colors.blue[300], size: 50),
              const SizedBox(height: 8),
              Text(
                'Tap to add image',
                style: GoogleFonts.poppins(color: Colors.blue[400]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image of Damage',
          style: GoogleFonts.poppins(
            color: Colors.blueGrey[900],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
            if (_damageImage != null || _existingImageUrl != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _damageImage = null;
                        _existingImageUrl = null;
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
        if (_damageImage != null || _existingImageUrl != null)
          Center(
            child: TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.change_circle, color: Colors.blue),
              label: Text(
                'Change Image',
                style: GoogleFonts.poppins(color: Colors.blue),
              ),
            ),
          ),
      ],
    );
  }

  // Helper method for input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.blueGrey[700],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(color: Colors.blueGrey[900]),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.blueGrey[400]),
            fillColor: Colors.blue[50],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // Helper method for the dropdown field
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.blueGrey[700],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            fillColor: Colors.blue[50],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          dropdownColor: Colors.white,
          style: GoogleFonts.poppins(
            color: Colors.blueGrey[900],
            fontWeight: FontWeight.bold,
          ),
          validator: validator,
          onChanged: onChanged,
          items:
              items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
