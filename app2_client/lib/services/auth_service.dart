import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<bool> authenticateWithBackend() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      // 테스트용: 토큰 출력 (백엔드 호출 없이 성공 처리)
      print('idToken: $idToken');
      print('accessToken: $accessToken');

      // 실제 백엔드 주소가 준비되면 주석 해제하여 아래 코드를 사용하세요.
      /*
      final response = await http.post(
        Uri.parse('https://your-backend.com/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'accessToken': accessToken,
        }),
      );
      return response.statusCode == 200;
      */

      // 임시로 로그인 성공 처리
      return true;
    } catch (e) {
      print('구글 로그인 실패: $e');
      return false;
    }
  }
}