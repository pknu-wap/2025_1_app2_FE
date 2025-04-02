import 'package:flutter/material.dart';
import 'package:app2_client/screens/destination_map_screen.dart';

class DestinationSelectScreen extends StatelessWidget {
  const DestinationSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 dummy 검색 결과 목록
    final List<String> searchResults = [
      '서울특별시 강남구 테헤란로 123',
      '서울특별시 종로구 종로 1',
      '부산광역시 해운대구 센텀중앙로 200',
    ];

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
              // 사용자가 검색어를 입력 후 엔터를 누르면 MapScreen으로 이동하며 dummy 좌표 전달
              onSubmitted: (value) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DestinationMapScreen(
                      initialLat: 37.567,
                      initialLng: 126.978,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                // "현재 위치로 찾기" 버튼 누르면 MapScreen으로 이동 (dummy 좌표 전달)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DestinationMapScreen(
                      initialLat: 37.567,
                      initialLng: 126.978,
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
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(searchResults[index]),
                    onTap: () {
                      // 사용자가 리스트의 주소를 선택하면 MapScreen으로 이동하며 dummy 좌표 전달
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DestinationMapScreen(
                            initialLat: 37.567,
                            initialLng: 126.978,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}