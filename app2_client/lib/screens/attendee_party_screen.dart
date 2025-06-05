// lib/screens/attendee_party_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
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

  // WebView 관련
  WebViewController? _mapController;
  bool _mapLoaded = false;

  @override
  void initState() {
    super.initState();
    _connectAndSubscribe();
    _fetchParty();
  }

  /// STOMP 구독
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
          if (partyId.toString() == widget.partyId) {
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

  /// PartyDetail 불러오기
  Future<void> _fetchParty() async {
    setState(() => _loading = true);
    try {
      final fetched = await PartyService.fetchPartyDetailById(widget.partyId);
      if (mounted) {
        setState(() {
          party = fetched;
        });
        // 파티 정보를 받았으면 지도를 초기화
        _initMapWebView();
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

  /// WebView(카카오 지도) 초기화 및 HTML 로드
  Future<void> _initMapWebView() async {
    if (party == null) return;

    // HTML 템플릿 불러오기
    final raw = await rootBundle.loadString('assets/kakao_party_map.html');
    final kakaoKey = dotenv.env['KAKAO_JS_KEY'] ?? '';

    // 출발지(origin)와 도착지(dest) 좌표로 치환
    final centerLat = party!.destLat;
    final centerLng = party!.destLng;
    final html = raw
        .replaceAll('{{KAKAO_JS_KEY}}', kakaoKey)
        .replaceAll('{{CENTER_LAT}}', centerLat.toString())
        .replaceAll('{{CENTER_LNG}}', centerLng.toString());

    final wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) {
          setState(() {
            _mapLoaded = true;
          });
          _renderMarkers();
        }),
      )
      ..loadHtmlString(html, baseUrl: 'about:blank');

    setState(() {
      _mapController = wc;
    });
  }

  /// 출발지/도착지에 마커 추가
  void _renderMarkers() {
    if (_mapController == null || party == null) return;

    // 출발지(파란색) 마커
    final oLat = party!.originLat;
    final oLng = party!.originLng;
    final dLat = party!.destLat;
    final dLng = party!.destLng;

    final jsOrigin = '''
      addMarker("origin", $oLat, $oLng, "출발지", "blue");
    ''';
    final jsDest = '''
      addMarker("destination", $dLat, $dLng, "도착지", "red");
    ''';

    _mapController!.runJavaScript(jsOrigin);
    _mapController!.runJavaScript(jsDest);
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
        centerTitle: true,
        title: const Text('내 파티'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 지도 영역 ───────────────────────────────────────────────────
            Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              clipBehavior: Clip.hardEdge,
              child: _mapController == null
                  ? const Center(child: CircularProgressIndicator())
                  : WebViewWidget(controller: _mapController!),
            ),
            const SizedBox(height: 16),

            // ─── 최대 인원 및 팟 옵션(성별) ────────────────────────────────────────────
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
                      party!.partyOption,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // ─── 파티원 목록 ─────────────────────────────────────────────────────
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