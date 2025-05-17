import 'dart:convert';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app2_client/services/fare_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  List<Map<String, dynamic>> users = [];
  bool isBookkeeper = false;

  @override
  void initState() {
    super.initState();
    fetchFareData();
  }

  Future<void> fetchFareData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.jwtToken;
    final myId = authProvider.userId;
    try {
      final baseUrl = dotenv.env['BACKEND_BASE_URL']!;
      final fetchedUsers = await fetchFareResult(
        token: token,
        myId: myId,
        baseUrl: baseUrl,
      );
      setState(() {
        users = fetchedUsers;
      });
    } catch (e) {
      print('정산 데이터 불러오기 실패: $e');
    }
  }

  void updatePaymentStatus(int userId, int stopoverId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.jwtToken;
    final baseUrl = dotenv.env['BACKEND_BASE_URL']!;

    try {
      await confirmPayment(
        token: token,
        partyMemberId: userId,
        stopoverId: stopoverId,
        baseUrl: baseUrl,
      );
      setState(() {
        final user = users.firstWhere((u) => u['id'] == userId);
        user['confirmed'] = true;
      });
    } catch (e) {
      print('결제 상태 업데이트 실패: $e');
    }
  }

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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final bool isMe = user['isMe'] == true;
                final bool isConfirmed = user['confirmed'] == true;
                final String buttonText = isBookkeeper
                    ? (isConfirmed ? '정산완' : '돈받음')
                    : (isConfirmed ? '송금완' : '확인요청');
                // Removed the if-statement that skips rendering rows
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
                      Expanded(
                        child: Row(
                          children: [
                            const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: Text(
                                user['name'],
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                user['fare'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isBookkeeper || isMe)
                        ElevatedButton(
                          onPressed: isBookkeeper
                              ? () {
                                  updatePaymentStatus(user['id'], user['stopoverId']);
                                }
                              : isMe
                                  ? () {
                                      setState(() {
                                        user['confirmed'] = !(user['confirmed'] ?? false);
                                      });
                                    }
                                  : null,
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

// 이슈번호 16