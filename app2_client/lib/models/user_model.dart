class UserModel {
  final String email;
  final String name;
  final bool isRegistered;
  final String token;
  final String phone;
  final int age;
  final String gender; // 추가: 성별

  UserModel({
    required this.email,
    required this.isRegistered,
    required this.token,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] as String,
      isRegistered: json['isRegistered'] as bool,
      token: json['token'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
    );
  }
}