import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/custom_toast.dart';
import 'add_update_documents_page.dart';

class AddCarPage extends StatefulWidget {
  const AddCarPage({super.key});

  @override
  _AddCarPageState createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _mobileController = TextEditingController();
  final _carNameController = TextEditingController();
  final _chassisNoController = TextEditingController();
  final _engineNoController = TextEditingController();
  final _fuelTypeController = TextEditingController();
  final _feature1Controller = TextEditingController();
  final _feature2Controller = TextEditingController();
  final _feature3Controller = TextEditingController();
  final _feature4Controller = TextEditingController();
  final _feature5Controller = TextEditingController();
  final _feature6Controller = TextEditingController();
  final _basicPriceController = TextEditingController();
  final _plusPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  List<File?> carImages = [null, null, null, null];
  List<String> imageUrls = ['', '', '', ''];
  int? selectedSeats = 2;
  String? selectedBrand;
  String? selectedVillage;
  bool _isSaving = false;
  List<String> brandTypes = [];
  String userEmail = '';

  final List<String> villages = [
    'BILIMORA',
    'SURAT',
    'NAVSARI',
    'TARSADI',
    'SACHIN',
    'VALSAD'
  ];

  final ImagePicker _picker = ImagePicker();
  late appwrite.Client client;
  late appwrite.Storage storage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Update the initState method to check verification
  @override
  void initState() {
    super.initState();
    client = appwrite.Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('67e8384a0024f79666ba');
    storage = appwrite.Storage(client);

    _fetchUserEmail();
    _fetchBrandTypes();
    _setupInputFormatters();

    // Check document verification when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowVerificationAlert();
    });
  }

  // Add this method to check and show alert
  Future<void> _checkAndShowVerificationAlert() async {
    final isVerified = await _checkDocumentVerification();
    if (!isVerified && mounted) {
      _showVerificationAlert();
    }
  }
  void _setupInputFormatters() {
    // Mobile controller - only numbers, max 10
    _mobileController.addListener(() {
      final text = _mobileController.text;
      if (text.length > 10) {
        _mobileController.text = text.substring(0, 10);
        _mobileController.selection = TextSelection.fromPosition(
          TextPosition(offset: _mobileController.text.length),
        );
      }
    });

    // Price controllers - max 3 digits
    _setupPriceController(_basicPriceController);
    _setupPriceController(_plusPriceController);
    _setupPriceController(_maxPriceController);

    // Feature controllers - max 10 characters
    _setupFeatureController(_feature1Controller);
    _setupFeatureController(_feature2Controller);
    _setupFeatureController(_feature3Controller);
    _setupFeatureController(_feature4Controller);
    _setupFeatureController(_feature5Controller);
    _setupFeatureController(_feature6Controller);

    // Name controller - only words, max 15
    _nameController.addListener(() {
      final text = _nameController.text;
      if (text.length > 15) {
        _nameController.text = text.substring(0, 15);
        _nameController.selection = TextSelection.fromPosition(
          TextPosition(offset: _nameController.text.length),
        );
      }
    });
  }

  void _setupPriceController(TextEditingController controller) {
    controller.addListener(() {
      final text = controller.text;
      if (text.length > 3) {
        controller.text = text.substring(0, 3);
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      }
    });
  }

  void _setupFeatureController(TextEditingController controller) {
    controller.addListener(() {
      final text = controller.text;
      if (text.length > 10) {
        controller.text = text.substring(0, 10);
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      }
    });
  }

  void _fetchUserEmail() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? 'No email';
      });
    }
  }

  // Add this method to check document verification
  Future<bool> _checkDocumentVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('personal_documents')
          .doc('verification_status')
          .get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      final adminApproved = data?['admin_approved'] == true;
      final verificationStatus = data?['verification_status'];

      return adminApproved && verificationStatus == 'verified';
    } catch (e) {
      print('Error checking verification: $e');
      return false;
    }
  }
  Future<void> _fetchBrandTypes() async {
    try {
      final snapshot = await _firestore.collection('Brands').get();
      List<String> fetchedBrandTypes = snapshot.docs
          .map((doc) => doc.data()['type'] as String?)
          .where((type) => type != null)
          .cast<String>()
          .toList();

      if (fetchedBrandTypes.isNotEmpty) {
        setState(() => brandTypes = fetchedBrandTypes);
      }
    } catch (e) {
      print('Error fetching brands: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _mobileController.dispose();
    _carNameController.dispose();
    _chassisNoController.dispose();
    _engineNoController.dispose();
    _fuelTypeController.dispose();
    _feature1Controller.dispose();
    _feature2Controller.dispose();
    _feature3Controller.dispose();
    _feature4Controller.dispose();
    _feature5Controller.dispose();
    _feature6Controller.dispose();
    _basicPriceController.dispose();
    _plusPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  String _generateRandomId() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(12, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<void> _pickImage(int index) async {
    try {
      setState(() => _isSaving = true);
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 100,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.blue[600],
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.ratio3x2,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: 'Crop Image'),
          ],
        );

        if (croppedFile != null) {
          setState(() => carImages[index] = File(croppedFile.path));
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _uploadImage(File image, String fileId) async {
    try {
      final response = await storage.createFile(
        bucketId: '67e98cf800089750f324',
        fileId: fileId,
        file: appwrite.InputFile.fromPath(
          path: image.path,
          filename: '$fileId.jpg',
        ),
      );
      return 'https://cloud.appwrite.io/v1/storage/buckets/67e98cf800089750f324/files/${response.$id}/view?project=67e8384a0024f79666ba&mode=admin';
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveCarRequest() async {

    // Check verification first
    final isVerified = await _checkDocumentVerification();
    if (!isVerified) {
      _showVerificationAlert();
      return;
    }
    if (_isSaving) return;

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Fluttertoast.showToast(msg: 'No internet connection');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: 'Please fix form errors');
      return;
    }

    if (carImages.any((image) => image == null) || selectedBrand == null || selectedVillage == null) {
      Fluttertoast.showToast(msg: 'Please fill all fields and select all images');
      return;
    }

    setState(() => _isSaving = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blue[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text('Uploading Car Request...', style: GoogleFonts.poppins(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      // Upload images
      final uuid = Uuid();
      for (int i = 0; i < carImages.length; i++) {
        final fileId = uuid.v4();
        final url = await _uploadImage(carImages[i]!, fileId);
        if (url != null) imageUrls[i] = url;
      }

      final randomID = _generateRandomId();
      final userId = _auth.currentUser!.uid;

      // Save to user's my_cars collection
      await _firestore.collection('Users').doc(userId).collection('my_cars').doc(randomID).set({
        'customerName': _nameController.text.trim(),
        'car_name': _carNameController.text.trim(),
        'car_brand': selectedBrand,
        'chassis_no': _chassisNoController.text.trim(),
        'engine_no': _engineNoController.text.trim(),
        'fuel_type': _fuelTypeController.text.trim(),
        'features1': _feature1Controller.text.trim(),
        'features2': _feature2Controller.text.trim(),
        'features3': _feature3Controller.text.trim(),
        'features4': _feature4Controller.text.trim(),
        'features5': _feature5Controller.text.trim(),
        'features6': _feature6Controller.text.trim(),
        'basic_price': double.parse(_basicPriceController.text.trim()),
        'plus_price': double.parse(_plusPriceController.text.trim()),
        'max_price': double.parse(_maxPriceController.text.trim()),
        'no_of_seats': selectedSeats,
        'car_image1': imageUrls[0],
        'car_image2': imageUrls[1],
        'car_image3': imageUrls[2],
        'car_image4': imageUrls[3],
        'randomID': randomID,
        'village': selectedVillage,
        'mobile': _mobileController.text.trim(),
        'email': userEmail,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      // Send notifications and emails
      await _postNotification();
      await _sendCustomerEmail();
      await _sendAdminEmail();

      CustomToast.show(context, message: 'Request Sent Successfully!');
      _clearFields();

    } catch (e) {
      print('Error saving car: $e');
      Fluttertoast.showToast(msg: 'Error saving request: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  Future<void> _postNotification() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('Users').doc(userId).collection('Notification').add({
          'title': 'Car Request Sent!',
          'description': 'Your car add request has been submitted successfully.',
          'time': DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()),
        });
      }
    } catch (error) {
      print('Notification error: $error');
    }
  }

  Future<void> _sendCustomerEmail() async {
    try {
      final success = await EmailService.sendEmail(
        recipientEmail: userEmail,
        subject: '🚗 GearGo - Request Sent Car Successfully !',
        htmlBody: '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Car Request</title></head>
<body style="font-family: Arial, sans-serif;">
  <div style="max-width: 600px; margin: 0 auto; background: #f8f9fa;">
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; color: white;">
      <h1>🚗 GearGo</h1>
      <p>Car Rental Service</p>
    </div>
    <div style="padding: 30px;">
      <h2>Dear ${_nameController.text.trim()},</h2>
      <p>Thank you for submitting your car add request to GearGo!</p>
      
      <div style="background: white; padding: 20px; border-radius: 10px; margin: 20px 0;">
        <h3>📋 Request Details</h3>
        <p><strong>Car:</strong> ${_carNameController.text.trim()} - $selectedBrand</p>
        <p><strong>Status:</strong> Pending Review</p>
        <p><strong>Submitted:</strong> ${DateFormat('MMM dd, yyyy').format(DateTime.now())}</p>
      </div>
      
      <p>We will review your request and contact you shortly.</p>
      <p>Best regards,<br><strong>GearGo Team</strong></p>
    </div>
  </div>
</body>
</html>
        ''',
      );
      if (success) print('✅ Customer email sent');
    } catch (e) {
      print('Customer email error: $e');
    }
  }

  Future<void> _sendAdminEmail() async {
    try {
      final success = await EmailService.sendEmail(
        recipientEmail: 'mahekjkevat@gmail.com',
        subject: '🔔 New Car Add Request - GearGo',
        htmlBody: '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>New Car Request</title></head>
<body style="font-family: Arial, sans-serif;">
  <div style="max-width: 600px; margin: 0 auto; background: #f8f9fa;">
    <div style="background: linear-gradient(135deg, #dc3545 0%, #c82333 100%); padding: 30px; text-align: center; color: white;">
      <h1>GearGo Admin Alert</h1>
      <p>New Car Add Request</p>
    </div>
    <div style="padding: 30px;">
      <h2>Hello Admin,</h2>
      <p>A new car add request has been submitted.</p>
      
      <div style="background: white; padding: 20px; border-radius: 10px; margin: 20px 0;">
        <h3>👤 Customer Information</h3>
        <p><strong>Name:</strong> ${_nameController.text.trim()}</p>
        <p><strong>Email:</strong> $userEmail</p>
        <p><strong>Mobile:</strong> ${_mobileController.text.trim()}</p>
        <p><strong>Village:</strong> $selectedVillage</p>
      </div>
      
      <div style="background: white; padding: 20px; border-radius: 10px; margin: 20px 0;">
        <h3>🚗 Car Details</h3>
        <p><strong>Car:</strong> ${_carNameController.text.trim()} - $selectedBrand</p>
        <p><strong>Chassis:</strong> ${_chassisNoController.text.trim()}</p>
        <p><strong>Status:</strong> Pending</p>
      </div>
      
      <p>Please review this request in the admin panel.</p>
    </div>
  </div>
</body>
</html>
        ''',
      );
      if (success) print('✅ Admin email sent');
    } catch (e) {
      print('Admin email error: $e');
    }
  }

  void _clearFields() {
    _nameController.clear();
    _mobileController.clear();
    _carNameController.clear();
    _chassisNoController.clear();
    _engineNoController.clear();
    _fuelTypeController.clear();
    _feature1Controller.clear();
    _feature2Controller.clear();
    _feature3Controller.clear();
    _feature4Controller.clear();
    _feature5Controller.clear();
    _feature6Controller.clear();
    _basicPriceController.clear();
    _plusPriceController.clear();
    _maxPriceController.clear();
    setState(() {
      carImages = [null, null, null, null];
      selectedSeats = 2;
      selectedBrand = null;
      selectedVillage = null;
    });
  }

  // VALIDATION FUNCTIONS
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 3) return 'Minimum 3 characters required';
    if (value.length > 15) return 'Maximum 15 characters allowed';
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) return 'Only letters and spaces allowed';
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) return 'Enter exactly 10 digits';
    return null;
  }

  String? _validateFeature(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 3) return 'Minimum 3 characters required';
      if (value.length > 10) return 'Maximum 10 characters allowed';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    if (double.tryParse(value) == null) return 'Enter valid number';
    if (double.parse(value) <= 0) return 'Must be greater than 0';
    if (value.length > 3) return 'Maximum 3 digits allowed';
    return null;
  }

  String? _validateRequired(String? value) => value == null || value.isEmpty ? 'This field is required' : null;

  Widget _buildUserInfoCard() {
    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Information', style: GoogleFonts.poppins(color: Colors.blue[900], fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _nameController,
              hint: 'Your Full Name (3-15 letters)',
              prefixIcon: Icons.person,
              validator: _validateName,
              maxLength: 15,
            ),
            const SizedBox(height: 20),
            _buildVillageDropdown(),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _mobileController,
              hint: 'Mobile Number (10 digits)',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: _validateMobile,
              maxLength: 10,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(child: Text(userEmail, style: GoogleFonts.poppins(color: Colors.blue[900]))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVillageDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedVillage,
      hint: Text('Select Village/City', style: GoogleFonts.poppins(color: Colors.blue[500])),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIcon: const Icon(Icons.location_city, color: Colors.blue),
      ),
      items: villages.map((village) {
        return DropdownMenuItem<String>(
          value: village,
          child: Text(village, style: GoogleFonts.poppins(color: Colors.blue[900])),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedVillage = value),
      validator: (value) => value == null ? 'Please select village/city' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        title: Text('ADD Car Request', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.1), Colors.white.withOpacity(0.8)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add New Car', style: GoogleFonts.poppins(color: Colors.blue[900], fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('Enter car details and upload images', style: GoogleFonts.poppins(color: Colors.blue[600], fontSize: 16)),
                    const SizedBox(height: 20),

                    _buildUserInfoCard(),
                    const SizedBox(height: 20),

                    // Image Upload Section
                    Text('Car Images (4 required)', style: GoogleFonts.poppins(color: Colors.blue[900], fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(4, (index) => _buildImageContainer(index)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Car Details Card
                    _buildCard(
                      title: 'Car Details',
                      children: [
                        _buildTextField(
                            controller: _carNameController,
                            hint: 'Car Name',
                            prefixIcon: Icons.directions_car,
                            validator: _validateRequired
                        ),
                        const SizedBox(height: 20),
                        _buildBrandDropdown(),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _chassisNoController,
                          hint: 'Chassis No (17 characters)',
                          prefixIcon: Icons.build,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Chassis number required';
                            if (value.length != 17) return 'Must be 17 characters';
                            return null;
                          },
                          maxLength: 17,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _engineNoController,
                          hint: 'Engine No (8-12 characters)',
                          prefixIcon: Icons.engineering,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Engine number required';
                            if (value.length < 8 || value.length > 12) return '8-12 characters required';
                            return null;
                          },
                          maxLength: 12,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _buildFeaturesCard(),
                    const SizedBox(height: 20),
                    _buildFuelTypeCard(),
                    const SizedBox(height: 20),
                    _buildSubscriptionCard(),
                    const SizedBox(height: 20),
                    _buildSeatsCard(),

                    const SizedBox(height: 30),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContainer(int index) {
    return GestureDetector(
      onTap: _isSaving ? null : () => _pickImage(index),
      child: Container(
        width: 150, height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: carImages[index] != null ? Colors.blue[600]! : Colors.grey, width: 2),
        ),
        child: carImages[index] == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_a_photo, color: Colors.blue[300], size: 30),
          const SizedBox(height: 8),
          Text('Image ${index + 1}', style: GoogleFonts.poppins(color: Colors.blue[300], fontSize: 10)),
        ])
            : ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.file(carImages[index]!, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.blue[900], fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ...children,
        ]),
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedBrand,
      hint: Text('Select Car Brand', style: GoogleFonts.poppins(color: Colors.blue[500])),
      decoration: InputDecoration(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIcon: const Icon(Icons.branding_watermark, color: Colors.blue),
      ),
      items: brandTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
      onChanged: (value) => setState(() => selectedBrand = value),
      validator: (value) => value == null ? 'Please select brand' : null,
    );
  }

  Widget _buildFeaturesCard() {
    return _buildCard(
      title: 'Features (3-10 characters each)',
      children: [
        _buildFeatureField(_feature1Controller, 'Feature 1'),
        const SizedBox(height: 20),
        _buildFeatureField(_feature2Controller, 'Feature 2'),
        const SizedBox(height: 20),
        _buildFeatureField(_feature3Controller, 'Feature 3'),
        const SizedBox(height: 20),
        _buildFeatureField(_feature4Controller, 'Feature 4'),
        const SizedBox(height: 20),
        _buildFeatureField(_feature5Controller, 'Feature 5'),
        const SizedBox(height: 20),
        _buildFeatureField(_feature6Controller, 'Feature 6'),
      ],
    );
  }

  Widget _buildFeatureField(TextEditingController controller, String hint) {
    return _buildTextField(
      controller: controller,
      hint: '$hint (3-10 chars)',
      prefixIcon: Icons.star,
      validator: _validateFeature,
      maxLength: 10,
    );
  }

  Widget _buildFuelTypeCard() {
    return _buildCard(
      title: 'Fuel Type',
      children: [
        DropdownButtonFormField<String>(
          value: _fuelTypeController.text.isNotEmpty ? _fuelTypeController.text : null,
          hint: Text('Select Fuel Type', style: GoogleFonts.poppins(color: Colors.blue[500])),
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.local_gas_station, color: Colors.blue),
          ),
          items: ['Petrol', 'Diesel', 'Petrol/CNG', 'Diesel/CNG'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
          onChanged: (value) => setState(() => _fuelTypeController.text = value ?? ''),
          validator: (value) => value == null ? 'Please select fuel type' : null,
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    return _buildCard(
      title: 'Subscription Plans (Max 3 digits)',
      children: [
        _buildPriceField(_basicPriceController, 'Basic Plan Price'),
        const SizedBox(height: 20),
        _buildPriceField(_plusPriceController, 'Plus Plan Price'),
        const SizedBox(height: 20),
        _buildPriceField(_maxPriceController, 'Max Plan Price'),
      ],
    );
  }

  Widget _buildPriceField(TextEditingController controller, String hint) {
    return _buildTextField(
      controller: controller,
      hint: '$hint (max 3 digits)',
      prefixIcon: Icons.subscriptions,
      keyboardType: TextInputType.number,
      validator: _validatePrice,
      maxLength: 3,
    );
  }

  Widget _buildSeatsCard() {
    return _buildCard(
      title: 'Number of People',
      children: [
        DropdownButtonFormField<int>(
          value: selectedSeats,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.event_seat, color: Colors.blue),
          ),
          items: List.generate(6, (index) => index + 2).map((seats) => DropdownMenuItem(value: seats, child: Text(seats.toString()))).toList(),
          onChanged: (value) => setState(() => selectedSeats = value),
          validator: (value) => value == null ? 'Please select seats' : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[100], padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.blue[900], fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 150,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveCarRequest,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                : Text('Request ADD Car', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

// Add this method to show verification alert



  // Update this method to close both dialog and page when Cancel is pressed
  void _showVerificationAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.verified_user, size: 50, color: Colors.orange),
            SizedBox(height: 10),
            Text(
              'Document Verification Required',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'You need to complete document verification before adding a car. Please upload and verify your documents first.',
          style: GoogleFonts.poppins(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close page and go back
            },
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to document upload page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddUpdateDocumentsPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: Text('Upload Documents', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true, fillColor: Colors.white,
        hintText: hint, hintStyle: GoogleFonts.poppins(color: Colors.blue[500]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIcon: Icon(prefixIcon, color: Colors.blue[600]),
        counterText: '',
      ),
      style: GoogleFonts.poppins(color: Colors.blue[900]),
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
    );
  }
}