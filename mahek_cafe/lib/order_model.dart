import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String orderId; // Document ID
  final String name;
  final double totalPrice;
  final int quantity;
  final String status;
  final DateTime timestamp;

  // Delivery & User Details
  final String cityPinCode;
  final String deliveryAddress;
  final String deliveryOption;
  final double latitude;
  final double longitude;
  final String userCity;
  final String userName;
  final String userEmail;
  final String userMobile;

  // Payment Details
  final String paymentId;
  final String paymentMethod;
  final String paymentStatus;
  final double price; // Individual item price (before total calculation)

  // Product Details
  final String? imgUrl;
  final bool isIce;

  final List<Map<String, dynamic>> timeline;

  final double deliveryScooterLatitude;
  final double deliveryScooterLongitude;
  final String deliveryBoyLiveAddress;


  Order({
    required this.orderId,
    required this.name,
    required this.totalPrice,
    required this.quantity,
    required this.status,
    required this.timestamp,
    required this.cityPinCode,
    required this.deliveryAddress,
    required this.deliveryOption,
    required this.latitude,
    required this.longitude,
    required this.userCity,
    required this.userName,
    required this.userEmail,
    required this.userMobile,
    required this.paymentId,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.price,
    this.imgUrl,
    required this.isIce,
    required this.timeline,
    required this.deliveryScooterLatitude,
    required this.deliveryScooterLongitude,
    required this.deliveryBoyLiveAddress,
  });

  // Factory constructor to create an Order instance from a Firestore document snapshot.
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Timestamp timestamp = data['timestamp'] as Timestamp? ?? Timestamp.now();

    // Safely extract timeline data as a list of maps
    final List<Map<String, dynamic>> timeline = (data['timeline'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Order(
      orderId: doc.id,
      name: data['name'] as String? ?? 'Unknown Product',
      totalPrice: (data['totalPrice'] as num? ?? 0.0).toDouble(),
      quantity: data['quantity'] as int? ?? 1,
      status: data['status'] as String? ?? 'Processing',
      timestamp: timestamp.toDate(),

      cityPinCode: data['cityPinCode'] as String? ?? 'N/A',
      deliveryAddress: data['deliveryAddress'] as String? ?? 'N/A',
      deliveryOption: data['deliveryOption'] as String? ?? 'N/A',
      latitude: (data['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (data['longitude'] as num? ?? 0.0).toDouble(),
      userCity: data['userCity'] as String? ?? 'N/A',
      userName: data['userName'] as String? ?? 'Customer',
      userEmail: data['userEmail'] as String? ?? 'N/A',
      userMobile: data['userMobile'] as String? ?? 'N/A',

      paymentId: data['paymentId'] as String? ?? 'N/A',
      paymentMethod: data['paymentMethod'] as String? ?? 'N/A',
      paymentStatus: data['paymentStatus'] as String? ?? 'N/A',
      price: (data['price'] as num? ?? 0.0).toDouble(),

      imgUrl: data['imgUrl'] as String?,
      isIce: data['isIce'] as bool? ?? false,

      timeline: timeline,
      deliveryScooterLatitude: (data['deliveryScooterLatitude'] as num? ?? 0.0).toDouble(),
      deliveryScooterLongitude: (data['deliveryScooterLongitude'] as num? ?? 0.0).toDouble(),
      deliveryBoyLiveAddress: data['d_boy_location'] as String? ?? 'N/A',
    );
  }
}