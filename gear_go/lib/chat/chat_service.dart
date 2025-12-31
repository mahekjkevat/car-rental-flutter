import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/message_model.dart';
import 'models/chat_room_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add to ChatService class in chat_service.dart

// Create chat room with specific admin
  Future<String> createChatRoom(String userId,
      Map<String, dynamic> userInfo, {
        required String adminId,
        required String adminEmail,
      }) async {
    final roomId = _firestore
        .collection('chat_rooms')
        .doc()
        .id;

    final chatRoom = ChatRoomModel(
      roomId: roomId,
      participants: {
        'userId': userId,
        'adminId': adminId,
      },
      userInfo: {
        userId: userInfo,
        adminId: {
          'name': 'GearGo Admin',
          'email': adminEmail,
        },
      },
      lastMessage: 'Chat started with support',
      lastMessageTime: Timestamp.now(),
      unreadCount: {
        userId: 0,
        adminId: 0,
      },
      createdAt: Timestamp.now(),
      isActive: true,
    );

    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .set(chatRoom.toMap());

    return roomId;
  }

// Send message (customer version)
  Future<void> sendMessage({
    required String roomId,
    required String message,
    required String receiverId,
    required bool isAdmin,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageId = _firestore
        .collection('chat_rooms')
        .doc()
        .id;

    String senderName;
    if (isAdmin) {
      senderName = 'GearGo Admin';
    } else {
      // Get user name from Firestore or use display name
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      senderName = userData?['name'] ?? user.displayName ?? 'User';
    }

    final messageData = MessageModel(
      messageId: messageId,
      senderId: user.uid,
      senderName: senderName,
      message: message,
      messageType: 'text',
      timestamp: Timestamp.now(),
      readBy: {
        user.uid: true,
        receiverId: false,
      },
      isRead: false,
    );

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
  }

// Get customer's chat room
  Stream<ChatRoomModel?> getCustomerChatRoom() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('chat_rooms')
        .where('participants.userId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ChatRoomModel.fromMap(snapshot.docs.first.data());
    });
  }

  // Get all chat rooms for admin
  Stream<List<ChatRoomModel>> getAdminChatRooms() {
    return _firestore
        .collection('chat_rooms')
        .where('participants.adminId', isEqualTo: _auth.currentUser!.uid)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => ChatRoomModel.fromMap(doc.data()))
            .toList());
  }

  // Get messages for a specific chat room
  Stream<List<MessageModel>> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }


  // Mark messages as read by admin
  Future<void> markMessagesAsRead(String roomId) async {
    final messagesSnapshot = await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .where('readBy.${_auth.currentUser!.uid}', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {
        'readBy.${_auth.currentUser!.uid}': true,
      });
    }

    await batch.commit();

    // Reset unread count for admin
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'unreadCount.${_auth.currentUser!.uid}': 0,
    });
  }
}