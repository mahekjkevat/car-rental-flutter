import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const EditProfilePage({
    super.key,
    required this.currentName,
    required this.currentEmail,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityUrbanController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _pincodeController;

  File? _selectedImage;
  String? _currentProfilePhotoUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  // ImageKit configuration
  final String _privateApiKey = 'private_u6KRAwruwE6w8xR63Vl7enrhpzk=';
  final String _uploadEndpoint = 'https://upload.imagekit.io/api/v1/files/upload';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _addressController = TextEditingController();
    _cityUrbanController = TextEditingController();
    _mobileNumberController = TextEditingController();
    _pincodeController = TextEditingController();
    _loadCurrentProfilePhoto();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityUrbanController.dispose();
    _mobileNumberController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['profile_photo'] != null) {
        setState(() {
          _currentProfilePhotoUrl = userDoc.data()?['profile_photo'];
        });
      }
    } catch (e) {
      print('Error loading profile photo: $e');
    }
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

  Future<void> _showFullScreenImage() async {
    if (_selectedImage != null) {
      // Show selected image
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: Image.file(_selectedImage!),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_currentProfilePhotoUrl != null) {
      // Show current profile photo
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: Image.network(_currentProfilePhotoUrl!),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
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
          'fileName': 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          'useUniqueFileName': 'true',
          'folder': '/profile_images', // Store in profile_images folder
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

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {};
    }

    // Fetch address data
    final addressDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('Address')
        .doc('default')
        .get();

    // Fetch user data for profile photo
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    Map<String, dynamic> data = addressDoc.exists ? addressDoc.data()! : {};

    // Add profile photo from user document
    if (userDoc.exists && userDoc.data()?['profile_photo'] != null) {
      data['profile_photo'] = userDoc.data()?['profile_photo'];
    }

    return data;
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No user logged in!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToImageKit();
        if (imageUrl == null) {
          setState(() => _isSaving = false);
          return;
        }
      }

      // Update user document with profile photo
      final userUpdateData = <String, dynamic>{};
      if (imageUrl != null) {
        userUpdateData['profile_photo'] = imageUrl;
      }

      if (userUpdateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(userUpdateData);
      }

      // Update address data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Address')
          .doc('default')
          .update({
        'name': _nameController.text,
        'address': _addressController.text,
        'cityUrban': _cityUrbanController.text,
        'mobileNumber': _mobileNumberController.text,
        'pincode': _pincodeController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.orange[800],
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating profile: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
              ),
            );
          }

          final data = snapshot.data ?? {};
          _addressController.text = data['address'] ?? '';
          _cityUrbanController.text = data['cityUrban'] ?? '';
          _mobileNumberController.text = data['mobileNumber'] ?? '';
          _pincodeController.text = data['pincode'] ?? '';
          if (data['name'] != null) _nameController.text = data['name'];

          // Load profile photo if not already loaded
          if (data['profile_photo'] != null && _currentProfilePhotoUrl == null) {
            _currentProfilePhotoUrl = data['profile_photo'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header with Editable Photo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[800]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showFullScreenImage,
                        onLongPress: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : (_currentProfilePhotoUrl != null
                                    ? NetworkImage(_currentProfilePhotoUrl!)
                                    : null),
                                child: _selectedImage == null && _currentProfilePhotoUrl == null
                                    ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.orange,
                                )
                                    : null,
                              ),
                            ),
                            if (_isUploading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.orange[800],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _emailController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap photo to view • Long press to change',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Edit Fields Section
                Text(
                  'Update Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Name',
                  controller: _nameController,
                  hintText: 'Enter your name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  hintText: 'Your email',
                  icon: Icons.email_outlined,
                  enabled: false,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Address',
                  controller: _addressController,
                  hintText: 'Enter your address',
                  icon: Icons.home_outlined,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'City/Urban',
                  controller: _cityUrbanController,
                  hintText: 'Enter your city',
                  icon: Icons.location_city_outlined,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Mobile Number',
                  controller: _mobileNumberController,
                  hintText: 'Enter your mobile number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Pincode',
                  controller: _pincodeController,
                  hintText: 'Enter your pincode',
                  icon: Icons.local_post_office_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                      shadowColor: Colors.orange.withOpacity(0.5),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.orange[800],
              size: 24,
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.orange[200]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.orange[800]!, width: 2),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
          ),
          keyboardType: keyboardType,
        ),
      ],
    );
  }
}