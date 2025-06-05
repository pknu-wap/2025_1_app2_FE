// lib/models/party_detail_model.dart

import 'package:app2_client/models/party_member_model.dart';
import 'package:app2_client/models/stopover_model.dart';

class PartyDetail {
  final int partyId;
  final String originAddress;
  final double originLat;     // 출발지 위도
  final double originLng;     // 출발지 경도
  final String destAddress;
  final double destLat;       // 도착지 위도  ← 새로 추가
  final double destLng;       // 도착지 경도  ← 새로 추가
  final double radius;
  final int maxPerson;
  final String partyOption;
  final List<PartyMember> members;
  final List<StopoverResponse> stopovers;

  PartyDetail({
    required this.partyId,
    required this.originAddress,
    required this.originLat,
    required this.originLng,
    required this.destAddress,
    required this.destLat,
    required this.destLng,
    required this.radius,
    required this.maxPerson,
    required this.partyOption,
    required this.members,
    required this.stopovers,
  });

  factory PartyDetail.fromJson(Map<String, dynamic> json) {
    // JSON 구조에 따라 "party_start"와 "party_destination" 에서 address/lat/lng 를 꺼냅니다.
    final startLocation = json['party_start']?['location'] as Map<String, dynamic>? ?? {};
    final destLocation  = json['party_destination']?['location'] as Map<String, dynamic>? ?? {};

    final originAddress = startLocation['address'] as String? ?? '출발지 정보 없음';
    final originLat     = (startLocation['lat']    as num?)?.toDouble() ?? 0.0;
    final originLng     = (startLocation['lng']    as num?)?.toDouble() ?? 0.0;

    final destAddress = destLocation['address'] as String? ?? '도착지 정보 없음';
    final destLat     = (destLocation['lat']    as num?)?.toDouble() ?? 0.0;
    final destLng     = (destLocation['lng']    as num?)?.toDouble() ?? 0.0;

    final memberList = (json['party_members'] as List<dynamic>?)
        ?.map((m) => PartyMember.fromJson(m as Map<String, dynamic>))
        .toList() ??
        [];

    final stopoverList = (json['party_stopovers'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map((e) => StopoverResponse.fromJson(e))
        .toList() ?? [];

    return PartyDetail(
      partyId: json['party_id'] as int,
      originAddress: originAddress,
      originLat: originLat,
      originLng: originLng,
      destAddress: destAddress,
      destLat: destLat,       // 추가된 필드
      destLng: destLng,       // 추가된 필드
      radius: (json['party_radius'] as num).toDouble(),
      maxPerson: json['party_max_people'] as int,
      partyOption: json['party_option'] as String,
      members: memberList,
      stopovers: stopoverList,
    );
  }
}