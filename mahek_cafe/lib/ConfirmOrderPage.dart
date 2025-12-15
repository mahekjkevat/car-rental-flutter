import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'MapSelectionPage.dart';
import 'email_template.dart';
import 'OrderSuccessPage.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ConfirmOrderPage extends StatefulWidget {
  final String name;
  final double price;
  final String imgUrl;
  final bool isIce;

  const ConfirmOrderPage({
    super.key,
    required this.name,
    required this.price,
    required this.imgUrl,
    required this.isIce,
  });

  @override
  _OrderPageBody createState() => _OrderPageBody();
}

class _OrderPageBody extends State<ConfirmOrderPage> {
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
  int _quantity = 1;
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

    // FIX: Call processOrderAfterPayment to save data and navigate
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
        'description': 'Order: ${widget.name}',
        'prefill': {
          'contact': _mobileNumber.isNotEmpty ? _mobileNumber : '9999999999',
          'email':
              _email.isNotEmpty
                  ? _email
                  : (_currentUser?.email ?? 'customer@mahek.com'),
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
      builder:
          (context) => AlertDialog(
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
      _randomDeliveryFee =
          _selectedOption == 'Delivery'
              ? 20.0 + Random().nextDouble() * 10.0
              : 0.0;
    });
  }

  Future<void> _fetchAddress() async {
    if (_currentUser == null) return;

    final doc =
        await FirebaseFirestore.instance
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
    TextEditingController mobileController = TextEditingController(
      text: _mobileNumber,
    );
    TextEditingController pincodeController = TextEditingController(
      text: _pincode,
    );

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (BuildContext dialogContext, StateSetter dialogSetState) {
              void _handleMapSelection() async {
                LatLng initialLocation =
                    (_latitude != null && _longitude != null)
                        ? LatLng(_latitude!, _longitude!)
                        : const LatLng(20.7630, 72.9691);

                final result = await Navigator.push(
                  dialogContext,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            MapSelectionPage(initialLocation: initialLocation),
                  ),
                );

                if (result is LocationResult) {
                  setState(() {
                    _address = result.address;
                    _latitude = result.latitude;
                    _longitude = result.longitude;
                    _deliveryAddress =
                        '$_address, ${_selectedCity ?? ''}, $_pincode';
                  });
                  dialogSetState(() {});
                }
              }

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
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
                          _buildEmailDisplayField(
                            _currentUser?.email ?? _email,
                          ),
                          _buildTextField(
                            mobileController,
                            'Mobile Number',
                            keyboardType: TextInputType.phone,
                          ),
                          _buildCityDropdown(_selectedCity, (String? newValue) {
                            setState(() => _selectedCity = newValue);
                            dialogSetState(
                              () =>
                                  _deliveryAddress =
                                      '$_address, ${_selectedCity ?? ''}, $_pincode',
                            );
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
                                      _deliveryAddress =
                                          '$_address, ${_selectedCity!}, $_pincode';
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: Icon(
            Icons.lock_outline,
            color: Colors.grey[600],
            size: 18,
          ),
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
              child: Icon(
                Icons.info_outline,
                color: Colors.grey[500],
                size: 16,
              ),
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

  // FIXED: This method now properly saves order and navigates
  Future<void> _processOrderAfterPayment(String? paymentId) async {
    if (_currentUser == null) {
      _showErrorSnackbar('User not logged in.');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              Center(child: CircularProgressIndicator(color: accentOrange)),
    );

    try {
      final orderId = const Uuid().v4();
      double deliveryFee =
          _selectedOption == 'Delivery'
              ? double.parse(_randomDeliveryFee.toStringAsFixed(2))
              : 0.0;
      double totalPrice = (widget.price * _quantity) + deliveryFee;

      final orderData = {
        'orderId': orderId,
        'name': widget.name,
        'price': widget.price,
        'quantity': _quantity,
        'isIce': widget.isIce,
        'imgUrl': widget.imgUrl,
        'deliveryOption': _selectedOption,
        'deliveryAddress':
            _selectedOption == 'Delivery' ? _deliveryAddress : 'Pick Up',
        'latitude': _latitude,
        'longitude': _longitude,
        'paymentMethod': paymentId != null ? 'RazorPay' : 'Cash on Delivery',
        'totalPrice': totalPrice,
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

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('orders')
          .doc(orderId)
          .set(orderData);

      _printOrderDetails(orderData);
      await _sendOrderEmail(orderData);

      // Close loading dialog
      Navigator.pop(context);

      // FIX: Navigate to OrderSuccessPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => OrderSuccessPage(
                orderId: orderId,
                name: widget.name,
                totalPrice: totalPrice,
                quantity: _quantity,
                deliveryOption: _selectedOption,
                paymentMethod:
                    paymentId != null ? 'RazorPay' : 'Cash on Delivery',
              ),
        ),
      );
    } catch (e) {
      // Close loading dialog on error
      Navigator.pop(context);
      _showErrorSnackbar('Error placing order: $e');
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

  void _printOrderDetails(Map<String, dynamic> orderData) {
    print(
      '🎉 ORDER PLACED: ${orderData['orderId']} - ₹${orderData['totalPrice']}',
    );
    print('📧 Email: ${orderData['userEmail']}');
    print('📞 Mobile: ${orderData['userMobile']}');
    print('🏠 Address: ${orderData['deliveryAddress']}');
  }

  Future<void> _sendOrderEmail(Map<String, dynamic> orderData) async {
    final subject = '🎉 Order Confirmed - Mahek Food Delivery';
    final bodyText = '''
We're excited to confirm your order! Here are your order details:

📋 ORDER SUMMARY
• Order ID: ${orderData['orderId']}
• Item: ${orderData['name']}
• Type: ${orderData['isIce'] ? 'Ice' : 'Hot'}
• Quantity: ${orderData['quantity']}
• Total Amount: ₹${orderData['totalPrice']}
• Delivery Option: ${orderData['deliveryOption']}
• Payment Method: ${orderData['paymentMethod']}

🏠 DELIVERY ADDRESS
${orderData['deliveryAddress']}

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
        (_deliveryAddress.isEmpty ||
            _selectedCity == null ||
            _latitude == null)) {
      return _showErrorSnackbar(
        'Please complete your delivery address (City and Map location).',
      );
    }

    double deliveryFee =
        _selectedOption == 'Delivery'
            ? double.parse(_randomDeliveryFee.toStringAsFixed(2))
            : 0.0;
    double totalPrice = (widget.price * _quantity) + deliveryFee;

    _openRazorPayPayment(totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    double deliveryFee =
        _selectedOption == 'Delivery'
            ? double.parse(_randomDeliveryFee.toStringAsFixed(2))
            : 0.0;
    double totalPrice = (widget.price * _quantity) + deliveryFee;

    return Scaffold(
      backgroundColor: lightBgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: ClipPath(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBrown.withOpacity(0.9),
                  accentOrange.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentOrange,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    Text(
                      'Place Order',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 13),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            color:
                                _deliveryAddress.isEmpty
                                    ? Colors.grey[600]
                                    : primaryBrown,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: _editDeliveryAddress,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
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

              _buildSectionTitle('Your Item'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _buildContainerDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: widget.imgUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: accentOrange,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/images/cofee.png',
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryBrown,
                            ),
                          ),
                          Text(
                            '${widget.isIce ? 'Ice' : 'Hot'} • ₹${widget.price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: primaryBrown.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildQuantityButton(
                          Icons.remove,
                          () => setState(
                            () => _quantity > 1 ? _quantity-- : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_quantity',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryBrown,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          Icons.add,
                          () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Payment Summary'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _buildContainerDecoration(),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Item Price (${_quantity}x)',
                      '₹${(widget.price * _quantity).toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Delivery Fee',
                      '₹${deliveryFee.toStringAsFixed(2)}',
                      isHighlighted: deliveryFee > 0,
                    ),
                    const Divider(color: Colors.brown, height: 20),
                    _buildSummaryRow(
                      'Total',
                      '₹${totalPrice.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPaymentProcessing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isPaymentProcessing ? Colors.grey : accentOrange,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child:
                      _isPaymentProcessing
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
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
                            'Place Order (₹${totalPrice.toStringAsFixed(2)})',
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
      ),
    );
  }

  // Helper methods
  Widget _buildCityDropdown(
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
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
        items:
            _cities.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(color: primaryBrown),
                ),
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
            labelStyle: GoogleFonts.poppins(
              color: primaryBrown.withOpacity(0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: Icon(Icons.map, color: accentOrange),
          ),
          child: Text(
            _address.isEmpty
                ? 'Tap to select location on Map'
                : 'Address: $_address',
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
                color:
                    isSelected ? Colors.white : primaryBrown.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: accentOrange),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isHighlighted = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color:
                isHighlighted
                    ? accentOrange
                    : primaryBrown.withOpacity(isTotal ? 1 : 0.7),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color:
                isHighlighted
                    ? accentOrange
                    : primaryBrown.withOpacity(isTotal ? 1 : 0.8),
          ),
        ),
      ],
    );
  }
}
