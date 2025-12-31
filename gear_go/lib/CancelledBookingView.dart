import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'AllBookings/cancel_refund_money.dart';
import 'car_booking_model.dart';

class CancelledBookingView extends StatefulWidget {
  final CarBooking booking;

  const CancelledBookingView({Key? key, required this.booking}) : super(key: key);

  @override
  _CancelledBookingViewState createState() => _CancelledBookingViewState();
}

class _CancelledBookingViewState extends State<CancelledBookingView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        elevation: 0,
        title: Text(
          'Cancelled Booking',
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
      body: Column(
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[700]!, Colors.red[400]!],
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.white, size: 30),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Cancelled',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'This booking has been cancelled',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Refund Tracking Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.track_changes, color: Colors.blue, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Refund Status',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              if (widget.booking.cancelRequest != null &&
                                  widget.booking.cancelRequest != 'Completed')
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
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 15),
                          // Refund Tracking Widget
                          RefundTrackingWidget(booking: widget.booking),
                          SizedBox(height: 10),
                          if (widget.booking.cancelRequest != 'Completed')
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CancelRefundMoneyPage(booking: widget.booking),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.remove_red_eye, size: 18),
                                label: Text(
                                  'View Details',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Cancellation Info Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.red, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Cancellation Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          _buildInfoRow(
                            'Cancelled On',
                            _formatTimestamp(widget.booking.cancelledAt),
                            Colors.red,
                          ),
                          _buildInfoRow(
                            'Refund Status',
                            _getRefundStatus(),
                            _getRefundStatusColor(),
                          ),
                          _buildInfoRow(
                            'Cancellation Reason',
                            _getCancellationReason(),
                            Colors.blue,
                          ),
                          if (widget.booking.cancelledBy != null)
                            _buildInfoRow(
                              'Cancelled By',
                              widget.booking.cancelledBy!,
                              Colors.purple,
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Car Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Stack(
                            children: [
                              Image.network(
                                widget.booking.carImage1.isNotEmpty
                                    ? widget.booking.carImage1
                                    : 'https://via.placeholder.com/400x200',
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: Icon(Icons.car_rental, size: 50),
                                    ),
                              ),
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.cancel,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'CANCELLED',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.booking.carName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${widget.booking.totalPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: Colors.grey, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('MMM d, yyyy').format(widget.booking.pickUpDateTime.toDate())} - ${DateFormat('MMM d, yyyy').format(widget.booking.returnDateTime.toDate())}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Booking Details
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Details',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 15),
                          _buildDetailItem(
                            Icons.location_on,
                            'Pickup Location',
                            widget.booking.fromAddress,
                            Colors.red,
                          ),
                          _buildDetailItem(
                            Icons.location_off,
                            'Drop-off Location',
                            widget.booking.toAddress,
                            Colors.blue,
                          ),
                          _buildDetailItem(
                            Icons.calendar_today,
                            'Pickup Date',
                            DateFormat('MMM d, yyyy - HH:mm')
                                .format(widget.booking.pickUpDateTime.toDate()),
                            Colors.green,
                          ),
                          _buildDetailItem(
                            Icons.calendar_today,
                            'Return Date',
                            DateFormat('MMM d, yyyy - HH:mm')
                                .format(widget.booking.returnDateTime.toDate()),
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Additional Info
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Additional Information',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 15),
                          _buildInfoRow('Status', 'Cancelled', Colors.red),
                          _buildInfoRow('Payment Method',
                              widget.booking.paymentMethod ?? 'Not Paid',
                              Colors.grey),
                          _buildInfoRow('Booking ID', widget.booking.id,
                              Colors.teal),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not available';
    final dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy - HH:mm').format(dateTime);
  }

  String _getCancellationReason() {
    return widget.booking.cancellationReason ?? 'Not specified';
  }

  String _getRefundStatus() {
    if (widget.booking.refundProcessed == true) {
      return 'Refund Processed';
    } else if (widget.booking.refundEligible == true) {
      return 'Eligible for Refund';
    } else {
      return 'No Refund';
    }
  }

  Color _getRefundStatusColor() {
    if (widget.booking.refundProcessed == true) {
      return Colors.green;
    } else if (widget.booking.refundEligible == true) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

// Refund Tracking Widget
class RefundTrackingWidget extends StatefulWidget {
  final CarBooking booking;

  const RefundTrackingWidget({Key? key, required this.booking}) : super(key: key);

  @override
  _RefundTrackingWidgetState createState() => _RefundTrackingWidgetState();
}

class _RefundTrackingWidgetState extends State<RefundTrackingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<TrackingPoint> trackingPoints = _getTrackingPoints();
    final int currentStep = _getCurrentStepIndex();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            for (int i = 0; i < trackingPoints.length; i++)
              _buildTrackingPoint(
                trackingPoints[i],
                i,
                currentStep,
                i < currentStep,
                i == currentStep,
              ),
          ],
        );
      },
    );
  }

  Widget _buildTrackingPoint(
      TrackingPoint point,
      int index,
      int currentStep,
      bool isCompleted,
      bool isCurrent,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress line and point
          Column(
            children: [
              // Top connector line (hidden for first item)
              if (index > 0)
                Container(
                  width: 2,
                  height: 20,
                  color: isCompleted ? Colors.green : Colors.grey[300],
                ),
              // Progress point
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                      ? Colors.blue
                      : Colors.grey[300],
                  border: Border.all(
                    color: isCurrent ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(Icons.check, color: Colors.white, size: 16)
                    : isCurrent
                    ? Icon(Icons.adjust, color: Colors.white, size: 16)
                    : null,
              ),
              // Bottom connector line (hidden for last item)
              if (index < 2)
                Container(
                  width: 2,
                  height: 20,
                  color: isCompleted ? Colors.green : Colors.grey[300],
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
                  point.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? Colors.green
                        : isCurrent
                        ? Colors.blue
                        : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  point.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (point.timestamp != null)
                  Text(
                    point.timestamp!,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TrackingPoint> _getTrackingPoints() {
    return [
      TrackingPoint(
        title: 'Cancellation Requested',
        description: 'Your cancellation request has been submitted',
        timestamp: _formatTimestamp(widget.booking.cancelledAt),
      ),
      TrackingPoint(
        title: 'Under Processing',
        description: 'We are processing your refund request',
        timestamp: widget.booking.cancelRequest == 'Processing' ? 'In Progress' : null,
      ),
      TrackingPoint(
        title: 'Refund Completed',
        description: 'Amount has been refunded to your account',
        timestamp: widget.booking.refundProcessedAt != null
            ? _formatTimestamp(widget.booking.refundProcessedAt)
            : null,
      ),
    ];
  }

  int _getCurrentStepIndex() {
    switch (widget.booking.cancelRequest) {
      case 'Pending':
        return 0;
      case 'Processing':
        return 1;
      case 'Completed':
        return 2;
      default:
        return 0;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy - HH:mm').format(dateTime);
  }
}

class TrackingPoint {
  final String title;
  final String description;
  final String? timestamp;

  TrackingPoint({
    required this.title,
    required this.description,
    this.timestamp,
  });
}