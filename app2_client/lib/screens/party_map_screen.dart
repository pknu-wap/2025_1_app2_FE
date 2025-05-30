import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:app2_client/widgets/custom_back_button.dart';
import 'package:app2_client/widgets/party_join_modal.dart';
import 'package:app2_client/widgets/party_create_modal.dart';

import 'package:app2_client/models/party_model.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/services/socket_service.dart'; // 추가!
import 'package:app2_client/providers/auth_provider.dart';

class PartyMapScreen extends StatefulWidget {
  final double initialLat, initialLng;
  final String  initialAddress;
  final double startLat,  startLng;
  final String  startAddress;

  const PartyMapScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.initialAddress,
    required this.startLat,
    required this.startLng,
    required this.startAddress,
  });

  @override
  State<PartyMapScreen> createState() => _PartyMapScreenState();
}

class _PartyMapScreenState extends State<PartyMapScreen> {
  WebViewController? _controller;
  bool   _pageLoaded = false;
  List<PartyModel> _pots = [];
  bool _subscribed = false;

  /* ───────────────────────── Map Drag-enable 토글 ───────────────────────── */
  Future<void> _setMapInteractive(bool enable) async {
    await _controller?.runJavaScript('''
      map.setDraggable(${enable.toString()});
      map.setZoomable(${enable.toString()});
    ''');
  }

  /* ───────────────────────── 초기화 ───────────────────────── */
  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadPots();

    // 파티 외부 사용자용 실시간 브로드캐스트 구독
    // 중복 구독 방지 플래그 사용
    if (!_subscribed) {
      SocketService.subscribe(
        topic: "/topic/parties/public-updates",
        onMessage: (msg) {
          // print("🌐 외부 파티 업데이트: $msg");
          _loadPots(); // 실시간으로 파티 목록 새로고침
        },
      );
      _subscribed = true;
    }
  }

  @override
  void dispose() {
    // 여긴 소켓 연결 끊으면 안됨(검색화면은 앱 전체에서 계속 유지할 수도 있음)
    // 필요하다면 SocketService.unsubscribe('/topic/parties/public-updates'); 호출
    super.dispose();
  }

  Future<void> _initWebView() async {
    final raw  = await rootBundle.loadString('assets/kakao_map.html');
    final html = raw
        .replaceAll('{{KAKAO_JS_KEY}}', dotenv.env['KAKAO_JS_KEY'] ?? '')
        .replaceAll('{{LAT}}', widget.initialLat.toString())
        .replaceAll('{{LNG}}', widget.initialLng.toString());

    final wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('MarkerClick',
          onMessageReceived: (msg) {
            final data = jsonDecode(msg.message);
            final pot  = _pots.firstWhere((p) => p.id == data['id'],
                orElse: () => _pots.first);
            _openJoinModal(pot);
          })
      ..setNavigationDelegate(
          NavigationDelegate(onPageFinished: (_) => _onWebReady()))
      ..loadHtmlString(html, baseUrl: 'about:blank');

    setState(() => _controller = wc);
  }

  Future<void> _onWebReady() async {
    // 초기 확대 레벨
    await _controller?.runJavaScript('map.setLevel(3);');
    // 빨간 고정 마커 & 라벨
    await _controller?.runJavaScript("""
      var m=new kakao.maps.Marker({
        position:new kakao.maps.LatLng(${widget.initialLat},${widget.initialLng}),
        map:map,
        image:new kakao.maps.MarkerImage(
          'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
          new kakao.maps.Size(48,68),
          {offset:new kakao.maps.Point(24,68)}
        )
      });
      new kakao.maps.CustomOverlay({
        position:m.getPosition(),
        content:'<div style="padding:6px 12px;background:#fff;border:2px solid red;border-radius:6px;font-weight:bold;">${widget.initialAddress}</div>',
        yAnchor:2.2
      }).setMap(map);
    """);

    setState(() => _pageLoaded = true);
    if (_pots.isNotEmpty) _renderMarkers();
  }

  /* ───────────────────────── 서버에서 파티 목록 ───────────────────────── */
  Future<void> _loadPots() async {
    final list = await PartyService.fetchNearbyParties(
        lat: widget.initialLat,
        lng: widget.initialLng,
        radiusKm: 50
    );
    setState(() => _pots = list);
    if (_pageLoaded) _renderMarkers();
  }

  void _renderMarkers() {
    for (final p in _pots) {
      _controller?.runJavaScript(
          'addMarker("${p.id}",${p.destLat},${p.destLng},"${p.creatorName}");');
    }
  }

  /* ───────────────────────── 모달 열기 ───────────────────────── */
  Future<void> _openJoinModal(PartyModel pot) async {
    await _setMapInteractive(false);          // ← 지도 잠금
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PartyJoinModal(pot: pot),
    );
    await _setMapInteractive(true);           // ← 지도 해제
  }

  Future<void> _openCreateModal() async {
    await _setMapInteractive(false);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PartyCreateModal(
        startLat: widget.startLat,
        startLng: widget.startLng,
        startAddress: widget.startAddress,
        destLat:  widget.initialLat,
        destLng:  widget.initialLng,
        destAddress: widget.initialAddress,
      ),
    );
    await _setMapInteractive(true);
  }

  /* ───────────────────────── UI ───────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(children: [
        WebViewWidget(controller: _controller!),
        const Positioned(top: 40, left: 16, child: CustomBackButton()),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _pageLoaded ? _openCreateModal : null,
            child: const Text('파티 추가하기'),
          ),
        ),
      ),
    );
  }
}