import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/services/dio_client.dart';

class ProfileService {
  /// 내 프로필 정보를 요청
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await DioClient.dio.get(ApiConstants.getProfileEndpoint);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('🔴 프로필 요청 실패: ${response.statusCode} ${response.data}');
        return null;
      }
    } catch (e) {
      print('❌ 프로필 요청 중 예외 발생: $e');
      return null;
    }
  }
}
