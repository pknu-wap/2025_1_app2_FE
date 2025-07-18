// lib/screens/attendee_party_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  /// 현재 로그인된 사용자의 이메일을 가져옵니다.
  /// AuthProvider.user 안에 UserModel이 들어있고,
  /// UserModel.email 프로퍼티가 실제 사용자 이메일입니다.
  String? get _currentUserEmail {
    return Provider.of<AuthProvider>(context, listen: false).user?.email;
  }

  @override
  void initState() {
    super.initState();
    _connectAndSubscribe();
    _fetchParty();
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }

  /// STOMP 구독 (파티 멤버 변경, 참여 요청 응답)
  void _connectAndSubscribe() {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    void _doSubscribe() {
      if (_subscribed) return;

      // 1) 파티 멤버 업데이트 브로드캐스트 구독
      SocketService.subscribePartyMembers(
        partyId: int.parse(widget.partyId),
        onMessage: (_) => _fetchParty(),
      );

      // 2) 참여 요청 응답 구독
      SocketService.subscribeJoinRequestResponse(onMessage: (msg) {
        final incomingPartyId = msg['partyId']?.toString();
        final status = msg['status'] as String? ?? '';
        final requesterEmail = msg['requesterEmail'] as String? ?? '';

        // "내 요청"인지, "내가 보고 있는 파티"인지 확인
        if (incomingPartyId == widget.partyId &&
            requesterEmail == _currentUserEmail) {
          if (status == 'PENDING') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('참여 요청을 보냈습니다.')),
              );
            }
          } else if (status == 'ACCEPTED') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('참여 요청이 수락되었습니다!')),
              );
              _fetchParty();
            }
          } else if (status == 'REJECTED') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('참여 요청이 거절되었습니다.')),
              );
            }
          }
        }
      });

      _subscribed = true;
    }

    SocketService.connect(token, onConnect: () {
      _doSubscribe();
    });
    if (SocketService.isConnected) {
      _doSubscribe();
    }
  }

  /// PartyDetail을 서버에서 조회하고, 화면-지도 초기화
  Future<void> _fetchParty() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
      if (token == null) return;

      final fetchedParty = await PartyService.fetchPartyDetailById(widget.partyId);
      setState(() {
        party = fetchedParty;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (party == null) {
      return const Scaffold(
        body: Center(child: Text('파티 정보를 불러올 수 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('내 파티'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 최대 인원 / 팟 옵션 ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '최대 인원',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${party!.maxPerson}명',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '팟 옵션',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      party!.partyOption.label,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // ─── 파티원 목록 ───────────────────────────────────────
            const Text(
              '파티원 목록',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...party!.members.map((m) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(
                    m.gender == 'FEMALE' ? Icons.female : Icons.male,
                    color: m.gender == 'FEMALE' ? Colors.pink : Colors.blue,
                  ),
                  title: Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${m.email} (${m.role})'),
                ),
              );
            }).toList(),
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