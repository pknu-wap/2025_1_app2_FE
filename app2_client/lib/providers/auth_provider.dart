// lib/providers/auth_provider.dart
import 'package:app2_client/models/user_model.dart';
import 'package:app2_client/services/auth_service.dart';
import 'package:app2_client/services/secure_storage_service.dart';
import 'package:flutter/material.dart';

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
  /// @deprecated 예정
  Future<String> login() async {
    final u = await _authService.loginWithGoogle();
    if (u == null) return 'GOOGLE_SIGN_IN_FAILED';

    _user = u;

    final resp = await _authService.loginOnServer(
      idToken: u.idToken,
      accessToken: u.accessToken,
    );

    if (resp != null && resp.statusCode == 200) {
      _tokens = resp;
      
      // 사용자 정보 저장
      print('🔄 사용자 정보 저장 시도');
      print('   ▶ userId: ${u.email}');
      print('   ▶ userName: ${u.name}');
      
      await _authService.saveUserInfo(
        userId: u.email, // 이메일을 userId로 사용
        userName: u.name,
      );
      
      print('✅ 사용자 정보 저장 완료');
      
      notifyListeners();
      return 'SUCCESS';
    } else if (resp?.statusCode == 404) {
      return "MEMBER_NOT_FOUND";
    }

    return 'ERROR';
  }

  /// 회원가입 완료
  /// @deprecated 예정
  Future<bool> completeSignup({
    required String name,
    required String phone,
    required int age,
    required String gender,
    String? profileImageUrl,
  }) async {
    if (_user == null) return false;

    final resp = await _authService.registerOnServer(
      session: '',
      idToken: _user!.idToken,
      accessToken: _user!.accessToken,
      name: name,
      phone: phone,
      age: age,
      gender: gender,
      profileImageUrl: profileImageUrl,
    );

    if (resp != null && resp.statusCode == 200) {
      _tokens = resp;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// 앱 시작 시 secure storage에서 토큰을 불러와 Provider에 세팅
  Future<void> initTokens() async {
    final storage = SecureStorageService();
    final accessToken = await storage.getAccessToken();
    final refreshToken = await storage.getRefreshToken();
    if (accessToken != null && accessToken.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty) {
      _tokens = AuthResponse(statusCode: 200, accessToken: accessToken, refreshToken: refreshToken);
      notifyListeners();
    }
  }

  /// 로그아웃: 토큰/유저 상태 초기화 및 AuthService.logout 호출
  Future<void> logout() async {
    await _authService.logout();
    _tokens = null;
    _user = null;
    notifyListeners();
  }
}
