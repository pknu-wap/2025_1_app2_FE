import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app2_client/widgets/custom_back_button.dart';
import 'package:app2_client/services/party_service.dart';

class DestinationMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const DestinationMapScreen({
    Key? key,
    required this.initialLat,
    required this.initialLng,
  }) : super(key: key);

  @override
  _DestinationMapScreenState createState() => _DestinationMapScreenState();
}

class _DestinationMapScreenState extends State<DestinationMapScreen> {
  late WebViewController _controller;
  String _localHtml = '';

  static const double _markerRadiusKm = 5.0;   // 마커 띄울 반경
  static const int    _mapRadiusMeter = 7000; // 지도에 표시할 원 반경 (단위: m)

  @override
  void initState() {
    super.initState();
    _loadLocalHtml();
  }

  Future<void> _loadLocalHtml() async {
    var html = await rootBundle.loadString('assets/kakao_map.html');
    // 초기 중심 좌표를 HTML 플레이스홀더에 심어두셨다면 여기서 replaceAll 해도 되고…
    setState(() => _localHtml = html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // (1) 로컬 HTML 로드
        WebView(
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (ctrl) {
            _controller = ctrl;
            if (_localHtml.isNotEmpty) {
              _controller.loadHtmlString(_localHtml);
            }
          },
        ),

        // (2) 중앙 고정 마커
        const Center(
          child: Icon(Icons.location_on, size: 56, color: Colors.redAccent),
        ),

        // (3) 뒤로가기 버튼
        const Positioned(top: 40, left: 16, child: CustomBackButton()),

        // (4) “이 위치로 목적지 설정” 버튼
        Positioned(
          bottom: 30, left: 16, right: 16,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              // 1) JS 함수 호출: 선택된 목적지 좌표 받기
              final raw = await _controller.runJavascriptReturningResult(
                  "getSelectedDestination()"
              );
              final coord = jsonDecode(raw);
              final lat = coord['lat'] as double;
              final lng = coord['lng'] as double;

              // 2) 백엔드에서 파티 탐색 (5km 반경)
              final parties = await PartyService().fetchNearbyParties(
                  lat: lat, lng: lng, radiusKm: _markerRadiusKm
              );

              // 3) 지도 위에 마커 찍기 (JS 함수로)
              for (final p in parties) {
                _controller.runJavascript(
                    'addPartyMarker(${p.startLat}, ${p.startLng});'
                );
              }

              // 4) 7km 반경 원(circle) 표시 (JS 함수로)
              _controller.runJavascript(
                  'drawCircle($lat, $lng, $_mapRadiusMeter);'
              );
            },
            child: const Text('이 위치로 목적지 설정', style: TextStyle(fontSize: 18)),
          ),
        ),
      ]),
    );
  }
}