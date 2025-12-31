import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String carName;
  final String feedbackLine;
  final String feedbackRating;
  final DateTime feedbackTime; // Store as DateTime internally
  final String userName;

  Review({
    required this.carName,
    required this.feedbackLine,
    required this.feedbackRating,
    required this.feedbackTime,
    required this.userName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final feedbackTimeData = json['feedback_time'];
    DateTime parsedTime;

    if (feedbackTimeData is Timestamp) {
      // Firestore Timestamp
      parsedTime = feedbackTimeData.toDate();
    } else if (feedbackTimeData is String) {
      // ISO String
      parsedTime = DateTime.parse(feedbackTimeData);
    } else {
      // fallback
      parsedTime = DateTime.now();
    }

    return Review(
      carName: json['car_name'] ?? '',
      feedbackLine: json['feedback_line'] ?? '',
      feedbackRating: (json['feedback_rating'] ?? '').toString(),
      feedbackTime: parsedTime,
      userName: json['userName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'car_name': carName,
      'feedback_line': feedbackLine,
      'feedback_rating': feedbackRating,
      'feedback_time': Timestamp.fromDate(feedbackTime), // Convert to Timestamp for Firestore
      'userName': userName,
    };
  }

  // Optional helper to get string representation
  String get feedbackTimeString => feedbackTime.toIso8601String();
}