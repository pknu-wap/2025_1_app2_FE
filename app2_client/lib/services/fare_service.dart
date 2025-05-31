import 'package:flutter/foundation.dart';
import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/services/dio_client.dart';

class FareService {
  /// 요금 제출
  static Future<void> submitFare(String partyId, Map<int, String?> fareInputs) async {
    final payload = fareInputs.entries
        .where((entry) => entry.value != null)
        .map((entry) => {
      'stopover_id': entry.key,
      'fare': int.parse(entry.value!)
    })
        .toList();

    try {
      final response = await DioClient.dio.post(
        '${ApiConstants.partyEndpoint}/$partyId/fare',
        data: payload,
      );

      if (response.statusCode == 200) {
        debugPrint("✅ 요금 제출 성공");
      } else {
        debugPrint("⚠️ 요금 제출 실패: ${response.statusCode}, ${response.data}");
        throw Exception('요금 제출 실패');
      }
    } catch (e) {
      debugPrint("❌ 요금 제출 중 오류: $e");
    }
  }
}
