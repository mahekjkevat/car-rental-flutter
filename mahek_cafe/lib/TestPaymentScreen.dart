import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorPayWorkingDemo extends StatefulWidget {
  const RazorPayWorkingDemo({super.key});

  @override
  State<RazorPayWorkingDemo> createState() => _RazorPayWorkingDemoState();
}

class _RazorPayWorkingDemoState extends State<RazorPayWorkingDemo> {
  final Razorpay _razorpay = Razorpay();
  bool _isProcessing = false;
  String _status = 'Tap to Pay ₹500';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _setupRazorpay();
  }

  void _setupRazorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    // Removed EVENT_PAYMENT_INITIATED as it’s not supported in current version
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _status = 'Payment Successful!';
    });
    _addLog('🎉 PAYMENT SUCCESS');
    _addLog('💰 Payment ID: ${response.paymentId}');
    _addLog('📦 Order ID: ${response.orderId}');
    _addLog('🔐 Signature: ${response.signature}');
  }

  void _handleError(dynamic error) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _status = 'Payment Failed';
    });

    if (error is PaymentFailureResponse) {
      _addLog('❌ Payment Failed: ${error.message}');
      _addLog('❌ Error Code: ${error.code}');
    } else if (error is String) {
      _addLog('❌ Payment Error: Received String - $error');
      try {
        final decoded = jsonDecode(error);
        if (decoded is Map) {
          _addLog('❌ Parsed Error: ${decoded['error']?['description'] ?? 'Unknown error'}');
        }
      } catch (e) {
        _addLog('❌ Failed to parse error: $e');
      }
    } else {
      _addLog('❌ Payment Error: $error');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _addLog('🌐 External Wallet: ${response.walletName}');
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() => _logs.add('${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} - $message'));
    print('💳 RAZORPAY: $message');
  }

  Future<void> _openRazorpay() async {
    if (_isProcessing) return;

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _status = 'Opening RazorPay...';
    });

    _addLog('🚀 Opening RazorPay Gateway');
    _addLog('🔑 Using Test Key: rzp_test_rZKfDFHhxQJLOI');
    _addLog('💰 Amount: ₹500 (50000 paise)');

    final options = {
      'key': 'rzp_test_rZKfDFHhxQJLOI',
      'amount': 50000, // 500 INR in paise
      'name': 'Mahek Cafe',
      'description': 'Delicious Food Order',
      'prefill': {
        'contact': '9999999999',
        'email': 'customer@mahek.com'
      },
      'external': {
        'wallets': ['paytm', 'phonepe', 'gpay']
      }
    };

    try {
      _razorpay.open(options); // Removed 'await' since it returns void
      _addLog('✅ RazorPay Gateway Opened Successfully');
      _addLog('👆 Select your payment method in the gateway');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _status = 'Failed to Open';
      });
      _addLog('❌ Error opening RazorPay: $e');
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });
  }
  void _resetDemo() {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _status = 'Tap to Pay ₹500';
      _logs.clear();
    });
    _addLog('🔄 Demo Reset - Ready for Payment');
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RazorPay Gateway', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6D4C41),
        actions: [IconButton(onPressed: _resetDemo, icon: const Icon(Icons.refresh))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _status.contains('Success')
                        ? [Colors.green, Colors.lightGreen]
                        : _status.contains('Failed')
                        ? [Colors.red, Colors.orange]
                        : _isProcessing
                        ? [Colors.orange, Colors.amber]
                        : [const Color(0xFF6D4C41), const Color(0xFFE65100)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _status.contains('Success') ? Icons.check_circle
                          : _status.contains('Failed') ? Icons.error
                          : _isProcessing ? Icons.payment : Icons.credit_card,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(_status,
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 5),
                    Text(_isProcessing ? 'Processing...' : 'Test Amount: ₹500.00',
                        style: GoogleFonts.poppins(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _openRazorpay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text('Opening Gateway...', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                  ],
                )
                    : Text('OPEN RAZORPAY GATEWAY',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💳 Test Card Details:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('Card: 4111 1111 1111 1111', style: GoogleFonts.poppins(fontSize: 12)),
                    Text('CVV: Any 3 digits', style: GoogleFonts.poppins(fontSize: 12)),
                    Text('Expiry: Any future date', style: GoogleFonts.poppins(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Payment Logs', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${_logs.length} events', style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _logs[index].contains('✅') || _logs[index].contains('🎉')
                                ? Colors.green[50]
                                : _logs[index].contains('❌')
                                ? Colors.red[50]
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _logs[index].contains('🎉') ? Icons.check_circle
                                    : _logs[index].contains('❌') ? Icons.error
                                    : Icons.info,
                                color: _logs[index].contains('🎉') ? Colors.green
                                    : _logs[index].contains('❌') ? Colors.red
                                    : Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_logs[index], style: GoogleFonts.poppins(fontSize: 12))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}