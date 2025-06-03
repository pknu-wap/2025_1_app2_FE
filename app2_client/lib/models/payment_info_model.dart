class PartyMemberInfoModel {
  final int id;
  final String name;
  final String email;
  final String gender;
  final String role;
  final String additionalRole;

  PartyMemberInfoModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.role,
    required this.additionalRole,
  });

  factory PartyMemberInfoModel.fromJson(Map<String, dynamic> json) {
    return PartyMemberInfoModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      role: json['role'],
      additionalRole: json['additional_role'],
    );
  }
}

class PaymentInfoModel {
  final int stopoverId;
  final int baseFare;
  final int finalFare;
  final bool isPaid;

  PaymentInfoModel({
    required this.stopoverId,
    required this.baseFare,
    required this.finalFare,
    required this.isPaid,
  });

  factory PaymentInfoModel.fromJson(Map<String, dynamic> json) {
    return PaymentInfoModel(
      stopoverId: json['stopover_id'],
      baseFare: json['base_fare'],
      finalFare: json['final_fare'],
      isPaid: json['is_paid'],
    );
  }
}

class PartyPaymentModel {
  final PartyMemberInfoModel partyMemberInfo;
  final PaymentInfoModel paymentInfo;

  PartyPaymentModel({
    required this.partyMemberInfo,
    required this.paymentInfo,
  });

  factory PartyPaymentModel.fromJson(Map<String, dynamic> json) {
    return PartyPaymentModel(
      partyMemberInfo: PartyMemberInfoModel.fromJson(json['party_member_info']),
      paymentInfo: PaymentInfoModel.fromJson(json['payment_info']),
    );
  }
} 