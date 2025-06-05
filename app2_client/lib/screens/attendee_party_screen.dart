// lib/screens/attendee_party_screen.dart

import 'package:flutter/material.dart';
import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/screens/chat_room_screen.dart';

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
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _connectAndSubscribe();
    _fetchParty();
  }

  void _connectAndSubscribe() {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    // 구독 로직을 함수로 분리
    void _doSubscribe() {
      if (!_subscribed) {
        // 1) 파티 멤버 업데이트(브로드캐스트) 구독
        SocketService.subscribePartyMembers(
          partyId: int.parse(widget.partyId),
          onMessage: (_) => _fetchParty(),
        );

        // 2) 개인적인 참여 요청 응답 구독 (여기서는 이미 승인이 됐으므로 실제로는 ACCEPTED를 받을 일은 거의 없지만,
        //    혹시 나중에 “REJECTED” 메시지가 들어오면 토스트로 띄우거나 해줄 수도 있다.)
        SocketService.subscribeJoinRequestResponse(onMessage: (msg) {
          final int partyId = msg['partyId'] as int;
          final String status = msg['status'] as String;
          if (partyId == int.parse(widget.partyId)) {
            if (status == 'ACCEPTED') {
              // (이미 화면이 AttendeePartyScreen이라서 굳이 이동은 안 해도 되지만,
              //  혹시 뒤로 가 있었다면 다시 불러올 수도 있다.)
              _fetchParty();
            } else if (status == 'REJECTED') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('참여 요청이 거절되었어.')),
              );
            }
          }
        });

        _subscribed = true;
      }
    }

    // 1) STOMP 연결 시도 → 처음 연결되면 onConnect에서 _doSubscribe() 호출
    SocketService.connect(token, onConnect: () {
      _doSubscribe();
    });

    // 2) 이미 연결된 상태라면(onConnect이 안 불릴 수 있음) 바로 구독
    if (SocketService.connected) {
      _doSubscribe();
    }
  }

  Future<void> _fetchParty() async {
    setState(() => _loading = true);
    try {
      final fetched = await PartyService.fetchPartyDetailById(widget.partyId);
      if (mounted) {
        setState(() {
          party = fetched;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파티 정보를 불러올 수 없어: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    // 현재는 화면을 떠날 때 STOMP 연결을 끊도록 구현.
    // (필요하다면, 구독만 해제하는 방식으로 수정 가능)
    SocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || party == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
            const SizedBox(height: 8),
            ...party!.members.map((m) => ListTile(
              leading: Icon(
                m.gender == 'FEMALE' ? Icons.female : Icons.male,
                color: m.gender == 'FEMALE' ? Colors.pink : Colors.blue,
              ),
              title: Text(m.name),
              subtitle: Text('${m.email} (${m.role})'),
            )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomScreen(
                roomId: widget.partyId,
              ),
            ),
          );
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.chat, color: Colors.black87),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}