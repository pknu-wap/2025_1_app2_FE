// lib/services/party_service.dart

import 'package:dio/dio.dart';
import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/models/party_model.dart';
import 'package:app2_client/models/party_create_request.dart';
import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/models/stopover_model.dart';
import 'package:app2_client/models/location_model.dart';
import 'package:app2_client/services/dio_client.dart';
import 'package:flutter/foundation.dart';

import '../models/party_member_model.dart';

class PartyService {
  /// 주변 팟 조회 (Authorization 헤더 추가)
  static Future<List<PartyModel>> fetchNearbyParties({
    required double lat,
    required double lng,
    required double radiusKm,
    required String accessToken,
  }) async {
    final body = {
      'lat': lat,
      'lng': lng,
      'radius': radiusKm,
    };

    try {
      debugPrint('📤 주변 파티 검색 요청 - body: $body');
      
      final response = await DioClient.dio.post(
        ApiConstants.partySearchEndpoint,
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      
      debugPrint('📥 서버 응답 - statusCode: ${response.statusCode}, data: ${response.data}');
      
      if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      }
      
      if (response.statusCode == 404) {
        throw Exception('주변에 파티가 없습니다.');
      }
      
      if (response.statusCode != 200) {
        throw Exception('서버 오류가 발생했습니다. (상태 코드: ${response.statusCode})');
      }

      final List<dynamic> jsonList = response.data as List<dynamic>;
      final parties = jsonList
          .map((e) => PartyModel.fromJson(e as Map<String, dynamic>))
          .toList();
          
      debugPrint('✅ 파싱 완료 - 파티 ${parties.length}개 발견');
      return parties;
      
    } on DioException catch (e) {
      debugPrint('❌ Dio 예외 발생 - type: ${e.type}, message: ${e.message}');
      debugPrint('❌ 응답 데이터: ${e.response?.data}');
      
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('서버 연결 시간이 초과되었습니다.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('인터넷 연결을 확인해주세요.');
      } else {
        throw Exception('파티 검색 중 오류가 발생했습니다: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ 예외 발생: $e');
      throw Exception('알 수 없는 오류가 발생했습니다: $e');
    }
  }

  /// 파티 생성
  static Future<PartyDetail> createParty({
    required PartyCreateRequest request,
    required String accessToken,
  }) async {
    final body = request.toJson();
    final response = await DioClient.dio.post(
      ApiConstants.partyEndpoint,
      data: body,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
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
    final response = await DioClient.dio.post(
      url,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
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