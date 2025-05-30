// lib/services/auth_service.dart

import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:app2_client/models/user_model.dart';
import 'package:app2_client/constants/api_constants.dart';

/// 백엔드가 반환해 주는 토큰 쌍
class AuthResponse {
  final String accessToken;
  final String refreshToken;

  AuthResponse({required this.accessToken, required this.refreshToken});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

class AuthService {
  GoogleSignInAccount? _lastUser;
  GoogleSignInAccount? get lastGoogleUser => _lastUser;

  Future<UserModel?> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) return null;

      _lastUser = account;
      final auth = await account.authentication;
      final idToken = auth.idToken ?? '';
      final accessToken = auth.accessToken ?? '';

      _printIdTokenPayload(idToken);

      return UserModel(
        email: account.email,
        name: account.displayName ?? '',
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      print('🔴 Google 로그인 실패: $e');
      return null;
    }
  }

  void _printIdTokenPayload(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) {
        print('⚠️ Invalid ID Token format');
        return;
      }

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> jsonPayload = jsonDecode(decoded);

      print('🪪 [ID Token Payload]');
      print('📧 email: ${jsonPayload['email']}');
      print('👥 aud:   ${jsonPayload['aud']}');
      print('🌍 iss:   ${jsonPayload['iss']}');
      print('🕒 exp:   ${jsonPayload['exp']}');
    } catch (e) {
      print('❌ ID Token 디코딩 실패: $e');
    }
  }

  /// 백엔드 로그인 호출 (/api/oauth/login)
  Future<AuthResponse?> loginOnServer({
    required String idToken,
    required String accessToken,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'accessToken': accessToken,
      }),
    );
    if (resp.statusCode == 200) {
      final authResp = AuthResponse.fromJson(jsonDecode(resp.body));
      // 서버가 준 토큰을 찍어 봅니다.
      print('✅ Server Login Success');
      print('   ▶ accessToken:  ${authResp.accessToken}');
      print('   ▶ refreshToken: ${authResp.refreshToken}');
      return authResp;
    }
    print('🔴 login failed (${resp.statusCode}): ${resp.body}');
    return null;
  }

  /// 백엔드 회원가입 호출 (/api/oauth/register)
  Future<AuthResponse?> registerOnServer({
    required String idToken,
    required String accessToken,
    required String name,
    required String phone,
    required int age,
    required String gender,
    String? profileImageUrl,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.signupEndpoint}');
    final body = {
      'idToken': idToken,
      'accessToken': accessToken,
      'name': name,
      'phone': phone,
      'age': age,
      'gender': gender,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
    
    // 요청 데이터 로깅 추가
    print('📤 Register Request:');
    print(jsonEncode(body));
    
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200) {
      final authResp = AuthResponse.fromJson(jsonDecode(resp.body));
      print('✅ Server Register Success');
      print('   ▶ accessToken:  ${authResp.accessToken}');
      print('   ▶ refreshToken: ${authResp.refreshToken}');
      return authResp;
    }
    
    // 에러 응답 상세 로깅
    print('🔴 Register failed (${resp.statusCode}):');
    print('   ▶ Response body: ${resp.body}');
    print('   ▶ Request URL: $url');
    print('   ▶ Headers: ${resp.headers}');
    return null;
  }
}