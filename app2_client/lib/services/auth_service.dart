import 'dart:convert';
import 'package:app2_client/services/secure_storage_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:app2_client/models/user_model.dart';
import 'package:app2_client/constants/api_constants.dart';
import '/services/dio_client.dart';

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
  final SecureStorageService _storage = SecureStorageService();
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
    try {
      final res = await DioClient.dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'idToken': idToken,
          'accessToken': accessToken,
        },
      );
      if (res.statusCode == 200) {
        final authResp = AuthResponse.fromJson(res.data);
        _storage.saveTokens(accessToken: authResp.accessToken, refreshToken: authResp.refreshToken);
        print('✅ Server Login Success');
        print('   ▶ accessToken:  ${authResp.accessToken}');
        print('   ▶ refreshToken: ${authResp.refreshToken}');
        return authResp;
      }
      print('🔴 login failed (${res.statusCode}): ${res.data}');
      return null;
    } on DioException catch (e) {
      print('🔴 login failed (DioError): ${e.response?.statusCode} ${e.response?.data}');
      return null;
    } catch (e) {
      print('🔴 login failed: $e');
      return null;
    }
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
    try {
      final body = {
        'idToken': idToken,
        'accessToken': accessToken,
        'name': name,
        'phone': phone,
        'age': age,
        'gender': gender,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      };
      final res = await DioClient.dio.post(
        ApiConstants.signupEndpoint,
        data: body,
      );
      if (res.statusCode == 200) {
        final authResp = AuthResponse.fromJson(res.data);
        _storage.saveTokens(accessToken: authResp.accessToken, refreshToken: authResp.refreshToken);
        print('✅ Server Register Success');
        print('   ▶ accessToken:  ${authResp.accessToken}');
        print('   ▶ refreshToken: ${authResp.refreshToken}');
        return authResp;
      }
      print('🔴 register failed (${res.statusCode}): ${res.data}');
      return null;
    } on DioException catch (e) {
      print('🔴 register failed (DioError): ${e.response?.statusCode} ${e.response?.data}');
      return null;
    } catch (e) {
      print('🔴 register failed: $e');
      return null;
    }
  }
}
