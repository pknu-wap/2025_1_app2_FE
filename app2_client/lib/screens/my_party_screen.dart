// lib/screens/my_party_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/models/stopover_model.dart';
import 'package:app2_client/models/location_model.dart';
import 'package:app2_client/models/party_member_model.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/services/socket_service.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/models/join_request_model.dart';
import 'package:app2_client/screens/stopover_setting_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _party = widget.party;
    _desc = widget.description ?? '';
    _descController.text = _desc!;
    _subscribeSocket();
  }

  void _subscribeSocket() {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;
    SocketService.connect(token);

    SocketService.subscribe(
      topic: "/sub/party/${_party.partyId}",
      onMessage: (msg) async {
        // 참여 요청 수신
        if (msg['type'] == 'JOIN_REQUEST') {
          setState(() {
            _joinRequests.add(JoinRequest.fromJson(msg));
          });
        }
        // 멤버 리스트 갱신 or 파티 업데이트 메시지 수신
        else if (msg['eventType'] == 'MEMBER_JOIN' ||
            msg['eventType'] == 'PARTY_UPDATE') {
          final updated = await PartyService.fetchPartyDetailById(
              _party.partyId.toString());
          setState(() => _party = updated);
        }
      },
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    SocketService.disconnect();
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
      // 자동으로 브로드캐스트된 MEMBER_JOIN 이벤트가 들어오면 멤버 리스트 갱신됨
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

  Future<void> _addStopoverDialog() async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    String email = '';
    String address = '';
    String latStr = '';
    String lngStr = '';

    final _emailController = TextEditingController();
    final _addressController = TextEditingController();
    final _latController = TextEditingController();
    final _lngController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('경유지 추가'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration:
                  const InputDecoration(labelText: '내릴 유저 이메일'),
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: '주소'),
                ),
                TextField(
                  controller: _latController,
                  decoration: const InputDecoration(labelText: '위도'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: _lngController,
                  decoration: const InputDecoration(labelText: '경도'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('추가'),
              onPressed: () async {
                email = _emailController.text.trim();
                address = _addressController.text.trim();
                latStr = _latController.text.trim();
                lngStr = _lngController.text.trim();

                if (email.isEmpty ||
                    address.isEmpty ||
                    latStr.isEmpty ||
                    lngStr.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모든 항목을 입력해주세요.')),
                  );
                  return;
                }

                final lat = double.tryParse(latStr);
                final lng = double.tryParse(lngStr);
                if (lat == null || lng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('위도/경도를 올바르게 입력해주세요.')),
                  );
                  return;
                }

                try {
                  final List<StopoverResponse> newList =
                  await PartyService.addStopover(
                    partyId: _party.partyId.toString(),
                    memberEmail: email,
                    location: LocationModel(
                        address: address, lat: lat, lng: lng),
                    accessToken: token,
                  );
                  // (옵션) 로컬 파티 정보를 업데이트하거나, 화면에 경유지 리스트를 띄우고 싶으면
                  debugPrint('새 경유지 목록: $newList');
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('경유지 추가 실패: $e')));
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStopoverDialog(StopoverResponse existing) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    String email = existing.partyMembers.isNotEmpty
        ? existing.partyMembers.first.email
        : '';
    String address = existing.stopover.location.address;
    String latStr = existing.stopover.location.lat.toString();
    String lngStr = existing.stopover.location.lng.toString();

    final _emailController = TextEditingController(text: email);
    final _addressController = TextEditingController(text: address);
    final _latController = TextEditingController(text: latStr);
    final _lngController = TextEditingController(text: lngStr);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('경유지 수정'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration:
                  const InputDecoration(labelText: '내릴 유저 이메일'),
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: '주소'),
                ),
                TextField(
                  controller: _latController,
                  decoration: const InputDecoration(labelText: '위도'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: _lngController,
                  decoration: const InputDecoration(labelText: '경도'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('수정'),
              onPressed: () async {
                email = _emailController.text.trim();
                address = _addressController.text.trim();
                latStr = _latController.text.trim();
                lngStr = _lngController.text.trim();

                final double? lat = double.tryParse(latStr);
                final double? lng = double.tryParse(lngStr);

                try {
                  final List<StopoverResponse> updatedList =
                  await PartyService.updateStopover(
                    partyId: _party.partyId.toString(),
                    stopoverId: existing.stopover.id,
                    memberEmail: email.isEmpty ? null : email,
                    location:
                    (lat != null && lng != null)
                        ? LocationModel(
                        address: address, lat: lat, lng: lng)
                        : null,
                    accessToken: token,
                  );
                  debugPrint('수정 후 경유지 목록: $updatedList');
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('경유지 수정 실패: $e')));
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
                  final updatedMembers = await PartyService.designateBookkeeper(
                    partyId: _party.partyId.toString(),
                    partyMemberId: member.id.toString(),
                    accessToken: token,
                  );
                  // (옵션) 로컬 파티 멤버 리스트를 최신화하려면:
                  final refreshed = await PartyService.fetchPartyDetailById(
                      _party.partyId.toString());
                  setState(() => _party = refreshed);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 파티')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _destinationCard(_party.destAddress),
            const SizedBox(height: 16),

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

            // “경유지 추가” 버튼
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_road),
                label: const Text('경유지 추가'),
                onPressed: _addStopoverDialog,
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // **경유지 리스트 (설정된 경유지와 해당 멤버들)**
            FutureBuilder<List<StopoverResponse>>(
              future: PartyService
                  .fetchPartyDetailById(_party.partyId.toString())
                  .then((_) async {
                // 서버가 경유지 정보를 함께 내려주지는 않으므로,
                // “fetch 파티 디테일” 이후 newline((내부 로직이나 별도 엔드포인트 필요시))
                // 경유지 리스트 API 호출을 추가로 구현해야 합니다.
                // 하지만 현재 API 명세서 상에는 별도 GET 엔드포인트가 없으므로,
                // “addStopover” 나 “updateStopover” 호출 후 리턴값에 의존합니다.
                return <StopoverResponse>[];
              }),
              builder: (context, snapshot) {
                // 이 부분은 “경유지 추가/수정” 후 리턴값을 직접 로컬에 보관해두고,
                // setState를 통해 레이아웃에 반영하는 방식으로 구현해야 합니다.
                // 여기서는 예시이므로 비워둡니다.
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 24),

            // **파티원 리스트 & 정산자 지정 버튼**
            const Text('파티원 목록', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._party.members.map((m) {
              final isBookkeeper = m.role == 'BOOKKEEPER' ||
                  m.additionalRole == 'BOOKKEEPER';
              return Card(
                child: ListTile(
                  leading: Icon(
                    m.gender == 'FEMALE' ? Icons.female : Icons.male,
                    color: m.gender == 'FEMALE' ? Colors.pink : Colors.blue,
                  ),
                  title: Text(m.name),
                  subtitle: Text('${m.email}  |  역할: ${m.role}'
                      '${m.additionalRole == 'BOOKKEEPER' ? ' (정산자)' : ''}'),
                  trailing: m.role != 'HOST'
                      ? ElevatedButton(
                    child: Text(isBookkeeper ? '정산자 해제' : '정산자 지정'),
                    onPressed: () {
                      _designateBookkeeperDialog(m);
                    },
                  )
                      : const SizedBox.shrink(),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // **참여 요청 리스트 (생략: JoinRequest UI)**
            if (_joinRequests.isNotEmpty) ...[
              const Divider(),
              const Text('신규 참여요청', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._joinRequests.map((req) {
                return Card(
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
                );
              }).toList(),
            ],
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
        const Center(child: Icon(Icons.location_on, size: 48, color: Colors.amber)),
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