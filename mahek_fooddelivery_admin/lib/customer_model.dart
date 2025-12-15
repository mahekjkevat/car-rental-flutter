// customer_model.dart
class Customer {
  final String objectId;
  final String name;
  final String email;
  final String? mobile;
  final String? profilePhoto;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  Customer({
    required this.objectId,
    required this.name,
    required this.email,
    this.mobile,
    this.profilePhoto,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      objectId: json['objectId'],
      name: json['name'] ?? 'Unknown Customer',
      email: json['email'] ?? '',
      mobile: json['mobile'],
      profilePhoto: json['profile_photo'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'name': name,
      'email': email,
      'mobile': mobile,
      'profile_photo': profilePhoto,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
    };
  }
}