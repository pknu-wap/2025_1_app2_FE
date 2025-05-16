import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfileService {
  // .env에 정의된 BACKEND_BASE_URL 값을 읽음
  final String baseUrl = dotenv.env['BACKEND_BASE_URL']!;

  // accessToken을 이용해 프로필 정보를 요청
  Future<Map<String, dynamic>?> getProfile(String accessToken) async {
    final uri = Uri.parse('$baseUrl/api/profile');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('🔴 프로필 요청 실패: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 프로필 요청 중 예외 발생: $e');
      return null;
    }
  }
}
