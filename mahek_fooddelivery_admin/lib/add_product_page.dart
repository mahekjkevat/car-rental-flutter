import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appwrite/appwrite.dart';
import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:mahek_fooddelivery_admin/admin_mahek_toast.dart';

import 'CategoryManagementPage.dart';

class AddProductPage extends StatefulWidget {
  final Client client;

  const AddProductPage({super.key, required this.client});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightBackground = const Color(0xFFFBFBFB);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _selectedType;
  XFile? _pickedImage;
  bool _isLoading = false;

  List<String> _productTypes = [];
  bool _isTypesLoading = true;
  late Storage _storage;

  @override
  void initState() {
    super.initState();
    _storage = Storage(widget.client);
    _fetchProductTypes();
  }

  // Generate random 10-character product ID
  String _generateProductID() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        10,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _fetchProductTypes() async {
    setState(() {
      _isTypesLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('category')
          .get();
      final Set<String> uniqueTypes = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type']; // Use 'name' field from category collection

        if (type is String && type.isNotEmpty) {
          uniqueTypes.add(type);
        }
      }

      setState(() {
        _productTypes = uniqueTypes.toList()..sort();
        _isTypesLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching product types: $e');
      if (mounted) {
        context.showErrorToast(
          'Failed to load product categories. Please check your connection.',
        );
      }
      setState(() {
        _productTypes = [];
        _isTypesLoading = false;
      });
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('🔄 Starting AppWrite upload...');
      print('📁 File: $fileName');
      print('📦 Bucket ID: 68f2a07f002878b444a0');

      final response = await _storage.createFile(
        bucketId: '68f2a07f002878b444a0',
        fileId: ID.unique(),
        file: InputFile(path: image.path, filename: fileName),
      );

      print('✅ AppWrite upload successful!');
      print('📄 File ID: ${response.$id}');

      // Generate the file URL - Use the exact same format as AppWrite provides
      final fileUrl = 'https://fra.cloud.appwrite.io/v1/storage/buckets/68f2a07f002878b444a0/files/${response.$id}/view?project=68f2a01f00207f73a4d3';

      print('🔗 Generated URL: $fileUrl');
      return fileUrl;

    } catch (e) {
      print('❌ AppWrite upload error: $e');
      if (mounted) {
        context.showErrorToast('Failed to upload image. Please try again.');
      }
      return null;
    }
  }
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate() || _pickedImage == null) {
      context.showWarningToast(
        _pickedImage == null
            ? 'Please select an image and fill all fields.'
            : 'Please fill all fields.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(),
    );

    try {
      print('🚀 Starting product submission process...');

      // 1. Upload Image to AppWrite
      print('📤 Uploading image to AppWrite...');
      final imageUrl = await _uploadImage(_pickedImage!);
      if (imageUrl == null) {
        throw Exception('Image upload failed.');
      }
      print('✅ Image uploaded successfully: $imageUrl');

      // 2. Generate Product ID
      final productID = _generateProductID();
      print('🆔 Generated Product ID: $productID');

      // 3. Prepare Product Data
      final newProduct = {
        'productID': productID, // Add the generated productID
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'rate': 1.0,
        'type': _selectedType,
        'img_url': imageUrl, // This will now be the AppWrite URL
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      print('📊 Product Data to Save:');
      print('  - productID: $productID');
      print('  - name: ${_nameController.text}');
      print('  - type: $_selectedType');
      print('  - img_url: $imageUrl');

      // 4. Save to Firestore
      print('💾 Saving product to Firestore...');
      await FirebaseFirestore.instance.collection('products').add(newProduct);

      print('🎉 Product "${_nameController.text}" added successfully!');

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        context.showSuccessToast(
          'Product "${_nameController.text}" added successfully!',
        );

        // Clear fields after successful submission
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        setState(() {
          _selectedType = null;
          _pickedImage = null;
        });

        // Re-fetch types
        _fetchProductTypes();
      }
    } catch (e) {
      debugPrint('❌ Product submission error: $e');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        context.showErrorToast('Failed to add product. Please try again.');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryAppColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: primaryAppColor, width: 2),
          ),
          filled: true,
          fillColor: lightBackground,
        ),
        style: GoogleFonts.poppins(color: secondaryDarkColor),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the $label';
          }
          if (keyboardType == TextInputType.number) {
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTypeDropdown() {
    if (_isTypesLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            Text(
              'Loading Product Categories...',
              style: GoogleFonts.poppins(
                color: secondaryDarkColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(color: primaryAppColor),
          ],
        ),
      );
    }

    if (_productTypes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          'No categories found. Please add categories first.',
          style: GoogleFonts.poppins(
            color: primaryAppColor,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedType,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.category_rounded, color: primaryAppColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: primaryAppColor, width: 2),
          ),
          filled: true,
          fillColor: lightBackground,
        ),
        hint: Text(
          'Select Product Category',
          style: GoogleFonts.poppins(
            color: secondaryDarkColor.withOpacity(0.7),
          ),
        ),
        items: _productTypes
            .map(
              (String type) => DropdownMenuItem<String>(
                value: type,
                child: Text(
                  type,
                  style: GoogleFonts.poppins(color: secondaryDarkColor),
                ),
              ),
            )
            .toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedType = newValue;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a product category';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'Add New Product',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: secondaryDarkColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: secondaryDarkColor),
        actions: [
          IconButton(
            icon: Icon(Icons.category, color: primaryAppColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CategoryManagementPage(client: widget.client),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pickedImage == null
                          ? Colors.grey.shade300
                          : primaryAppColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: secondaryDarkColor.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _pickedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              size: 50,
                              color: primaryAppColor.withOpacity(0.7),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to select image',
                              style: GoogleFonts.poppins(
                                color: secondaryDarkColor.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_pickedImage!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 25),

              _buildTextField(_nameController, 'Name', Icons.fastfood_rounded),
              _buildTextField(
                _descriptionController,
                'Description',
                Icons.description_rounded,
                maxLines: 3,
              ),
              _buildTextField(
                _priceController,
                'Price (₹)',
                Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
              ),
              _buildTypeDropdown(),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAppColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 8,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        'Save Product to Catalog',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CategoryManagementPage(client: widget.client),
            ),
          );
        },
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.category),
        label: Text(
          'Manage Categories',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
              'Adding Product...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we save your product',
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
