// lib/screens/party_map_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app2_client/widgets/custom_back_button.dart';
import 'package:app2_client/screens/party_create_screen.dart';

class PartyMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const PartyMapScreen({
    Key? key,
    required this.initialLat,
    required this.initialLng,
  }) : super(key: key);

  @override
  State<PartyMapScreen> createState() => _PartyMapScreenState();
}

class _PartyMapScreenState extends State<PartyMapScreen> {
  late final WebViewController _controller;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initControllerAndLoadHtml();
  }

  Future<void> _initControllerAndLoadHtml() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) {
          setState(() => _pageLoaded = true);
        }),
      );

    // 1) HTML 자산 읽기
    String html = await rootBundle.loadString('assets/kakao_map.html');

    // 2) 플레이스홀더 치환: env 키와 초기 위경도
    html = html
        .replaceAll('{{KAKAO_JS_KEY}}', dotenv.env['KAKAO_JS_KEY'] ?? '')
        .replaceAll('{{LAT}}', widget.initialLat.toString())
        .replaceAll('{{LNG}}', widget.initialLng.toString());

    // 3) HTML 로드 (baseUrl은 about:blank가 안정적입니다)
    await _controller.loadHtmlString(html, baseUrl: 'about:blank');
  }

  Future<void> _onConfirmPressed() async {
    try {
      final raw = await _controller.runJavaScriptReturningResult(
        'getSelectedDestination()',
      );
      final coord = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final lat = coord['lat'] as double;
      final lng = coord['lng'] as double;
      debugPrint('선택된 위치: lat=$lat, lng=$lng');

      // destLat/destLng를 PartyCreateScreen에 넘겨줍니다
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PartyCreateScreen(
            destLat: lat,
            destLng: lng,
          ),
        ),
      );
    } catch (e) {
      debugPrint('지도 조작 에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ① WebView
          WebViewWidget(controller: _controller),

          // ② 중앙 핀
          const Center(
            child: Icon(Icons.location_on, size: 56, color: Colors.redAccent),
          ),

          // ③ 뒤로가기
          const Positioned(top: 40, left: 16, child: CustomBackButton()),

          // ④ 팟 생성 버튼
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _pageLoaded ? _onConfirmPressed : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _pageLoaded ? '팟 생성하기' : '지도 로딩 중...',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}