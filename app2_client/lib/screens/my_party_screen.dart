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

      // ─── 참여 요청 수신 구독 (호스트 전용) ────────────────────────────────
      SocketService.subscribeJoinRequests(onMessage: (msg) {
        // 예시 msg:
        // {
        //   "type": "JOIN_REQUEST",
        //   "request_id": 123,
        //   "name": "홍길동",
        //   "email": "hong@domain.com",
        //   "partyId": 84
        // }

        // ① 들어온 메시지의 partyId 와 현재 화면의 _party.partyId 를 비교
        final incomingPartyId = msg['partyId']?.toString();
        if (incomingPartyId == _party.partyId.toString()) {
          // ② 파티 ID가 일치할 때만 리스트에 추가
          try {
            final joinRequest = JoinRequest.fromJson(msg);
            setState(() {
              _joinRequests.add(joinRequest);
            });
          } catch (e) {
            debugPrint('❌ JoinRequest 파싱 실패: $e');
          }
        } else {
          // 파티 ID가 다르면 무시
          debugPrint(
              '🔕 다른 파티(${incomingPartyId}) 요청이라 무시: 현재 파티=${_party.partyId}');
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
              // 필요하다면 _stopoverList 도 갱신
            });
            _refreshAllMarkers();
          }
        },
      );

      _subscribed = true;
      debugPrint('✅ 소켓 구독 완료 - 파티 ID: ${_party.partyId}');
    }

    // 1) STOMP 연결 시도 → onConnect 에서 _doSubscribe() 호출
    SocketService.connect(token, onConnect: () {
      _doSubscribe();
    });

    // 2) 이미 연결된 상태라면(onConnect이 불릴 수 없으므로) 즉시 구독
    if (SocketService.connected) {
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
      // Host 도착지(빨간색) 마커만 ID "destination"으로 제거
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
      // 구독 중인 subscribePartyMembers가 MEMBER_JOIN 브로드캐스트를 받아와서 자동으로 _party 갱신
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

  /// 경유지 추가 다이얼로그 (생략)
  Future<void> _addStopoverDialog() async { /* … */ }

  /// 경유지 수정 다이얼로그 (생략)
  Future<void> _updateStopoverDialog(StopoverResponse existing) async { /* … */ }

  /// 정산자 지정 다이얼로그 (생략)
  Future<void> _designateBookkeeperDialog(PartyMember member) async { /* … */ }

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

                  // 설명 출력·수정 (생략)

                  const SizedBox(height: 12),

                  // 해시태그 (생략)

                  const SizedBox(height: 24),

                  // 경유지 추가 버튼 (생략)

                  const SizedBox(height: 24),
                  const Divider(),

                  // 경유지 목록 (생략)

                  const SizedBox(height: 24),

                  const Divider(),

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

                  // ─── 필터링된 “신규 참여요청” ─────────────────────────────────────
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

                  // 디버그 정보 (생략)
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
}