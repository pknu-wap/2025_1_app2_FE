import 'package:app2_client/services/dio_client.dart';
import 'package:flutter/foundation.dart';

class ReviewService {
  /// 리뷰 안 한 멤버 목록 가져오기
  static Future<List<Map<String, dynamic>>> getUnreviewTargets() async {
    try {
      final response = await DioClient.dio.get('/api/unreview');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        debugPrint('🔴 리뷰 대상자 불러오기 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ 예외 발생: $e');
      return [];
    }
  }

  /// 리뷰 제출하기
  static Future<String?> submitReview({
    required String email,
    required int partyId,
    required double score,
    required List<String> tags,
  }) async {
    try {
      final response = await DioClient.dio.post(
        '/api/$email/review',
        data: {
          'party_id': partyId,
          'score': score,
          'tags': tags,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['message'];
      } else {
        debugPrint('🔴 리뷰 작성 실패: ${response.statusCode} ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 리뷰 작성 예외: $e');
      return null;
    }
  }
}
