import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'chat_service.dart';
import 'models/chat_room_model.dart';
import 'admin_chat_room_page.dart';

// --- THEME DEFINITIONS ---
const Color _primaryColor = Colors.black;
const Color _accentColor = Colors.yellow;
const Color _backgroundColor = Color(0xFF121212);
const Color _cardColor = Color(0xFF1E1E1E);
const Color _textColor = Colors.white;
const Color _secondaryTextColor = Colors.grey;
const Color _unreadBadgeColor = Color(0xFFD32F2F);
const Color _onlineStatusColor = Colors.green;

class AdminChatListPage extends StatefulWidget {
  const AdminChatListPage({Key? key}) : super(key: key);

  @override
  _AdminChatListPageState createState() => _AdminChatListPageState();
}

class _AdminChatListPageState extends State<AdminChatListPage> {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _setAdminOnline();
  }

  @override
  void dispose() {
    _setAdminOffline();
    super.dispose();
  }

  void _setAdminOnline() {
    _chatService.updateAdminStatus('online');
  }

  void _setAdminOffline() {
    _chatService.updateAdminStatus('offline');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 4,
        title: Text(
          'Customer Chats',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _accentColor,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _chatService.getAdminChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState('Error loading chats: ${snapshot.error}');
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final chatRooms = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              return _buildChatRoomItem(chatRooms[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoomModel chatRoom) {
    final unreadCount = chatRoom.unreadCount['admin001'] ?? 0;
    final isUserOnline = chatRoom.onlineStatus[chatRoom.userId] == 'online';

    return Card(
      elevation: 6,
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminChatRoomPage(
                chatRoom: chatRoom,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: chatRoom.userProfileImage != null &&
                      chatRoom.userProfileImage!.isNotEmpty
                      ? ClipOval(
                    child: Image.network(
                      chatRoom.userProfileImage!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person, color: _primaryColor, size: 28);
                      },
                    ),
                  )
                      : Icon(Icons.person, color: _primaryColor, size: 28),
                ),
                if (isUserOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _onlineStatusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _cardColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    chatRoom.userName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: _unreadBadgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: GoogleFonts.poppins(
                        color: _textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatRoom.lastMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('MMM dd, hh:mm a').format(chatRoom.lastMessageTime.toDate()),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUserOnline ? 'Online' : 'Offline',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isUserOnline ? _onlineStatusColor : _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: _accentColor,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _accentColor),
          const SizedBox(height: 20),
          Text(
            'Loading conversations...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'Error loading chats',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Please check your connection.',
            style: GoogleFonts.poppins(color: _secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: _secondaryTextColor,
          ),
          const SizedBox(height: 20),
          Text(
            'No Active Chats',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When users start chatting with you,\nconversations will appear here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}