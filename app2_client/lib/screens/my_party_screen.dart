import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/party_detail_model.dart';
import '../services/socket_service.dart';
import '../services/party_service.dart';
import '../providers/auth_provider.dart';

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

class MyPartyScreen extends StatefulWidget {
  final PartyDetail party;

  const MyPartyScreen({super.key, required this.party});

  @override
  State<MyPartyScreen> createState() => _MyPartyScreenState();
}

class _MyPartyScreenState extends State<MyPartyScreen> {
  late PartyDetail party;
  List<JoinRequest> joinRequests = [];

  @override
  void initState() {
    super.initState();
    party = widget.party;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accessToken = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
      if (accessToken == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      SocketService.connect(accessToken);

      // [1] 참여요청 및 파티 멤버 갱신 브로드캐스트 모두 구독!
      SocketService.subscribe(
        topic: "/sub/party/${party.partyId}",
        onMessage: (msg) async {
          print("💬 받은 메시지: $msg");
          if (msg['type'] == 'JOIN_REQUEST') {
            setState(() {
              joinRequests.add(JoinRequest.fromJson(msg));
            });
          } else if (msg['eventType'] == 'MEMBER_JOIN' || msg['eventType'] == 'PARTY_UPDATE') {
            // 멤버 갱신 메시지 수신 시 PartyDetail을 다시 불러옴
            try {
              final detail = await PartyService.fetchPartyDetailById(party.partyId.toString());
              setState(() {
                party = detail;
              });
            } catch (e) {
              print("파티정보 갱신 실패: $e");
            }
          }
        },
      );
    });
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }

  Future<void> _acceptRequest(int requestId) async {
    final accessToken = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (accessToken == null) return;

    try {
      await PartyService.acceptJoinRequest(
        partyId: party.partyId.toString(),
        requestId: requestId,
        accessToken: accessToken,
      );
      setState(() {
        joinRequests.removeWhere((r) => r.requestId == requestId);
      });
      // 수락 후 멤버 리스트는 실시간 브로드캐스트로 자동 갱신됨!
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수락 실패: $e')));
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    final accessToken = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (accessToken == null) return;

    try {
      await PartyService.rejectJoinRequest(
        partyId: party.partyId.toString(),
        requestId: requestId,
        accessToken: accessToken,
      );
      setState(() {
        joinRequests.removeWhere((r) => r.requestId == requestId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('거절 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
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