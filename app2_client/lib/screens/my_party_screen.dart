import 'package:flutter/material.dart';
import '../models/party_detail_model.dart';
import '../services/socket_service.dart';

class JoinRequest {
  final int requestId;
  final String userName;
  final String userEmail;

  JoinRequest({required this.requestId, required this.userName, required this.userEmail});

  // 서버 메시지 포맷에 맞게 파싱
  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      requestId: json['request_id'],
      userName: json['name'],
      userEmail: json['email'],
    );
  }
}

class MyPartyScreen extends StatefulWidget {
  final PartyDetail party;

  const MyPartyScreen({super.key, required this.party});

  @override
  State<MyPartyScreen> createState() => _MyPartyScreenState();
}

class _MyPartyScreenState extends State<MyPartyScreen> {
  List<JoinRequest> joinRequests = [];

  @override
  void initState() {
    super.initState();

    // 실제 토큰으로 교체 필요!
    SocketService.connect('YOUR_ACCESS_TOKEN');

    // 방장용 구독: 파티ID별로 구독
    SocketService.subscribe(
      topic: "/sub/party/${widget.party.partyId}",
      onMessage: (msg) {
        print("💬 받은 메시지: $msg");
        // 예시: {"type": "JOIN_REQUEST", "request_id": 17, "name": "신청자", "email": "..."}
        if (msg['type'] == 'JOIN_REQUEST') {
          setState(() {
            joinRequests.add(JoinRequest.fromJson(msg));
          });
        }
        // TODO: 수락/거절 처리 응답 메시지 처리 (있으면)
      },
    );
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }

  Future<void> _acceptRequest(int requestId) async {
    // TODO: 실제로 서버에 수락 API 호출
    print('수락: $requestId');
    setState(() {
      joinRequests.removeWhere((r) => r.requestId == requestId);
    });
    // await PartyService.acceptRequest(...);
  }

  Future<void> _rejectRequest(int requestId) async {
    // TODO: 실제로 서버에 거절 API 호출
    print('거절: $requestId');
    setState(() {
      joinRequests.removeWhere((r) => r.requestId == requestId);
    });
    // await PartyService.rejectRequest(...);
  }

  @override
  Widget build(BuildContext context) {
    final party = widget.party;

    return Scaffold(
      appBar: AppBar(title: const Text('내 파티')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _destinationCard(party.destAddress),
            const SizedBox(height: 16),
            const Text('서면까지 갈 사람 구해요 ~! (간단한 설명)', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _tag('#${party.maxPerson}인팟'),
                _tag(party.partyOption == 'MIXED' ? '#혼성' : '#동성만'),
                _tag('#친절'),
                _tag('#시간엄수'),
              ],
            ),
            const SizedBox(height: 16),
            Text('방장 평점: 3.2', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('파티원', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('모집중 ${party.members.length} / ${party.maxPerson}명'),
              ],
            ),
            const SizedBox(height: 12),
            ...party.members.map((m) => Card(
              elevation: 1,
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.grey),
                title: Text(m.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('목적지 서면 삼정타워'),
                    Text('평점 3.5'),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),

            // 신규: 참여요청 리스트!
            if (joinRequests.isNotEmpty) ...[
              const Divider(),
              const Text('신규 참여요청', style: TextStyle(fontWeight: FontWeight.bold)),
              ...joinRequests.map((req) => Card(
                color: Colors.amber[50],
                child: ListTile(
                  title: Text(req.userName),
                  subtitle: Text(req.userEmail),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptRequest(req.requestId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectRequest(req.requestId),
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                child: const Text('파티원 채팅방 가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationCard(String address) => Container(
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('목적지', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(address),
        const SizedBox(height: 12),
        const Center(
          child: Icon(Icons.location_on, size: 48, color: Colors.amber),
        ),
      ],
    ),
  );

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}