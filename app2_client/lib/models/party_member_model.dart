// lib/models/party_member_model.dart

class PartyMember {
  final int id;
  final String email;
  final String name;
  final bool confirmed;
  final int amount;
  final String? role;  // 방장, 팀원 등
  final String? gender; // MALE 또는 FEMALE
  final String? additionalRole; // BOOKKEEPER 등

  PartyMember({
    required this.id,
    required this.email,
    required this.name,
    required this.confirmed,
    required this.amount,
    this.role,
    this.gender,
    this.additionalRole,
  });

  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      confirmed: json['confirmed'] as bool,
      amount: json['amount'] as int,
      role: json['role'] as String?,
      gender: json['gender'] as String?,
      additionalRole: json['additional_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'confirmed': confirmed,
      'amount': amount,
      if (role != null) 'role': role,
      if (gender != null) 'gender': gender,
      if (additionalRole != null) 'additional_role': additionalRole,
    };
  }
}