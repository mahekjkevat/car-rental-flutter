import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/message_model.dart';
import 'models/chat_room_model.dart';
import 'package:intl/intl.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Your FCM Server Key
  static const String SERVER_KEY = 'AIzaSyDlTfXAEx9xRgy_AYQbu9Nc7LPAaZaPeiU';

  // CORRECT ADMIN UID - Use your actual admin UID everywhere
  String get adminId => 'NulFprQxJ1cQ5MHz1AZjoCE0yZC3';

  // Get all chat rooms for admin
  Stream<List<ChatRoomModel>> getAdminChatRooms() {
    return _firestore
        .collection('chat_rooms')
        .where('participants.adminId', isEqualTo: adminId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final chatRooms = <ChatRoomModel>[];

      for (final doc in snapshot.docs) {
        final chatRoom = ChatRoomModel.fromMap(doc.data());

        // Fetch latest user data for each chat room
        final userData = await getUserProfile(chatRoom.userId);
        if (userData != null) {
          final updatedChatRoom = chatRoom.copyWithUserInfo(userData);
          chatRooms.add(updatedChatRoom);
        } else {
          chatRooms.add(chatRoom);
        }
      }

      return chatRooms;
    });
  }

  // Get messages for a specific chat room
  Stream<List<MessageModel>> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Stream for a single chat room
  Stream<ChatRoomModel> getChatRoomStream(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .snapshots()
        .asyncMap((snapshot) async {
      final data = snapshot.data();
      if (data == null) {
        throw Exception('Chat room not found or deleted.');
      }
      final chatRoom = ChatRoomModel.fromMap(data);

      final userData = await getUserProfile(chatRoom.userId);
      if (userData != null) {
        return chatRoom.copyWithUserInfo(userData);
      }
      return chatRoom;
    });
  }

  // Send a new message as ADMIN
  Future<void> sendMessage({
    required String roomId,
    required String message,
    required String receiverId,
  }) async {
    final messageId = _firestore.collection('chat_rooms').doc().id;

    // USE CORRECT ADMIN UID
    final messageData = MessageModel(
      messageId: messageId,
      senderId: adminId, // Use adminId getter
      senderName: 'GearGo Admin',
      message: message,
      messageType: 'text',
      timestamp: Timestamp.now(),
      readBy: {
        adminId: true, // Admin has read their own message
        receiverId: false, // User hasn't read it yet
      },
      isRead: false,
    );

    print('📤 Sending message as ADMIN: $adminId');

    // Add message to subcollection
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .set(messageData.toMap());

    // Update last message in chat room
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'lastMessage': message,
      'lastMessageTime': Timestamp.now(),
      'unreadCount.$receiverId': FieldValue.increment(1),
    });

    print('✅ Message sent successfully as admin');
  }

  // Send push notification to admin when USER sends message
  Future<void> sendPushNotificationToAdmin({
    required String roomId,
    required String message,
    required String userName,
    required String userId,
  }) async {
    try {
      print('🟡 Starting to send notification to admin...');

      // Get admin FCM token from database - USE CORRECT ADMIN UID
      final tokenDoc = await _firestore
          .collection('admin_tokens')
          .doc(adminId) // Use adminId getter
          .get();

      if (tokenDoc.exists && tokenDoc.data() != null) {
        final String adminToken = tokenDoc.data()!['token'];
        print('🔑 Found admin token: ${adminToken.substring(0, 20)}...');

        // Prepare notification payload
        final Map<String, dynamic> notificationPayload = {
          'to': adminToken,
          'notification': {
            'title': 'New Message from $userName',
            'body': message.length > 100 ? '${message.substring(0, 100)}...' : message,
            'sound': 'default',
            'android_channel_id': 'chat_channel',
          },
          'data': {
            'type': 'chat_message',
            'roomId': roomId,
            'senderId': userId,
            'senderName': userName,
            'message': message,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'chat_channel',
              'sound': 'default',
              'vibrate_timings': [0, 1000, 500, 1000],
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {
                  'title': 'New Message from $userName',
                  'body': message.length > 100 ? '${message.substring(0, 100)}...' : message,
                },
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        };

        print('📤 Sending FCM request...');

        final response = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$SERVER_KEY',
          },
          body: jsonEncode(notificationPayload),
        );

        print('📥 FCM Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == 1) {
            print('✅ Notification sent successfully to admin');
          } else {
            print('❌ FCM API error: ${responseData['results']}');
          }
        } else {
          print('❌ HTTP error: ${response.statusCode}');
        }
      } else {
        print('⚠️ No FCM token found for admin $adminId in database');
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  // Mark all messages as read
  Future<void> markMessagesAsRead(String roomId) async {
    // Reset admin's unread count
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'unreadCount.$adminId': 0,
    });

    // Mark all user-sent messages as read by the admin
    final messagesSnapshot = await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: adminId) // Only user messages
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {
        'readBy.$adminId': true,
      });
    }
    await batch.commit();

    print('✅ Messages marked as read by admin: $adminId');
  }

  // Update admin online status
  Future<void> updateAdminStatus(String status) async {
    String statusToSet;
    Timestamp? lastSeenTimestamp;

    if (status == 'online') {
      statusToSet = 'online';
      lastSeenTimestamp = null;
    } else {
      statusToSet = DateFormat('hh:mm a').format(DateTime.now());
      lastSeenTimestamp = Timestamp.now();
    }

    final chatRooms = await _firestore
        .collection('chat_rooms')
        .where('participants.adminId', isEqualTo: adminId)
        .get();

    final batch = _firestore.batch();

    for (final doc in chatRooms.docs) {
      final updateData = <String, dynamic>{
        'onlineStatus.$adminId': statusToSet,
      };

      if (lastSeenTimestamp != null) {
        updateData['lastSeen.$adminId'] = lastSeenTimestamp;
      } else {
        updateData['lastSeen.$adminId'] = FieldValue.delete();
      }

      batch.update(doc.reference, updateData);
    }

    await batch.commit();

    print('✅ Admin status updated: $status - Admin: $adminId');
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('Users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Create new chat room
  Future<String> createChatRoom(String userId, Map<String, dynamic> userInfo) async {
    final roomId = _firestore.collection('chat_rooms').doc().id;

    final chatRoom = ChatRoomModel(
      roomId: roomId,
      participants: {
        'userId': userId,
        'adminId': adminId, // Use adminId getter
      },
      userInfo: {
        userId: userInfo,
        adminId: { // Use adminId getter
          'name': 'GearGo Admin',
          'email': 'mahekjkevat@gmail.com',
        },
      },
      lastMessage: 'Chat started',
      lastMessageTime: Timestamp.now(),
      unreadCount: {
        userId: 0,
        adminId: 0, // Use adminId getter
      },
      createdAt: Timestamp.now(),
      isActive: true,
      onlineStatus: {
        adminId: 'online', // Use adminId getter
        userId: 'offline',
      },
      lastSeen: {},
    );

    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .set(chatRoom.toMap());

    print('✅ Chat room created - Admin: $adminId, User: $userId');
    return roomId;
  }

  // Stream user profile updates
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  // Save admin FCM token to database
  Future<void> saveAdminFCMToken(String token) async {
    try {
      await _firestore
          .collection('admin_tokens')
          .doc(adminId) // Use adminId getter
          .set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': 'android',
      }, SetOptions(merge: true));

      print('✅ Admin FCM token saved: ${token.substring(0, 20)}...');
    } catch (e) {
      print('❌ Error saving admin FCM token: $e');
    }
  }

  // Delete admin FCM token (when logging out)
  Future<void> deleteAdminFCMToken() async {
    try {
      await _firestore
          .collection('admin_tokens')
          .doc(adminId) // Use adminId getter
          .delete();
      print('✅ Admin FCM token deleted');
    } catch (e) {
      print('❌ Error deleting admin FCM token: $e');
    }
  }
}