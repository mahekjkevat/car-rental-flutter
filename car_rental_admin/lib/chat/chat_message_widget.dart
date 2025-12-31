import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/message_model.dart';

// --- THEME DEFINITIONS ---
const Color _primaryColor = Colors.black;
const Color _accentColor = Colors.yellow;
const Color _textColor = Colors.white;
const Color _timestampColor = Color(0xFF9E9E9E);
const Color _userBubbleColor = Colors.yellow; // User messages: Yellow background
const Color _adminBubbleColor = Color(0xFF333333); // Admin messages: Dark background
const Color _userTextColor = Colors.black; // User messages: Black text
const Color _adminTextColor = Colors.yellow; // Admin messages: Yellow text
const Color _readIconColor = Colors.blue;
const Color _unreadIconColor = Color(0xFF757575);
const Color _deletedMessageColor = Colors.white;
const Color _deletedMessageBgColor = Color(0xFF666666);

class ChatMessageWidget extends StatefulWidget {
  final MessageModel message;
  final bool isAdmin;
  final String? userProfileImage;
  final VoidCallback? onProfileImageTap;
  final Function(String messageId)? onDeleteMessage;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    required this.isAdmin,
    this.userProfileImage,
    this.onProfileImageTap,
    this.onDeleteMessage,
  }) : super(key: key);

  @override
  _ChatMessageWidgetState createState() => _ChatMessageWidgetState();
}
// Replace the entire _ChatMessageWidgetState class with this:

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  bool _showDeleteOption = false;
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    _isDeleted = widget.message.message == "This message was deleted";
  }

  // FIXED LOGIC:
  // Admin UID: NulFprQxJ1cQ5MHz1AZjoCE0yZC3
  // If senderId is admin UID = RIGHT side (admin message)
  // If senderId is NOT admin UID = LEFT side (user message)
  bool get isAdminMessage => widget.message.senderId == 'NulFprQxJ1cQ5MHz1AZjoCE0yZC3';
  bool get isUserMessage => !isAdminMessage;

  void _showDeleteMenu() {
    // FIXED: Only allow admin to delete their OWN messages (admin messages)
    if (widget.isAdmin && isAdminMessage && !_isDeleted) {
      setState(() {
        _showDeleteOption = true;
      });
    }
  }

  void _hideDeleteMenu() {
    setState(() {
      _showDeleteOption = false;
    });
  }

  void _deleteMessage() {
    if (widget.onDeleteMessage != null) {
      widget.onDeleteMessage!(widget.message.messageId);
    }
    _hideDeleteMenu();
  }

  @override
  Widget build(BuildContext context) {
    // Check if message is deleted
    final bool isMessageDeleted = widget.message.message == "This message was deleted";

    return GestureDetector(
      onLongPress: _showDeleteMenu,
      onTap: _hideDeleteMenu,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          children: [
            // Delete Option Menu (shown above message) - ONLY FOR ADMIN MESSAGES
            if (_showDeleteOption && !isMessageDeleted)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _deleteMessage,
                      child: Text(
                        'Delete for everyone',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _hideDeleteMenu,
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Message Row
            Row(
              mainAxisAlignment: isUserMessage ? MainAxisAlignment.start : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Image (LEFT side for user messages only)
                if (isUserMessage) ...[
                  GestureDetector(
                    onTap: widget.onProfileImageTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _accentColor, width: 1),
                      ),
                      child: ClipOval(
                        child: widget.userProfileImage != null && widget.userProfileImage!.isNotEmpty
                            ? Image.network(
                          widget.userProfileImage!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: _userBubbleColor,
                              child: Icon(Icons.person, color: _primaryColor, size: 20),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: _userBubbleColor,
                              child: Icon(Icons.person, color: _primaryColor, size: 20),
                            );
                          },
                        )
                            : Container(
                          color: _userBubbleColor,
                          child: Icon(Icons.person, color: _primaryColor, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Message Content
                Flexible(
                  child: Column(
                    crossAxisAlignment: isUserMessage ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      // Message Bubble
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMessageDeleted
                              ? _deletedMessageBgColor
                              : (isUserMessage ? _userBubbleColor : _adminBubbleColor),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isUserMessage ? 4 : 18),
                            bottomRight: Radius.circular(isUserMessage ? 18 : 4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMessageDeleted ? "This message was deleted" : widget.message.message,
                              style: GoogleFonts.poppins(
                                color: isMessageDeleted
                                    ? _deletedMessageColor
                                    : (isUserMessage ? _userTextColor : _adminTextColor),
                                fontSize: 14,
                                fontWeight: isMessageDeleted ? FontWeight.w400 : FontWeight.w500,
                                fontStyle: isMessageDeleted ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),

                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Timestamp and Read Status
                      Padding(
                        padding: EdgeInsets.only(
                          left: isUserMessage ? 8 : 0,
                          right: isUserMessage ? 0 : 8,
                        ),
                        child: Row(
                          mainAxisAlignment: isUserMessage ? MainAxisAlignment.start : MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('hh:mm a').format(widget.message.timestamp.toDate()),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: _timestampColor,
                              ),
                            ),
                            if (isAdminMessage) ...[
                              const SizedBox(width: 6),
                              // WhatsApp-like read status (only for admin messages)
                              Icon(
                                widget.message.isRead ? Icons.done_all : Icons.done,
                                size: 14,
                                color: widget.message.isRead ? _readIconColor : _unreadIconColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Admin Logo (RIGHT side for admin messages only)
                if (isAdminMessage) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_logo.jpeg',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.admin_panel_settings, color: _primaryColor, size: 20);
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}