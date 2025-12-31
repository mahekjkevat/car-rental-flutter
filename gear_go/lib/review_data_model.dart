import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userName;
  final String feedbackLine;
  final double feedbackRating;
  final Timestamp feedbackTime;

  Review({
    required this.userName,
    required this.feedbackLine,
    required this.feedbackRating,
    required this.feedbackTime,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      userName: json['userName'] ?? 'Anonymous',
      feedbackLine: json['feedback_line'] ?? '',
      feedbackRating: json['feedback_rating'] != null
          ? (json['feedback_rating'] is double
              ? json['feedback_rating']
              : (json['feedback_rating'] is int ? (json['feedback_rating'] as int).toDouble() : 0.0))
          : 0.0,
      feedbackTime: json['feedback_time'] != null
          ? (json['feedback_time'] is Timestamp
              ? json['feedback_time']
              : Timestamp.fromMillisecondsSinceEpoch((json['feedback_time'] as int).toInt()))
          : Timestamp.now(),
    );
  }

  // Add this method
  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'feedback_line': feedbackLine,
      'feedback_rating': feedbackRating,
      'feedback_time': feedbackTime,
    };
  }
}