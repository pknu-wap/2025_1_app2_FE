import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app2_client/widgets/custom_back_button.dart';
import 'party_create_screen.dart'; // 팟 생성 페이지 (임시 페이지)

class PartyMapScreen extends StatefulWidget {
  const PartyMapScreen({Key? key}) : super(key: key);

  @override
  _PartyMapScreenState createState() => _PartyMapScreenState();
}

class _PartyMapScreenState extends State<PartyMapScreen> {
  late WebViewController _controller;
  String _localHtml = '';

  @override
  void initState() {
    super.initState();
    _loadLocalHtml();
  }

  Future<void> _loadLocalHtml() async {
    _localHtml = await rootBundle.loadString('assets/kakao_map.html');
    // _controller가 이미 생성되어 있다면 HTML 내용을 로드
    if (_localHtml.isNotEmpty && _controller != null) {
      _controller.loadHtmlString(_localHtml);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // WebView: 로컬 kakao_map.html 파일을 로드합니다.
          WebView(
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (controller) {
              _controller = controller;
              if (_localHtml.isNotEmpty) {
                _controller.loadHtmlString(_localHtml);
              }
            },
            // 필요하면 JavaScript 채널 설정하여 Flutter와 HTML 간 데이터 주고받기
          ),
          // 중앙에 고정된 위치 마커 아이콘 (사용자가 보는 지도 중심 또는 선택된 위치를 표시)
          const Center(
            child: Icon(
              Icons.location_on,
              size: 50,
              color: Colors.redAccent,
            ),
          ),
          // 왼쪽 상단에 재사용 가능한 CustomBackButton 배치
          const Positioned(
            top: 40,
            left: 16,
            child: CustomBackButton(),
          ),
          // 하단 중앙에 "팟 생성하기" 버튼 배치
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
                // HTML 내 JavaScript 함수 getSelectedDestination()을 호출하여, 사용자가 선택한 위치 정보를 받아옵니다.
                String result = await _controller.evaluateJavascript("getSelectedDestination()");
                print('선택된 위치 정보: $result');
                // 여기서 result를 파싱하여 백엔드 API 호출 등의 후속 처리를 할 수 있습니다.
                // 이후, 팟 생성 페이지로 이동합니다.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PartyCreateScreen(),
                  ),
                );
              },
              child: const Text(
                '팟 생성하기',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}