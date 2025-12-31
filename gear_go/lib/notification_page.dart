import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 26, // Increased by 2
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        // Removed three dots action button
      ),
      body: userId == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_circle, color: Colors.blue[800], size: 50), // Increased size
            ),
            SizedBox(height: 20),
            Text(
              "Please log in to view notifications",
              style: GoogleFonts.poppins(
                fontSize: 18, // Increased by 2
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('Notification')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.threeArchedCircle(
                    color: Colors.blue[700]!,
                    size: 50,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading notifications...",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 16, // Increased by 2
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline, color: Colors.red, size: 50), // Increased size
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load notifications',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontSize: 18, // Increased by 2
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off,
                      color: Colors.blue[800],
                      size: 50, // Increased size
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "No Notifications",
                    style: GoogleFonts.poppins(
                      fontSize: 22, // Increased by 2
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "You're all caught up!",
                    style: GoogleFonts.poppins(
                      fontSize: 16, // Increased by 2
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              String formattedTime;
              dynamic timeData = notification['time'];
              if (timeData is Timestamp) {
                formattedTime = DateFormat('MMM dd, yyyy - HH:mm').format(timeData.toDate());
              } else if (timeData is String) {
                formattedTime = timeData;
                try {
                  final parsedDate = DateTime.parse(timeData);
                  formattedTime = DateFormat('MMM dd, yyyy - HH:mm').format(parsedDate);
                } catch (e) {
                  // Keep original string if parsing fails
                }
              } else {
                formattedTime = 'Unknown Time';
              }

              final bool isRead = notification.data() != null &&
                  (notification.data()! as Map<String, dynamic>).containsKey('status') &&
                  notification['status'] == 'read';

              return NotificationItem(
                title: notification['title'] ?? 'No Title',
                description: notification['description'] ?? 'No Description',
                dateTime: formattedTime,
                docId: notification.id,
                isRead: isRead,
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationItem extends StatefulWidget {
  final String title;
  final String description;
  final String dateTime;
  final String docId;
  final bool isRead;

  const NotificationItem({
    Key? key,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.docId,
    required this.isRead,
  }) : super(key: key);

  @override
  _NotificationItemState createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  IconData _getLeadingIcon() {
    if (widget.title.toLowerCase().contains('success')) {
      return Icons.check_circle;
    } else if (widget.title.toLowerCase().contains('error') || widget.title.toLowerCase().contains('fail')) {
      return Icons.error;
    } else if (widget.title.toLowerCase().contains('warning')) {
      return Icons.warning;
    } else if (widget.title.toLowerCase().contains('booking') || widget.title.toLowerCase().contains('reservation')) {
      return Icons.confirmation_number;
    } else if (widget.title.toLowerCase().contains('payment')) {
      return Icons.payment;
    }
    return Icons.notifications;
  }

  Color _getIconColor() {
    if (widget.title.toLowerCase().contains('success')) {
      return Colors.green;
    } else if (widget.title.toLowerCase().contains('error') || widget.title.toLowerCase().contains('fail')) {
      return Colors.red;
    } else if (widget.title.toLowerCase().contains('warning')) {
      return Colors.orange;
    } else if (widget.title.toLowerCase().contains('booking') || widget.title.toLowerCase().contains('reservation')) {
      return Colors.blue;
    } else if (widget.title.toLowerCase().contains('payment')) {
      return Colors.purple;
    }
    return Colors.blue[800]!;
  }

  Color _getCardColor() {
    if (widget.title.toLowerCase().contains('success')) {
      return Colors.green[50]!;
    } else if (widget.title.toLowerCase().contains('error') || widget.title.toLowerCase().contains('fail')) {
      return Colors.red[50]!;
    } else if (widget.title.toLowerCase().contains('warning')) {
      return Colors.orange[50]!;
    } else if (widget.title.toLowerCase().contains('booking') || widget.title.toLowerCase().contains('reservation')) {
      return Colors.blue[50]!;
    } else if (widget.title.toLowerCase().contains('payment')) {
      return Colors.purple[50]!;
    }
    return Colors.grey[50]!;
  }

  Future<void> _markAsRead() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Notification')
          .doc(widget.docId)
          .set({'status': 'read'}, SetOptions(merge: true));
    }
  }

  Future<void> _deleteNotification() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Notification')
          .doc(widget.docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Notification deleted"),
          backgroundColor: Colors.blue[800]!,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isRead)
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mark_chat_read, color: Colors.green, size: 22), // Increased size
                ),
                title: Text(
                  'Mark as read',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16, // Increased by 2
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _markAsRead();
                },
              ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete, color: Colors.red, size: 22), // Increased size
              ),
              title: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 16, // Increased by 2
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteNotification();
              },
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(fontSize: 16), // Increased by 2
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: widget.isRead ? Colors.transparent : _getIconColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Mark as read when tapped
            if (!widget.isRead) {
              await _markAsRead();
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationDetailPage(
                  title: widget.title,
                  description: widget.description,
                  dateTime: widget.dateTime,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getLeadingIcon(),
                    color: _getIconColor(),
                    size: 26, // Increased by 2
                  ),
                ),
                SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18, // Increased by 2
                                fontWeight: widget.isRead ? FontWeight.w500 : FontWeight.bold,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!widget.isRead)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getIconColor(),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'NEW',
                                style: GoogleFonts.poppins(
                                  fontSize: 12, // Increased by 2
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: GoogleFonts.poppins(
                          fontSize: 16, // Increased by 2
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Text(
                            widget.dateTime,
                            style: GoogleFonts.poppins(
                              fontSize: 14, // Increased by 2
                              color: Colors.grey[600],
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20), // Increased size
                            onPressed: _showActionMenu,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationDetailPage extends StatelessWidget {
  final String title;
  final String description;
  final String dateTime;

  const NotificationDetailPage({
    Key? key,
    required this.title,
    required this.description,
    required this.dateTime,
  }) : super(key: key);

  String _getNotificationType() {
    if (title.toLowerCase().contains('success')) {
      return 'Success';
    } else if (title.toLowerCase().contains('error') || title.toLowerCase().contains('fail')) {
      return 'Error';
    } else if (title.toLowerCase().contains('warning')) {
      return 'Warning';
    } else if (title.toLowerCase().contains('booking') || title.toLowerCase().contains('reservation')) {
      return 'Booking';
    } else if (title.toLowerCase().contains('payment')) {
      return 'Payment';
    }
    return 'Information';
  }

  Color _getTypeColor() {
    if (title.toLowerCase().contains('success')) {
      return Colors.green;
    } else if (title.toLowerCase().contains('error') || title.toLowerCase().contains('fail')) {
      return Colors.red;
    } else if (title.toLowerCase().contains('warning')) {
      return Colors.orange;
    } else if (title.toLowerCase().contains('booking') || title.toLowerCase().contains('reservation')) {
      return Colors.blue;
    } else if (title.toLowerCase().contains('payment')) {
      return Colors.purple;
    }
    return Colors.blue[800]!;
  }

  IconData _getTypeIcon() {
    if (title.toLowerCase().contains('success')) {
      return Icons.check_circle;
    } else if (title.toLowerCase().contains('error') || title.toLowerCase().contains('fail')) {
      return Icons.error;
    } else if (title.toLowerCase().contains('warning')) {
      return Icons.warning;
    } else if (title.toLowerCase().contains('booking') || title.toLowerCase().contains('reservation')) {
      return Icons.confirmation_number;
    } else if (title.toLowerCase().contains('payment')) {
      return Icons.payment;
    }
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        title: Text(
          'Notification Details',
          style: GoogleFonts.poppins(
            fontSize: 22, // Increased by 2
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(),
                  size: 42, // Increased by 2
                ),
              ),
            ),
            SizedBox(height: 20),

            // Type Badge
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getTypeColor().withOpacity(0.3)),
                ),
                child: Text(
                  _getNotificationType(),
                  style: GoogleFonts.poppins(
                    fontSize: 16, // Increased by 2
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),

            // Title
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 26, // Increased by 2
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            // Date & Time
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 18, color: Colors.grey[600]), // Increased size
                  SizedBox(width: 6),
                  Text(
                    dateTime,
                    style: GoogleFonts.poppins(
                      fontSize: 16, // Increased by 2
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Description Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 18, // Increased by 2
                  color: Colors.grey[800],
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}