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

import '../MahekAdminToast.dart';

class AddCarPage extends StatefulWidget {
  const AddCarPage({super.key});

  @override
  _AddCarPageState createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final _formKey = GlobalKey<FormState>();
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
  bool _isSaving = false;
  bool _showProgress = false;
  double _uploadProgress = 0.0;
  List<String> brandTypes = [];

  final ImagePicker _picker = ImagePicker();
  late appwrite.Client client;
  late appwrite.Storage storage;

  @override
  void initState() {
    super.initState();
    client =
        appwrite.Client()
          ..setEndpoint('https://cloud.appwrite.io/v1')
          ..setProject('67e8384a0024f79666ba');
    storage = appwrite.Storage(client);

    _fetchBrandTypes();
  }

  Future<void> _fetchBrandTypes() async {
    try {
      print('Fetching brands...');

      final snapshot =
          await FirebaseFirestore.instance.collection('Brands').get();

      if (snapshot.docs.isEmpty) {
        Fluttertoast.showToast(
          msg: 'No brands available.',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return;
      }

      print('Brands fetched: ${snapshot.docs.length}');

      List<String> fetchedBrandTypes =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                if (data.containsKey('type') && data['type'] is String) {
                  return data['type'] as String;
                }
                print(
                  'Document ID: ${doc.id} does not have a valid "type" field or it is not a string.',
                );
                return null;
              })
              .where((type) => type != null)
              .cast<String>()
              .toList();

      if (fetchedBrandTypes.isNotEmpty) {
        setState(() {
          brandTypes = fetchedBrandTypes;
        });
      } else {
        Fluttertoast.showToast(
          msg: 'No valid brands found.',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('Error fetching brands: $e');
      Fluttertoast.showToast(
        msg: 'Failed to load brands. Please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  void dispose() {
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
      Iterable.generate(
        12,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    try {
      setState(() => _isSaving = true);
      print('Requesting gallery access for image $index...');
      final pickedFile = await _picker
          .pickImage(source: ImageSource.gallery)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Image picking timed out');
            },
          );

      if (pickedFile != null) {
        print('Image picked: ${pickedFile.path}');
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 100,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.yellow,
              toolbarWidgetColor: Colors.black,
              initAspectRatio: CropAspectRatioPreset.ratio3x2,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: 'Crop Image'),
          ],
        );

        if (croppedFile != null) {
          print('Image cropped: ${croppedFile.path}');
          setState(() {
            carImages[index] = File(croppedFile.path);
          });
          MahekAdminToast.show(
            context: context,
            message: 'Image ${index + 1} selected and cropped!',
            status: ToastStatus.success,
          );

          if (carImages.every((image) => image != null)) {
            MahekAdminToast.show(
              context: context,
              message: 'All 4 photos selected!',
              status: ToastStatus.success,
            );
          }
        } else {
          print('Error: Image cropping cancelled');
          MahekAdminToast.show(
            context: context,
            message: 'Image cropping cancelled',
            status: ToastStatus.info,
          );
        }
      } else {
        print('Error: No image selected');
        MahekAdminToast.show(
          context: context,
          message: 'No image selected',
          status: ToastStatus.info,
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      String errorMsg;
      if (e.toString().contains('permission')) {
        errorMsg =
            'Photo access denied. Please enable in Settings > Apps > Your App > Permissions.';
      } else if (e is TimeoutException) {
        errorMsg = 'Image picking timed out. Please try again.';
      } else {
        errorMsg = 'Failed to pick image: $e';
      }
      MahekAdminToast.show(
        context: context,
        message: errorMsg,
        status: ToastStatus.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _uploadImage(
    File image,
    String fileId,
    int imageIndex,
  ) async {
    try {
      print('Uploading image: ${image.path} with fileId: $fileId');
      final response = await storage
          .createFile(
            bucketId: '67e98cf800089750f324',
            fileId: fileId,
            file: appwrite.InputFile.fromPath(
              path: image.path,
              filename: '$fileId.jpg',
            ),
          )
          .timeout(const Duration(seconds: 30));
      final url =
          'https://cloud.appwrite.io/v1/storage/buckets/67e98cf800089750f324/files/${response.$id}/view?project=67e8384a0024f79666ba&mode=admin';
      print('Image uploaded: $url');

      // Update progress for each image upload
      setState(() {
        _uploadProgress = (imageIndex + 1) / 4 * 100;
      });

      return url;
    } catch (e) {
      print('Error uploading image: $e');
      MahekAdminToast.show(
        context: context,
        message: 'Image upload failed: $e',
        status: ToastStatus.error,
      );
      return null;
    }
  }

  Future<void> _saveCar() async {
    if (_isSaving) return;
    double car_rating = 1.0;

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('Error: No internet connection detected');
      MahekAdminToast.show(
        context: context,
        message: 'No internet connection. Please connect and try again.',
        status: ToastStatus.error,
      );
      return;
    }

    if (_formKey.currentState!.validate() &&
        carImages.every((image) => image != null) &&
        selectedBrand != null) {
      setState(() {
        _isSaving = true;
        _showProgress = true;
        _uploadProgress = 0.0;
      });

      try {
        final uuid = Uuid();
        for (int i = 0; i < carImages.length; i++) {
          final fileId = uuid.v4();
          final url = await _uploadImage(carImages[i]!, fileId, i);
          if (url != null) {
            imageUrls[i] = url;
          } else {
            throw Exception('Image upload failed for image ${i + 1}');
          }
        }
        double avg_rating = 1.0;

        // Update progress for database save
        setState(() {
          _uploadProgress = 90.0;
        });

        final randomID = _generateRandomId();
        await FirebaseFirestore.instance
            .collection('CarData')
            .doc(randomID)
            .set({
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
              'car_rating': car_rating,
              'created_at': FieldValue.serverTimestamp(),
              'avg_rating': avg_rating,
            })
            .timeout(const Duration(seconds: 10));

        // Complete progress
        setState(() {
          _uploadProgress = 100.0;
        });

        await Future.delayed(const Duration(milliseconds: 500));

        print('Car data saved with ID: $randomID');

        MahekAdminToast.show(
          context: context,
          message: 'Car Added Successfully!',
          status: ToastStatus.success,
        );

        _clearFields();
      } catch (e) {
        print('Error saving car: $e');
        MahekAdminToast.show(
          context: context,
          message: 'Error saving car: $e',
          status: ToastStatus.error,
        );
        _showRetryDialog();
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _showProgress = false;
            _uploadProgress = 0.0;
          });
        }
      }
    } else {
      print('Error: Form validation failed or incomplete');
      MahekAdminToast.show(
        context: context,
        message:
            'Please fill all fields, select all images, and choose a brand',
        status: ToastStatus.error,
      );
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              'Operation Failed',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Unable to save car data. Please ensure you have a stable internet connection and try again.',
              style: GoogleFonts.poppins(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.yellow),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveCar();
                },
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _clearFields() {
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
      imageUrls = ['', '', '', ''];
      selectedSeats = 2;
      selectedBrand = null;
    });
  }

  bool _isFormValid() {
    return _formKey.currentState != null &&
        _formKey.currentState!.validate() &&
        carImages.every((image) => image != null) &&
        selectedBrand != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Add New Car',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.yellow),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Opacity(
                opacity: 0.25,
                child: Image.asset('assets/images/car.png', fit: BoxFit.cover),
              ),
            ),
          ),

          // Blur effect when saving
          if (_showProgress)
            Positioned.fill(
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.srcOver,
                ),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                // Changed to disabled to prevent initial validation
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter car details and upload images',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Image Upload Section
                    _buildImageUploadSection(),
                    const SizedBox(height: 30),

                    Divider(color: Colors.grey[800], thickness: 1),
                    const SizedBox(height: 20),

                    // Car Details Section
                    _buildCarDetailsSection(),
                    const SizedBox(height: 20),

                    // Features Section
                    _buildFeaturesSection(),
                    const SizedBox(height: 20),

                    // Fuel Type Section
                    _buildFuelTypeSection(),
                    const SizedBox(height: 20),

                    // Subscription Section
                    _buildSubscriptionSection(),
                    const SizedBox(height: 20),

                    // Seats Section
                    _buildSeatsSection(),
                    const SizedBox(height: 30),

                    // Action Buttons
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Progress Overlay
          if (_showProgress)
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: _uploadProgress / 100,
                        strokeWidth: 6,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.yellow,
                        ),
                        backgroundColor: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Uploading...',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_uploadProgress.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _getProgressMessage(),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getProgressMessage() {
    if (_uploadProgress < 25) return 'Starting upload...';
    if (_uploadProgress < 50) return 'Uploading images...';
    if (_uploadProgress < 75) return 'Processing images...';
    if (_uploadProgress < 100) return 'Saving to database...';
    return 'Complete!';
  }

  Widget _buildImageUploadSection() {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Car Images (4 required)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(4, (index) {
                    return GestureDetector(
                      onTap: _isSaving ? null : () => _pickImage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 150,
                        height: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color:
                                carImages[index] != null
                                    ? Colors.yellow
                                    : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child:
                            carImages[index] == null
                                ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: Colors.grey[400],
                                      size: 30,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image ${index + 1}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                                : ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.file(
                                    carImages[index]!,
                                    fit: BoxFit.cover,
                                    width: 150,
                                    height: 100,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                  ),
                                ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarDetailsSection() {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Car Details',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _carNameController,
              hint: 'Car Name (e.g., Suzuki Swift)',
              prefixIcon: Icons.directions_car,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter car name';
                if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value))
                  return 'Only alphanumeric characters allowed';
                return null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedBrand,
              hint: Text(
                'Select Car Brand',
                style: GoogleFonts.poppins(color: Colors.grey[500]),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.yellow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.branding_watermark,
                  color: Colors.black,
                ),
              ),
              items:
                  brandTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() => selectedBrand = value);
              },
              validator:
                  (value) => value == null ? 'Please select a car brand' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _chassisNoController,
              hint: 'Chassis No (e.g., MSABCX123456789)',
              prefixIcon: Icons.build,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter chassis number';
                if (value.length != 17)
                  return 'Chassis must be exactly 17 characters';
                if (!RegExp(r'^[0-9A-Z]+$').hasMatch(value))
                  return 'Only numeric and capital letters allowed';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _engineNoController,
              hint: 'Engine No (e.g., K12M123456789)',
              prefixIcon: Icons.engineering,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter engine number';
                if (value.length < 8 || value.length > 12)
                  return 'Engine number must be 8-12 characters';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Features',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _feature1Controller,
              hint: 'Feature 1 (e.g., Dual Front Airbags)',
              prefixIcon: Icons.star,
              validator: (value) {
                if (value != null && value.length > 15)
                  return 'Max 15 characters allowed';
                if (value != null &&
                    !RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
                  return 'Only alphanumeric characters allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _feature2Controller,
              hint: 'Feature 2 (e.g., 7-inch Touchscreen)',
              prefixIcon: Icons.star,
              validator: (value) {
                if (value != null && value.length > 15)
                  return 'Max 15 characters allowed';
                if (value != null &&
                    !RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
                  return 'Only alphanumeric characters allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _feature3Controller,
              hint: 'Feature 3 (e.g., Wireless Apple CarPlay)',
              prefixIcon: Icons.star,
              validator: (value) {
                if (value != null && value.length > 15)
                  return 'Max 15 characters allowed';
                if (value != null &&
                    !RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
                  return 'Only alphanumeric characters allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _feature4Controller,
              hint: 'Feature 4 (e.g., Rear AC Vents)',
              prefixIcon: Icons.star,
              validator: (value) {
                if (value != null && value.length > 15)
                  return 'Max 15 characters allowed';
                if (value != null &&
                    !RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
                  return 'Only alphanumeric characters allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _feature5Controller,
              hint: 'Feature 5 (e.g., Alloy Wheels)',
              prefixIcon: Icons.star,
              validator: (value) {
                if (value != null && value.length > 15)
                  return 'Max 15 characters allowed';
                if (value != null &&
                    !RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
                  return 'Only alphanumeric characters allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _feature6Controller,
              hint: 'Feature 6 (e.g., Smart Key Access)',
              prefixIcon: Icons.star,
              validator: (value) {
                if (value != null && value.length > 15)
                  return 'Max 15 characters allowed';
                if (value != null &&
                    !RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
                  return 'Only alphanumeric characters allowed';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelTypeSection() {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fuel Type',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value:
                  _fuelTypeController.text.isNotEmpty
                      ? _fuelTypeController.text
                      : null,
              hint: Text(
                'Select Fuel Type',
                style: GoogleFonts.poppins(color: Colors.grey[500]),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.yellow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.local_gas_station,
                  color: Colors.black,
                ),
              ),
              items:
                  ['Petrol', 'Diesel', 'Petrol/CNG', 'Diesel/CNG'].map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() => _fuelTypeController.text = value ?? '');
              },
              validator:
                  (value) => value == null ? 'Please select a fuel type' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Plans',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _basicPriceController,
              hint: 'Basic Plan Price (e.g., 250.00)',
              prefixIcon: Icons.subscriptions,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter basic plan price';
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _plusPriceController,
              hint: 'Plus Plan Price (e.g., 450.00)',
              prefixIcon: Icons.subscriptions,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter plus plan price';
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _maxPriceController,
              hint: 'Max Plan Price (e.g., 300.00)',
              prefixIcon: Icons.subscriptions,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter max plan price';
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatsSection() {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Number of Seats',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<int>(
              value: selectedSeats,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.yellow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.event_seat, color: Colors.black),
              ),
              items:
                  List.generate(6, (index) => index + 2).map((seats) {
                    return DropdownMenuItem<int>(
                      value: seats,
                      child: Text(
                        seats.toString(),
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() => selectedSeats = value);
              },
              validator:
                  (value) =>
                      value == null ? 'Please select number of seats' : null,
            ),
          ],
        ),
      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveCar,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFormValid() ? Colors.yellow : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        color: _isFormValid() ? Colors.black : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(prefixIcon, color: Colors.yellow),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
      ),
      style: GoogleFonts.poppins(color: Colors.white),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (value) => setState(() {}),
    );
  }
}
