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

    void _doSubscribe() {
      if (!_subscribed) {
        SocketService.subscribePartyMembers(
          partyId: int.parse(widget.partyId),
          onMessage: (_) => _fetchParty(),
        );
        SocketService.subscribeJoinRequestResponse(onMessage: (msg) {
          final int partyId = msg['partyId'] as int;
          final String status = msg['status'] as String;
          if (partyId == int.parse(widget.partyId)) {
            if (status == 'ACCEPTED') {
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

    SocketService.connect(token, onConnect: () {
      _doSubscribe();
    });

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 기본 정보 ─────────────────────────────────────────────
            Text(
              '출발지',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(party!.originAddress, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),

            Text(
              '도착지',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(party!.destAddress, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),

            Text(
              '반경: ${party!.radius} km',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            Text(
              '최대 인원: ${party!.maxPerson}명',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            Text(
              '옵션: ${party!.partyOption}',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 12),

            // ─── 파티원 목록 ─────────────────────────────────────────────
            const Text(
              '파티원 목록',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // 각 멤버를 Card 안에 ListTile 형태로 감싼다.
            ...party!.members.map((m) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(
                    m.gender == 'FEMALE' ? Icons.female : Icons.male,
                    color: m.gender == 'FEMALE' ? Colors.pink : Colors.blue,
                  ),
                  title: Text(m.name),
                  subtitle: Text('${m.email} (${m.role})'),
                  // 호스트 자격이면 정산자 지정 버튼 대신 없애거나 표시하지 않음
                ),
              );
            }).toList(),

            const SizedBox(height: 24),
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