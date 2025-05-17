// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:app2_client/services/auth_service.dart';
import 'package:app2_client/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthResponse? _tokens;
  UserModel? _user;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  UserModel? get user => _user;
  AuthResponse? get tokens => _tokens;

  int get userId {
    if (_user == null) throw Exception('User not logged in');
    return _user!.id!;
  }

  String get jwtToken {
    if (_tokens == null) throw Exception('Token not available');
    return _tokens!.jwt;
  }

  /// 로그인 + 서버 인증
  Future<String> login() async {
    final u = await _authService.loginWithGoogle();
    if (u == null) return 'GOOGLE_SIGN_IN_FAILED';

    _user = u;

    final resp = await _authService.loginOnServer(
      idToken: u.idToken,
      accessToken: u.accessToken,
    );

    if (resp != null) {
      _tokens = resp;
      notifyListeners();
      return 'SUCCESS';
    }

    return 'MEMBER_NOT_FOUND';
  }

  /// 회원가입 완료
  Future<bool> completeSignup({
    required String name,
    required String phone,
    required int age,
    required String gender,
    String? profileImageUrl,
  }) async {
    if (_user == null) return false;

    final resp = await _authService.registerOnServer(
      idToken: _user!.idToken,
      accessToken: _user!.accessToken,
      name: name,
      phone: phone,
      age: age,
      gender: gender,
      profileImageUrl: profileImageUrl,
    );

    if (resp != null) {
      _tokens = resp;
      notifyListeners();
      return true;
    }

    return false;
  }
}
