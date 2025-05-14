// lib/services/party_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/models/party_model.dart';
import 'package:app2_client/models/party_create_request.dart';

import '../models/party_detail_model.dart';

class PartyService {
  /// 주변 팟 조회
  static Future<List<PartyModel>> fetchNearbyParties({
    required double lat,
    required double lng,
    required double radiusKm,
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.partySearchEndpoint}');

    final body = jsonEncode({
      'lat': lat,
      'lng': lng,
      'radius': radiusKm,
    });

    debugPrint('POST $uri');
    debugPrint('Request body: $body');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: body,
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: '
          '${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      if (response.statusCode != 200) {
        debugPrint('PartyService error ${response.statusCode}, body: ${response.body}');
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      if (jsonList.isEmpty) {
        debugPrint('ℹ️ 반경 내 파티가 없습니다.');
      }
      return jsonList
          .map((e) => PartyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('PartyService.fetchNearbyParties failed: $e');
      return [];
    }
  }

  /// 파티 생성
  static Future<void> createParty({
    required PartyCreateRequest request,
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.partyEndpoint}');
    final body = jsonEncode(request.toJson());

    debugPrint('POST $uri');
    debugPrint('Request body: $body');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('파티 생성 실패: ${response.statusCode}, ${response.body}');
      }

      debugPrint('✅ 파티 생성 성공: ${response.body}');
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
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.partyEndpoint}/$partyId/attend');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('파티 참여 실패: ${response.body}');
    }
  }

  static Future<PartyDetail?> getMyParty(String accessToken) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/party/my');

    try {
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return PartyDetail.fromJson(json);
      } else {
        debugPrint('❌ getMyParty 실패: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ getMyParty 예외: $e');
      return null;
    }
  }
}