import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../car_booking_model.dart';

class CancelRefundMoneyPage extends StatefulWidget {
  final CarBooking booking;

  const CancelRefundMoneyPage({Key? key, required this.booking}) : super(key: key);

  @override
  _CancelRefundMoneyPageState createState() => _CancelRefundMoneyPageState();
}

class _CancelRefundMoneyPageState extends State<CancelRefundMoneyPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _getProgressValue(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getProgressValue() {
    switch (widget.booking.cancelRequest) {
      case 'Pending':
        return 0.33;
      case 'Processing':
        return 0.66;
      case 'Completed':
        return 1.0;
      default:
        return 0.33;
    }
  }

  String _getCurrentStatusText() {
    switch (widget.booking.cancelRequest) {
      case 'Pending':
        return 'Cancellation Requested';
      case 'Processing':
        return 'Refund Processing';
      case 'Completed':
        return 'Refund Completed';
      default:
        return 'Cancellation Requested';
    }
  }

  Color _getCurrentStatusColor() {
    switch (widget.booking.cancelRequest) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        title: Text(
          'Refund Tracking',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getCurrentStatusColor().withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(),
                            color: _getCurrentStatusColor(),
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Status',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _getCurrentStatusText(),
                                style: GoogleFonts.poppins(
                                  color: _getCurrentStatusColor(),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Divider(),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Refund Amount',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '₹${_calculateRefundAmount().toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Booking ID',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              widget.booking.id,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Progress Tracking
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline, color: Colors.blue, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Refund Progress',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'TRACKING',
                                style: GoogleFonts.poppins(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Animated Progress Bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue, Colors.green],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${(_progressAnimation.value * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '100%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30),

                    // Tracking Steps
                    _buildTrackingSteps(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Refund Details
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refund Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    _buildRefundDetailItem('Original Amount',
                        '₹${widget.booking.totalPrice.toStringAsFixed(2)}', Colors.grey),
                    _buildRefundDetailItem('Cancellation Charges',
                        '₹${_calculateCancellationCharges().toStringAsFixed(2)}', Colors.orange),
                    _buildRefundDetailItem('Refundable Amount',
                        '₹${_calculateRefundAmount().toStringAsFixed(2)}', Colors.green),
                    Divider(height: 30),
                    _buildRefundDetailItem('Estimated Processing Time',
                        '5-7 Business Days', Colors.blue),
                    _buildRefundDetailItem('Payment Method',
                        widget.booking.paymentMethod ?? 'Not Specified', Colors.purple),
                    if (widget.booking.refundProcessedAt != null)
                      _buildRefundDetailItem('Refund Processed On',
                          _formatTimestamp(widget.booking.refundProcessedAt), Colors.green),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Support Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.orange, size: 30),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Help?',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Contact our support team for any refund related queries',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Add contact support functionality
                      },
                      child: Text(
                        'Contact',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (widget.booking.cancelRequest) {
      case 'Pending':
        return Icons.pending_actions;
      case 'Processing':
        return Icons.autorenew;
      case 'Completed':
        return Icons.check_circle;
      default:
        return Icons.pending_actions;
    }
  }

  Widget _buildTrackingSteps() {
    final List<TrackingStep> steps = [
      TrackingStep(
        title: 'Cancellation Requested',
        description: 'Your cancellation request has been received and is under review',
        status: 'completed',
        icon: Icons.check_circle,
        color: Colors.green,
        timestamp: _formatTimestamp(widget.booking.cancelledAt),
      ),
      TrackingStep(
        title: 'Under Processing',
        description: 'We are processing your refund request and verifying details',
        status: widget.booking.cancelRequest == 'Processing' ||
            widget.booking.cancelRequest == 'Completed'
            ? 'completed'
            : widget.booking.cancelRequest == 'Pending'
            ? 'current'
            : 'pending',
        icon: widget.booking.cancelRequest == 'Processing' ||
            widget.booking.cancelRequest == 'Completed'
            ? Icons.check_circle
            : Icons.autorenew,
        color: widget.booking.cancelRequest == 'Processing' ||
            widget.booking.cancelRequest == 'Completed'
            ? Colors.green
            : Colors.orange,
        timestamp: widget.booking.cancelRequest == 'Processing' ? 'Processing...' : null,
      ),
      TrackingStep(
        title: 'Refund Completed',
        description: 'Amount has been successfully refunded to your original payment method',
        status: widget.booking.cancelRequest == 'Completed' ? 'completed' : 'pending',
        icon: widget.booking.cancelRequest == 'Completed'
            ? Icons.check_circle
            : Icons.pending,
        color: widget.booking.cancelRequest == 'Completed' ? Colors.green : Colors.grey,
        timestamp: widget.booking.refundProcessedAt != null
            ? _formatTimestamp(widget.booking.refundProcessedAt)
            : 'Pending',
      ),
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        int index = entry.key;
        TrackingStep step = entry.value;
        bool isLast = index == steps.length - 1;

        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with connecting line
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.color.withOpacity(0.1),
                      border: Border.all(
                        color: step.color,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      step.icon,
                      color: step.color,
                      size: 20,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      margin: EdgeInsets.only(top: 4),
                      color: steps[index + 1].status == 'completed'
                          ? step.color
                          : Colors.grey[300],
                    ),
                ],
              ),
              SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: step.status == 'completed'
                            ? Colors.green
                            : step.status == 'current'
                            ? Colors.orange
                            : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      step.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (step.timestamp != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          step.timestamp!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRefundDetailItem(String title, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateRefundAmount() {
    double cancellationCharges = _calculateCancellationCharges();
    return (widget.booking.totalPrice - cancellationCharges).clamp(0, double.infinity);
  }

  double _calculateCancellationCharges() {
    // Calculate cancellation charges based on your business logic
    // For example: 20% of total price as cancellation fee
    return widget.booking.totalPrice * 0.2;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not available';
    final dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy - HH:mm').format(dateTime);
  }
}

class TrackingStep {
  final String title;
  final String description;
  final String status; // 'completed', 'current', 'pending'
  final IconData icon;
  final Color color;
  final String? timestamp;

  TrackingStep({
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
    required this.color,
    this.timestamp,
  });
}