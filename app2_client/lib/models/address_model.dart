// lib/models/address_model.dart
class AddressModel {
  final String addressName;
  final double lat;
  final double lng;

  AddressModel({
    required this.addressName,
    required this.lat,
    required this.lng,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final addr = json['address'] ?? json['road_address'];
    return AddressModel(
      addressName: addr['address_name'] as String,
      lat: double.parse(addr['y'] as String),
      lng: double.parse(addr['x'] as String),
    );
  }
}