import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:app2_client/models/user_model.dart';
import 'package:app2_client/constants/api_constants.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Google 로그인 진행 및 UserModel 반환 (임시 구현)
  Future<UserModel?> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      print('idToken: ${googleAuth.idToken}');
      print('accessToken: ${googleAuth.accessToken}');
      // 임시로, 미가입 상태의 UserModel 생성
      return UserModel(
        email: googleUser.email,
        name: googleUser.displayName ?? '',
        isRegistered: false,
        token: googleAuth.idToken ?? '',
      );
    } catch (e) {
      print('구글 로그인 실패: $e');
      return null;
    }
  }

  /// 추가 정보(회원가입) 전송 - 백엔드에 POST 요청
  Future<UserModel?> completeSignup(Map<String, dynamic> additionalInfo, String token) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.signupEndpoint}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(additionalInfo),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        print('회원가입 실패: ${response.body}');
        return null;
      }
    } catch (e) {
      print('회원가입 예외: $e');
      return null;
    }
  }
}