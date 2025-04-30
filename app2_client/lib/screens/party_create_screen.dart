// lib/screens/party_create_screen.dart
import 'package:flutter/material.dart';

class PartyCreateScreen extends StatelessWidget {
  // 1) destLat, destLng 필드 추가
  final double destLat;
  final double destLng;

  // 2) required 파라미터로 받도록 생성자 수정
  const PartyCreateScreen({
    Key? key,
    required this.destLat,
    required this.destLng,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("팟 생성하기"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("선택된 목적지 위도: $destLat", style: TextStyle(fontSize: 16)),
            Text("선택된 목적지 경도: $destLng", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "팟 생성하기 폼을\n여기에 구현하세요",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}