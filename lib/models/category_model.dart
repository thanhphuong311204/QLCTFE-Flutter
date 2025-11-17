class CategoryModel {
  final int categoryId;
  final String categoryName;
  final String type;
  final String? iconUrl;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.type,
    this.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      type: json['type'],
      iconUrl: json['iconUrl'],
    );
  }
}
