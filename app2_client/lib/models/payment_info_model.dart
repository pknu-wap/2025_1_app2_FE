import 'package:app2_client/models/party_member_model.dart';

class PaymentInfo {
  final PartyMember partyMemberInfo;
  final PaymentDetail paymentInfo;

  PaymentInfo({
    required this.partyMemberInfo,
    required this.paymentInfo,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      partyMemberInfo: PartyMember.fromJson(json['party_member_info']),
      paymentInfo: PaymentDetail.fromJson(json['payment_info']),
    );
  }
}

class PaymentDetail {
  final int stopoverId;
  final int baseFare;
  final int finalFare;
  final bool isPaid;

  PaymentDetail({
    required this.stopoverId,
    required this.baseFare,
    required this.finalFare,
    required this.isPaid,
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      stopoverId: json['stopover_id'] as int,
      baseFare: json['base_fare'] as int,
      finalFare: json['final_fare'] as int,
      isPaid: json['is_paid'] as bool,
    );
  }
} 