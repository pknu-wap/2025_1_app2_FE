// lib/models/user_model.dart
class UserModel {
  final String email;
  final String name;
  final String idToken;
  final String accessToken;
  final String? gender;

  UserModel({
    required this.email,
    required this.name,
    required this.idToken,
    required this.accessToken,
    this.gender,
  });
}
