class PaymentInfo {
  final int stopoverId;
  final int baseFare;
  final int finalFare;
  final bool isPaid;

  PaymentInfo({
    required this.stopoverId,
    required this.baseFare,
    required this.finalFare,
    required this.isPaid,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      stopoverId: json['stopover_id'] as int,
      baseFare: json['base_fare'] as int,
      finalFare: json['final_fare'] as int,
      isPaid: json['is_paid'] as bool,
    );
  }
}

class PaymentMemberInfo {
  final PartyMemberInfo memberInfo;
  final PaymentInfo paymentInfo;

  PaymentMemberInfo({
    required this.memberInfo,
    required this.paymentInfo,
  });

  factory PaymentMemberInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMemberInfo(
      memberInfo: PartyMemberInfo.fromJson(json['party_member_info']),
      paymentInfo: PaymentInfo.fromJson(json['payment_info']),
    );
  }
}

class PartyMemberInfo {
  final int id;
  final String name;
  final String email;
  final String gender;
  final String role;
  final String additionalRole;

  PartyMemberInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.role,
    required this.additionalRole,
  });

  factory PartyMemberInfo.fromJson(Map<String, dynamic> json) {
    return PartyMemberInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      gender: json['gender'] as String,
      role: json['role'] as String,
      additionalRole: json['additional_role'] as String,
    );
  }
} 