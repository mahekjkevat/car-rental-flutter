// admin_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'admin_pusher_service.dart';
import 'app_theme.dart';
import 'back4app_service.dart';
import 'customer_model.dart';
import 'dart:convert';

class AdminChatScreen extends StatefulWidget {
  final Customer customer;

  const AdminChatScreen({super.key, required this.customer});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final AdminPusherService _pusherService = AdminPusherService();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializePusher();
    _loadChatHistory();
  }

  Future<void> _initializePusher() async {
    await _pusherService.initPusher();

    _pusherService.onMessageReceived = (event) {
      _handleIncomingMessage(event);
    };

    await _pusherService.subscribeToCustomer(widget.customer.objectId);
    print("✅ Admin listening to customer: ${widget.customer.objectId}");
  }

  void _loadChatHistory() {
    // In a real app, you would fetch chat history from Back4App
    // For now, we'll use sample messages
    setState(() {
      _chatMessages.addAll([
        {
          'text': 'Hello! Welcome to Mahek Cafe. How can I help you today?',
          'timestamp': DateTime.now().subtract(Duration(minutes: 10)).toIso8601String(),
          'isSent': false,
          'sender_name': _pusherService.adminName,
          'sender_image': _pusherService.adminImage,
        },
        {
          'text': 'Hi, I want to order some food. What are your specials?',
          'timestamp': DateTime.now().subtract(Duration(minutes: 8)).toIso8601String(),
          'isSent': true,
          'sender_name': widget.customer.name,
          'sender_image': widget.customer.profilePhoto,
        },
        {
          'text': 'We have pizza, burgers, and pasta as today\'s specials!',
          'timestamp': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
          'isSent': false,
          'sender_name': _pusherService.adminName,
          'sender_image': _pusherService.adminImage,
        },
      ]);
    });
    _scrollToBottom();
  }

  void _handleIncomingMessage(PusherEvent event) {
    if (mounted) {
      setState(() {
        try {
          final decoded = json.decode(event.data);
          if (decoded['sender_role'] != 'admin') {
            final messageData = {
              'text': decoded['text'],
              'timestamp': DateTime.now().toIso8601String(),
              'isSent': false,
              'sender_name': decoded['sender_name'] ?? widget.customer.name,
              'sender_image': decoded['sender_image'] ?? widget.customer.profilePhoto,
            };
            _chatMessages.add(messageData);
            _scrollToBottom();

            // Update customer's last message in Back4App
            _updateCustomerLastMessage(decoded['text']);
          }
        } catch (e) {
          print("❌ Error parsing message: $e");
        }
      });
    }
  }

  Future<void> _updateCustomerLastMessage(String message) async {
    try {
      final newUnreadCount = widget.customer.unreadCount + 1;
      await Back4AppService.updateCustomerLastMessage(
        widget.customer.objectId,
        message,
        newUnreadCount,
      );
      print("✅ Updated customer last message in Back4App");
    } catch (e) {
      print("❌ Error updating customer last message: $e");
    }
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    final messageText = _messageController.text;

    // Add to local chat
    setState(() {
      _chatMessages.add({
        'text': messageText,
        'timestamp': DateTime.now().toIso8601String(),
        'isSent': true,
        'sender_name': _pusherService.adminName,
        'sender_image': _pusherService.adminImage,
      });
    });

    // Send via Pusher
    _pusherService.sendMessageToCustomer(widget.customer.objectId, messageText);

    // Update customer's last message in Back4App
    Back4AppService.updateCustomerLastMessage(
      widget.customer.objectId,
      messageText,
      0, // Reset unread count for admin messages
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

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isSent = message['isSent'] == true;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message['sender_image'] != null && message['sender_image'].isNotEmpty
                  ? NetworkImage(message['sender_image'])
                  : AssetImage('assets/images/user_placeholder.png') as ImageProvider,
              child: message['sender_image'] == null || message['sender_image'].isEmpty
                  ? Icon(Icons.person, size: 16, color: Colors.white)
                  : null,
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSent ? primaryOrange.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSent)
                    Text(
                      message['sender_name'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: darkGrayText,
                      ),
                    ),
                  SizedBox(height: 2),
                  Text(
                    message['text'],
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message['timestamp']),
                    style: TextStyle(fontSize: 10, color: grayText),
                  ),
                ],
              ),
            ),
          ),
          if (isSent) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/icon/app_icon.jpeg'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return 'Now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.customer.profilePhoto != null && widget.customer.profilePhoto!.isNotEmpty
                  ? NetworkImage(widget.customer.profilePhoto!)
                  : AssetImage('assets/images/user_placeholder.png') as ImageProvider,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customer.name,
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  widget.customer.mobile ?? widget.customer.email,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          if (widget.customer.mobile != null)
            IconButton(
              icon: Icon(Icons.call),
              onPressed: () {
                print("🟠 Call customer: ${widget.customer.mobile}");
              },
            ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              print("🟠 More options for ${widget.customer.name}");
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          Container(
            padding: EdgeInsets.all(8),
            color: _pusherService.isConnected ? Colors.green.shade50 : Colors.orange.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _pusherService.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _pusherService.isConnected ? Colors.green : Colors.orange,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  _pusherService.isConnected ? 'Connected to customer' : 'Connecting...',
                  style: TextStyle(
                    color: _pusherService.isConnected ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: _chatMessages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: grayText),
                  SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18, color: grayText),
                  ),
                  Text(
                    'Start a conversation with ${widget.customer.name}',
                    style: TextStyle(color: grayText),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_chatMessages[index], index);
              },
            ),
          ),

          // Quick Actions
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip('Order Confirmed'),
                _buildQuickChip('Out for Delivery'),
                _buildQuickChip('Delivered'),
                _buildQuickChip('Need Help?'),
              ],
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: primaryOrange,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
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

  Widget _buildQuickChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () => _sendQuickMessage(text),
      backgroundColor: primaryOrange.withOpacity(0.1),
      labelStyle: TextStyle(color: primaryOrange),
    );
  }

  @override
  void dispose() {
    _pusherService.disconnect();
    _scrollController.dispose();
    super.dispose();
  }
}