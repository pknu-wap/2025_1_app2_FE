class FareEntry {
  final String name;
  final int stopoverId;

  FareEntry({required this.name, required this.stopoverId});

  factory FareEntry.fromJson(Map<String, dynamic> json) {
    return FareEntry(
      name: json['party_member_info']['name'],
      stopoverId: json['payment_info']['stopover_id'],
    );
  }
}
