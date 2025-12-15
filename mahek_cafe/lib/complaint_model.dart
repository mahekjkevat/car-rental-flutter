// complaint_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String complaintType;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Complaint({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.complaintType,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'complaintType': complaintType,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Firestore Document
  factory Complaint.fromMap(String id, Map<String, dynamic> map) {
    return Complaint(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      complaintType: map['complaintType'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}