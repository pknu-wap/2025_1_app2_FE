// MyPartyScreen.dart 내부에 inline으로 정의된 JoinRequest
class JoinRequest {
  final int requestId;
  final String userName;
  final String userEmail;

  JoinRequest({required this.requestId, required this.userName, required this.userEmail});

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      requestId: json['request_id'],
      userName: json['name'],
      userEmail: json['email'],
    );
  }
}