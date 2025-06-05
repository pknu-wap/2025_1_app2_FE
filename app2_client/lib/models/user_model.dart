// lib/models/user_model.dart
class UserModel {
  final String email;
  final String name;
  final String idToken;
  final String accessToken;

  UserModel({
    required this.email,
    required this.name,
    required this.idToken,
    required this.accessToken,
  });
}
