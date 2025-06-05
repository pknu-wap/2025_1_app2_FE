class FareRequest {
  final int stopoverId;
  final int fare;

  FareRequest({
    required this.stopoverId,
    required this.fare,
  });

  Map<String, dynamic> toJson() {
    return {
      'stopover_id': stopoverId,
      'fare': fare,
    };
  }
} 