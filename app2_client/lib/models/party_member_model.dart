// lib/models/party_member_model.dart

class PartyMember {
  final int id;
  final String name;
  final String email;
  final String gender;          // e.g. "MALE" or "FEMALE"
  final String role;            // e.g. "HOST", "MEMBER", "BOOKKEEPER"
  final String additionalRole;  // 예: HOST 가 BOOKKEEPER 겸하면 "BOOKKEEPER", 아니면 "NONE"

  PartyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.role,
    required this.additionalRole,
  });

  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      gender: json['gender'] as String,
      role: json['role'] as String,
      additionalRole: json['additional_role'] as String? ?? 'NONE',
    );
  }
}