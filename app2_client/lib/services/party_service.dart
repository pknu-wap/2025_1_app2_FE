import 'dart:convert';
import 'package:app2_client/services/dio_client.dart';
import 'package:flutter/foundation.dart';

import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/models/party_model.dart';
import 'package:app2_client/models/party_create_request.dart';
import 'package:app2_client/models/party_detail_model.dart';

class PartyService {
  /// 주변 팟 조회
  static Future<List<PartyModel>> fetchNearbyParties({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final body = {
      'lat': lat,
      'lng': lng,
      'radius': radiusKm,
    };

    debugPrint('Request body: $body');

    try {
      final response = await DioClient.dio.post(
        ApiConstants.partySearchEndpoint,
        data: body,
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.data}');

      if (response.statusCode != 200) {
        debugPrint('PartyService error ${response.statusCode}, body: ${response.data}');
        return [];
      }

      final List<dynamic> jsonList = response.data as List<dynamic>;
      if (jsonList.isEmpty) {
        debugPrint('ℹ️ 반경 내 파티가 없습니다.');
      }
      return jsonList.map((e) => PartyModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('PartyService.fetchNearbyParties failed: $e');
      return [];
    }
  }

  /// 파티 생성 (응답을 PartyDetail로 반환)
  static Future<PartyDetail> createParty({
    required PartyCreateRequest request,
  }) async {
    final body = request.toJson();

    debugPrint('Request body: $body');

    try {
      final response = await DioClient.dio.post(
        ApiConstants.partyEndpoint,
        data: body,
      );

      if (response.statusCode != 200) {
        throw Exception('파티 생성 실패: ${response.statusCode}, ${response.data}');
      }

      debugPrint('✅ 파티 생성 성공: ${response.data}');
      return PartyDetail.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ 파티 생성 중 에러: $e');
      rethrow;
    }
  }

  /// 파티 참여
  static Future<void> attendParty({
    required String partyId,
    required String accessToken,
  }) async {
    final url = "${ApiConstants.partyEndpoint}/$partyId/attend";
    final response = await DioClient.dio.post(url);

    if (response.statusCode != 200) {
      throw Exception('파티 참여 실패: ${response.data}');
    }
  }

  /// 내가 만든 파티 조회 (POST 방식, 실제 서버 명세에 따라 GET/POST 확인 필요)
  static Future<PartyDetail?> getMyParty() async {
    try {
      final response = await DioClient.dio.post(
        '${ApiConstants.baseUrl}/api/party/my',
      );

      if (response.statusCode == 200) {
        return PartyDetail.fromJson(response.data);
      } else {
        debugPrint('❌ getMyParty 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ getMyParty 예외: $e');
      return null;
    }
  }
}