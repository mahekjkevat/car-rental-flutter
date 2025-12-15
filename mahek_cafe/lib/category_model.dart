class CategoryModel {
  final String name;
  final String type;

  CategoryModel({
    required this.name,
    required this.type,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> data) {
    return CategoryModel(
      name: data['name'] ?? '',
      type: data['type'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
    };
  }
}