class CategoryModel {
  final int id;
  final String name;
  final String? image;

  CategoryModel({required this.id, required this.name, this.image});

  /// Full image URL by prepending the server origin to the relative path.
  String? get imageUrl {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http')) return image;
    const origin = 'https://frijo.noviindus.in';
    return '$origin$image';
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // category_list returns int id; category_dict from home returns string like "0.01"
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : (double.tryParse(rawId?.toString() ?? '') ?? 0).toInt();

    return CategoryModel(
      id: id,
      name: json['title'] ?? json['name'] ?? '',
      image: json['image'],
    );
  }
}
