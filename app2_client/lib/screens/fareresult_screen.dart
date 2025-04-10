import 'package:flutter/material.dart';
import '../models/user_model.dart';

class SettlementRequestScreen extends StatefulWidget { // 버튼 상태 바뀜
  final List<UserModel> users;
  final String finalizerEmail;

  const SettlementRequestScreen({
    super.key,
    required this.users,
    required this.finalizerEmail,
  });

  @override
  State<SettlementRequestScreen> createState() => _SettlementRequestScreenState();
}

class _SettlementRequestScreenState extends State<SettlementRequestScreen> {
  final Set<String> confirmedUsers = {}; // 상태 저장용

  void _sendConfirmationRequest(String username) {
    setState(() {
      confirmedUsers.add(username);
    });
    debugPrint('$username 확인 요청 보냄');
  }

  void _confirmAsFinalizer(String username) {
    setState(() {
      confirmedUsers.add(username);
    });
    debugPrint('$username 정산자 확인 완료');
  }

  void _goToNextPage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const Placeholder()));
  }

  void _goToChatPage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const Placeholder()));
  }

  @override
  Widget build(BuildContext context) {
    final bool allConfirmed = true; // TODO: 실제 확인 상태에 따라 조건 나누기

    final testUsers = widget.users.isNotEmpty ? widget.users : [ // 임의 테스트 유저 설정
      UserModel(
        email: 'minseo@email.com',
        name: '민서',
        role: 'a',
        isRegistered: true,
        token: 'dummy-token-1',
        phone: '010-0000-0000',
        age: 25,
        gender: '남',
      ),
      UserModel(
        email: 'final@email.com',
        name: '은호',
        role: 'b',
        isRegistered: true,
        token: 'dummy-token-2',
        phone: '010-1111-1111',
        age: 27,
        gender: '여',
      ),
    ];

    final currentUser = testUsers.firstWhere((user) => user.role == 'a'); // 일반 사용자 기준
    // final currentUser = testUsers.firstWhere((user) => user.role == 'b'); // 최종 정산자 기준
    final currentUserEmail = currentUser.email;
    final isCurrentUserFinalizer = currentUser.role == 'b';

    return Scaffold(
      appBar: AppBar(title: const Center(child: Text('정산 권장 요금 안내'))),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (allConfirmed)
              const Text(
                '자신이 택시를 이용한 거리만큼의 비용을 그 당시 타고 있던 사람들과 나누어서 정산했어요. 최종정산자에게 입금 후 확인 요청 버튼을 누르세요.',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              )
            else
              const Text(
                '미터기 금액이 모두 입력되지 않아, 모두의 거리 비율로 정산되었습니다. 최종정산자에게 입금 후 확인 요청 버튼을 누르세요.',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            const Text(
              '📝 오늘의 정산 내역',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (testUsers.isEmpty)
              const Text('참여한 유저가 없습니다.')
            else
              ...testUsers.map((user) {
                final isFinalizer = user.role == 'b';
                final amount = 8500; // 임의 지정, 나중에 정산 구현 후 받아올 예정
                final isConfirmed = confirmedUsers.contains(user.name);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${user.name} - ${amount}원',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isFinalizer ? FontWeight.bold : FontWeight.normal,
                            color: isFinalizer ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                      if (isCurrentUserFinalizer && !isFinalizer)
                        ElevatedButton(
                          onPressed: isConfirmed ? null : () => _confirmAsFinalizer(user.name),
                          child: Text(isConfirmed ? '입금 완료' : '입금 확인'),
                        )
                      else if (!isCurrentUserFinalizer && user.email == currentUserEmail)
                        ElevatedButton(
                          onPressed: isConfirmed ? null : () => _sendConfirmationRequest(user.name),
                          child: Text(isConfirmed ? '요청 완료' : '확인 요청'),
                        ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 30),
            const Text(
              '\u{1F389} 오늘 내가 아낀 금액은?', // 계산로직 구현 후 금액 표시 예정
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const SizedBox(height: 30),
            const Text(
              '최종정산자가 입금 확인을 완료하면 자동으로 방이 폭파됩니다. 쾌적한 어플 이용을 위해 폭파 후 파티원 평가를 해주세요.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _goToChatPage(context),
                child: const Text('채팅방 이동'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
