import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'CancelBookingSuccessPage.dart';
import 'EmailService.dart';

class CancelCarBookingPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const CancelCarBookingPage({super.key, required this.bookingData});

  @override
  State<CancelCarBookingPage> createState() => _CancelCarBookingPageState();
}

class _CancelCarBookingPageState extends State<CancelCarBookingPage> {
  double _refundPercentage = 0.0;
  double _refundAmount = 0.0;
  bool _isCancelling = false;


  @override
  void initState() {
    super.initState();
    _calculateRefund();
  }

  void _calculateRefund() {
    final pickUpDate = (widget.bookingData['pickUpDateTime'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = pickUpDate.difference(now).inDays;

    setState(() {
      if (difference >= 7) {
        _refundPercentage = 70.0;
      } else if (difference >= 2) {
        _refundPercentage = 50.0;
      } else if (difference >= 1) {
        _refundPercentage = 30.0;
      } else {
        _refundPercentage = 0.0;
      }

      _refundAmount = (widget.bookingData['totalPrice'] * _refundPercentage / 100);
    });
  }

  Future<void> _submitCancelRequest() async {
    setState(() => _isCancelling = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('car_booking')
            .doc(widget.bookingData['id'])
            .update({
          'cancel_request': 'Pending',
          'cancel_request_amount': _refundAmount,
          'cancel_request_date': Timestamp.now(),
          'status': 'cancelled',
        });

        // Send email to user
        await _sendCancellationEmailToUser();

        // Send email to admin
        await _sendCancellationEmailToAdmin();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CancelBookingSuccessPage(
              bookingData: widget.bookingData,
              refundAmount: _refundAmount,
            ),
          ),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error submitting cancel request: $e");
    } finally {
      setState(() => _isCancelling = false);
    }
  }

  Future<void> _sendCancellationEmailToUser() async {
    try {
      String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      if (userEmail.isEmpty) return;

      String subject = '🚫 Booking Cancellation Confirmed - GearGo';
      String htmlBody = '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: 'Poppins', sans-serif; background-color: #000000; padding: 0; margin: 0; }
            .email-wrapper { background-color: #000000; padding: 20px; }
            .container { 
                background: #1C1C1C; 
                padding: 30px; 
                border-radius: 12px; 
                border: 1px solid #FFC10750; 
                margin: 0 auto; 
                max-width: 600px; 
                box-shadow: 0 4px 15px rgba(255,193,7,0.1); 
            }
            .header { 
                color: #FFC107; 
                text-align: center; 
                border-bottom: 2px solid #FFC107; 
                padding-bottom: 10px; 
                margin-bottom: 20px;
                font-size: 24px;
                font-weight: bold;
            }
            .content { margin: 20px 0; line-height: 1.8; color: #FFFFFF; font-size: 16px; }
            .refund-amount { color: #4CAF50; font-weight: bold; font-size: 1.2em; }
            .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #333; text-align: center; color: #999; }
        </style>
    </head>
    <body>
        <div class="email-wrapper">
            <div class="container">
                <h1 class="header">🚫 Booking Cancelled</h1>
                <div class="content">
                    <p>Dear <strong style="color: #FFC107;">${widget.bookingData['userName']}</strong>,</p>
                    <p>Your booking for <strong style="color: #FFC107;">${widget.bookingData['carName']}</strong> has been successfully cancelled.</p>
                    <p><strong>Refund Amount:</strong> <span class="refund-amount">₹${_refundAmount.toStringAsFixed(2)}</span></p>
                    <p>The refund will be processed to your original payment method within 5-7 business days.</p>
                    <p>If you have any questions, please contact our support team.</p>
                </div>
                <div class="footer">
                    <p style="color: #FFC107; font-weight: bold;">Thank you for using GearGo!</p>
                    <p style="font-size: 0.9em;">Best regards, The GearGo Team</p>
                </div>
            </div>
        </div>
    </body>
    </html>
    ''';

      await EmailService.sendEmail(
        recipientEmail: userEmail,
        subject: subject,
        htmlBody: htmlBody,
      );
    } catch (e) {
      print('Error sending user cancellation email: $e');
    }
  }

  Future<void> _sendCancellationEmailToAdmin() async {
    try {
      String adminEmail = 'mahekjkevat@gmail.com';
      String subject = '📋 Booking Cancellation - ${widget.bookingData['carName']}';
      String htmlBody = '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: 'Poppins', sans-serif; background-color: #000000; padding: 0; margin: 0; }
            .email-wrapper { background-color: #000000; padding: 20px; }
            .container { 
                background: #1C1C1C; 
                padding: 30px; 
                border-radius: 12px; 
                border: 1px solid #FFC10750; 
                margin: 0 auto; 
                max-width: 600px; 
                box-shadow: 0 4px 15px rgba(255,193,7,0.1); 
            }
            .header { 
                color: #FFC107; 
                text-align: center; 
                border-bottom: 2px solid #FFC107; 
                padding-bottom: 10px; 
                margin-bottom: 20px;
                font-size: 24px;
                font-weight: bold;
            }
            .content { margin: 20px 0; line-height: 1.8; color: #FFFFFF; font-size: 16px; }
            .info-box { background: #2A2A2A; padding: 15px; border-radius: 8px; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="email-wrapper">
            <div class="container">
                <h1 class="header">📋 Booking Cancellation Alert</h1>
                <div class="content">
                    <p>A booking has been cancelled by the user.</p>
                    <div class="info-box">
                        <p><strong>Car:</strong> ${widget.bookingData['carName']}</p>
                        <p><strong>User Email:</strong> ${widget.bookingData['userEmail']}</p>
                        <p><strong>Refund Amount:</strong> ₹${_refundAmount.toStringAsFixed(2)}</p>
                        <p><strong>Original Amount:</strong> ₹${widget.bookingData['totalPrice']?.toStringAsFixed(2)}</p>
                    </div>
                    <p>Please review the cancellation in the admin panel.</p>
                </div>
            </div>
        </div>
    </body>
    </html>
    ''';

      await EmailService.sendEmail(
        recipientEmail: adminEmail,
        subject: subject,
        htmlBody: htmlBody,
      );
    } catch (e) {
      print('Error sending admin cancellation email: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cancel Booking', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cancellation Policy Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cancellation Policy', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildPolicyItem('7+ days before pickup', '70% refund'),
                    _buildPolicyItem('2-6 days before pickup', '50% refund'),
                    _buildPolicyItem('1 day before pickup', '30% refund'),
                    _buildPolicyItem('Same day cancellation', 'No refund'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Refund Calculation Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Refund Calculation', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildCalculationRow('Original Amount', '₹${widget.bookingData['totalPrice']?.toStringAsFixed(2)}'),
                    _buildCalculationRow('Refund Percentage', '${_refundPercentage.toInt()}%'),
                    _buildCalculationRow('Refund Amount', '₹${_refundAmount.toStringAsFixed(2)}', isTotal: true),
                    _buildCalculationRow('Amount Deducted', '₹${(widget.bookingData['totalPrice'] - _refundAmount).toStringAsFixed(2)}', isDeducted: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Booking Details
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Details', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildDetailRow('Car', widget.bookingData['carName'] ?? 'N/A'),
                    _buildDetailRow('Pickup Date', _formatDate(widget.bookingData['pickUpDateTime'])),
                    _buildDetailRow('Days until pickup', _calculateDaysUntilPickup().toString()),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCancelling ? null : _submitCancelRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isCancelling
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Confirm Cancellation & Get ₹${_refundAmount.toStringAsFixed(2)} Refund',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem(String condition, String refund) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(condition, style: GoogleFonts.poppins(fontSize: 14))),
          Text(refund, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[600])),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, {bool isTotal = false, bool isDeducted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDeducted ? Colors.red : Colors.black,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          )),
          Text(value, style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDeducted ? Colors.red : (isTotal ? Colors.green : Colors.black),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          )),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('d MMM yyyy, HH:mm').format(date.toDate());
    }
    return 'N/A';
  }

  int _calculateDaysUntilPickup() {
    final pickUpDate = (widget.bookingData['pickUpDateTime'] as Timestamp).toDate();
    final now = DateTime.now();
    return pickUpDate.difference(now).inDays;
  }
}