// lib/screens/party_map_screen.dart

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
import 'package:app2_client/services/socket_service.dart';
import 'package:app2_client/providers/auth_provider.dart';

class PartyMapScreen extends StatefulWidget {
  final double initialLat, initialLng;
  final String initialAddress;
  final double startLat, startLng;
  final String startAddress;

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
  bool _pageLoaded = false;
  List<PartyModel> _pots = [];
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _connectAndSubscribe();
    _loadPots();  // 최초 로드
  }

  /// STOMP 연결 및 Public Updates 구독
  void _connectAndSubscribe() {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    // 1) STOMP 연결
    SocketService.connect(token, onConnect: () {
      // 2) 연결 직후 Public Updates 토픽 구독
      if (!_subscribed) {
        SocketService.subscribePublicUpdates(onMessage: (message) {
          // 파티 생성/업데이트 이벤트가 오면, 리스트를 다시 가져와서 지도 갱신
          if (mounted) {
            _loadPots();
          }
        });
        _subscribed = true;
      }
    });
  }

  @override
  void dispose() {
    // 소켓 연결 정리 및 구독 해제
    SocketService.disconnect();
    _subscribed = false;
    super.dispose();
  }

  /// WebView 초기화 및 HTML 로드
  Future<void> _initWebView() async {
    final raw = await rootBundle.loadString('assets/kakao_party_map.html');
    final html = raw
        .replaceAll('{{KAKAO_JS_KEY}}', dotenv.env['KAKAO_JS_KEY'] ?? '')
        .replaceAll('{{CENTER_LAT}}', widget.initialLat.toString())
        .replaceAll('{{CENTER_LNG}}', widget.initialLng.toString());

    final wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'MarkerClick',
        onMessageReceived: (msg) {
          final data = jsonDecode(msg.message);
          final pot = _pots.firstWhere(
                (p) => p.id == data['id'],
            orElse: () => _pots.first,
          );
          _openJoinModal(pot);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => _onWebReady()),
      )
      ..loadHtmlString(html, baseUrl: 'about:blank');

    setState(() {
      _controller = wc;
    });
  }

  /// 웹뷰가 로드된 직후 호출
  Future<void> _onWebReady() async {
    // 지도 초기 확대 레벨 설정
    await _controller?.runJavaScript('map.setLevel(3);');

    // 호스트 측 도착지(빨간색 마커 + 라벨) 찍기
    await _controller?.runJavaScript("""
      var m = new kakao.maps.Marker({
        position: new kakao.maps.LatLng(${widget.initialLat}, ${widget.initialLng}),
        map: map,
        image: new kakao.maps.MarkerImage(
          'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
          new kakao.maps.Size(64, 69),
          { offset: new kakao.maps.Point(27, 69) }
        )
      });
      new kakao.maps.CustomOverlay({
        position: m.getPosition(),
        content: '<div style="padding:6px 12px; background:#fff; border:2px solid red; border-radius:6px; font-weight:bold;">${widget.initialAddress}</div>',
        yAnchor: 2.2
      }).setMap(map);
    """);

    setState(() {
      _pageLoaded = true;
    });

    // 이미 서버에서 받아온 파티가 있으면 지도의 마커를 찍음
    if (_pots.isNotEmpty) {
      _renderMarkers();
    }
  }

  /// 서버에서 파티 목록을 가져와 _pots 업데이트 (토큰 포함)
  Future<void> _loadPots() async {
    if (!mounted) return;

    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) {
      // 토큰이 없으면 빈 리스트로 초기화
      if (mounted) {
        setState(() => _pots = []);
      }
      return;
    }

    // 지구 전체 범위의 반경을 주어 "모든 파티"를 가져오도록 설정
    const extremelyLargeRadius = 20000.0; // 약 20,000km
    try {
      final list = await PartyService.fetchNearbyParties(
        lat: widget.initialLat,
        lng: widget.initialLng,
        radiusKm: extremelyLargeRadius,
        accessToken: token, // ← 반드시 토큰을 넘겨야 함
      );
      debugPrint('▶️ fetchNearbyParties 응답: 파티 개수 = ${list.length}');
      if (mounted) {
        setState(() {
          _pots = list;
        });
        if (_pageLoaded) {
          _renderMarkers();
        }
      }
    } catch (e) {
      debugPrint('‼️ fetchNearbyParties 예외 발생: $e');
    }
  }

  /// _pots에 담긴 파티들을 지도 위에 마커로 찍어주는 메서드
  void _renderMarkers() {
    for (final p in _pots) {
      final js = 'addMarker("${p.id}", ${p.destLat}, ${p.destLng}, "${p.creatorName}", "blue");';
      debugPrint('실행 JS: $js');
      _controller?.runJavaScript(js);
    }
  }

  /// 파티 참가 모달 열기
  Future<void> _openJoinModal(PartyModel pot) async {
    // 지도를 잠시 비활성화
    await _setMapInteractive(false);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PartyJoinModal(pot: pot),
    );
    // 모달 닫힌 뒤 지도를 다시 활성화
    await _setMapInteractive(true);
  }

  /// 파티 생성 모달 열기
  Future<void> _openCreateModal() async {
    await _setMapInteractive(false);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PartyCreateModal(
        startLat: widget.startLat,
        startLng: widget.startLng,
        startAddress: widget.startAddress,
        destLat: widget.initialLat,
        destLng: widget.initialLng,
        destAddress: widget.initialAddress,
      ),
    );
    await _setMapInteractive(true);
  }

  /// 지도 상호작용(드래그/줌) 허용/비허용 토글
  Future<void> _setMapInteractive(bool enable) async {
    await _controller?.runJavaScript('''
      map.setDraggable(${enable.toString()});
      map.setZoomable(${enable.toString()});
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          WebViewWidget(controller: _controller!),
          const Positioned(top: 40, left: 16, child: CustomBackButton()),
        ],
      ),
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