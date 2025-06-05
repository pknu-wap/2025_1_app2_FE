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

  /// 사용자 이메일 편의 getter
  String? get email => _user?.email;

  /// 로그인 + 서버 인증
  Future<String?> login() async {
    // 1) Google 로그인 시도
    final u = await _authService.loginWithGoogle();
    if (u == null) return null;  // 사용자가 취소한 경우

    // 2) UserModel에 로그인된 사용자 정보 저장
    _user = u;

    // 3) 서버에 idToken/accessToken을 보내서 JWT 발급 요청
    final resp = await _authService.loginOnServer(
      idToken: u.idToken,
      accessToken: u.accessToken,
    );

    // 4) 서버가 성공적으로 JWT를 내려준 경우
    if (resp != null && resp.statusCode == 200) {
      _tokens = resp;

      // 사용자 정보(이메일, 이름)를 서버에 저장
      print('🔄 사용자 정보 저장 시도');
      print('   ▶ userId: ${u.email}');
      print('   ▶ userName: ${u.name}');

      await _authService.saveUserInfo(
        userId: u.email,
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

  /// 회원가입 완료 (사용자 정보를 서버에 등록)
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
    if (accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      _tokens = AuthResponse(
        statusCode: 200,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      notifyListeners();
    }
  }

  /// 로그아웃: 토큰/유저 정보 초기화 및 AuthService.logout 호출
  Future<void> logout() async {
    await _authService.logout();
    _tokens = null;
    _user = null;
    notifyListeners();
  }
}