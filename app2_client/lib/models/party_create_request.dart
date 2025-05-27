// lib/models/party_create_request.dart

class Location {
  final String address;
  final double lat;
  final double lng;

  Location({
    required this.address,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'lat': lat,
    'lng': lng,
  };
}

class Stopover {
  final Location location;
  final String stopoverType;

  Stopover({
    required this.location,
    required this.stopoverType,
  });

  Map<String, dynamic> toJson() => {
    'location': location.toJson(),
    'stopover_type': stopoverType,
  };
}

class PartyCreateRequest {
  final Stopover partyStart;
  final Stopover partyDestination;
  final double partyRadius;
  final int partyMaxPerson;
  final String partyOption;

  PartyCreateRequest({
    required Location partyStart,
    required Location partyDestination,
    required this.partyRadius,
    required this.partyMaxPerson,
    required this.partyOption,
  })  : partyStart = Stopover(location: partyStart, stopoverType: 'START'),
        partyDestination = Stopover(location: partyDestination, stopoverType: 'DESTINATION');

  Map<String, dynamic> toJson() => {
    'party_start': partyStart.location.toJson(),
    'party_destination': partyDestination.location.toJson(),
    'party_radius': partyRadius,
    'party_max_person': partyMaxPerson,
    'party_option': partyOption,
  };
}