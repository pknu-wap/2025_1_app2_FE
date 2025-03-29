import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app2_client/widgets/custom_back_button.dart';
// 아래 두 파일은 임시로 만든 페이지 예시입니다.
import 'search_address_screen.dart';
import 'destination_radius_screen.dart';

class DestinationMapScreen extends StatefulWidget {
  const DestinationMapScreen({Key? key}) : super(key: key);

  @override
  _DestinationMapScreenState createState() => _DestinationMapScreenState();
}

class _DestinationMapScreenState extends State<DestinationMapScreen> {
  late WebViewController _controller;

  // 미리 호스팅된 카카오 지도 페이지 URL, 초기 좌표는 쿼리 파라미터로 전달
  final String mapUrl =
      "https://your-hosted-kakao-map-page.com/?lat=37.5665&lng=126.9780";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 전체 화면을 채우는 WebView: 카카오 지도 페이지 로드
          WebView(
            initialUrl: mapUrl,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (controller) {
              _controller = controller;
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
          // 왼쪽 상단에 재사용 가능한 뒤로가기 버튼
          Positioned(
            top: 40,
            left: 16,
            child: CustomBackButton(),
          ),
          // 하단 중앙 "이 위치로 목적지 설정" 버튼
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
                // 웹페이지 내 JavaScript 함수를 호출해 선택한 위치 정보를 가져온다고 가정
                String result = await _controller.evaluateJavascript("getSelectedDestination()");
                print('선택된 위치 정보: $result');
                // 이후 선택된 위치 정보를 백엔드로 보내거나, 다음 페이지로 전환
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