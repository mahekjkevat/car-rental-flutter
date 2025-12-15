// edit_admin_profile_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAdminProfilePage extends StatefulWidget {
  final String adminId;
  final String currentName;
  final String? currentProfileImage;
  final String adminEmail;

  const EditAdminProfilePage({
    super.key,
    required this.adminId,
    required this.currentName,
    this.currentProfileImage,
    required this.adminEmail,
  });

  @override
  State<EditAdminProfilePage> createState() => _EditAdminProfilePageState();
}

class _EditAdminProfilePageState extends State<EditAdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _selectedImage;
  bool _isUploading = false;
  bool _isSaving = false;

  // ImageKit configuration
  final String _privateApiKey = 'private_Kd4PZh26CjhVn/Y/ZK6S8H1FegA=';
  final String _uploadEndpoint = 'https://upload.imagekit.io/api/v1/files/upload';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToImageKit() async {
    if (_selectedImage == null) return null;

    setState(() => _isUploading = true);

    try {
      final file = _selectedImage!;
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_uploadEndpoint),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_privateApiKey:'))}',
        },
        body: {
          'file': base64Image,
          'fileName': 'admin_profile_${widget.adminId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          'useUniqueFileName': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url']; // Return the ImageKit URL
      } else {
        print('❌ Image upload failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: ${response.statusCode}')),
        );
        return null;
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? imageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToImageKit();
        if (imageUrl == null) {
          // If image upload fails, don't proceed with save
          setState(() => _isSaving = false);
          return;
        }
      }

      // Update Firestore
      final updateData = {
        'name': _nameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update image URL if a new image was uploaded
      if (imageUrl != null) {
        updateData['img_url'] = imageUrl;
      }

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.adminId)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Profile updated successfully')),
      );

      // Navigate back
      if (mounted) {
        Navigator.pop(context, {
          'name': _nameController.text.trim(),
          'profileImage': imageUrl ?? widget.currentProfileImage,
        });
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryAppColor = const Color(0xFFF96D0A);
    final Color secondaryDarkColor = const Color(0xFF333333);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image Section
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: primaryAppColor.withOpacity(0.1),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (widget.currentProfileImage != null
                                ? NetworkImage(widget.currentProfileImage!)
                                : null),
                            child: _selectedImage == null && widget.currentProfileImage == null
                                ? Icon(
                              Icons.person,
                              size: 60,
                              color: primaryAppColor,
                            )
                                : null,
                          ),
                          if (_isUploading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickImage,
                        icon: Icon(Icons.camera_alt_outlined),
                        label: Text('Change Profile Picture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAppColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name Edit Section
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: secondaryDarkColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryAppColor),
                          ),
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        style: GoogleFonts.poppins(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field (read-only)
                      TextFormField(
                        initialValue: widget.adminEmail,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabled: false,
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAppColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Save Changes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}