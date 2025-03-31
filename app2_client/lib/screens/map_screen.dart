import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app2_client/widgets/custom_back_button.dart';
import 'search_address_screen.dart';
import 'destination_radius_screen.dart';

class DestinationMapScreen extends StatefulWidget {
  const DestinationMapScreen({Key? key}) : super(key: key);

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
    // _controller가 이미 생성된 경우 HTML 로드
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
              // 이미 _localHtml이 로드되었으면 바로 HTML을 로드
              if (_localHtml.isNotEmpty) {
                _controller.loadHtmlString(_localHtml);
              }
            },
          ),
          // 중앙에 고정된 위치 마커 (선택된 위치 표시)
          Center(
            child: Icon(
              Icons.location_on,
              size: 50,
              color: Colors.redAccent,
            ),
          ),
          // 왼쪽 상단: CustomBackButton (재사용 가능한 뒤로가기 버튼)
          Positioned(
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
                // 로컬 HTML 내에 정의된 JavaScript 함수 호출
                String result = await _controller.evaluateJavascript("getSelectedDestination()");
                print('선택된 위치 정보: $result');
                // 이후, 결과에 따라 다음 페이지로 이동하거나 추가 처리를 함
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