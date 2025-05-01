import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:app2_client/models/user_model.dart';
import 'package:app2_client/constants/api_constants.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  AuthResponse({required this.accessToken, required this.refreshToken});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}

class AuthService {
  GoogleSignInAccount? _lastUser;
  GoogleSignInAccount? get lastGoogleUser => _lastUser;

  Future<UserModel?> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      final account = await googleSignIn.signIn();
      if (account == null) return null;

      _lastUser = account;
      final auth = await account.authentication;
      final idToken = auth.idToken ?? '';
      final accessToken = auth.accessToken ?? '';

      _printIdTokenPayload(idToken); // ✅ 토큰 디코드 출력 추가

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
      final json = jsonDecode(decoded);
      print('🪪 [ID Token Payload]');
      print('📧 email: ${json['email']}');
      print('👥 aud: ${json['aud']}');
      print('🌍 iss: ${json['iss']}');
      print('🕒 exp: ${json['exp']}');
    } catch (e) {
      print('❌ ID Token 디코딩 실패: $e');
    }
  }

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
      return AuthResponse.fromJson(jsonDecode(resp.body));
    }
    print('🔴 login failed (${resp.statusCode}): ${resp.body}');
    return null;
  }

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
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(resp.body));
    }
    print('🔴 register failed (${resp.statusCode}): ${resp.body}');
    return null;
  }
}