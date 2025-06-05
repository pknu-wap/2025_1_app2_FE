// lib/screens/my_party_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/models/stopover_model.dart';
import 'package:app2_client/models/join_request_model.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/services/socket_service.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/screens/stopover_setting_screen.dart';
import 'package:app2_client/screens/chat_room_screen.dart';

import '../models/location_model.dart';
import '../models/party_member_model.dart';

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

  WebViewController? _mapController;
  bool _mapLoaded = false;
  bool _subscribed = false;

  List<StopoverResponse> _stopoverList = [];

  @override
  void initState() {
    super.initState();
    _party = widget.party;
    _desc = widget.description ?? '';
    _descController.text = _desc!;
    _connectAndSubscribe();
    _initMapWebView();
  }

  @override
  void dispose() {
    _descController.dispose();
    SocketService.disconnect();
    super.dispose();
  }

  /// STOMP 연결 및 호스트 전용 구독
  void _connectAndSubscribe() {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    void _doSubscribe() {
      if (_subscribed) return;

      // ─── 참여 요청 응답 구독 (호스트 전용) ────────────────────────────────
      SocketService.subscribeJoinRequestResponse(onMessage: (msg) {
        final incomingPartyId = msg['partyId']?.toString();
        final status = msg['status'] as String? ?? '';
        if (incomingPartyId == _party.partyId.toString() && status == 'PENDING') {
          try {
            final joinRequest = JoinRequest.fromJson(msg);
            setState(() {
              _joinRequests.add(joinRequest);
            });
          } catch (e) {
            debugPrint('❌ JoinRequest 파싱 실패: $e');
          }
        }
      });

      // ─── 파티 멤버 업데이트 구독 ───────────────────────────────────────
      SocketService.subscribePartyMembers(
        partyId: _party.partyId,
        onMessage: (msg) async {
          final eventType = msg['eventType'];
          if (eventType == 'MEMBER_JOIN' || eventType == 'PARTY_UPDATE') {
            final updated = await PartyService.fetchPartyDetailById(
              _party.partyId.toString(),
            );
            setState(() {
              _party = updated;
            });
            _refreshAllMarkers();
          }
        },
      );

      _subscribed = true;
      debugPrint('✅ 소켓 구독 완료 - 파티 ID: ${_party.partyId}');
    }

    // 1) STOMP 연결 시도 → onConnect에서 _doSubscribe() 호출
    SocketService.connect(token, onConnect: () {
      _doSubscribe();
    });

    // 2) 이미 연결된 상태라면(onConnect이 불릴 수 없으므로) 즉시 구독
    if (SocketService.isConnected) {
      _doSubscribe();
    }
  }

  /// WebViewController 생성 & kakao_party_map.html 로드
  Future<void> _initMapWebView() async {
    final rawHtml = await rootBundle.loadString('assets/kakao_party_map.html');
    final centerLat = _party.destLat;
    final centerLng = _party.destLng;
    final kakaoKey = dotenv.env['KAKAO_JS_KEY'] ?? '';
    final htmlWithParams = rawHtml
        .replaceAll('{{KAKAO_JS_KEY}}', kakaoKey)
        .replaceAll('{{CENTER_LAT}}', centerLat.toString())
        .replaceAll('{{CENTER_LNG}}', centerLng.toString());

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _mapLoaded = true;
            });
            _refreshAllMarkers();
          },
        ),
      )
      ..loadHtmlString(htmlWithParams, baseUrl: 'about:blank');

    setState(() {
      _mapController = controller;
    });
  }

  /// 목적지 + 경유지 전체 마커 갱신
  Future<void> _refreshAllMarkers() async {
    if (!_mapLoaded || _mapController == null) return;

    try {
      // 1) 기존 마커 제거
      for (final stop in _stopoverList) {
        await _mapController!
            .runJavaScript('removeMarker("${stop.stopover.id}");');
      }
      // Host 도착지(빨간색) 마커 제거
      await _mapController!.runJavaScript('removeMarker("destination");');

      // 2) Host 도착지(빨간색) 마커 찍기
      final destLat = _party.destLat;
      final destLng = _party.destLng;
      await _mapController!.runJavaScript(
        'addMarker("destination", $destLat, $destLng, "도착지", "red");',
      );

      // 3) 경유지(초록색) 마커 찍기
      for (final stop in _stopoverList) {
        final id = stop.stopover.id.toString();
        final lat = stop.stopover.location.lat;
        final lng = stop.stopover.location.lng;
        final title = '경유지 #$id';
        await _mapController!.runJavaScript(
          'addMarker("$id", $lat, $lng, "$title", "green");',
        );
      }
    } catch (e) {
      debugPrint('지도 마커 갱신 중 오류: $e');
    }
  }

  /// 설명 저장
  void _saveDesc() {
    setState(() {
      _desc = _descController.text.trim();
      _editingDesc = false;
    });
  }

  /// 참여 요청 수락
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
      // MEMBER_JOIN 브로드캐스트를 받아 자동 갱신됨
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('수락 실패: $e')));
    }
  }

  /// 참여 요청 거절
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

  /// 경유지 추가 다이얼로그
  Future<void> _addStopoverDialog() async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
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
                    const SnackBar(
                        content: Text('위도/경도를 올바르게 입력해주세요.')),
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

                  setState(() {
                    _stopoverList = newList;
                  });

                  if (newList.isNotEmpty) {
                    final added = newList.firstWhere(
                            (e) =>
                        e.stopover.location.address == address &&
                            e.partyMembers.any((m) => m.email == email),
                        orElse: () => newList.first);

                    Navigator.of(context).pop();

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StopoverSettingScreen(
                          partyId: _party.partyId.toString(),
                          stopoverData: added,
                        ),
                      ),
                    );
                    return;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('경유지 추가 실패: $e')),
                  );
                }

                Navigator.of(context).pop();
                _refreshAllMarkers();
              },
            ),
          ],
        );
      },
    );
  }

  /// 경유지 수정 다이얼로그
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
                    location: (lat != null && lng != null)
                        ? LocationModel(address: address, lat: lat, lng: lng)
                        : null,
                    accessToken: token,
                  );
                  setState(() {
                    _stopoverList = updatedList;
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('경유지 수정 실패: $e')),
                  );
                }

                Navigator.of(context).pop();
                _refreshAllMarkers();
              },
            ),
          ],
        );
      },
    );
  }

  /// 정산자 지정 다이얼로그
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 파티')),
      body: Column(
        children: [
          // 1) 지도(WebView) 영역
          SizedBox(
            height: 240,
            child: _mapController == null
                ? const Center(child: CircularProgressIndicator())
                : WebViewWidget(controller: _mapController!),
          ),

          // 2) 나머지 콘텐츠
          Expanded(
            child: SingleChildScrollView(
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
                        icon: const Icon(Icons.check,
                            color: Colors.green),
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
                        onPressed: () =>
                            setState(() => _editingDesc = true),
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

                  // 경유지 추가 버튼
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_road),
                      label: const Text('경유지 추가'),
                      onPressed: _addStopoverDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),

                  // **경유지 목록**
                  if (_stopoverList.isNotEmpty) ...[
                    const Text('경유지 목록',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._stopoverList.map((s) {
                      return ListTile(
                        title: Text(s.stopover.location.address),
                        subtitle: Text(
                          '하차자: ${s.partyMembers.map((m) => m.name).join(", ")}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _updateStopoverDialog(s);
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StopoverSettingScreen(
                                partyId: _party.partyId.toString(),
                                stopoverData: s,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    const Divider(),
                  ],

                  // 파티원 목록 & 정산자 지정 버튼
                  const Text('파티원 목록',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._party.members.map((m) {
                    final isBookkeeper =
                        m.role == 'BOOKKEEPER' || m.additionalRole == 'BOOKKEEPER';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
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

                  // ─── 오직 "내 파티 ID"로 온 요청만 보여줌 ───────────────────────────
                  if (_joinRequests.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('신규 참여요청',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ..._joinRequests.map((req) {
                      return Card(
                        color: Colors.amber[50],
                        margin: const EdgeInsets.symmetric(vertical: 6),
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
                                icon: const Icon(Icons.close,
                                    color: Colors.red),
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

                  // 디버그 정보
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
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        Text('참여 요청 개수: ${_joinRequests.length}'),
                        Text('파티 ID: ${_party.partyId}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatRoomScreen(roomId: _party.partyId.toString()),
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
}