// file: lib/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id; // Firestore document ID
  final String productID; // Custom product ID field
  final String name;
  final String description;
  final String imgUrl;
  final double price;
  final double rate;
  final String type;

  Product({
    required this.id,
    required this.productID,
    required this.name,
    required this.description,
    required this.imgUrl,
    required this.price,
    required this.rate,
    required this.type,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    T getValue<T>(String key, T defaultValue) {
      final value = data?[key];
      if (value is int && (key == 'price' || key == 'rate')) {
        return value.toDouble() as T;
      } else if (value is num && (key == 'price' || key == 'rate')) {
        return value.toDouble() as T;
      } else if (value is T) {
        return value;
      }
      return defaultValue;
    }

    return Product(
      id: doc.id, // Use Firestore document ID
      productID: getValue<String>('productID', doc.id),
      name: getValue<String>('name', 'Unknown Item'),
      description: getValue<String>('description', 'No description available.'),
      imgUrl: getValue<String>('img_url', 'https://placehold.co/600x400/cccccc/333333?text=No+Image'),
      price: getValue<double>('price', 0.0),
      rate: getValue<double>('rate', 0.0),
      type: getValue<String>('type', 'general'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productID': productID,
      'name': name,
      'description': description,
      'img_url': imgUrl,
      'price': price,
      'rate': rate,
      'type': type,
    };
  }
}