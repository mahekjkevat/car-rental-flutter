import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gear_go/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'EmailService.dart';
import 'car_booking_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'cancel_car_booking.dart';

class AcceptedBookingCarViewPage extends StatefulWidget {
  final CarBooking? booking;
  final Map<String, dynamic>? bookingData;

  const AcceptedBookingCarViewPage({Key? key, this.booking, this.bookingData})
    : super(key: key);

  @override
  _AcceptedBookingCarViewPageState createState() =>
      _AcceptedBookingCarViewPageState();
}

class _AcceptedBookingCarViewPageState extends State<AcceptedBookingCarViewPage>
    with SingleTickerProviderStateMixin {
  late CarBooking _booking;
  late Map<String, dynamic> _bookingData;
  String _titleText = 'Booking Details';
  late Razorpay _razorpay;
  bool _isProcessingPayment = false;
  bool _isPaymentSuccess = false;

  // Discount-related variables
  final TextEditingController _discountController = TextEditingController();
  bool _showDiscountField = false;
  double _discountPercentage = 0.0;
  double _finalPrice = 0.0;
  bool _isDiscountApplied = false;
  bool _isDiscountValidating = false;
  Timer? _discountTimer;
  int _timerSeconds = 300; // 5 minutes
  bool _showTimer = false;

  late AnimationController _animationController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize booking data
    if (widget.booking != null) {
      _booking = widget.booking!;
      _bookingData = _booking.toMap();
    } else if (widget.bookingData != null) {
      _bookingData = widget.bookingData!;
      _booking = CarBooking.fromMap(_bookingData, _bookingData['id'] ?? '');
    } else {
      throw Exception("Either booking or bookingData must be provided");
    }

    _finalPrice = _booking.totalPrice;

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Check if payment is already successful
    if (_bookingData['status'] == 'confirmed') {
      _isPaymentSuccess = true;
    }

    _animationController.forward();
  }

  // Check if discount is valid based on date range
  bool _isDiscountValid() {
    final now = DateTime.now();
    final startDate = DateTime(2025, 11, 1); // 01/11/2025
    final endDate = DateTime(
      2025,
      12,
      31,
      23,
      59,
      59,
    ); // 31/12/2025 11:59:59 PM

    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Discount code validation and probability system
  void _validateDiscountCode() async {
    if (_discountController.text.isEmpty) {
      CustomToast.show(
        context: context,
        message: "Please enter a discount code",
        duration: Duration(seconds: 3),
        textColor: Colors.white,
        gradientColors: [Colors.orange, Colors.orangeAccent],
      );
      return;
    }

    // Check if discount period is valid
    if (!_isDiscountValid()) {
      setState(() {
        _isDiscountValidating = false;
      });
      CustomToast.show(
        context: context,
        message: "Discount period has ended (Valid: 01/11/2025 - 31/12/2025)",
        duration: Duration(seconds: 4),
        textColor: Colors.white,
        gradientColors: [Colors.red, Colors.orange],
      );
      return;
    }

    setState(() {
      _isDiscountValidating = true;
    });

    // Simulate API call delay
    await Future.delayed(Duration(seconds: 2));

    // Check if discount code is valid
    bool isValidCode =
        _discountController.text.toLowerCase() == 'save10' ||
        _discountController.text.toLowerCase() == 'discount20' ||
        _discountController.text.toLowerCase() == 'carrental' ||
        _discountController.text.toUpperCase() == 'GEARGO1YEAR';

    if (isValidCode) {
      // SPECIAL ANNIVERSARY DISCOUNT: GEARGO1YEAR gets fixed discount based on new rules
      if (_discountController.text.toUpperCase() == 'GEARGO1YEAR') {
        _generateFixedDiscount(); // Use new fixed probability system
        _showSpecialAnniversaryPopup();
      } else {
        _generateRandomDiscount();
        _showDiscountPopup();
      }
    } else {
      setState(() {
        _isDiscountValidating = false;
      });
      CustomToast.show(
        context: context,
        message: "Invalid discount code",
        duration: Duration(seconds: 3),
        textColor: Colors.white,
        gradientColors: [Colors.red, Colors.orange],
      );
    }
  }

  // New fixed discount probability system
  void _generateFixedDiscount() {
    Random random = Random();
    int chance = random.nextInt(100); // 0-99

    if (chance < 70) {
      // 70% chance for 1-25% discount
      _discountPercentage = 1.0 + random.nextInt(25); // 1% to 25%
      print(
        "🎉 Discount Applied: ${_discountPercentage.toStringAsFixed(1)}% (70% probability tier)",
      );
    } else if (chance < 95) {
      // 25% chance for 26-45% discount
      _discountPercentage = 26.0 + random.nextInt(20); // 26% to 45%
      print(
        "🎉 Discount Applied: ${_discountPercentage.toStringAsFixed(1)}% (25% probability tier)",
      );
    } else {
      // 5% chance for 46-50% discount
      _discountPercentage = 46.0 + random.nextInt(5); // 46% to 50%
      print(
        "🎉 Discount Applied: ${_discountPercentage.toStringAsFixed(1)}% (5% probability tier - LUCKY!)",
      );
    }

    // Calculate final price
    _finalPrice = _booking.totalPrice * (1 - _discountPercentage / 100);

    setState(() {
      _isDiscountApplied = true;
      _isDiscountValidating = false;
    });
  }

  void _generateRandomDiscount() {
    Random random = Random();
    int chance = random.nextInt(100); // 0-99

    if (chance < 70) {
      // 70% chance for 1-25% discount
      _discountPercentage = 1.0 + random.nextInt(25);
      print(
        "🎉 Discount Applied: ${_discountPercentage.toStringAsFixed(1)}% (70% probability tier)",
      );
    } else if (chance < 95) {
      // 25% chance for 26-45% discount
      _discountPercentage = 26.0 + random.nextInt(20);
      print(
        "🎉 Discount Applied: ${_discountPercentage.toStringAsFixed(1)}% (25% probability tier)",
      );
    } else {
      // 5% chance for 46-50% discount
      _discountPercentage = 46.0 + random.nextInt(5);
      print(
        "🎉 Discount Applied: ${_discountPercentage.toStringAsFixed(1)}% (5% probability tier - LUCKY!)",
      );
    }

    // Calculate final price
    _finalPrice = _booking.totalPrice * (1 - _discountPercentage / 100);

    setState(() {
      _isDiscountApplied = true;
      _isDiscountValidating = false;
    });
  }

  // Special anniversary celebration popup
  void _showSpecialAnniversaryPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.orange[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(Icons.celebration, color: Colors.orange, size: 50),
              SizedBox(height: 10),
              Text(
                "🎉 Happy 1st Anniversary! 🎉",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You got ${_discountPercentage.toStringAsFixed(1)}% OFF!",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              // Original price with strikethrough
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Original: ",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    "₹${_booking.totalPrice.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              // Final price
              Text(
                "Final: ₹${_finalPrice.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "You saved: ₹${(_booking.totalPrice - _finalPrice).toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 15),
              Text(
                "Thank you for celebrating with us!",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _startDiscountTimer();
                      },
                      child: Text(
                        "Not Satisfied",
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openCheckoutWithDiscount();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: Text(
                        "Pay Now",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDiscountPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "🎉 Discount Applied!",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You got ${_discountPercentage.toStringAsFixed(1)}% OFF!",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              // Original price with strikethrough
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Original: ",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    "₹${_booking.totalPrice.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              // Final price
              Text(
                "Final: ₹${_finalPrice.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "You saved: ₹${(_booking.totalPrice - _finalPrice).toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _startDiscountTimer();
                      },
                      child: Text(
                        "Not Satisfied",
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openCheckoutWithDiscount();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        "Pay Now",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _startDiscountTimer() {
    setState(() {
      _showTimer = true;
      _isDiscountApplied = false;
      _discountPercentage = 0.0;
      _finalPrice = _booking.totalPrice;
    });

    _discountTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _showTimer = false;
          _timerSeconds = 300;
        });
        _showPaymentWithoutDiscountDialog();
      }
    });
  }

  void _showPaymentWithoutDiscountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Time's Up!",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Discount offer has expired. You can proceed to pay the original amount.",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _openCheckoutWithDiscount() {
    setState(() => _isProcessingPayment = true);
    print(
      "💳 Proceeding to payment with ${_discountPercentage.toStringAsFixed(1)}% discount",
    );
    print(
      "💰 Original: ₹${_booking.totalPrice.toStringAsFixed(2)} | Final: ₹${_finalPrice.toStringAsFixed(2)} | Saved: ₹${(_booking.totalPrice - _finalPrice).toStringAsFixed(2)}",
    );

    try {
      final amount = (_finalPrice * 100).toInt();
      final options = {
        'key': 'rzp_test_VMCy3olYpU8PYs',
        'amount': amount,
        'name': 'Car Rental Service',
        'description':
            'Car Rental Payment for ${_bookingData['carName']} (${_discountPercentage.toStringAsFixed(1)}% discount applied)',
        'prefill': {
          'contact': _bookingData['userMobile'] ?? '1234567890',
          'email': _bookingData['userEmail'] ?? 'user@example.com',
        },
        'theme': {'color': '#007BFF'},
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      Fluttertoast.showToast(msg: "Error initializing payment: $e");
    }
  }

  void _openCheckout() async {
    // If discount is applied, use the discounted price
    if (_isDiscountApplied) {
      _openCheckoutWithDiscount();
      return;
    }

    // Show discount input dialog if not already showing
    if (!_showDiscountField) {
      _showDiscountInputDialog();
      return;
    }

    // If no discount applied but discount field is shown, proceed with original price
    setState(() => _isProcessingPayment = true);
    print("💳 Proceeding to payment without discount");
    print("💰 Amount: ₹${_booking.totalPrice.toStringAsFixed(2)}");

    try {
      final options = {
        'key': 'rzp_test_VMCy3olYpU8PYs',
        'amount': (_bookingData['totalPrice'] * 100).toInt(),
        'name': 'Car Rental Service',
        'description': 'Car Rental Payment for ${_bookingData['carName']}',
        'prefill': {
          'contact': _bookingData['userMobile'] ?? '1234567890',
          'email': _bookingData['userEmail'] ?? 'user@example.com',
        },
        'theme': {'color': '#007BFF'},
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      Fluttertoast.showToast(msg: "Error initializing payment: $e");
    }
  }

  void _showDiscountInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.discount, color: Colors.orange),
              SizedBox(width: 10),
              Text(
                "Apply Discount Code",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your discount code to get special offers!",
                style: GoogleFonts.poppins(),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _discountController,
                decoration: InputDecoration(
                  hintText: "Enter discount code",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              if (_showTimer) ...[
                SizedBox(height: 10),
                Text(
                  "New discount available in: ${_formatTime(_timerSeconds)}",
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Valid until: 31/12/2025 11:59 PM",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Proceed to payment without discount
                setState(() {
                  _showDiscountField = true;
                });
                _openCheckoutWithoutDiscount();
              },
              child: Text("Skip"),
            ),
            ElevatedButton(
              onPressed: _isDiscountValidating ? null : _validateDiscountCode,
              child:
                  _isDiscountValidating
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  void _openCheckoutWithoutDiscount() {
    setState(() => _isProcessingPayment = true);
    print("💳 Proceeding to payment without discount (skipped)");
    print("💰 Amount: ₹${_booking.totalPrice.toStringAsFixed(2)}");

    try {
      final options = {
        'key': 'rzp_test_VMCy3olYpU8PYs',
        'amount': (_bookingData['totalPrice'] * 100).toInt(),
        'name': 'Car Rental Service',
        'description': 'Car Rental Payment for ${_bookingData['carName']}',
        'prefill': {
          'contact': _bookingData['userMobile'] ?? '1234567890',
          'email': _bookingData['userEmail'] ?? 'user@example.com',
        },
        'theme': {'color': '#007BFF'},
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      Fluttertoast.showToast(msg: "Error initializing payment: $e");
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Show discount information card
  void _showDiscountInfoCard() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[50]!, Colors.yellow[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.orange, size: 30),
                    SizedBox(width: 10),
                    Text(
                      "Discount Information",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Text(
                  "🎉 Special 1st Anniversary Offer!",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 10),
                _buildProbabilityInfo(
                  "70% chance",
                  "1% to 25% discount",
                  Colors.green,
                ),
                _buildProbabilityInfo(
                  "25% chance",
                  "26% to 45% discount",
                  Colors.orange,
                ),
                _buildProbabilityInfo(
                  "5% chance",
                  "46% to 50% discount",
                  Colors.red,
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Valid: 01/11/2025 - 31/12/2025 11:59 PM",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  "Use code: GEARGO1YEAR for anniversary discount",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showDiscountInputDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      "Apply Discount",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProbabilityInfo(String chance, String discount, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chance,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  discount,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _razorpay.clear();
    _discountTimer?.cancel();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        title: Text(
          _titleText,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showDiscountInfoCard,
            icon: Icon(Icons.info_outline, color: Colors.white),
            tooltip: "Discount Information",
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Payment Status Section
            if (!_isPaymentSuccess)
              FadeTransition(
                opacity: _animationController,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[700]!, Colors.orange[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.payment, color: Colors.white, size: 40),
                        SizedBox(height: 10),
                        Text(
                          'Payment Pending',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        if (_isDiscountApplied) ...[
                          Text(
                            'Discount: ${_discountPercentage.toStringAsFixed(1)}% OFF',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 5),
                          // Original price with strikethrough
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Original: ",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                "₹${_booking.totalPrice.toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          // Final price
                          Text(
                            'Final Price: ₹${_finalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'You save: ₹${(_booking.totalPrice - _finalPrice).toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.yellow[100],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                        ElevatedButton(
                          onPressed:
                              _isProcessingPayment ? null : _openCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child:
                              _isProcessingPayment
                                  ? CircularProgressIndicator(strokeWidth: 2)
                                  : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isDiscountApplied) ...[
                                        // Original price with strikethrough
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "₹${_booking.totalPrice.toStringAsFixed(2)}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2),
                                      ],
                                      Text(
                                        _isDiscountApplied
                                            ? 'Pay Now - ₹${_finalPrice.toStringAsFixed(2)}'
                                            : 'Pay Now - ₹${_bookingData['totalPrice']?.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                        if (_showTimer) ...[
                          SizedBox(height: 10),
                          Text(
                            'Discount expires in: ${_formatTime(_timerSeconds)}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        SizedBox(height: 5),
                        if (!_isDiscountApplied && _isDiscountValid())
                          TextButton(
                            onPressed: _showDiscountInputDialog,
                            child: Text(
                              "Have a discount code?",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else
              FadeTransition(
                opacity: _animationController,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[700]!, Colors.green[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 40),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Successful!',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Booking Confirmed',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              if (_isDiscountApplied)
                                Text(
                                  'Discount: ${_discountPercentage.toStringAsFixed(1)}% applied',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.yellow[100],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            SizedBox(height: 20),

            // Booking Details Card
            FadeTransition(
              opacity: _animationController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_cardAnimation),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  child: Column(
                    children: [
                      Hero(
                        tag: 'carImage-${_booking.carName}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            _booking.carImage1.isNotEmpty
                                ? _booking.carImage1
                                : 'https://via.placeholder.com/400x250',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SpinKitFadingCircle(color: Colors.blue);
                            },
                            errorBuilder:
                                (context, error, stackTrace) => Image.network(
                                  'https://via.placeholder.com/400x250',
                                ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Car Name',
                              _booking.carName,
                              Icons.directions_car,
                            ),
                            _buildDetailRow(
                              'Pickup Location',
                              _booking.fromAddress,
                              Icons.location_on,
                            ),
                            _buildDetailRow(
                              'Drop-off Location',
                              _booking.toAddress,
                              Icons.location_off,
                            ),
                            _buildDetailRow(
                              'Pickup Date',
                              DateFormat(
                                'd MMM, yyyy HH:mm',
                              ).format(_booking.pickUpDateTime.toDate()),
                              Icons.calendar_today,
                            ),
                            _buildDetailRow(
                              'Return Date',
                              DateFormat(
                                'd MMM, yyyy HH:mm',
                              ).format(_booking.returnDateTime.toDate()),
                              Icons.calendar_today,
                            ),
                            _buildDetailRow(
                              'Total Price',
                              '₹${_booking.totalPrice.toStringAsFixed(2)}',
                              Icons.attach_money,
                            ),
                            if (_isDiscountApplied)
                              Column(
                                children: [
                                  _buildDetailRow(
                                    'Discount Applied',
                                    '${_discountPercentage.toStringAsFixed(1)}% OFF',
                                    Icons.discount,
                                  ),
                                  _buildDetailRow(
                                    'Final Price',
                                    '₹${_finalPrice.toStringAsFixed(2)}',
                                    Icons.attach_money,
                                  ),
                                  _buildDetailRow(
                                    'You Saved',
                                    '₹${(_booking.totalPrice - _finalPrice).toStringAsFixed(2)}',
                                    Icons.savings,
                                  ),
                                ],
                              ),
                            _buildDetailRow(
                              'Status',
                              _bookingData['status'] ?? 'Pending',
                              Icons.info,
                            ),
                            _buildDetailRow(
                              'Payment Method',
                              _bookingData['payment_method'] ?? 'Pending',
                              Icons.payment,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue[800], size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                // Navigate to terms and conditions
              },
              child: Text(
                'Terms & Conditions',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<double>(
              future: _calculateCancelRefund(),
              builder: (context, snapshot) {
                final refundPercentage = snapshot.data ?? 0.0;
                return ElevatedButton(
                  onPressed: _navigateToCancelBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cancel Booking',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      Text(
                        '${refundPercentage.toInt()}% Refund',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Payment handling methods
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessingPayment = false);
    print("✅ PAYMENT SUCCESSFUL!");
    print("📊 Payment ID: ${response.paymentId}");
    print("💰 Amount: ₹${_finalPrice.toStringAsFixed(2)}");
    if (_isDiscountApplied) {
      print("🎉 Discount: ${_discountPercentage.toStringAsFixed(1)}% applied");
      print(
        "💵 Saved: ₹${(_booking.totalPrice - _finalPrice).toStringAsFixed(2)}",
      );
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Update booking status to confirmed
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('car_booking')
            .doc(_bookingData['id'])
            .update({
              'status': 'confirmed',
              'payment_method': 'RazorPay',
              'payment_date': Timestamp.now(),
              'payment_id': response.paymentId,
              'original_price': _booking.totalPrice,
              'discount_applied': _isDiscountApplied ? _discountPercentage : 0,
              'final_price': _finalPrice,
            });

        // Update local state
        setState(() {
          _bookingData['status'] = 'confirmed';
          _bookingData['payment_method'] = 'RazorPay';
          _isPaymentSuccess = true;
        });

        // Send email notifications to both customer and admin using SMTP
        await _sendPaymentConfirmationEmail();

        // Show success message
        CustomToast.show(
          context: context,
          message: "Payment Successful! Confirmation emails sent.",
          duration: Duration(seconds: 3),
          textColor: Colors.white,
          gradientColors: [Colors.green, Colors.lightGreen],
        );

        print("📧 Emails sent successfully");
        print("🎊 BOOKING COMPLETED SUCCESSFULLY!");
      }
    } catch (e) {
      print('❌ Error in payment success handler: $e');
      Fluttertoast.showToast(
        msg: "Payment successful but failed to update booking",
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessingPayment = false);
    print("❌ PAYMENT FAILED: ${response.message ?? 'Unknown error'}");
    CustomToast.show(
      context: context,
      message: "Payment Failed: ${response.message ?? 'Unknown error'}",
      duration: Duration(seconds: 3),
      textColor: Colors.white,
      gradientColors: [Colors.red, Colors.orange],
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessingPayment = false);
    print("🔗 External Wallet: ${response.walletName}");
    Fluttertoast.showToast(
      msg: "External Wallet: ${response.walletName}",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
    );
  }

  Future<void> _sendPaymentConfirmationEmail() async {
    try {
      final userEmail = _bookingData['userEmail'];
      final userName = _bookingData['userName'] ?? 'Customer';
      final carName = _bookingData['carName'] ?? 'Car';
      final totalPrice = _booking.totalPrice.toStringAsFixed(2);
      final finalPrice = _finalPrice.toStringAsFixed(2);
      final bookingId = _bookingData['id'] ?? 'N/A';
      final paymentDate = DateFormat(
        'd MMM yyyy, HH:mm',
      ).format(DateTime.now());

      // Send email to customer
      if (userEmail != null && userEmail.isNotEmpty) {
        final customerHtml = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; color: white; text-align: center; }
        .content { padding: 20px; }
        .details { background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0; }
        .footer { background: #343a40; color: white; padding: 15px; text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎉 Payment Confirmed!</h1>
        <p>Your car rental booking has been successfully processed</p>
    </div>
    
    <div class="content">
        <h2>Dear $userName,</h2>
        <p>Your payment for the car rental has been successfully processed.</p>
        
        <div class="details">
            <h3>📋 Booking Details</h3>
            <p><strong>Booking ID:</strong> $bookingId</p>
            <p><strong>Car:</strong> $carName</p>
            ${_isDiscountApplied ? '<p><strong>Original Price:</strong> ₹$totalPrice</p><p><strong>Discount Applied:</strong> ${_discountPercentage.toStringAsFixed(1)}%</p><p><strong>Final Amount Paid:</strong> ₹$finalPrice</p>' : '<p><strong>Total Amount:</strong> ₹$totalPrice</p>'}
            <p><strong>Payment Date:</strong> $paymentDate</p>
            <p><strong>Payment Method:</strong> RazorPay</p>
        </div>

        <div class="details">
            <h3>📍 Trip Details</h3>
            <p><strong>Pickup:</strong> ${_booking.fromAddress}</p>
            <p><strong>Drop-off:</strong> ${_booking.toAddress}</p>
            <p><strong>Pickup Date:</strong> ${DateFormat('d MMM, yyyy HH:mm').format(_booking.pickUpDateTime.toDate())}</p>
            <p><strong>Return Date:</strong> ${DateFormat('d MMM, yyyy HH:mm').format(_booking.returnDateTime.toDate())}</p>
        </div>

        <p>Thank you for choosing our service! We look forward to serving you.</p>
    </div>
    
    <div class="footer">
        <p>Best regards,<br>Car Rental Team</p>
    </div>
</body>
</html>
      ''';

        final customerSent = await EmailService.sendEmail(
          recipientEmail: userEmail,
          subject: 'Car Rental Payment Confirmation - Booking #$bookingId',
          htmlBody: customerHtml,
        );

        if (customerSent) {
          print('✅ Customer email sent successfully to: $userEmail');
        } else {
          print('❌ Failed to send customer email to: $userEmail');
        }
      }

      // Send notification email to ADMIN
      final adminHtml = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .header { background: linear-gradient(135deg, #28a745 0%, #20c997 100%); padding: 20px; color: white; text-align: center; }
        .content { padding: 20px; }
        .section { background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0; border-left: 4px solid #28a745; }
        .footer { background: #343a40; color: white; padding: 15px; text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚗 New Payment Received</h1>
        <p>Booking #$bookingId has been successfully paid</p>
    </div>
    
    <div class="content">
        <div class="section">
            <h3>💰 Payment Details</h3>
            <p><strong>Booking ID:</strong> $bookingId</p>
            ${_isDiscountApplied ? '<p><strong>Original Amount:</strong> ₹$totalPrice</p><p><strong>Discount Applied:</strong> ${_discountPercentage.toStringAsFixed(1)}%</p><p><strong>Final Amount Received:</strong> ₹$finalPrice</p>' : '<p><strong>Amount:</strong> ₹$totalPrice</p>'}
            <p><strong>Payment Date:</strong> $paymentDate</p>
            <p><strong>Payment Method:</strong> RazorPay</p>
        </div>

        <div class="section">
            <h3>👤 Customer Information</h3>
            <p><strong>Name:</strong> $userName</p>
            <p><strong>Email:</strong> ${userEmail ?? 'Not provided'}</p>
            <p><strong>Mobile:</strong> ${_bookingData['userMobile'] ?? 'Not provided'}</p>
        </div>

        <div class="section">
            <h3>🚗 Car & Trip Details</h3>
            <p><strong>Car:</strong> $carName</p>
            <p><strong>Pickup Location:</strong> ${_booking.fromAddress}</p>
            <p><strong>Drop-off Location:</strong> ${_booking.toAddress}</p>
            <p><strong>Pickup Date:</strong> ${DateFormat('d MMM, yyyy HH:mm').format(_booking.pickUpDateTime.toDate())}</p>
            <p><strong>Return Date:</strong> ${DateFormat('d MMM, yyyy HH:mm').format(_booking.returnDateTime.toDate())}</p>
        </div>

        <div class="section">
            <h3>📊 Additional Info</h3>
            <p><strong>Distance:</strong> ${_booking.distance} km</p>
            <p><strong>Booking Status:</strong> Confirmed</p>
            <p><strong>Payment Status:</strong> Success</p>
            ${_isDiscountApplied ? '<p><strong>Discount Used:</strong> Yes (${_discountPercentage.toStringAsFixed(1)}%)</p>' : '<p><strong>Discount Used:</strong> No</p>'}
        </div>

        <p><em>This is an automated notification. Please check the admin panel for more details.</em></p>
    </div>
    
    <div class="footer">
        <p>Car Rental System - Automated Notification</p>
    </div>
</body>
</html>
    ''';

      final adminSent = await EmailService.sendEmail(
        recipientEmail: 'mahekjkevat@gmail.com',
        subject: '🚗 New Payment Received - Booking #$bookingId',
        htmlBody: adminHtml,
      );

      if (adminSent) {
        print('✅ Admin email sent successfully to: mahekjkevat@gmail.com');
      } else {
        print('❌ Failed to send admin email to: mahekjkevat@gmail.com');
      }

      print('📧 Email sending process completed');
    } catch (e) {
      print('❌ Error in email sending process: $e');
      // Don't show error to user as payment was successful
    }
  }

  Future<double> _calculateCancelRefund() async {
    final pickUpDate = (_bookingData['pickUpDateTime'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = pickUpDate.difference(now).inDays;

    if (difference >= 7) {
      return 70.0;
    } else if (difference >= 2) {
      return 50.0;
    } else if (difference >= 1) {
      return 30.0;
    } else {
      return 0.0;
    }
  }

  void _navigateToCancelBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CancelCarBookingPage(bookingData: _bookingData),
      ),
    );
  }
}
