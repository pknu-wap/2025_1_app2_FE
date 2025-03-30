import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/models/party_model.dart';

class PartyService {
  /// 파티 생성
  ///
  /// [partyData]에는 아래와 같은 JSON 형식의 데이터가 포함됩니다:
  /// {
  ///   "party_start": {"location": {"name": "xxx", "lat": 11.1111, "lng": 22.2222}, "stopover_type": "START"},
  ///   "party_destination": {"location": {"name": "xxx", "lat": 33.3333, "lng": 44.4444}, "stopover_type": "DESTINATION"},
  ///   "party_radius": 5.0,
  ///   "party_max_person": 3,
  ///   "party_option": "MIXED"
  /// }
  ///
  /// [token]은 인증 토큰입니다.
  Future<PartyModel?> createParty(Map<String, dynamic> partyData, String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.partyEndpoint}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(partyData),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PartyModel.fromJson(data);
      } else {
        print('파티 생성 실패: ${response.body}');
        return null;
      }
    } catch (e) {
      print('파티 생성 예외: $e');
      return null;
    }
  }

  /// 파티 조회
  ///
  /// [partyId]는 조회할 파티의 ID입니다.
  /// [token]은 인증 토큰입니다.
  Future<PartyModel?> getParty(int partyId, String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.partyEndpoint}/$partyId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PartyModel.fromJson(data);
      } else {
        print('파티 조회 실패: ${response.body}');
        return null;
      }
    } catch (e) {
      print('파티 조회 예외: $e');
      return null;
    }
  }

  /// 파티에 경유지 추가
  ///
  /// [partyId]는 수정할 파티의 ID입니다.
  /// [stopoverData]에는 아래와 같은 JSON 형식의 데이터가 포함됩니다:
  /// {
  ///   "location": {"name": "xxx", "lat": 55.5555, "lng": 66.6666},
  ///   "stopover_type": "STOPOVER"
  /// }
  /// [token]은 인증 토큰입니다.
  Future<bool> addStopover(int partyId, Map<String, dynamic> stopoverData, String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.partyEndpoint}/$partyId');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(stopoverData),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('경유지 추가 실패: ${response.body}');
        return false;
      }
    } catch (e) {
      print('경유지 추가 예외: $e');
      return false;
    }
  }
}