// lib/models/party_detail_model.dart

import 'party_member_model.dart';
import 'stopover_model.dart';

class PartyDetail {
  final int partyId;
  final String originAddress;
  final String destAddress;
  final double radius;
  final int maxPerson;
  final String partyOption;
  final List<PartyMember> members;
  final List<StopoverResponse> stopovers; // ← 추가

  PartyDetail({
    required this.partyId,
    required this.originAddress,
    required this.destAddress,
    required this.radius,
    required this.maxPerson,
    required this.partyOption,
    required this.members,
    required this.stopovers,            // 생성자 파라미터에 포함
  });

  factory PartyDetail.fromJson(Map<String, dynamic> json) {
    final originAddress =
        json['party_start']?['location']?['address'] ?? '출발지 정보 없음';
    final destAddress =
        json['party_destination']?['location']?['address'] ?? '도착지 정보 없음';

    final memberList = (json['party_members'] as List<dynamic>?)
        ?.map((m) => PartyMember.fromJson(m as Map<String, dynamic>))
        .toList() ?? [];

    // “stopovers” 배열이 JSON에 내려온다고 가정
    final stopoverJsonList = (json['stopovers'] as List<dynamic>?) ?? [];
    final stopovers = stopoverJsonList
        .map((s) => StopoverResponse.fromJson(s as Map<String, dynamic>))
        .toList();

    return PartyDetail(
      partyId: json['party_id'] as int,
      originAddress: originAddress,
      destAddress: destAddress,
      radius: (json['party_radius'] as num).toDouble(),
      maxPerson: json['party_max_people'] as int,
      partyOption: json['party_option'] as String,
      members: memberList,
      stopovers: stopovers,
    );
  }
}