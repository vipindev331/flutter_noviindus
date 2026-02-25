class AuthModel {
  final String accessToken;
  final String? name;
  final String? phone;
  final String? profileImage;

  AuthModel({
    required this.accessToken,
    this.name,
    this.phone,
    this.profileImage,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final tokenMap = json['token'] as Map<String, dynamic>? ?? {};
    return AuthModel(
      accessToken: tokenMap['access'] ?? '',
      name: json['name'],
      phone: json['phone'],
      profileImage: json['profile_image'],
    );
  }
}
