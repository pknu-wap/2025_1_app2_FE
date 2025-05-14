class PartyMember {
  final int id;
  final String name;
  final String email;
  final String gender;
  final String role;

  PartyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.role,
  });

  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      role: json['role'],
    );
  }
}

class PartyDetail {
  final int partyId;
  final String originAddress;
  final String destAddress;
  final double radius;
  final int maxPerson;
  final String partyOption;
  final List<PartyMember> members;

  PartyDetail({
    required this.partyId,
    required this.originAddress,
    required this.destAddress,
    required this.radius,
    required this.maxPerson,
    required this.partyOption,
    required this.members,
  });

  factory PartyDetail.fromJson(Map<String, dynamic> json) {
    final memberList = (json['party_members'] as List)
        .map((m) => PartyMember.fromJson(m))
        .toList();

    return PartyDetail(
      partyId: json['party_id'],
      originAddress: json['origin'] ?? '출발지 정보 없음',
      destAddress: json['destination'] ?? '도착지 정보 없음',
      radius: (json['party_radius'] as num).toDouble(),
      maxPerson: json['party_max_person'],
      partyOption: json['party_option'],
      members: memberList,
    );
  }
}