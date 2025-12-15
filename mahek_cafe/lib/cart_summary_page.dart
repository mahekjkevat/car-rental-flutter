// cart_summary_page.dart
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'MapSelectionPage.dart';
import 'email_template.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CartSummaryPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double total;

  const CartSummaryPage({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  _CartSummaryPageState createState() => _CartSummaryPageState();
}

class _CartSummaryPageState extends State<CartSummaryPage> {
  final Color primaryBrown = const Color(0xFF6D4C41);
  final Color accentOrange = const Color(0xFFE65100);
  final Color lightBgColor = const Color(0xFFFAF7F5);

  final List<String> _cities = [
    'BILIMORA',
    'SURAT',
    'BARDOLI',
    'NAVSARI',
    'GANDEVI',
  ];

  String _selectedOption = 'Delivery';
  String _deliveryAddress = '';
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _name = '';
  String _email = '';
  String _mobileNumber = '';
  String _address = '';
  String? _selectedCity;
  String _pincode = '';
  double? _latitude;
  double? _longitude;
  double _randomDeliveryFee = 0.0;

  late Razorpay _razorpay;
  bool _isPaymentProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _fetchAddress();
    _generateDeliveryFee();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
        PaymentSuccessResponse response,
        ) {
      _handlePaymentSuccess(response);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (dynamic errorResponse) {
      _handlePaymentErrorSafe(errorResponse);
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (
        ExternalWalletResponse response,
        ) {
      _handleExternalWallet(response);
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('✅ Payment Successful: ${response.paymentId}');
    setState(() => _isPaymentProcessing = false);
    _processOrderAfterPayment(response.paymentId);
  }

  void _handlePaymentErrorSafe(dynamic errorResponse) {
    print('❌ PAYMENT ERROR: $errorResponse');
    setState(() => _isPaymentProcessing = false);

    String errorMessage = 'Payment failed. Please try again.';

    try {
      if (errorResponse is PaymentFailureResponse) {
        errorMessage = errorResponse.message ?? errorMessage;
        print('Error Code: ${errorResponse.code}');
      } else if (errorResponse is Map<String, dynamic>) {
        errorMessage = errorResponse['message']?.toString() ?? errorMessage;
      } else if (errorResponse is String) {
        errorMessage = errorResponse;
      }
    } catch (e) {
      print('Error parsing error response: $e');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('💼 External Wallet Selected: ${response.walletName}');
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openRazorPayPayment(double totalAmount) async {
    if (_isPaymentProcessing) return;

    setState(() => _isPaymentProcessing = true);

    try {
      if (totalAmount <= 0) {
        throw Exception('Invalid amount: $totalAmount');
      }

      final options = {
        'key': 'rzp_test_rZKfDFHhxQJLOI',
        'amount': (totalAmount * 100).round(),
        'name': 'Mahek Food Delivery',
        'description': 'Cart Order',
        'prefill': {
          'contact': _mobileNumber.isNotEmpty ? _mobileNumber : '9999999999',
          'email': _email.isNotEmpty ? _email : (_currentUser?.email ?? 'customer@mahek.com'),
        },
        'theme': {'color': '#F96D0A'},
        'timeout': 300,
      };

      print('💰 Opening RazorPay: ₹$totalAmount (${options['amount']} paise)');
      await Future.delayed(const Duration(milliseconds: 300));
      _razorpay.open(options);
    } catch (e) {
      print('❌ RazorPay Setup Error: $e');
      setState(() => _isPaymentProcessing = false);
      _showPaymentFallbackDialog(totalAmount);
    }
  }

  void _showPaymentFallbackDialog(double totalAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Error'),
        content: Text(
          'Could not open Razorpay for ₹$totalAmount. Try again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _processCashOnDelivery(double totalAmount) {
    setState(() => _isPaymentProcessing = true);
    _processOrderAfterPayment(null);
  }

  void _generateDeliveryFee() {
    setState(() {
      _randomDeliveryFee = _selectedOption == 'Delivery'
          ? 20.0 + Random().nextDouble() * 10.0
          : 0.0;
    });
  }

  Future<void> _fetchAddress() async {
    if (_currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('Address')
        .doc('default')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _name = data['name'] ?? '';
        _email = data['email'] ?? '';
        _mobileNumber = data['mobileNumber'] ?? '';
        _address = data['address'] ?? '';
        _selectedCity = data['cityUrban'];
        _pincode = data['pincode'] ?? '';
        _latitude = data['latitude'];
        _longitude = data['longitude'];
        _deliveryAddress = '$_address, ${_selectedCity ?? ''}, $_pincode';
      });
    }
  }

  void _editDeliveryAddress() {
    TextEditingController nameController = TextEditingController(text: _name);
    TextEditingController mobileController = TextEditingController(text: _mobileNumber);
    TextEditingController pincodeController = TextEditingController(text: _pincode);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter dialogSetState) {
          void _handleMapSelection() async {
            LatLng initialLocation = (_latitude != null && _longitude != null)
                ? LatLng(_latitude!, _longitude!)
                : const LatLng(20.7630, 72.9691);

            final result = await Navigator.push(
              dialogContext,
              MaterialPageRoute(
                builder: (context) => MapSelectionPage(initialLocation: initialLocation),
              ),
            );

            if (result is LocationResult) {
              setState(() {
                _address = result.address;
                _latitude = result.latitude;
                _longitude = result.longitude;
                _deliveryAddress = '$_address, ${_selectedCity ?? ''}, $_pincode';
              });
              dialogSetState(() {});
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            child: Container(
              decoration: BoxDecoration(
                color: lightBgColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: primaryBrown.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Update Address',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown,
                        ),
                      ),
                      const Divider(color: Colors.brown, height: 24),
                      _buildTextField(nameController, 'Name'),
                      _buildEmailDisplayField(_currentUser?.email ?? _email),
                      _buildTextField(
                        mobileController,
                        'Mobile Number',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildCityDropdown(_selectedCity, (String? newValue) {
                        setState(() => _selectedCity = newValue);
                        dialogSetState(() => _deliveryAddress = '$_address, ${_selectedCity ?? ''}, $_pincode');
                      }),
                      const SizedBox(height: 12),
                      _buildTextField(
                        pincodeController,
                        'Pincode',
                        keyboardType: TextInputType.number,
                      ),
                      _buildAddressField(onTap: _handleMapSelection),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: primaryBrown.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty &&
                                  _address.isNotEmpty &&
                                  _selectedCity != null &&
                                  _latitude != null) {
                                setState(() {
                                  _name = nameController.text;
                                  _email = _currentUser?.email ?? _email;
                                  _mobileNumber = mobileController.text;
                                  _pincode = pincodeController.text;
                                  _deliveryAddress = '$_address, ${_selectedCity!}, $_pincode';
                                });
                                _saveAddressToFirestore();
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please select a City, Pincode, and location on the map.',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: accentOrange,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBrown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              'Save Address',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailDisplayField(String email) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: GoogleFonts.poppins(color: primaryBrown.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: Icon(Icons.lock_outline, color: Colors.grey[600], size: 18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                email,
                style: GoogleFonts.poppins(
                  color: primaryBrown.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            Tooltip(
              message: 'Email is managed by your account',
              child: Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAddressToFirestore() async {
    if (_currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('Address')
        .doc('default')
        .set({
      'name': _name,
      'email': _currentUser?.email ?? _email,
      'mobileNumber': _mobileNumber,
      'address': _address,
      'cityUrban': _selectedCity,
      'pincode': _pincode,
      'latitude': _latitude,
      'longitude': _longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _processOrderAfterPayment(String? paymentId) async {
    if (_currentUser == null) {
      _showErrorSnackbar('User not logged in.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: accentOrange)),
    );

    try {
      final orderId = const Uuid().v4();
      double deliveryFee = _selectedOption == 'Delivery'
          ? double.parse(_randomDeliveryFee.toStringAsFixed(2))
          : 0.0;

      // Calculate total for all cart items
      double itemsTotal = widget.cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
      double totalPrice = itemsTotal + deliveryFee;

      // Save each item as individual order
      for (var item in widget.cartItems) {
        final itemOrderId = '${orderId}_${item['docId']}';
        final orderData = {
          'orderId': itemOrderId,
          'parentOrderId': orderId,
          'name': item['name'],
          'price': item['price'],
          'quantity': item['quantity'],
          'imgUrl': item['imgUrl'],
          'deliveryOption': _selectedOption,
          'deliveryAddress': _selectedOption == 'Delivery' ? _deliveryAddress : 'Pick Up',
          'latitude': _latitude,
          'longitude': _longitude,
          'paymentMethod': paymentId != null ? 'RazorPay' : 'Cash on Delivery',
          'totalPrice': (item['price'] * item['quantity']) + (deliveryFee / widget.cartItems.length),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Processing',
          'userEmail': _email,
          'userMobile': _mobileNumber,
          'userCity': _selectedCity,
          'cityPinCode': _pincode,
          'userName': _name,
          'paymentId': paymentId,
          'paymentStatus': paymentId != null ? 'Completed' : 'Pending',
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('orders')
            .doc(itemOrderId)
            .set(orderData);
      }

      // Clear cart after successful order
      await _clearCart();

      _printOrderDetails(orderId, totalPrice);
      await _sendOrderEmail(orderId, totalPrice);

      Navigator.pop(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CartOrderSuccessPage(
            orderId: orderId,
            cartItems: widget.cartItems,
            totalPrice: totalPrice,
            deliveryOption: _selectedOption,
            paymentMethod: paymentId != null ? 'RazorPay' : 'Cash on Delivery',
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackbar('Error placing order: $e');
    }
  }

  Future<void> _clearCart() async {
    if (_currentUser == null) return;

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('addToCart')
          .get();

      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  void _printOrderDetails(String orderId, double totalPrice) {
    print('🎉 CART ORDER PLACED: $orderId - ₹$totalPrice');
    print('📧 Email: $_email');
    print('📞 Mobile: $_mobileNumber');
    print('🏠 Address: $_deliveryAddress');
    print('📦 Items Count: ${widget.cartItems.length}');
  }

  Future<void> _sendOrderEmail(String orderId, double totalPrice) async {
    final subject = '🎉 Cart Order Confirmed - Mahek Food Delivery';

    String itemsList = '';
    for (var item in widget.cartItems) {
      itemsList += '• ${item['name']} (Qty: ${item['quantity']}) - ₹${(item['price'] * item['quantity']).toStringAsFixed(2)}\n';
    }

    final bodyText = '''
We're excited to confirm your cart order! Here are your order details:

📋 ORDER SUMMARY
• Order ID: $orderId
• Total Amount: ₹${totalPrice.toStringAsFixed(2)}
• Delivery Option: $_selectedOption
• Payment Method: ${_isPaymentProcessing ? 'RazorPay' : 'Cash on Delivery'}

🛒 ORDER ITEMS:
$itemsList

🏠 DELIVERY ADDRESS
$_deliveryAddress

Thank you for choosing Mahek Food Delivery! 🍕☕
''';

    final emailSent = await CallMahekForeverMail(
      subject: subject,
      bodyText: bodyText,
      recipientEmail: _email,
    );

    print(emailSent ? '✅ Email sent to $_email' : '❌ Failed to send email');
  }

  void _placeOrder() async {
    if (_isPaymentProcessing) return;
    if (_currentUser == null) return _showErrorSnackbar('User not logged in.');

    if (_selectedOption == 'Delivery' &&
        (_deliveryAddress.isEmpty || _selectedCity == null || _latitude == null)) {
      return _showErrorSnackbar(
        'Please complete your delivery address (City and Map location).',
      );
    }

    double deliveryFee = _selectedOption == 'Delivery'
        ? double.parse(_randomDeliveryFee.toStringAsFixed(2))
        : 0.0;
    double itemsTotal = widget.cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
    double totalPrice = itemsTotal + deliveryFee;

    _openRazorPayPayment(totalPrice);
  }

  // Helper Widgets
  Widget _buildCityDropdown(String? currentValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: 'Select City/Urban',
          labelStyle: GoogleFonts.poppins(color: primaryBrown.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _cities.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: GoogleFonts.poppins(color: primaryBrown)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddressField({required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Delivery Address from Map',
            labelStyle: GoogleFonts.poppins(color: primaryBrown.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: Icon(Icons.map, color: accentOrange),
          ),
          child: Text(
            _address.isEmpty ? 'Tap to select location on Map' : 'Address: $_address',
            style: GoogleFonts.poppins(
              color: _address.isEmpty ? Colors.grey : primaryBrown,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: primaryBrown.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        style: GoogleFonts.poppins(color: primaryBrown),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? accentOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? accentOrange : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : primaryBrown.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double deliveryFee = _selectedOption == 'Delivery'
        ? double.parse(_randomDeliveryFee.toStringAsFixed(2))
        : 0.0;
    double itemsTotal = widget.cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
    double totalPrice = itemsTotal + deliveryFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Order Summary',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF96D0A),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Scrollable Cart Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Type Section
                  _buildSectionTitle('Order Type'),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: _buildContainerDecoration(),
                    child: Row(
                      children: [
                        _buildToggleButton(
                          'Delivery',
                          _selectedOption == 'Delivery',
                              () {
                            setState(() {
                              _selectedOption = 'Delivery';
                              _generateDeliveryFee();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildToggleButton(
                          'Pick Up',
                          _selectedOption == 'Pick Up',
                              () {
                            setState(() {
                              _selectedOption = 'Pick Up';
                              _randomDeliveryFee = 0.0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Delivery Address Section (Non-scrollable in layout)
                  if (_selectedOption == 'Delivery') ...[
                    _buildSectionTitle('Delivery Address'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _buildContainerDecoration(),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: accentOrange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _deliveryAddress.isEmpty
                                  ? 'Tap "Edit" to set your address'
                                  : _deliveryAddress,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _deliveryAddress.isEmpty ? Colors.grey[600] : primaryBrown,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: _editDeliveryAddress,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                color: primaryBrown,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Edit',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Cart Items
                  _buildSectionTitle('Order Items (${widget.cartItems.length})'),
                  const SizedBox(height: 12),
                  ...widget.cartItems.map((item) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6D4C41).withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFE65100).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: item['imgUrl'],
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(color: const Color(0xFF6D4C41)),
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/images/coffee.png',
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6D4C41),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Quantity: ${item['quantity']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),

          // Fixed Bottom Section with Pay Now Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6D4C41).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSummaryRow('Items Total', '₹${itemsTotal.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _buildSummaryRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(2)}', isHighlighted: deliveryFee > 0),
                const Divider(height: 28, thickness: 1.5, color: Colors.grey),
                _buildSummaryRow('Total', '₹${totalPrice.toStringAsFixed(2)}', isTotal: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPaymentProcessing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPaymentProcessing ? Colors.grey : accentOrange,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                      shadowColor: const Color(0xFFE65100).withOpacity(0.6),
                    ),
                    child: _isPaymentProcessing
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
                        const SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                        : Text(
                      'Pay Now (₹${totalPrice.toStringAsFixed(2)})',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryBrown,
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: lightBgColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted ? accentOrange : primaryBrown.withOpacity(isTotal ? 1 : 0.7),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isHighlighted ? accentOrange : primaryBrown.withOpacity(isTotal ? 1 : 0.8),
          ),
        ),
      ],
    );
  }
}

// Cart Order Success Page
class CartOrderSuccessPage extends StatelessWidget {
  final String orderId;
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;
  final String deliveryOption;
  final String paymentMethod;

  const CartOrderSuccessPage({
    super.key,
    required this.orderId,
    required this.cartItems,
    required this.totalPrice,
    required this.deliveryOption,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F5),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Success Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFFE65100),
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Success Message
                    Text(
                      'Order Confirmed!',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6D4C41),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Your order has been successfully placed',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: const Color(0xFF6D4C41).withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Order ID: $orderId',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Order Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6D4C41).withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6D4C41),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Order Items
                          ...cartItems.take(3).map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item['name']} (x${item['quantity']})',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF6D4C41),
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6D4C41),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),

                          if (cartItems.length > 3) ...[
                            Text(
                              '+ ${cartItems.length - 3} more items',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF6D4C41).withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          const Divider(height: 20, color: Colors.grey),

                          // Total and Details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6D4C41),
                                ),
                              ),
                              Text(
                                '₹${totalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Delivery',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF6D4C41).withOpacity(0.7),
                                ),
                              ),
                              Text(
                                deliveryOption,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF6D4C41).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF6D4C41).withOpacity(0.7),
                                ),
                              ),
                              Text(
                                paymentMethod,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF6D4C41).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Thank You Message
                    Text(
                      'Thank you for your order! 🎉',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF6D4C41).withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'You will receive an email confirmation shortly.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6D4C41).withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D4C41).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 8,
                  ),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}