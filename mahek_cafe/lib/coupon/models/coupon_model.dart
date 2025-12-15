// file: lib/models/coupon_model.dart

class CouponModel {
  final String code;
  final String title;
  final String description;
  final int minOrder;
  final double discountValue;
  final bool isPurchased;

  CouponModel({
    required this.code,
    required this.title,
    required this.description,
    required this.minOrder,
    required this.discountValue,
    this.isPurchased = false,
  });

  // Example factory for creating a copy with updated purchase status
  CouponModel copyWith({bool? isPurchased}) {
    return CouponModel(
      code: code,
      title: title,
      description: description,
      minOrder: minOrder,
      discountValue: discountValue,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}