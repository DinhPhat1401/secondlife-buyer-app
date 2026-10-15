class CategoryModel {
  final String id;
  final String name;
  final String? code;
  final String? iconUrl;
  final String? description;

  const CategoryModel({
    required this.id,
    required this.name,
    this.code,
    this.iconUrl,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      iconUrl: json['iconUrl'],
      description: json['description'],
    );
  }
}

class ItemModel {
  final String id;
  final String categoryId;
  final String name;
  final String? code;
  final String? description;

  const ItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.code,
    this.description,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      description: json['description'],
    );
  }
}
