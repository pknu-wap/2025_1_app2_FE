// lib/models/stopover_model.dart

import 'location_model.dart';
import 'party_member_model.dart';

/// 서버 응답 구조: { "stopover": { ... }, "partyMembers": [ ... ] }
class StopoverResponse {
  final Stopover stopover;
  final List<PartyMember> partyMembers;

  StopoverResponse({
    required this.stopover,
    required this.partyMembers,
  });

  factory StopoverResponse.fromJson(Map<String, dynamic> json) {
    final stopoverJson = json['stopover'] as Map<String, dynamic>;
    final membersJson = (json['partyMembers'] as List<dynamic>?) ?? [];

    return StopoverResponse(
      stopover: Stopover.fromJson(stopoverJson),
      partyMembers: membersJson
          .map((e) => PartyMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 경유지 정보 (id, location, stopoverType)
class Stopover {
  final int id;
  final LocationModel location;
  final String stopoverType; // "START" | "STOPOVER" | "DESTINATION"

  Stopover({
    required this.id,
    required this.location,
    required this.stopoverType,
  });

  factory Stopover.fromJson(Map<String, dynamic> json) {
    return Stopover(
      id: json['id'] as int,
      location: LocationModel.fromJson(json['location'] as Map<String, dynamic>),
      stopoverType: json['stopover_type'] as String,
    );
  }
}