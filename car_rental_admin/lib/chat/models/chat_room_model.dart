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
  final Map<String, String> onlineStatus;
  final Map<String, dynamic> lastSeen;

  ChatRoomModel({
    required this.roomId,
    required this.participants,
    required this.userInfo,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    required this.isActive,
    required this.onlineStatus,
    required this.lastSeen,
  });

  String get userId => participants['userId'] ?? '';
  String get adminId => participants['adminId'] ?? '';

  // Enhanced getters with fallback values
  String get userName => userInfo[userId]?['name'] ?? 'Unknown User';
  String get userEmail => userInfo[userId]?['email'] ?? 'No Email';
  String? get userProfileImage => userInfo[userId]?['profile_image'];
  String? get userPhone => userInfo[userId]?['mobile_number'];
  String? get userBio => userInfo[userId]?['bio'];
  String? get userCity => userInfo[userId]?['city'];
  String? get userCountry => userInfo[userId]?['country'];
  String? get userState => userInfo[userId]?['state'];

  bool get isUserOnline => onlineStatus[userId] == 'online';
  bool get isAdminOnline => onlineStatus[adminId] == 'online';

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
      onlineStatus: Map<String, String>.from(map['onlineStatus'] ?? {}),
      lastSeen: Map<String, dynamic>.from(map['lastSeen'] ?? {}),
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
      'onlineStatus': onlineStatus,
      'lastSeen': lastSeen,
    };
  }

  // Method to update user info with fresh data
  ChatRoomModel copyWithUserInfo(Map<String, dynamic> newUserInfo) {
    final updatedUserInfo = Map<String, Map<String, dynamic>>.from(userInfo);
    updatedUserInfo[userId] = newUserInfo;

    return ChatRoomModel(
      roomId: roomId,
      participants: participants,
      userInfo: updatedUserInfo,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      createdAt: createdAt,
      isActive: isActive,
      onlineStatus: onlineStatus,
      lastSeen: lastSeen,
    );
  }
}