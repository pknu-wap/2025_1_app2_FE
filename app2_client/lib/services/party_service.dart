import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/models/party_model.dart';

class PartyService {
  /// 기존 createParty(), getParty(), addStopover() 생략…

  /// 주변 팟 조회
  /// 경로: GET /api/party?lat={lat}&lng={lng}&radius={radiusKm}
  Future<List<PartyModel>> fetchNearbyParties({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.partySearch)
        .replace(queryParameters: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius': radiusKm.toString(),
    });

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // 인증 필요하다면 토큰도 넣으세요:
        // 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // 서버에서 [{…}, {…}, …] 형태의 JSON 배열을 내려준다고 가정
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => PartyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('주변 팟 조회 실패: ${response.statusCode} ${response.body}');
    }
  }
}