class FeedUser {
  final int id;
  final String name;
  final String? profileImage;

  FeedUser({required this.id, required this.name, this.profileImage});

  factory FeedUser.fromJson(Map<String, dynamic> json) {
    return FeedUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      profileImage: json['image'] ?? json['profile_image'],
    );
  }
}

class FeedModel {
  final int id;
  final String? description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final FeedUser? user;
  final String? createdAt;
  final List<dynamic> likes;
  final List<dynamic> dislikes;
  final bool follow;

  FeedModel({
    required this.id,
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.user,
    this.createdAt,
    this.likes = const [],
    this.dislikes = const [],
    this.follow = false,
  });

  factory FeedModel.fromJson(Map<String, dynamic> json) {
    return FeedModel(
      id: json['id'] ?? 0,
      description: json['description'] ?? json['desc'],
      videoUrl: json['video'],
      thumbnailUrl: json['image'] ?? json['thumbnail'],
      user: json['user'] != null
          ? FeedUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'],
      likes: json['likes'] as List? ?? [],
      dislikes: json['dislikes'] as List? ?? [],
      follow: json['follow'] ?? false,
    );
  }
}
