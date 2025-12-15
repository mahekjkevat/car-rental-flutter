// lib/models/product_model.dart
class ProductModel {
  final String description;
  final String imgUrl;
  final String name;
  final double price;
  final String productId;
  final double rate;
  final String restaurant_id;


  ProductModel({
    required this.description,
    required this.imgUrl,
    required this.name,
    required this.price,
    required this.productId,
    required this.rate,
    required this.restaurant_id,
  });

  // Factory constructor to create a ProductModel from Firestore data
  factory ProductModel.fromFirestore(Map<String, dynamic> data) {
    return ProductModel(
      description: data['description'] ?? '',
      imgUrl: data['img_url'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      productId: data['productID'] ?? '',
      rate: (data['rate'] as num?)?.toDouble() ?? 0.0,
      restaurant_id: data['res_id'] ?? '',

    );
  }

  // Convert to Map for Firestore (if needed for writing)
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'img_url': imgUrl,
      'name': name,
      'price': price,
      'productID': productId,
      'rate': rate,
      'res_id': restaurant_id,
    };
  }
}