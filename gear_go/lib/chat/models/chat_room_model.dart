import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String roomId;
  final Map<String, String> participants;
  final Map<String, Map<String, dynamic>> userInfo;
  final String lastMessage;
  final Timestamp lastMessageTime;
  final Map<String, int> unreadCount;
  final Timestamp createdAt;
  final bool isActive;

  ChatRoomModel({
    required this.roomId,
    required this.participants,
    required this.userInfo,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    required this.isActive,
  });

  String get userId => participants['userId'] ?? '';
  String get adminId => participants['adminId'] ?? '';
  String get userName => userInfo[userId]?['name'] ?? 'Unknown User';
  String get userEmail => userInfo[userId]?['email'] ?? '';
  String? get userProfileImage => userInfo[userId]?['profileImage'];

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      roomId: map['roomId'] ?? '',
      participants: Map<String, String>.from(map['participants'] ?? {}),
      userInfo: Map<String, Map<String, dynamic>>.from(map['userInfo'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] ?? Timestamp.now(),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'participants': participants,
      'userInfo': userInfo,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}