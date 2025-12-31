import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'chat_service.dart';
import 'chat_message_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/chat_room_model.dart';
import 'models/message_model.dart';
import 'user_profile_page.dart';

class AdminChatRoomPage extends StatefulWidget {
  final ChatRoomModel chatRoom;

  const AdminChatRoomPage({
    Key? key,
    required this.chatRoom,
  }) : super(key: key);

  @override
  _AdminChatRoomPageState createState() => _AdminChatRoomPageState();
}

class _AdminChatRoomPageState extends State<AdminChatRoomPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatRoomModel _currentChatRoom;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  @override
  void initState() {
    super.initState();
    _currentChatRoom = widget.chatRoom;
    _chatService.markMessagesAsRead(_currentChatRoom.roomId);
    _setAdminOnline();
  }

  @override
  void dispose() {
    _setAdminOffline();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setAdminOnline() {
    _chatService.updateAdminStatus('online');
  }

  void _setAdminOffline() {
    _chatService.updateAdminStatus('offline');
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    await _chatService.sendMessage(
      roomId: _currentChatRoom.roomId,
      message: message,
      receiverId: _currentChatRoom.userId,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // NEW: Delete message function
// In AdminChatRoomPage.dart - Update the _deleteMessage function

// NEW: Delete admin's own message function
  Future<void> _deleteMessage(String messageId) async {
    try {
      // Update the message to show "deleted" text instead of actually deleting it
      await _firestore
          .collection('chat_rooms')
          .doc(_currentChatRoom.roomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'message': 'This message was deleted', // Updated text
        'isDeleted': true,
      });

      print('✅ Admin message marked as deleted: $messageId');

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message deleted for everyone'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _makePhoneCall() async {
    final phoneNumber = _currentChatRoom.userPhone;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final url = 'tel:$phoneNumber';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot make call to $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _openUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: _currentChatRoom.userId,
          userData: _currentChatRoom.userInfo[_currentChatRoom.userId] ?? {},
        ),
      ),
    );
  }

  String _getLastSeenText() {
    final lastSeen = _currentChatRoom.lastSeen[_currentChatRoom.userId];
    if (_currentChatRoom.isUserOnline) {
      return 'Online';
    } else if (lastSeen != null) {
      final lastSeenTime = (lastSeen as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(lastSeenTime);

      if (difference.inMinutes < 1) {
        return 'Last seen just now';
      } else if (difference.inMinutes < 60) {
        return 'Last seen ${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return 'Last seen ${DateFormat('MMM dd, hh:mm a').format(lastSeenTime)}';
      }
    }
    return 'Last seen recently';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.yellow),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<Map<String, dynamic>?>(
          stream: _chatService.getUserProfileStream(_currentChatRoom.userId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final userData = snapshot.data!;
              _currentChatRoom = _currentChatRoom.copyWithUserInfo(userData);
            }

            return GestureDetector(
              onTap: _openUserProfile,
              child: Row(
                children: [
                  // User Profile Image
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _currentChatRoom.userProfileImage != null &&
                              _currentChatRoom.userProfileImage!.isNotEmpty
                              ? Image.network(
                            _currentChatRoom.userProfileImage!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person, color: Colors.black, size: 20);
                            },
                          )
                              : Icon(Icons.person, color: Colors.black, size: 20),
                        ),
                      ),
                      if (_currentChatRoom.isUserOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentChatRoom.userName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _getLastSeenText(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _currentChatRoom.isUserOnline ? Colors.green : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          // Call Button
          IconButton(
            icon: Icon(Icons.phone, color: Colors.yellow),
            onPressed: _makePhoneCall,
          ),
          SizedBox(width: 8),
        ],
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: Container(
              color: Color(0xFF121212),
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(_currentChatRoom.roomId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: Colors.yellow),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 60,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Start a conversation...',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ChatMessageWidget(
                        message: message,
                        isAdmin: true, // This is admin side
                        userProfileImage: _currentChatRoom.userProfileImage,
                        onProfileImageTap: _openUserProfile,
                        onDeleteMessage: _deleteMessage, // Pass delete function
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}