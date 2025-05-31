// lib/screens/destination_select_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:app2_client/screens/destination_map_screen.dart';
import 'package:app2_client/screens/start_map_screen.dart';
import 'package:app2_client/screens//my_page_popup.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
