import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app2_client/widgets/custom_back_button.dart';
import 'search_address_screen.dart';
import 'destination_radius_screen.dart';

class DestinationMapScreen extends StatefulWidget {
  // 선택한 위치의 좌표를 전달받도록 수정 (optional)
  final double? initialLat;
  final double? initialLng;

  const DestinationMapScreen({Key? key, this.initialLat, this.initialLng}) : super(key: key);

  @override
  _DestinationMapScreenState createState() => _DestinationMapScreenState();
}

class _DestinationMapScreenState extends State<DestinationMapScreen> {
  late WebViewController _controller;
  String _localHtml = '';

  @override
  void initState() {
    super.initState();
    _loadLocalHtml();
  }

  Future<void> _loadLocalHtml() async {
    _localHtml = await rootBundle.loadString('assets/kakao_map.html');
    // 만약 initialLat, initialLng 값이 있으면, HTML 파일 내 플레이스홀더를 대체
    if (widget.initialLat != null && widget.initialLng != null) {
      _localHtml = _localHtml
          .replaceAll('__INITIAL_LAT__', widget.initialLat.toString())
          .replaceAll('__INITIAL_LNG__', widget.initialLng.toString());
    }
    if (_controller != null && _localHtml.isNotEmpty) {
      _controller.loadHtmlString(_localHtml);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // WebView: 로컬 HTML 파일 내용을 로드
          WebView(
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (controller) {
              _controller = controller;
              if (_localHtml.isNotEmpty) {
                _controller.loadHtmlString(_localHtml);
              }
            },
          ),
          // 중앙에 고정된 위치 마커 (선택된 위치 표시)
          const Center(
            child: Icon(
              Icons.location_on,
              size: 50,
              color: Colors.redAccent,
            ),
          ),
          // 왼쪽 상단: CustomBackButton
          const Positioned(
            top: 40,
            left: 16,
            child: CustomBackButton(),
          ),
          // 하단 중앙: "이 위치로 목적지 설정" 버튼
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                String result = await _controller.evaluateJavascript("getSelectedDestination()");
                print('선택된 위치 정보: $result');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DestinationRadiusScreen(),
                  ),
                );
              },
              child: const Text(
                '이 위치로 목적지 설정',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}