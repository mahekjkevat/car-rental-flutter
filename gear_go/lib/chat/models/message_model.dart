import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String message;
  final String messageType;
  final Timestamp timestamp;
  final Map<String, bool> readBy;
  final bool isRead;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.messageType,
    required this.timestamp,
    required this.readBy,
    required this.isRead,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      messageType: map['messageType'] ?? 'text',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      readBy: Map<String, bool>.from(map['readBy'] ?? {}),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'messageType': messageType,
      'timestamp': timestamp,
      'readBy': readBy,
      'isRead': isRead,
    };
  }
}