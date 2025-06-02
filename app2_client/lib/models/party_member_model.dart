// lib/models/party_member_model.dart

class PartyMember {
  final String email;
  final String name;
  final bool confirmed;
  final int amount;
  final String? role;  // 방장, 팀원 등

  PartyMember({
    required this.email,
    required this.name,
    required this.confirmed,
    required this.amount,
    this.role,
  });

  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      email: json['email'] as String,
      name: json['name'] as String,
      confirmed: json['confirmed'] as bool,
      amount: json['amount'] as int,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'confirmed': confirmed,
      'amount': amount,
      if (role != null) 'role': role,
    };
  }
}