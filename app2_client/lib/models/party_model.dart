// lib/models/party_model.dart

class PartyModel {
  final String id;
  final String creatorName;
  final DateTime createdAt;
  final int remainingSeats;
  final String originAddress;
  final String destAddress;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  PartyModel({
    required this.id,
    required this.creatorName,
    required this.createdAt,
    required this.remainingSeats,
    required this.originAddress,
    required this.destAddress,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
  });

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    // party_members에서 첫 번째 멤버의 이름을 creatorName으로 사용
    final members = json['party_members'] as List?;
    final creatorName = (members != null && members.isNotEmpty)
        ? (members[0]['name'] as String? ?? '')
        : '';
    // 출발지/도착지 정보 추출
    final stopovers = json['party_stopovers'] as List? ?? [];
    final start = stopovers.firstWhere((e) => e['stopover_type'] == 'START', orElse: () => null);
    final dest = stopovers.firstWhere((e) => e['stopover_type'] == 'DESTINATION', orElse: () => null);
    return PartyModel(
      id: json['party_id'].toString(),
      creatorName: creatorName,
      createdAt: DateTime.now(), // 서버에서 createdAt이 없으므로 임시로 현재 시간
      remainingSeats: (json['party_max_people'] as int) - (json['party_current_people'] as int),
      originAddress: start != null ? start['location']['address'] as String : '',
      destAddress: dest != null ? dest['location']['address'] as String : '',
      originLat: start != null ? (start['location']['lat'] as num).toDouble() : 0.0,
      originLng: start != null ? (start['location']['lng'] as num).toDouble() : 0.0,
      destLat: dest != null ? (dest['location']['lat'] as num).toDouble() : 0.0,
      destLng: dest != null ? (dest['location']['lng'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'creatorName': creatorName,
    'createdAt': createdAt.toIso8601String(),
    'remainingSeats': remainingSeats,
    'originAddress': originAddress,
    'destAddress': destAddress,
    'originLat': originLat,
    'originLng': originLng,
    'destLat': destLat,
    'destLng': destLng,
  };
}