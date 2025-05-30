import 'package:flutter/material.dart';
import '../models/party_detail_model.dart';
import '../services/party_service.dart';
import '../services/socket_service.dart';

class AttendeePartyScreen extends StatefulWidget {
  final String partyId;
  final bool isHost;

  const AttendeePartyScreen({
    super.key,
    required this.partyId,
    this.isHost = false,
  });

  @override
  State<AttendeePartyScreen> createState() => _AttendeePartyScreenState();
}

class _AttendeePartyScreenState extends State<AttendeePartyScreen> {
  PartyDetail? party;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchParty();
    // 실시간 브로드캐스트 구독
    SocketService.subscribe(
      topic: "/topic/party/${widget.partyId}/members",
      onMessage: (_) => _fetchParty(), // 누가 들어오거나 나가면 새로고침
    );
  }

  Future<void> _fetchParty() async {
    setState(() => _loading = true);
    try {
      party = await PartyService.fetchPartyDetailById(widget.partyId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파티 정보를 불러올 수 없습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    SocketService.disconnect(); // 혹시 해당 화면 전용 소켓이라면
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || party == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHost ? '내 파티 관리' : '파티 상세정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('출발지: ${party!.originAddress}'),
            Text('도착지: ${party!.destAddress}'),
            Text('반경: ${party!.radius}km'),
            Text('최대 인원: ${party!.maxPerson}명'),
            Text('옵션: ${party!.partyOption}'),
            const SizedBox(height: 16),
            const Text('파티원 목록', style: TextStyle(fontWeight: FontWeight.bold)),
            ...party!.members.map((m) => ListTile(
              title: Text(m.name),
              subtitle: Text('${m.email} (${m.role})'),
              leading: Icon(
                m.gender == 'FEMALE' ? Icons.female : Icons.male,
                color: m.gender == 'FEMALE' ? Colors.pink : Colors.blue,
              ),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                child: const Text('파티 채팅방 가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}