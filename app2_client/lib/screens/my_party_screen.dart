import 'package:flutter/material.dart';
import '../models/party_detail_model.dart';

class MyPartyScreen extends StatelessWidget {
  final PartyDetail party;

  const MyPartyScreen({super.key, required this.party});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 파티')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 목적지 카드
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('목적지', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(party.destAddress),
                  const SizedBox(height: 12),
                  const Center(
                    child: Icon(Icons.location_on, size: 48, color: Colors.amber),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 설명
            const Text(
              '서면까지 갈 사람 구해요 ~! (간단한 설명)',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),

            // 해시태그
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _tag('#${party.maxPerson}인팟'),
                _tag(party.partyOption == 'MIXED' ? '#혼성' : '#동성만'),
                _tag('#친절'),
                _tag('#시간엄수'),
              ],
            ),
            const SizedBox(height: 16),

            // 방장 정보
            Text(
              '방장 평점: 3.2',
              style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Divider(),

            // 파티원 목록
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('파티원', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('모집중 ${party.members.length} / ${party.maxPerson}명'),
              ],
            ),
            const SizedBox(height: 12),
            ...party.members.map((m) => Card(
              elevation: 1,
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.grey),
                title: Text(m.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('목적지 서면 삼정타워'), // 추후 동적으로 교체 가능
                    Text('평점 3.5'),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),

            // 채팅방 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                child: const Text('파티원 채팅방 가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}