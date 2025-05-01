// lib/screens/destination_select_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:app2_client/screens/destination_map_screen.dart';

class DestinationSelectScreen extends StatefulWidget {
  const DestinationSelectScreen({Key? key}) : super(key: key);

  @override
  State<DestinationSelectScreen> createState() =>
      _DestinationSelectScreenState();
}

class _DestinationSelectScreenState extends State<DestinationSelectScreen> {
  double? _departureLat;
  double? _departureLng;
  String? _departureAddress;
  final TextEditingController _destController = TextEditingController();

  Future<void> _setCurrentLocation() async {
    // 1) 권한 체크/요청
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 거부되었습니다.')),
        );
        return;
      }
    }
    if (perm == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앱 설정에서 위치 권한을 허용해주세요.')),
      );
      return;
    }

    // 2) GPS 현재위치 가져오기
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 3) 리버스 지오코딩 (주소 문자열)
    String address;
    try {
      var places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      var p = places.first;
      address = '${p.street}, ${p.locality}, ${p.country}';
    } catch (_) {
      address = '현재 위치';
    }

    setState(() {
      _departureLat = pos.latitude;
      _departureLng = pos.longitude;
      _departureAddress = address;
    });
  }

  Future<void> _onDestSubmitted(String value) async {
    if (_departureLat == null || _departureLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 출발지를 설정해주세요.')),
      );
      return;
    }
    if (value.trim().isEmpty) return;

    try {
      // 1) 텍스트 주소 → 좌표 변환
      final locations = await locationFromAddress(value);
      if (locations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 주소를 찾을 수 없습니다.')),
        );
        return;
      }
      final dest = locations.first;

      // 2) DestinationMapScreen으로 이동 (목적지 정보 전달)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DestinationMapScreen(
            initialLat: dest.latitude,
            initialLng: dest.longitude,
            initialAddress: value, // 입력된 목적지 문자열
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목적지 변환 중 오류: $e')),
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
          '주소 검색',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (_departureAddress != null) ...[
            //   const SizedBox(height: 8),
            //   Text(
            //     '설정된 출발지: $_departureAddress',
            //     style: const TextStyle(fontSize: 14, color: Colors.black54),
            //   ),
            // ],

            // 2) 목적지 텍스트 입력
            const Text(
              '목적지를\n검색해주세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _destController,
              decoration: InputDecoration(
                hintText: '지번, 도로명, 건물명으로 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
              ),
              onSubmitted: _onDestSubmitted,
            ),

            const SizedBox(height: 15),
            // const Text(
            //   '예시: 위례성대로 2, 방이동 44-2, 반포 자이',
            //   style: TextStyle(color: Colors.black38),
            // ),
            // 1) 출발지 설정 버튼
            ElevatedButton.icon(
              onPressed: _setCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text(
                '현재 위치로 찾기',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}