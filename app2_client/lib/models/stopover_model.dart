// lib/models/stopover_model.dart

import 'location_model.dart'; // location_model.dart 에 LocationModel 정의를 가정

class StopoverModel {
  final LocationModel location;
  final String       stopoverType;

  StopoverModel({
    required this.location,
    required this.stopoverType,
  });

  factory StopoverModel.fromJson(Map<String, dynamic> json) {
    return StopoverModel(
      location:     LocationModel.fromJson(json['location'] as Map<String, dynamic>),
      stopoverType: json['stopover_type'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'location'      : location.toJson(),
    'stopover_type' : stopoverType,
  };
}