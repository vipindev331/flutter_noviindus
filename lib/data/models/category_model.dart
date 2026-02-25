class CategoryModel {
  final String id;
  final String name;
  final String? image;

  CategoryModel({required this.id, required this.name, this.image});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      // home API uses 'title', category_list API may use 'name'
      name: json['title'] ?? json['name'] ?? '',
      image: json['image'],
    );
  }
}
