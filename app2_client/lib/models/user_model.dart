// lib/models/user_model.dart
class UserModel {
  final int? id;
  final String email;
  final String name;
  final String idToken;
  final String accessToken;

  UserModel({
    this.id,
    required this.email,
    required this.name,
    required this.idToken,
    required this.accessToken,
  });
}
