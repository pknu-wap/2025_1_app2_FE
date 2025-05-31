// lib/services/party_service.dart

import 'package:dio/dio.dart';
import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/models/party_model.dart';
import 'package:app2_client/models/party_create_request.dart';
import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/models/stopover_model.dart';
import 'package:app2_client/models/location_model.dart';
import 'package:app2_client/services/dio_client.dart';

import '../models/party_member_model.dart';

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

    try {
      final response = await DioClient.dio.post(
        ApiConstants.partySearchEndpoint,
        data: body,
      );
      if (response.statusCode != 200) return [];
      final List<dynamic> jsonList = response.data as List<dynamic>;
      return jsonList
          .map((e) => PartyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 파티 생성
  static Future<PartyDetail> createParty({
    required PartyCreateRequest request,
  }) async {
    final body = request.toJson();
    final response = await DioClient.dio.post(
      ApiConstants.partyEndpoint,
      data: body,
    );
    if (response.statusCode != 200) {
      throw Exception('파티 생성 실패: ${response.statusCode}');
    }
    return PartyDetail.fromJson(response.data as Map<String, dynamic>);
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

  /// 파티 참여 수락
  static Future<void> acceptJoinRequest({
    required String partyId,
    required int requestId,
    required String accessToken,
  }) async {
    final url = "${ApiConstants.partyEndpoint}/$partyId/attend/accept";
    final response = await DioClient.dio.post(
      url,
      data: {'request_id': requestId},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    if (response.statusCode != 200) {
      throw Exception('참여 수락 실패: ${response.data}');
    }
  }

  /// 파티 참여 거절
  static Future<void> rejectJoinRequest({
    required String partyId,
    required int requestId,
    required String accessToken,
  }) async {
    final url = "${ApiConstants.partyEndpoint}/$partyId/attend/reject";
    final response = await DioClient.dio.post(
      url,
      data: {'request_id': requestId},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    if (response.statusCode != 200) {
      throw Exception('참여 거절 실패: ${response.data}');
    }
  }

  /// 파티 참여 요청 취소
  static Future<void> cancelJoinRequest({
    required String partyId,
    required int requestId,
    required String accessToken,
  }) async {
    final url = "${ApiConstants.partyEndpoint}/$partyId/attend/cancel";
    final response = await DioClient.dio.post(
      url,
      data: {'request_id': requestId},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    if (response.statusCode != 200) {
      throw Exception('참여 요청 취소 실패: ${response.data}');
    }
  }

  /// 내가 만든 파티 조회
  static Future<PartyDetail?> getMyParty() async {
    final response =
    await DioClient.dio.post("${ApiConstants.baseUrl}/api/party/my");
    if (response.statusCode == 200) {
      return PartyDetail.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  /// 파티 상세조회
  static Future<PartyDetail> fetchPartyDetailById(String partyId) async {
    final url = "${ApiConstants.partyEndpoint}/$partyId";
    final response = await DioClient.dio.get(url);
    if (response.statusCode != 200) {
      throw Exception('파티 상세 조회 실패: ${response.data}');
    }
    return PartyDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// 경유지 추가 (POST /api/party/{id})
  static Future<List<StopoverResponse>> addStopover({
    required String partyId,
    required String memberEmail,
    required LocationModel location,
    required String accessToken,
  }) async {
    final url = "${ApiConstants.partyEndpoint}/$partyId";
    final body = {
      "member_email": memberEmail,
      "location": location.toJson(),
    };
    final response = await DioClient.dio.post(
      url,
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    if (response.statusCode != 200) {
      throw Exception('경유지 추가 실패: ${response.statusCode}');
    }
    final List<dynamic> arr = response.data as List<dynamic>;
    return arr
        .map((e) => StopoverResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 경유지 수정 (PATCH /api/party/{id})
  static Future<List<StopoverResponse>> updateStopover({
    required String partyId,
    required int stopoverId,
    String? memberEmail,
    LocationModel? location,
    required String accessToken,
  }) async {
    final url = "${ApiConstants.partyEndpoint}/$partyId";
    final Map<String, dynamic> body = {
      "stopover_id": stopoverId,
      if (memberEmail != null) "member_email": memberEmail,
      if (location != null) "location": location.toJson(),
    };
    final response = await DioClient.dio.patch(
      url,
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    if (response.statusCode == 204) {
      return <StopoverResponse>[];
    }
    if (response.statusCode != 200) {
      throw Exception('경유지 수정 실패: ${response.statusCode}');
    }
    final List<dynamic> arr = response.data as List<dynamic>;
    return arr
        .map((e) => StopoverResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 정산자 지정 (PATCH /api/party/{partyId}/member/{partyMemberId}/bookkeeper)
  static Future<List<PartyMember>> designateBookkeeper({
    required String partyId,
    required String partyMemberId,
    required String accessToken,
  }) async {
    final url =
        "${ApiConstants.partyEndpoint}/$partyId/member/$partyMemberId/bookkeeper";
    final response = await DioClient.dio.patch(
      url,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    if (response.statusCode != 200) {
      throw Exception('정산자 지정 실패: ${response.statusCode}');
    }
    final List<dynamic> arr = response.data as List<dynamic>;
    return arr
        .map((e) => PartyMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}