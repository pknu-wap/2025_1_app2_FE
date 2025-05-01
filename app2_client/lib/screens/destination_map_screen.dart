// lib/screens/destination_map_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app2_client/widgets/custom_back_button.dart';
import 'package:app2_client/screens/party_map_screen.dart';

class DestinationMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String initialAddress;

  const DestinationMapScreen({
    Key? key,
    required this.initialLat,
    required this.initialLng,
    required this.initialAddress,
  }) : super(key: key);

  @override
  _DestinationMapScreenState createState() => _DestinationMapScreenState();
}

class _DestinationMapScreenState extends State<DestinationMapScreen> {
  WebViewController? _controller;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    var html = await rootBundle.loadString('assets/kakao_map.html');
    html = html
        .replaceAll('{{KAKAO_JS_KEY}}', dotenv.env['KAKAO_JS_KEY'] ?? '')
        .replaceAll('{{LAT}}', widget.initialLat.toString())
        .replaceAll('{{LNG}}', widget.initialLng.toString());

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // _controller 에 할당된 이후이므로 안전하게 호출 가능
            _controller?.runJavaScript('map.setLevel(2);');
            setState(() => _pageLoaded = true);
          },
        ),
      )
      ..loadHtmlString(html, baseUrl: 'about:blank');

    setState(() => _controller = controller);
  }

  Future<void> _onConfirmPressed() async {
    if (_controller == null) return;
    try {
      final raw = await _controller!
          .runJavaScriptReturningResult('getSelectedDestination()');
      final coord = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final lat = coord['lat'] as double;
      final lng = coord['lng'] as double;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PartyMapScreen(
            initialLat: lat,
            initialLng: lng,
            initialAddress: widget.initialAddress,
          ),
        ),
      );
    } catch (e) {
      debugPrint('지도 조작 중 에러: $e');
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
            child: Icon(Icons.location_on,
                size: 56, color: Colors.redAccent),
          ),
          const Positioned(
            top: 40,
            left: 16,
            child: CustomBackButton(),
          ),
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
                _pageLoaded ? '이 위치로 목적지 설정' : '지도 로딩 중...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}