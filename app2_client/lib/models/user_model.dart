class UserModel {
  final String email;
  final String? name;
  final bool isRegistered;
  final String token;
  final String? phone;         // 추가: 휴대폰 번호
  final int? age;              // 추가: 나이
  final String? profileImageUrl; // 추가: 프로필 이미지 URL

  UserModel({
    required this.email,
    required this.isRegistered,
    required this.token,
    this.name,
    this.phone,
    this.age,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] as String,
      isRegistered: json['isRegistered'] as bool,
      token: json['token'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      age: json['age'] != null ? json['age'] as int : null,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}