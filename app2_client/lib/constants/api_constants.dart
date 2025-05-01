import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl =>
      dotenv.env['BACKEND_BASE_URL'] ?? 'https://fallback-url.com';

  static final kakaoRestKey = dotenv.env['KAKAO_REST_KEY'] ?? '';
  static final kakaoJsKey = dotenv.env['KAKAO_JS_KEY'] ?? '';

  static const String kakaoSearchUrl =
      'https://dapi.kakao.com/v2/local/search/address.json';

  static const String loginEndpoint = '/api/oauth/login';
  static const String signupEndpoint = '/api/oauth/register';
  static const String partyEndpoint = '/api/party';
  static const String partySearch = '/api/party';
}
