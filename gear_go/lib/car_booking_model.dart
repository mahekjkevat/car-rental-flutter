import 'package:cloud_firestore/cloud_firestore.dart';

class CarBooking {
  final String id;
  final String documentId;
  final String fromLocation;
  final String toLocation;
  final String fromAddress;
  final String toAddress;
  final Timestamp pickUpDateTime;
  final Timestamp returnDateTime;
  final String? subscription;
  final String? seats;
  final double distance;
  final double totalPrice;
  final Timestamp bookingTime;
  final String status;
  final String carImage1;
  final String carName;
  final String? carBrand;
  final String? paymentMethod;
  final String? userName;
  final String? userEmail;
  final String? userMobile;
  final String? userCity;
  final String? userState;
  final String? userCountry;
  final String? userPinCode;
  final String? userLicense;
  final String? invoiceLink;
  final Timestamp? invoiceSentDate;

  // Cancellation and refund fields
  final Timestamp? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final bool? refundProcessed;
  final bool? refundEligible;
  final Timestamp? refundProcessedAt;
  final String? cancelRequest; // 'Pending', 'Processing', 'Completed'

  CarBooking({
    required this.id,
    required this.documentId,
    required this.fromLocation,
    required this.toLocation,
    required this.fromAddress,
    required this.toAddress,
    required this.pickUpDateTime,
    required this.returnDateTime,
    this.subscription,
    this.seats,
    required this.distance,
    required this.totalPrice,
    required this.bookingTime,
    required this.status,
    required this.carImage1,
    required this.carName,
    this.carBrand,
    this.paymentMethod,
    this.userName,
    this.userEmail,
    this.userMobile,
    this.userCity,
    this.userState,
    this.userCountry,
    this.userPinCode,
    this.userLicense,
    this.invoiceLink,
    this.invoiceSentDate,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    this.refundProcessed,
    this.refundEligible,
    this.refundProcessedAt,
    this.cancelRequest,
  });

  factory CarBooking.fromFirestore(Map<String, dynamic> data, String id) {
    return CarBooking(
      id: id,
      documentId: data['documentId'] ?? '',
      fromLocation: data['fromLocation'] ?? '',
      toLocation: data['toLocation'] ?? '',
      fromAddress: data['fromAddress'] ?? '',
      toAddress: data['toAddress'] ?? '',
      pickUpDateTime: data['pickUpDateTime'] ?? Timestamp.now(),
      returnDateTime: data['returnDateTime'] ?? Timestamp.now(),
      subscription: data['subscription'],
      seats: data['seats'],
      distance: (data['distance'] ?? 0.0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      bookingTime: data['bookingTime'] ?? Timestamp.now(),
      status: data['status'] ?? 'Pending',
      carImage1: data['carImage1'] ?? '',
      carName: data['carName'] ?? '',
      carBrand: data['car_brand'],
      paymentMethod: data['payment_method'],
      userName: data['userName'],
      userEmail: data['userEmail'],
      userMobile: data['userMobile'],
      userCity: data['userCity'],
      userState: data['userState'],
      userCountry: data['userCountry'],
      userPinCode: data['userPinCode'],
      userLicense: data['userLicense'],
      invoiceLink: data['invoice_link'],
      invoiceSentDate: data['invoice_to_user_date'],
      // Cancellation and refund fields
      cancelledAt: data['cancelled_at'],
      cancelledBy: data['cancelled_by'],
      cancellationReason: data['cancellation_reason'],
      refundProcessed: data['refund_processed'] ?? false,
      refundEligible: data['refund_eligible'] ?? false,
      refundProcessedAt: data['refund_processed_at'],
      cancelRequest: data['cancel_request'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'pickUpDateTime': pickUpDateTime,
      'returnDateTime': returnDateTime,
      'subscription': subscription,
      'seats': seats,
      'distance': distance,
      'totalPrice': totalPrice,
      'bookingTime': bookingTime,
      'status': status,
      'carImage1': carImage1,
      'carName': carName,
      'car_brand': carBrand,
      'payment_method': paymentMethod,
      'userName': userName,
      'userEmail': userEmail,
      'userMobile': userMobile,
      'userCity': userCity,
      'userState': userState,
      'userCountry': userCountry,
      'userPinCode': userPinCode,
      'userLicense': userLicense,
      'invoice_link': invoiceLink,
      'invoice_to_user_date': invoiceSentDate,
      'location_Status': false,
      'cancel_request': cancelRequest ?? 'Pending',
      'cancel_request_amount': 0.0,
      'cancel_request_date': null,
      // Cancellation and refund fields
      'cancelled_at': cancelledAt,
      'cancelled_by': cancelledBy,
      'cancellation_reason': cancellationReason,
      'refund_processed': refundProcessed ?? false,
      'refund_eligible': refundEligible ?? false,
      'refund_processed_at': refundProcessedAt,
    };
  }

  factory CarBooking.fromMap(Map<String, dynamic> map, String id) {
    return CarBooking(
      id: id,
      documentId: map['documentId'] ?? '',
      fromLocation: map['fromLocation'] ?? '',
      toLocation: map['toLocation'] ?? '',
      fromAddress: map['fromAddress'] ?? '',
      toAddress: map['toAddress'] ?? '',
      pickUpDateTime: map['pickUpDateTime'] is Timestamp
          ? map['pickUpDateTime'] as Timestamp
          : Timestamp.now(),
      returnDateTime: map['returnDateTime'] is Timestamp
          ? map['returnDateTime'] as Timestamp
          : Timestamp.now(),
      subscription: map['subscription'],
      seats: map['seats'],
      distance: (map['distance'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      bookingTime: map['bookingTime'] is Timestamp
          ? map['bookingTime'] as Timestamp
          : Timestamp.now(),
      status: map['status'] ?? 'Pending',
      carImage1: map['carImage1'] ?? '',
      carName: map['carName'] ?? '',
      carBrand: map['car_brand'],
      paymentMethod: map['payment_method'],
      userName: map['userName'],
      userEmail: map['userEmail'],
      userMobile: map['userMobile'],
      userCity: map['userCity'],
      userState: map['userState'],
      userCountry: map['userCountry'],
      userPinCode: map['userPinCode'],
      userLicense: map['userLicense'],
      invoiceLink: map['invoice_link'],
      invoiceSentDate: map['invoice_to_user_date'],
      // Cancellation and refund fields
      cancelledAt: map['cancelled_at'],
      cancelledBy: map['cancelled_by'],
      cancellationReason: map['cancellation_reason'],
      refundProcessed: map['refund_processed'] ?? false,
      refundEligible: map['refund_eligible'] ?? false,
      refundProcessedAt: map['refund_processed_at'],
      cancelRequest: map['cancel_request'] ?? 'Pending',
    );
  }
}