import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:app2_client/screens/destination_map_screen.dart';
import 'package:app2_client/screens/start_map_screen.dart';
import 'my_page_popup.dart';

// [추가됨] 웹소켓 서비스 및 SharedPreferences import
import 'package:app2_client/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DestinationSelectScreen extends StatefulWidget {
  const DestinationSelectScreen({Key? key}) : super(key: key);

  @override
  State<DestinationSelectScreen> createState() => _DestinationSelectScreenState();
}

class _DestinationSelectScreenState extends State<DestinationSelectScreen> {
  double? _departureLat;
  double? _departureLng;
  String? _departureAddress;
  final TextEditingController _destController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 화면이 준비되면 진단용 웹소켓 연결 테스트를 시작합니다.
    _initializeAndConnectSocketWithDelay();
  }

  // [수정됨] SharedPreferences에서 토큰을 가져와 연결을 시도하는 진단용 함수
  Future<void> _initializeAndConnectSocketWithDelay() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // --- 진단 시작 ---
      print("⏰ [진단] 웹소켓 연결 전 2초간 강제 대기 시작...");
      await Future.delayed(const Duration(seconds: 2));
      print("⏰ [진단] 대기 완료. 이제 웹소켓 연결을 시작합니다.");
      // --- 진단 끝 ---

      try {
        // [수정됨] SharedPreferences에서 직접 accessToken을 가져옵니다.
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('accessToken');

        if (accessToken != null && accessToken.isNotEmpty) {
          await SocketService.connect(accessToken, onConnect: () {
            print("✅ [진단] 강제 지연 후 웹소켓 연결 성공!");
          });
        } else {
          print("🚨 [진단] SharedPreferences에서 accessToken을 찾을 수 없습니다.");
        }
      } catch (e) {
        print("🚨 [진단] 강제 지연 후 웹소켓 연결 중 오류 발생: $e");
      }
    });
  }

  Future<void> _selectStartFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StartMapScreen()),
    );

    if (result != null && result is Map) {
      setState(() {
        _departureLat = result['lat'];
        _departureLng = result['lng'];
        _departureAddress = result['address'];
      });
    }
  }

  Future<void> _onDestSubmitted(String value) async {
    if (_departureLat == null || _departureLng == null) {
      _showError('먼저 출발지를 설정해주세요.');
      return;
    }
    if (value.trim().isEmpty) return;

    try {
      final locations = await locationFromAddress(value);
      if (locations.isEmpty) {
        _showError('해당 주소를 찾을 수 없습니다.');
        return;
      }
      final dest = locations.first;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DestinationMapScreen(
            initialLat: dest.latitude,
            initialLng: dest.longitude,
            initialAddress: value,
            startLat: _departureLat!,
            startLng: _departureLng!,
            startAddress: _departureAddress!,
          ),
        ),
      );
    } catch (e) {
      _showError('목적지 변환 중 오류: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '출발지 및 목적지 설정',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            iconSize: 50.0,
            color: Colors.black38,
            onPressed: () {
              MyPagePopup.show(context);
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. 출발지를 설정해주세요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _selectStartFromMap,
              icon: const Icon(Icons.map),
              label: const Text('지도에서 출발지 설정'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
              ),
            ),
            if (_departureAddress != null) ...[
              const SizedBox(height: 10),
              Text('출발지: $_departureAddress'),
              const Divider(height: 32),

              const Text(
                '2. 목적지를 입력해주세요',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _destController,
                decoration: InputDecoration(
                  hintText: '지번, 도로명, 건물명으로 검색',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: _onDestSubmitted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}