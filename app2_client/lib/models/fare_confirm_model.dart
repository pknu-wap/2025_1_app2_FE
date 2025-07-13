class FareConfirm {
  final int partyMemberId;
  final int stopoverId;

  FareConfirm({
    required this.partyMemberId,
    required this.stopoverId,
  });

  Map<String, dynamic> toJson() {
    return {
      'party_member_id': partyMemberId,
      'stopover_id': stopoverId,
    };
  }
} 