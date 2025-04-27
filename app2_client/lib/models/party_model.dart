// lib/models/party_model.dart

import 'location_model.dart';
import 'stopover_model.dart';

class PartyModel {
  final int               partyId;
  final StopoverModel     partyStart;
  final StopoverModel     partyDestination;
  final double            partyRadius;
  final int               partyMaxPerson;
  final String            partyOption;
  final List<StopoverModel> partyStopovers;

  // 추가 필드
  final double            startLat;
  final double            startLng;
  final double?           distance;   // 선택 필드라면 nullable

  PartyModel({
    required this.partyId,
    required this.partyStart,
    required this.partyDestination,
    required this.partyRadius,
    required this.partyMaxPerson,
    required this.partyOption,
    required this.partyStopovers,
    required this.startLat,
    required this.startLng,
    this.distance,
  });

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    return PartyModel(
      partyId:          json['party_id']          as int,
      partyStart:       StopoverModel.fromJson(json['party_start']       as Map<String,dynamic>),
      partyDestination: StopoverModel.fromJson(json['party_destination'] as Map<String,dynamic>),
      partyRadius:      (json['party_radius']      as num).toDouble(),
      partyMaxPerson:   json['party_max_person']  as int,
      partyOption:      json['party_option']      as String,
      partyStopovers:   (json['party_stopovers'] as List<dynamic>?)
          ?.map((e) => StopoverModel.fromJson((e as Map<String,dynamic>)['stopover'] as Map<String,dynamic>))
          .toList() ?? <StopoverModel>[],
      startLat:         (json['start_lat']         as num).toDouble(),
      startLng:         (json['start_lng']         as num).toDouble(),
      distance:         json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
    );
  }
}