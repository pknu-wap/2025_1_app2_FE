import 'dart:convert';
import 'package:app2_client/main.dart';
import 'package:app2_client/models/sms_session_model.dart';
import 'package:app2_client/models/sms_verify_model.dart';
import 'package:app2_client/screens/login_screen.dart';
import 'package:app2_client/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:app2_client/models/user_model.dart';
import 'package:app2_client/constants/api_constants.dart';
import '/services/dio_client.dart';

/// 백엔드가 반환해 주는 토큰 쌍
class AuthResponse {
  final int? statusCode;
  final String accessToken;
  final String refreshToken;

  AuthResponse({this.statusCode, required this.accessToken, required this.refreshToken});

  factory AuthResponse.fromJson(int? statusCode, Map<String, dynamic> json) {
    return AuthResponse(
      statusCode: statusCode,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

class AuthService {
  final SecureStorageService _storage = SecureStorageService();
  GoogleSignInAccount? _lastUser;
  GoogleSignInAccount? get lastGoogleUser => _lastUser;

  Future<void> logout() async {;
    await _storage.deleteTokens();
    GoogleSignIn().signOut();

    // 로그인 화면으로 이동
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  Future<void> saveUserInfo({
    required String userId,
    required String userName,
  }) async {
    print('📝 AuthService: 사용자 정보 저장 시작');
    print('   ▶ userId: $userId');
    print('   ▶ userName: $userName');
    
    await _storage.saveUserInfo(
      userId: userId,
      userName: userName,
    );
    
    print('✅ AuthService: 사용자 정보 저장 완료');
  }

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

      // 사용자 프로필 정보 가져오기
      final userInfo = await account.authentication;
      final gender = userInfo.idToken != null ? 
          _extractGenderFromIdToken(userInfo.idToken!) : null;

      return UserModel(
        email: account.email,
        name: account.displayName ?? '',
        idToken: idToken,
        accessToken: accessToken,
        gender: gender,
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

  // ID 토큰에서 성별 정보 추출
  String? _extractGenderFromIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(decoded);
      
      return data['gender'] as String?;
    } catch (e) {
      print('🔴 ID 토큰 파싱 실패: $e');
      return null;
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
        final authResp = AuthResponse.fromJson(res.statusCode, res.data);
        await _storage.saveTokens(accessToken: authResp.accessToken, refreshToken: authResp.refreshToken);
        print('✅ Server Login Success');
        print('   ▶ accessToken:  ${authResp.accessToken}');
        print('   ▶ refreshToken: ${authResp.refreshToken}');
        return authResp;
      }
      print('🔴 login failed (${res.statusCode}): ${res.data}');
      return null;
    } on DioException catch (e) {
      print('🔴 login failed (DioError): ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        //회원 존재 X
        return AuthResponse(
          statusCode: e.response?.statusCode,
          accessToken: "",
          refreshToken: "",
        );
      }
      return null;
    } catch (e) {
      print('🔴 login failed: $e');
      return null;
    }
  }

  /// 백엔드 회원가입 호출 (/api/oauth/register)
  Future<AuthResponse?> registerOnServer({
    required String session,
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
        'key': session,
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
        final authResp = AuthResponse.fromJson(res.statusCode, res.data);
        await _storage.saveTokens(accessToken: authResp.accessToken, refreshToken: authResp.refreshToken);
        print('✅ Server Register Success');
        print('   ▶ accessToken:  ${authResp.accessToken}');
        print('   ▶ refreshToken: ${authResp.refreshToken}');
        return authResp;
      }
      print('🔴 register failed (${res.statusCode}): ${res.data}');
      return null;
    } on DioException catch (e) {
      print('🔴 register failed (DioError): ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        //회원 존재 X
        return AuthResponse(
          statusCode: e.response?.statusCode,
          accessToken: "",
          refreshToken: "",
        );
      }
      return null;
    } catch (e) {
      print('🔴 register failed: $e');
      return null;
    }
  }

  Future<SmsSessionModel?> getSessionKey() async {
    try {
      final res = await DioClient.dio.get(
          ApiConstants.getSmsKeyEndPoint
      );
      Map<String, dynamic> json = res.data;
      return SmsSessionModel(sendTo: json["email"], key: json["key"]);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<SmsVerifyModel?> verifySms(String key) async {
    try {
      final res = await DioClient.dio.post(
        ApiConstants.verifySmsKeyEndPoint,
        data: {
          "key": key
        }
      );
      Map<String, dynamic> json = res.data;
      return SmsVerifyModel(phoneNumber: json["phoneNumber"], carrier: json["carrier"]);
    } on DioException catch (e) {
      print(e.toString());
      return null;
    } catch (e) {
      return null;
    }
  }
}
