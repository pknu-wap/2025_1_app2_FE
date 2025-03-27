import 'package:flutter/material.dart';
import 'package:app2_client/models/user_model.dart';
import 'package:app2_client/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  final AuthService _authService = AuthService();

  UserModel? get user => _user;

  Future<bool> login() async {
    final result = await _authService.loginWithGoogle();
    if (result != null) {
      _user = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> completeSignup(Map<String, dynamic> additionalInfo) async {
    if (_user == null) return false;
    // 백엔드에 추가 정보를 전송: 토큰은 기존 _user.token 사용
    final updatedUser = await _authService.completeSignup(additionalInfo, _user!.token);
    if (updatedUser != null) {
      _user = updatedUser;
      notifyListeners();
      return true;
    }
    return false;
  }
}