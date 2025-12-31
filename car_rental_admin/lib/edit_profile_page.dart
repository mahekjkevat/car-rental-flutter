import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'home_page.dart';
import 'package:uuid/uuid.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  LatLng? _selectedLocation;
  bool _isLoading = true;
  bool _isSaveEnabled = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late appwrite.Client _client;
  late appwrite.Storage _storage;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _client = appwrite.Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('67e8384a0024f79666ba');
    _storage = appwrite.Storage(_client);
    _loadUserData();

    // Add listeners to check fields on change
    _nameController.addListener(_checkFields);
    _emailController.addListener(_checkFields);
    _phoneController.addListener(_checkFields);
    _locationController.addListener(_checkFields);
  }

  Future<void> _requestPermissions() async {
    // Use Permission.photos for Android 13+ compatibility
    if (await Permission.photos.request().isGranted &&
        await Permission.camera.request().isGranted) {
      return;
    } else {
      Fluttertoast.showToast(msg: 'Please grant photo and camera permissions.');
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Fluttertoast.showToast(msg: 'User not authenticated.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('CarAdmin').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _locationController.text = data['selectedLocation'] ?? '';
          _profileImageUrl = data['profileImage'] ?? '';
        });
      } else {
        Fluttertoast.showToast(msg: 'User data not found for ID: $userId');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
      _checkFields();
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkFields);
    _emailController.removeListener(_checkFields);
    _phoneController.removeListener(_checkFields);
    _locationController.removeListener(_checkFields);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 85, // Reduced quality for smaller file size
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.yellow,
              toolbarWidgetColor: Colors.black,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _profileImage = File(croppedFile.path);
            _isSaveEnabled = true; // Enable save button on image change
          });
          Fluttertoast.showToast(msg: 'Image selected and cropped!');
        }
      } else {
        Fluttertoast.showToast(msg: 'No image selected');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to pick image: $e');
    }
  }

  Future<void> _selectLocation() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    LoadingDialog.show(context); // Show loading dialog

    try {
      final initialLocation = const LatLng(21.0696819, 73.1342103);
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Location Selection Dialog',
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          body: FlutterMap(
            options: MapOptions(
              initialCenter: _selectedLocation ?? initialLocation,
              initialZoom: 12.0,
              onTap: (tapPosition, point) async {
                _selectedLocation = point;
                final placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
                if (placemarks.isNotEmpty) {
                  final placemark = placemarks.first;
                  setState(() {
                    _locationController.text = '${placemark.locality}, ${placemark.country}';
                  });
                }
                Navigator.pop(context);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error selecting location: $e');
    } finally {
      LoadingDialog.hide(context);
      setState(() => _isLoading = false);
      _checkFields();
    }
  }

  void _checkFields() {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _isSaveEnabled = isValid &&
          _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _locationController.text.isNotEmpty;
    });
  }

  Future<void> _clearData() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Clear Data',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to clear all profile data?',
          style: GoogleFonts.poppins(
            color: Colors.grey[300],
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.yellow,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldClear ?? false) {
      setState(() {
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _locationController.clear();
        _profileImage = null;
        _profileImageUrl = null;
        _selectedLocation = null;
        _isSaveEnabled = false;
      });
      Fluttertoast.showToast(msg: 'Data cleared.');
    }
  }

  Future<String?> _uploadImageToAppwrite(File file) async {
    try {
      // Generate unique fileId using UUID
      final fileId = _uuid.v4();
      final result = await _storage.createFile(
        bucketId: '67ec1162000a2853d3f7', // Your Appwrite bucket ID
        fileId: fileId,
        file: appwrite.InputFile.fromPath(
          path: file.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      return 'https://cloud.appwrite.io/v1/storage/buckets/67ec1162000a2853d3f7/files/${result.$id}/view?project=67e8384a0024f79666ba';
    } catch (e) {
      print('Error uploading to Appwrite: $e');
      Fluttertoast.showToast(msg: 'Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() && !_isLoading && _auth.currentUser != null) {
      setState(() => _isLoading = true);
      LoadingDialog.show(context); // Show themed loading dialog

      try {
        // Update Firebase Authentication email if changed
        if (_emailController.text != _auth.currentUser!.email) {
          await _auth.currentUser!.updateEmail(_emailController.text);
        }

        String? imageUrl = _profileImageUrl;
        if (_profileImage != null) {
          imageUrl = await _uploadImageToAppwrite(_profileImage!);
          if (imageUrl == null) {
            LoadingDialog.hide(context);
            setState(() => _isLoading = false);
            return;
          }
        }

        await _firestore.collection('CarAdmin').doc(_auth.currentUser!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'selectedLocation': _locationController.text.trim(),
          'profileImage': imageUrl ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));

        LoadingDialog.hide(context);
        Fluttertoast.showToast(
          msg: 'Profile updated successfully!',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 18,
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        LoadingDialog.hide(context);
        Fluttertoast.showToast(msg: 'Error saving data: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      Fluttertoast.showToast(msg: 'Please fill all fields correctly.');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo, color: Colors.yellow),
            title: Text(
              'Choose from Gallery',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.yellow),
            title: Text(
              'Take a Photo',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/car.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
              ),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.yellow.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Update your account details',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Form container
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.yellow.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          // Profile image
                          GestureDetector(
                            onTap: _showImageOptions,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? NetworkImage(_profileImageUrl!)
                                      : null,
                                  child: _profileImage == null &&
                                      (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 60, color: Colors.yellow)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.yellow,
                                    child: Icon(
                                      _profileImage != null || _profileImageUrl != null
                                          ? Icons.edit
                                          : Icons.add,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Form fields
                          _buildTextField(
                            label: 'Full Name',
                            controller: _nameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter Full Name';
                              if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                return 'Only alphabets are allowed';
                              }
                              return null;
                            },
                            hint: 'Enter your full name',
                          ),
                          _buildTextField(
                            label: 'Email',
                            controller: _emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter Email';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                            hint: 'Enter your email',
                            enabled: true, // Allow email editing
                          ),
                          _buildTextField(
                            label: 'Phone',
                            controller: _phoneController,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter Phone';
                              if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                return 'Enter exactly 10 digits';
                              }
                              return null;
                            },
                            hint: 'Enter your 10-digit phone number',
                            keyboardType: TextInputType.phone,
                          ),
                          GestureDetector(
                            onTap: _selectLocation,
                            child: AbsorbPointer(
                              child: _buildTextField(
                                label: 'Location',
                                controller: _locationController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please select Location';
                                  return null;
                                },
                                hint: 'Tap to select location',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Save Changes button
                  GradientButton(
                    onPressed: _isSaveEnabled && !_isLoading ? _saveChanges : null,
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Clear Data button
                  GradientButton(
                    onPressed: _clearData,
                    child: Text(
                      'Clear Data',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    colors: const [Colors.red, Colors.redAccent],
                  ),
                ],
              ),
            ),
          ),
          // Full-screen loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                  strokeWidth: 6.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    String? hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 16),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.yellow, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        validator: validator,
        onChanged: (_) => _checkFields(),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color> colors;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.colors = const [Colors.yellow, Colors.amber],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
          elevation: 8,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.yellow.withOpacity(0.5),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey;
            }
            return null;
          }),
        ),
        child: AnimatedScale(
          scale: onPressed != null ? 1.0 : 0.95,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: onPressed != null ? colors : [Colors.grey, Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class LoadingDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                strokeWidth: 4,
              ),
              const SizedBox(height: 15),
              Text(
                'Please Wait',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}