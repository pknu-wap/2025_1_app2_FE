// MyPartyScreen.dart 내부에 inline으로 정의된 JoinRequest
class JoinRequest {
  final int requestId;
  final String requesterEmail;

  JoinRequest({required this.requestId, required this.requesterEmail});

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      requestId: json['requestId'] ?? json['request_id'],
      requesterEmail: json['requesterEmail'],
    );
  }
}