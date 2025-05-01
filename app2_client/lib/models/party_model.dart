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
    return PartyModel(
      id: json['id'] as String,
      creatorName: json['creatorName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      remainingSeats: json['remainingSeats'] as int,
      originAddress: json['originAddress'] as String,
      destAddress: json['destAddress'] as String,
      originLat: (json['originLat'] as num).toDouble(),
      originLng: (json['originLng'] as num).toDouble(),
      destLat: (json['destLat'] as num).toDouble(),
      destLng: (json['destLng'] as num).toDouble(),
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