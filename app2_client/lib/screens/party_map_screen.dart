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
import 'package:app2_client/providers/auth_provider.dart';

class PartyMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String initialAddress;

  const PartyMapScreen({
    Key? key,
    required this.initialLat,
    required this.initialLng,
    required this.initialAddress,
  }) : super(key: key);

  @override
  State<PartyMapScreen> createState() => _PartyMapScreenState();
}

class _PartyMapScreenState extends State<PartyMapScreen> {
  WebViewController? _controller;
  bool _pageLoaded = false;
  List<PartyModel> _pots = [];
  double _radiusMeters = 50000.0;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadPots();
  }

  Future<void> _initWebView() async {
    final rawHtml = await rootBundle.loadString('assets/kakao_map.html');
    final html = rawHtml
        .replaceAll('{{KAKAO_JS_KEY}}', dotenv.env['KAKAO_JS_KEY'] ?? '')
        .replaceAll('{{LAT}}', widget.initialLat.toString())
        .replaceAll('{{LNG}}', widget.initialLng.toString());

    final webController = WebViewController();
    await webController.setJavaScriptMode(JavaScriptMode.unrestricted);
    await webController.addJavaScriptChannel('MarkerClick', onMessageReceived: (msg) {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      final pot = _pots.firstWhere((p) => p.id == data['id'], orElse: () => _pots.first);
      _openJoinModal(pot);
    });
    await webController.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (_) => _onPageFinished(webController),
    ));
    await webController.loadHtmlString(html, baseUrl: 'about:blank');

    setState(() => _controller = webController);
  }

  Future<void> _onPageFinished(WebViewController webController) async {
    // 지도 확대
    await webController.runJavaScript('map.setLevel(3);');

    // 고정 목적지 마커 (빨간색)
    await webController.runJavaScript("""
      var fixedMarker = new kakao.maps.Marker({
        position: new kakao.maps.LatLng(${widget.initialLat}, ${widget.initialLng}),
        map: map,
        image: new kakao.maps.MarkerImage(
          'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
          new kakao.maps.Size(48, 68),
          { offset: new kakao.maps.Point(24, 68) }
        )
      });

      var overlay = new kakao.maps.CustomOverlay({
        position: fixedMarker.getPosition(),
        content: '<div style="padding:6px 12px; background:white; border:2px solid red; border-radius:6px; font-size:16px; font-weight:bold; color:black; box-shadow:0 2px 6px rgba(0,0,0,0.3);">${widget.initialAddress}</div>',
        yAnchor: 2.2
      });
      overlay.setMap(map);
    """);

    setState(() => _pageLoaded = true);
    if (_pots.isNotEmpty) _renderMarkers();
  }

  Future<void> _loadPots() async {
    final token = context.read<AuthProvider>().tokens?.accessToken;
    if (token == null) return;

    final pots = await PartyService.fetchNearbyParties(
      lat: widget.initialLat,
      lng: widget.initialLng,
      radiusKm: _radiusMeters / 1000.0,
      accessToken: token,
    );
    setState(() => _pots = pots);
    if (_pageLoaded) _renderMarkers();
  }

  void _renderMarkers() {
    for (final pot in _pots) {
      _controller?.runJavaScript('''
        addMarker(
          "${pot.id}",
          ${pot.destLat},
          ${pot.destLng},
          "${pot.creatorName}"
        );
      ''');
    }
  }

  void _openJoinModal(PartyModel pot) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => PartyJoinModal(pot: pot),
  );

  void _openCreateModal() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => PartyCreateModal(
      startLat: widget.initialLat,
      startLng: widget.initialLng,
      startAddress: widget.initialAddress,
      destLat: widget.initialLat,
      destLng: widget.initialLng,
      destAddress: widget.initialAddress,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          WebViewWidget(controller: _controller!),

          // ✅ 뒤로가기 버튼 추가
          const Positioned(
            top: 40,
            left: 16,
            child: CustomBackButton(), // 또는 BackButton()
          ),
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