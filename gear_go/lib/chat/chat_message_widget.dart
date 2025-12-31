import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/message_model.dart';

// --- THEME DEFINITIONS (Local for self-contained widget styling) ---
const Color _primaryColor = Colors.black;
const Color _accentColor = Colors.yellow;
const Color _textColor = Colors.white;
const Color _timestampColor = Color(0xFF9E9E9E); // Medium grey for timestamps
const Color _adminBubbleColor = _accentColor; // Yellow bubble for admin (left)
const Color _userBubbleColor = Color(0xFF333333); // Dark grey bubble for user (right)
const Color _readIconColor = _accentColor; // Yellow for read status
const Color _unreadIconColor = Color(0xFF757575); // Darker grey for unread status

class ChatMessageWidget extends StatelessWidget {
  final MessageModel message;
  final bool isAdmin;
  final String? adminAvatarAsset; // New property for the logo asset

  const ChatMessageWidget({
    Key? key,
    required this.message,
    required this.isAdmin,
    this.adminAvatarAsset, // Optional asset path
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine alignment based on whether the message is from the Admin (left) or Customer (right)
    final bool isFromAdmin = isAdmin;
    final bool isFromCustomer = !isAdmin;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
        isFromCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ----------------------------------------------------
          // 1. Admin Avatar (Only for received messages - isFromAdmin)
          // ----------------------------------------------------
          if (isFromAdmin) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: ClipOval(
                child: adminAvatarAsset != null
                    ? Image.asset(
                  adminAvatarAsset!,
                  fit: BoxFit.cover,
                )
                    : const Icon(Icons.support_agent,
                    color: _accentColor, size: 18),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCustomer
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // ----------------------------------------------------
                // 2. Message Bubble
                // ----------------------------------------------------
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    // Yellow for Admin (left), dark grey for Customer (right)
                    color: isFromAdmin ? _adminBubbleColor : _userBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      // Square corner points towards the avatar/edge
                      bottomLeft: Radius.circular(isFromCustomer ? 18 : 4),
                      bottomRight: Radius.circular(isFromCustomer ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: GoogleFonts.poppins(
                      // Black text on yellow bubble, White text on dark grey bubble
                      color: isFromAdmin ? _primaryColor : _textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // ----------------------------------------------------
                // 3. Timestamp and Read Status
                // ----------------------------------------------------
                Row(
                  mainAxisAlignment: isFromCustomer
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(message.timestamp.toDate()),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _timestampColor, // Medium grey
                      ),
                    ),
                    if (isFromCustomer) ...[
                      const SizedBox(width: 6),
                      // Read status indicator (only for customer's sent messages)
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        // Yellow for read, dark grey for unread
                        color:
                        message.isRead ? _readIconColor : _unreadIconColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // ----------------------------------------------------
          // 4. Customer Avatar (Only for sent messages - isFromCustomer)
          // ----------------------------------------------------
          if (isFromCustomer) ...[
            const SizedBox(width: 8),
            // Placeholder for customer avatar (no logo requested here)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _userBubbleColor, // Dark grey background
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person,
                  color: _accentColor, size: 18), // Yellow icon
            ),
          ],
        ],
      ),
    );
  }
}
