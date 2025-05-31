class PartyMember {
  final int id;
  final String name;
  final String email;
  final String gender;
  final String role;
  final String additionalRole; // ✅ 추가 필드

  PartyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.role,
    required this.additionalRole, //✅ 추가
  });

  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      role: json['role'],
      additionalRole: json['additional_role'] ?? 'NONE', // ✅ 파싱 추가
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
    final originAddress =
        json['party_start']?['location']?['address'] ?? '출발지 정보 없음';
    final destAddress =
        json['party_destination']?['location']?['address'] ?? '도착지 정보 없음';

    final memberList = (json['party_members'] as List<dynamic>?)
        ?.map((m) => PartyMember.fromJson(m))
        .toList() ??
        [];

    return PartyDetail(
      partyId: json['party_id'],
      originAddress: originAddress,
      destAddress: destAddress,
      radius: (json['party_radius'] as num).toDouble(),
      maxPerson: json['party_max_people'],
      partyOption: json['party_option'],
      members: memberList,
    );
  }
}