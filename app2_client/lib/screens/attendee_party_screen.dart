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

    SocketService.connect(token, onConnect: () {
      if (!_subscribed) {
        SocketService.subscribePartyMembers(
          partyId: int.parse(widget.partyId),
          onMessage: (_) => _fetchParty(),
        );
        _subscribed = true;
      }
    });
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
          SnackBar(content: Text('파티 정보를 불러올 수 없습니다: $e')),
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