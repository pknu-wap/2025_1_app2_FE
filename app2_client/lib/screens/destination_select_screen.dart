import 'package:flutter/material.dart';
import 'package:app2_client/screens/destination_map_screen.dart';

class DestinationSelectScreen extends StatelessWidget {
  const DestinationSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          '주소 검색',
          style: TextStyle(fontWeight: FontWeight.bold),
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
            const Text(
              '목적지를\n검색해주세요',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: '지번, 도로명, 건물명으로 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onSubmitted: (value) {
                if (value.isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DestinationMapScreen(
                      initialLat: 37.5665,
                      initialLng: 126.9780,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DestinationMapScreen(
                      initialLat: 37.5665,
                      initialLng: 126.9780,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.my_location),
              label: const Text('현재 위치로 찾기'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '이렇게 검색해 보세요',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('• 도로명 + 건물번호 (위례성대로 2)'),
            const Text('• 건물명 + 번지 (방이동 44-2)'),
            const Text('• 건물명, 아파트명 (반포 자이, 분당 주공 1차)'),
          ],
        ),
      ),
    );
  }
}