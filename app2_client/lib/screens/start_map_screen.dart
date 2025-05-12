// lib/screens/start_map_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class StartMapScreen extends StatefulWidget {
  const StartMapScreen({super.key});

  @override
  State<StartMapScreen> createState() => _StartMapScreenState();
}

class _StartMapScreenState extends State<StartMapScreen> {
  WebViewController? _controller;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    _setCurrentLocationAndLoadMap();
  }

  Future<void> _setCurrentLocationAndLoadMap() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          throw Exception('위치 권한이 없습니다.');
        }
      }

      Position pos = await Geolocator.getCurrentPosition();
      await _initWebView(pos.latitude, pos.longitude);
    } catch (e) {
      await _initWebView(37.5665, 126.9780); // 서울 시청 fallback
    }
  }

  Future<void> _initWebView(double lat, double lng) async {
    var html = await rootBundle.loadString('assets/kakao_map.html');
    html = html
        .replaceAll('{{KAKAO_JS_KEY}}', dotenv.env['KAKAO_JS_KEY'] ?? '')
        .replaceAll('{{LAT}}', lat.toString())
        .replaceAll('{{LNG}}', lng.toString());

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _pageLoaded = true),
        ),
      )
      ..loadHtmlString(html, baseUrl: 'about:blank');

    setState(() => _controller = controller);
    print('[DEBUG] KAKAO_HTML:\n$html');
  }

  Future<void> _onConfirmPressed() async {
    if (_controller == null) return;
    try {
      final raw = await _controller!.runJavaScriptReturningResult('getSelectedDestination()');
      dynamic result = raw;
      final first = result is String ? jsonDecode(result) : result;
      final decoded = first is String ? jsonDecode(first) : first;
      final coord = decoded as Map<String, dynamic>;
      final lat = coord['lat'] as double;
      final lng = coord['lng'] as double;

      Navigator.pop(context, {
        'lat': lat,
        'lng': lng,
        'address': '지도에서 선택한 출발지',
      });
    } catch (e) {
      debugPrint('지도 선택 에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          WebViewWidget(controller: _controller!),
          const Center(
            child: Icon(Icons.location_on, size: 56, color: Colors.redAccent),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _pageLoaded ? _onConfirmPressed : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF003366),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _pageLoaded ? '이 위치로 출발지 설정' : '지도 로딩 중...',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}