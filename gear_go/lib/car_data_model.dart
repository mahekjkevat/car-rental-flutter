import 'package:cloud_firestore/cloud_firestore.dart';

class CarDataModel {
  final double basicPrice;
  final String carBrand;
  final String carImage1;
  final String carImage2;
  final String carImage3;
  final String carImage4;
  final String carName;
  final String chassisNo;
  final String engineNo;
  final String features1;
  final String features2;
  final String features3;
  final String features4;
  final String features5;
  final String features6;
  final String fuelType;
  final double maxPrice;
  final int noOfSeats;
  final double plusPrice;
  final String randomID; // Keep randomID if you still need it
  final String documentId; // Document ID from Firestore
  final String feedback_line;
  final double feedback_rating;
  final Timestamp feedback_time;
  final double avg_rating; // Default value for avg_rating
  final String label;

  CarDataModel({
    required this.basicPrice,
    required this.carBrand,
    required this.carImage1,
    required this.carImage2,
    required this.carImage3,
    required this.carImage4,
    required this.carName,
    required this.chassisNo,
    required this.engineNo,
    required this.features1,
    required this.features2,
    required this.features3,
    required this.features4,
    required this.features5,
    required this.features6,
    required this.fuelType,
    required this.maxPrice,
    required this.noOfSeats,
    required this.plusPrice,
    required this.randomID,
    required this.documentId,
    required this.feedback_line,
    required this.feedback_rating,
    required this.feedback_time,
    required this.avg_rating,
    required this.label,


  });

  // Factory constructor with null safety and default values
  factory CarDataModel.fromJson(Map<String, dynamic> json, String docId) {
    try {
      return CarDataModel(
        basicPrice: json['basic_price'] != null
            ? (json['basic_price'] is double
                ? json['basic_price'] as double
                : (json['basic_price'] is int ? (json['basic_price'] as int).toDouble() : 0.0))
            : 0.0,
        carBrand: json['car_brand'] as String? ?? '',
        carImage1: json['car_image1'] as String? ?? '',
        carImage2: json['car_image2'] as String? ?? '',
        carImage3: json['car_image3'] as String? ?? '',
        carImage4: json['car_image4'] as String? ?? '',
        carName: json['car_name'] as String? ?? '',
        chassisNo: json['chassis_no'] as String? ?? '',
        engineNo: json['engine_no'] as String? ?? '',
        features1: json['features1'] as String? ?? '',
        features2: json['features2'] as String? ?? '',
        features3: json['features3'] as String? ?? '',
        features4: json['features4'] as String? ?? '',
        features5: json['features5'] as String? ?? '',
        features6: json['features6'] as String? ?? '',
        fuelType: json['fuel_type'] as String? ?? '',
        label: json['label'] as String? ?? '',
        maxPrice: json['max_price'] != null
            ? (json['max_price'] is double
                ? json['max_price'] as double
                : (json['max_price'] is int ? (json['max_price'] as int).toDouble() : 0.0))
            : 0.0,
        noOfSeats: json['no_of_seats'] != null ? json['no_of_seats'] as int : 0,
        plusPrice: json['plus_price'] != null
            ? (json['plus_price'] is double
                ? json['plus_price'] as double
                : (json['plus_price'] is int ? (json['plus_price'] as int).toDouble() : 0.0))
            : 0.0,
        randomID: json['randomID'] as String? ?? '',
        documentId: docId,
        feedback_line: json['feedback_line'] as String? ?? '',
        feedback_rating: json['feedback_rating'] != null
            ? (json['feedback_rating'] is double
                ? json['feedback_rating'] as double
                : (json['feedback_rating'] is int ? (json['feedback_rating'] as int).toDouble() : 0.0))
            : 0.0,
        feedback_time: json['feedback_time'] != null
            ? (json['feedback_time'] is Timestamp
                ? json['feedback_time'] as Timestamp
                : Timestamp.fromMillisecondsSinceEpoch((json['feedback_time'] as int).toInt()))
            : Timestamp.now(),
        avg_rating: json['avg_rating'] != null
            ? (json['avg_rating'] is double
                ? json['avg_rating'] as double
                : (json['avg_rating'] is int ? (json['avg_rating'] as int).toDouble() : 0.0))
            : 0.0,
      );
    } catch (e) {
      print("Error converting JSON to CarDataModel: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'basic_price': basicPrice,
      'car_brand': carBrand,
      'car_image1': carImage1,
      'car_image2': carImage2,
      'car_image3': carImage3,
      'car_image4': carImage4,
      'car_name': carName,
      'chassis_no': chassisNo,
      'engine_no': engineNo,
      'features1': features1,
      'features2': features2,
      'features3': features3,
      'features4': features4,
      'features5': features5,
      'features6': features6,
      'fuel_type': fuelType,
      'label': label,
      'max_price': maxPrice,
      'no_of_seats': noOfSeats,
      'plus_price': plusPrice,
      'randomID': randomID,
      'documentId': documentId,
      'feedback_line': feedback_line,
      'feedback_rating': feedback_rating,
      'feedback_time': feedback_time,
      'avg_rating': avg_rating,
    };
  }
}