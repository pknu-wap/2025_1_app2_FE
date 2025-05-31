// lib/screens/my_party_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  // ★ WebViewController 및 로드 여부 플래그
  WebViewController? _mapController;
  bool _mapLoaded = false;

  // 로컬에 보관할 StopoverResponse 리스트
  List<StopoverResponse> _stopoverList = [];

  bool _socketSubscribed = false;

  @override
  void initState() {
    super.initState();
    _party = widget.party;
    _desc = widget.description ?? '';
    _descController.text = _desc!;
    _connectAndSubscribe();

    // WebView(파티 지도) 초기화
    _initMapWebView();
  }

  /// STOMP 연결 및 호스트 전용 구독 (참여 요청 응답 채널 + 파티 내부 업데이트)
  void _connectAndSubscribe() {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    SocketService.connect(token, onConnect: () {
      if (!_socketSubscribed) {
        // 1) 호스트에게 날아오는 “참여 요청 응답” (PENDING, APPROVED, REJECTED, CANCELED)
        SocketService.subscribeJoinRequestResponse(onMessage: (msg) {
          // msg 안에 type이 "JOIN_REQUEST"인 경우엔 새 요청 정보를 _joinRequests에 추가
          if (msg['type'] == 'JOIN_REQUEST') {
            setState(() {
              _joinRequests.add(JoinRequest.fromJson(msg));
            });
          }
        });

        // 2) 파티 내부 업데이트(멤버 JOIN, 파티 업데이트 등)
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
                // 만약 서버가 StopoverResponse를 내려준다면 여기서 _stopoverList도 업데이트
                // 예: _stopoverList = updated.stopovers;
              });
              _refreshAllMarkers();
            }
          },
        );

        _socketSubscribed = true;
      }
    });
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

  /// WebViewController를 생성 & kakao_party_map.html 로드
  Future<void> _initMapWebView() async {
    // 1) assets 폴더에 kakao_party_map.html 이 반드시 있어야 합니다.
    final rawHtml = await rootBundle.loadString('assets/kakao_party_map.html');

    final centerLat = _party.destLat;
    final centerLng = _party.destLng;

    // .env에서 카카오 JS 키를 불러와 치환
    final kakaoKey = dotenv.env['KAKAO_JS_KEY'] ?? '';
    final htmlWithParams = rawHtml
        .replaceAll('{{KAKAO_JS_KEY}}', kakaoKey)
        .replaceAll('{{CENTER_LAT}}', centerLat.toString())
        .replaceAll('{{CENTER_LNG}}', centerLng.toString());

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // HTML이 완전히 로드된 직후에 true로 바꿔 주고 마커 찍기
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

  /// 목적지 + 경유지 전체 마커를 갱신
  Future<void> _refreshAllMarkers() async {
    if (!_mapLoaded || _mapController == null) return;

    try {
      // 1) 기존 마커 모두 제거
      for (final stop in _stopoverList) {
        await _mapController!
            .runJavaScript('removeMarker("${stop.stopover.id}");');
      }
      // 목적지(Host dest)는 ID를 “destination” 으로 고정
      await _mapController!.runJavaScript('removeMarker("destination");');

      // 2) Host 도착지(빨간색) 마커 찍기
      final destLat = _party.destLat;
      final destLng = _party.destLng;
      await _mapController!.runJavaScript(
        'addMarker("destination", $destLat, $destLng, "목적지", "red");',
      );

      // 3) 각 경유지(초록색) 마커 찍기
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

  /// “경유지 추가” 다이얼로그 띄우고, 파티에 경유지 추가 요청 후 로컬 리스트와 마커 갱신, 추가된 경유지 설정 화면으로 이동
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
                    const SnackBar(
                        content: Text('위도/경도를 올바르게 입력해주세요.')),
                  );
                  return;
                }

                try {
                  // 백엔드로 경유지 추가 요청
                  final List<StopoverResponse> newList =
                  await PartyService.addStopover(
                    partyId: _party.partyId.toString(),
                    memberEmail: email,
                    location: LocationModel(
                        address: address, lat: lat, lng: lng),
                    accessToken: token,
                  );

                  // 로컬 리스트 갱신 + 마커 다시 찍기
                  setState(() {
                    _stopoverList = newList;
                  });

                  // 새로 추가된 경유지가 있으면 → “하차 지점 설정 화면”으로 바로 이동
                  if (newList.isNotEmpty) {
                    final added = newList.firstWhere(
                            (e) =>
                        e.stopover.location.address == address &&
                            e.partyMembers.any((m) => m.email == email),
                        orElse: () => newList.first);

                    Navigator.of(context).pop(); // 다이얼로그 닫기

                    // 경유지 설정 화면으로 이동
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

                // 다이얼로그 닫고, 지도 마커 다시 그리기
                Navigator.of(context).pop();
                _refreshAllMarkers();
              },
            ),
          ],
        );
      },
    );
  }

  /// “경유지 수정” 다이얼로그 (MyPartyScreen 내에서도 호출 가능)
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
                          // 해당 경유지 설정 화면으로 이동
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
                          title: Text(req.userName),
                          subtitle: Text(req.userEmail),
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
                ],
              ),
            ),
          ),
        ],
      ),
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