import 'package:flutter/material.dart';

class FareResultScreen extends StatefulWidget {
  /// 결산자 페이지 여부 (true면 결산자, false면 일반 유저)
  final bool isBookkeeper;

  const FareResultScreen.bookkeeper({Key? key})
      : isBookkeeper = true,
        super(key: key);

  const FareResultScreen.user({Key? key})
      : isBookkeeper = false,
        super(key: key);

  @override
  _FareResultScreenState createState() => _FareResultScreenState();
}

class _FareResultScreenState extends State<FareResultScreen> {
  // 임시 파티원 데이터
  final List<Map<String, dynamic>> users = [
    {'name': '사용자 A', 'fare': '₩3,000', 'confirmed': false},
    {'name': '사용자 B', 'fare': '₩2,500', 'confirmed': false},
    {'name': '사용자 C', 'fare': '₩3,800', 'confirmed': false},
    {'name': '사용자 D', 'fare': '₩2,900', 'confirmed': false},
  ];
  @override
  Widget build(BuildContext context) {

    // 임시 아낀 금액
    final String goodgood = '12,200';

    return Scaffold(
      appBar: AppBar(
        title: const Text('정산하기'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: const Text(
                '본인이 타고 간 거리만큼의 비용을 그 당시 함께 \n타고 있던 사람들과 나누어서 내도록 정산했어요 :) \n최종 정산자에게 입금 후 확인 요청 버튼을 누르세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: const Text(
                '최종 정산자는 모두의 입금 내역을 확인하고, \n입급 확인 버튼을 눌러주세요. \n확인이 완료되면 자동으로 이 파티는 폭파됩니다. \n쾌적한 어플 이용을 위해 파티원 평가를 해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final bool isConfirmed = user['confirmed'] == true;
                final String buttonText = widget.isBookkeeper
                    ? (isConfirmed ? '돈받음' : '정산완')
                    : (isConfirmed ? '송금완' : '확인요청함');
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user['name'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        user['fare'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            user['confirmed'] = !(user['confirmed'] ?? false);
                          });
                        },
                        child: Text(buttonText),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 0),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[200],
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('오늘'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$goodgood',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Text('원을 아꼈어요!'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
