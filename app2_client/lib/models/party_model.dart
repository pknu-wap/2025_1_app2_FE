class PartyModel {
  final int partyId;
  final Map<String, dynamic>? partyStart;         // 예: {"location": {"name": "xxx", "lat": 11.1111, "lng": 22.2222}, "stopover_type": "START"}
  final Map<String, dynamic>? partyDestination;     // 예: {"location": {"name": "xxx", "lat": 33.3333, "lng": 44.4444}, "stopover_type": "DESTINATION"}
  final double? partyRadius;                        // 예: 5.0
  final int partyMaxPerson;                         // 예: 3
  final String partyOption;                         // 예: "MIXED"
  final List<dynamic>? partyStopovers;              // 파티 조회 시, 경유지 목록 등

  PartyModel({
    required this.partyId,
    this.partyStart,
    this.partyDestination,
    this.partyRadius,
    required this.partyMaxPerson,
    required this.partyOption,
    this.partyStopovers,
  });

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    return PartyModel(
      partyId: json['party_id'] as int,
      partyStart: json['party_start'] as Map<String, dynamic>?,
      partyDestination: json['party_destination'] as Map<String, dynamic>?,
      partyRadius: (json['party_radius'] is num) ? (json['party_radius'] as num).toDouble() : null,
      partyMaxPerson: json['party_max_person'] as int,
      partyOption: json['party_option'] as String,
      partyStopovers: json['party_stopovers'] as List<dynamic>?,
    );
  }
}