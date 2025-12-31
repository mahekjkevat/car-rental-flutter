import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';
import 'chat_message_widget.dart';
import 'models/message_model.dart';

// --- THEME DEFINITIONS (Light Theme) ---
const Color _primaryColor = Color(
  0xFF003366,
); // Dark Blue for primary text/icons/accents (matches ChatMessageWidget)
const Color _accentColor = Color(
  0xFFFFC107,
); // Amber/Yellow for buttons and highlights (matches ChatMessageWidget)
const Color _backgroundColor = Color(0xFFF5F5F5); // Light Gray Background
const Color _cardColor = Colors.blue; // White for input background/cards
const Color _textColor = Colors.black; // Primary text color
const Color _secondaryTextColor = Color(
  0xFF616161,
); // Secondary text color/hints
const Color _inputColor = Colors.white; // White for text field

class CustomerChatPage extends StatefulWidget {
  const CustomerChatPage({Key? key}) : super(key: key);

  @override
  _CustomerChatPageState createState() => _CustomerChatPageState();
}

class _CustomerChatPageState extends State<CustomerChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentRoomId;

  // Hardcoded admin ID - replace with your actual admin UID
  static const String ADMIN_ID =
      'NulFprQxJ1cQ5MHz1AZjoCE0yZC3'; // Get this from Firebase Auth
  static const String ADMIN_EMAIL = 'mahekjkevat@gmail.com';

  @override
  void initState() {
    super.initState();
    _checkOrCreateChatRoom();
  }

  Future<void> _checkOrCreateChatRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if chat room already exists
    final snapshot =
        await FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants.userId', isEqualTo: user.uid)
            .where('participants.adminId', isEqualTo: ADMIN_ID)
            .where('isActive', isEqualTo: true)
            .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _currentRoomId = snapshot.docs.first.id;
      });
      // Mark messages as read, passing the customer's ID as the reader
      _chatService.markMessagesAsRead(_currentRoomId!);
    } else {
      // Create new chat room
      final userInfo = {
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'profileImage': user.photoURL ?? '',
      };

      final roomId = await _chatService.createChatRoom(
        user.uid,
        userInfo,
        adminId: ADMIN_ID,
        adminEmail: ADMIN_EMAIL,
      );

      setState(() {
        _currentRoomId = roomId;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentRoomId == null)
      return;

    await _chatService.sendMessage(
      roomId: _currentRoomId!,

      message: _messageController.text.trim(),

      receiverId: ADMIN_ID,

      isAdmin: false, // Customer is sending
    );

    _messageController.clear();

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Apply light background
      appBar: AppBar(
        backgroundColor: _cardColor,
        // Apply White AppBar
        elevation: 1,
        // Slight elevation for definition
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          // Dark Blue back arrow
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // App Logo (replaces the old admin avatar icon)
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png', // Image asset as requested
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GearGo Support',
                    style: GoogleFonts.poppins(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor, // Dark Blue text
                    ),
                  ),
                  Text(
                    ' Online',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      // Darker green for online status
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body:
          _currentRoomId == null
              ? _buildLoadingState()
              : Column(
                children: [
                  // Chat Messages
                  Expanded(
                    child: StreamBuilder<List<MessageModel>>(
                      stream: _chatService.getMessages(_currentRoomId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: _accentColor,
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildWelcomeMessage();
                        }

                        final messages = snapshot.data!;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            // If senderId matches ADMIN_ID, it's an Admin message (left side).
                            final bool isAdminMessage =
                                message.senderId == ADMIN_ID;

                            return ChatMessageWidget(
                              message: message,
                              isAdmin: isAdminMessage,
                              // Pass the logo asset for admin messages (left side)
                              adminAvatarAsset:
                                  isAdminMessage
                                      ? 'assets/images/app_logo.png'
                                      : null,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Message Input
                  _buildMessageInput(),
                ],
              ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _cardColor, // White background
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accentColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.support_agent,
                size: 40,
                color: _primaryColor, // Dark Blue icon
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'GearGo Support',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor, // Black text
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hello! How can we help you today?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: _secondaryTextColor, // Gray text
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We typically reply within a few minutes',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _secondaryTextColor, // Gray text
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor, // White input background
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1), // Subtle dark shadow
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _inputColor, // White for text field
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ), // Light border
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: _textColor), // Black input text
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: _secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button
          Container(
            decoration: BoxDecoration(
              color: _accentColor, // Amber button
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: _primaryColor), // Dark Blue icon
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _accentColor),
          // Amber loading indicator
          const SizedBox(height: 20),
          Text(
            'Connecting to support...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _textColor, // Black text
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
