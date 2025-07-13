// lib/screens/my_party_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/models/party_member_model.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/services/socket_service.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/models/join_request_model.dart';
import 'package:app2_client/screens/stopover_setting_screen.dart';
import 'package:app2_client/screens/chat_room_screen.dart';
import 'package:app2_client/screens/fare_setting_screen.dart';

class MyPartyScreen extends StatefulWidget {
  final PartyDetail party;
  final String? description;

  const MyPartyScreen({
    Key? key,
    required this.party,
    this.description,
  }) : super(key: key);

  @override
  State<MyPartyScreen> createState() => _MyPartyScreenState();
}

class _MyPartyScreenState extends State<MyPartyScreen> {
  late PartyDetail _party;
  String? _desc;
  bool _editingDesc = false;
  final TextEditingController _descController = TextEditingController();
  List<JoinRequest> _joinRequests = [];
  bool _socketConnected = false;

  @override
  void initState() {
    super.initState();
    _party = widget.party;
    _desc = widget.description ?? '';
    _descController.text = _desc!;
    _connectAndSubscribe();

    // 파티원이 다 찼을 때만 정산 페이지로 이동
    if (_party.members.length >= _party.maxPerson) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFareSettingDialog();
      });
    }
  }

  /// STOMP 연결 및 호스트 전용 구독 (참여 요청 응답 채널 + 파티 내부 업데이트)
  void _connectAndSubscribe() {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    SocketService.connect(token, onConnect: () {
      setState(() {
        _socketConnected = true;
      });
      SocketService.subscribeJoinRequestResponse(onMessage: (msg) {
        print('🔔 호스트용 참여 요청 메시지 수신: $msg');
        if (msg['status'] == 'PENDING') {
          try {
            final joinRequest = JoinRequest.fromJson(msg);
            print('✅ JoinRequest 파싱 성공: ${joinRequest.requesterEmail}');
            setState(() {
              _joinRequests.add(joinRequest);
              print('✅ _joinRequests 길이: ${_joinRequests.length}');
            });
          } catch (e) {
            print('❌ JoinRequest 파싱 실패: $e');
            print('❌ 메시지 내용: $msg');
          }
        } else {
          print('⚠️ status가 PENDING이 아님: ${msg['status']}');
        }
      });

      // ★ 추가: 호스트용 참여 요청 구독
      SocketService.subscribeJoinRequests(onMessage: (msg) {
        print('🔔 [join-requests] 호스트용 참여 요청 수신: $msg');
        try {
          final joinRequest = JoinRequest.fromJson(msg);
          print('✅ [join-requests] JoinRequest 파싱 성공: ${joinRequest.requesterEmail}');
          setState(() {
            _joinRequests.add(joinRequest);
            print('✅ [join-requests] _joinRequests 길이: ${_joinRequests.length}');
          });
        } catch (e) {
          print('❌ [join-requests] JoinRequest 파싱 실패: $e');
          print('❌ [join-requests] 메시지 내용: $msg');
        }
      });

      SocketService.subscribePartyMembers(
        partyId: _party.partyId,
        onMessage: (msg) async {
          print('🔔 파티 멤버 업데이트 메시지 수신: $msg');
          final eventType = msg['eventType'];
          if (eventType == 'MEMBER_JOIN' || eventType == 'PARTY_UPDATE') {
            final updated = await PartyService.fetchPartyDetailById(
              _party.partyId.toString(),
            );
            setState(() {
              _party = updated;
              // 만약 서버가 StopoverResponse를 내려준다면 여기서 _stopoverList도 업데이트
              // 예: _stopoverList = updated.stopovers;
            });
          }
        },
      );
      print('✅ 소켓 구독 완료 - 파티 ID: ${_party.partyId}');
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    SocketService.disconnect();
    _socketConnected = false;
    super.dispose();
  }

  void _saveDesc() {
    setState(() {
      _desc = _descController.text.trim();
      _editingDesc = false;
    });
  }

  Future<void> _acceptRequest(int requestId) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;
    try {
      await PartyService.acceptJoinRequest(
        partyId: _party.partyId.toString(),
        requestId: requestId,
        accessToken: token,
      );
      setState(() {
        _joinRequests.removeWhere((r) => r.requestId == requestId);
      });
      // MemberJoin 이벤트가 들어오면 자동으로 멤버 리스트 갱신됨
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('수락 실패: $e')));
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;
    try {
      await PartyService.rejectJoinRequest(
        partyId: _party.partyId.toString(),
        requestId: requestId,
        accessToken: token,
      );
      setState(() {
        _joinRequests.removeWhere((r) => r.requestId == requestId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('거절 실패: $e')));
    }
  }

  void _showFareSettingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정산 페이지로 이동'),
        content: const Text('모든 파티원이 모였습니다. 정산 페이지로 이동하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FareSettingScreen(
                    partyId: _party.partyId.toString(),
                    members: _party.members,
                    stopovers: [],
                  ),
                ),
              );
            },
            child: const Text('이동'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePartyDetail() async {
    final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    try {
      final refreshed = await PartyService.fetchPartyDetailById(_party.partyId.toString());
      setState(() {
        _party = refreshed;
      });

      // 파티원이 다 찼을 때만 정산 페이지로 이동
      if (_party.members.length >= _party.maxPerson) {
        _showFareSettingDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파티 정보 업데이트 실패: $e')),
      );
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
            const SizedBox(height: 12),

            // 설명 출력·수정
            _editingDesc
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _descController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: '설명을 입력하세요',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: _saveDesc,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          _desc!.isEmpty ? '설명을 추가하세요' : _desc!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => setState(() => _editingDesc = true),
                      ),
                    ],
                  ),

            const SizedBox(height: 12),

            // 해시태그
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _tag('#${_party.maxPerson}인팟'),
                _tag(_party.partyOption == 'MIXED' ? '#혼성' : '#동성만'),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),

            // **파티원 목록 & 정산자 지정 버튼**
            const Text('파티원 목록',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._party.members.map((m) {
              final isBookkeeper =
                  m.role == 'BOOKKEEPER' || m.additionalRole == 'BOOKKEEPER';
              return Card(
                child: ListTile(
                  leading: Icon(
                    m.gender == 'FEMALE' ? Icons.female : Icons.male,
                    color: m.gender == 'FEMALE' ? Colors.pink : Colors.blue,
                  ),
                  title: Text(m.name),
                  subtitle: Text(
                    '${m.email}  |  역할: ${m.role}'
                        '${m.additionalRole == 'BOOKKEEPER' ? ' (정산자)' : ''}',
                  ),
                  trailing: m.role != 'HOST'
                      ? ElevatedButton(
                          child: Text(isBookkeeper
                              ? '정산자 해제'
                              : '정산자 지정'),
                          onPressed: () {
                            _designateBookkeeperDialog(m);
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // 정산 페이지로 이동 버튼
            if (_party.members.length >= _party.maxPerson)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  label: const Text('정산 페이지로 이동'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FareSettingScreen(
                          partyId: _party.partyId.toString(),
                          members: _party.members,
                          stopovers: [],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

            // **참여 요청 리스트**
            if (_joinRequests.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text('신규 참여요청',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ..._joinRequests.map((req) {
                return Card(
                  color: Colors.amber[50],
                  child: ListTile(
                    title: Text(req.requesterEmail),
                    subtitle: Text('요청 ID: ${req.requestId}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check,
                              color: Colors.green),
                          onPressed: () =>
                              _acceptRequest(req.requestId),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.close, color: Colors.red),
                          onPressed: () =>
                              _rejectRequest(req.requestId),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // 디버그: 현재 _joinRequests 상태 표시
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔧 디버그 정보',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text('참여 요청 개수: ${_joinRequests.length}'),
                  Text('파티 ID: ${_party.partyId}'),
                  Text('소켓 연결 상태: ${_socketConnected ? "연결됨" : "끊김"}'),
                  if (_joinRequests.isNotEmpty)
                    Text('요청자들: ${_joinRequests.map((r) => r.requesterEmail).join(", ")}'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomScreen(
                roomId: widget.party.partyId.toString(),
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

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );

  Future<void> _designateBookkeeperDialog(PartyMember member) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('정산자 지정 확인'),
          content: Text('${member.name}님을 정산자로 지정하시겠습니까?'),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('확인'),
              onPressed: () async {
                try {
                  await PartyService.designateBookkeeper(
                    partyId: _party.partyId.toString(),
                    partyMemberId: member.id.toString(),
                    accessToken: token,
                  );
                  final refreshed = await PartyService.fetchPartyDetailById(
                      _party.partyId.toString());
                  setState(() {
                    _party = refreshed;
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('정산자 지정 실패: $e')));
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}