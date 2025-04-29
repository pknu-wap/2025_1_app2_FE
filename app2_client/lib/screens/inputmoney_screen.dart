import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final bool isSelf;

  User({required this.id, required this.name, this.isSelf = false});
}

class RideSplitPage extends StatefulWidget {
  @override
  _RideSplitPageState createState() => _RideSplitPageState();
}

class _RideSplitPageState extends State<RideSplitPage> {
  final List<User> passengers = [
    User(id: '1', name: '성은', isSelf: true),
    User(id: '2', name: '민서'),
    User(id: '3', name: '준용'),
    User(id: '4', name: '채은'),
  ];

  late User currentUser;

  Map<String, String> enteredAmounts = {}; // userId -> amount
  Map<String, List<String>> approvedBy = {}; // userId -> list of approver IDs
  Map<String, TextEditingController> controllers = {}; // userId -> controller

  @override
  void initState() {
    super.initState();
    currentUser = passengers.firstWhere((u) => u.isSelf);
    for (var user in passengers) {
      controllers[user.id] = TextEditingController();
    }
  }

  void updateAmount(String userId, String amount) {
    setState(() {
      enteredAmounts[userId] = amount;
      controllers[userId]?.text = amount;
      approvedBy[userId] = []; // 금액 바뀌면 승인 초기화
    });
  }

  void approveAmount(String targetUserId) {
    final approverId = currentUser.id;
    if (!approvedBy[targetUserId]!.contains(approverId)) {
      setState(() {
        approvedBy[targetUserId]!.add(approverId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('금액 입력 및 승인')),
      body: Column(
        children: [
          // 상단 안내 텍스트
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '하차 시, 그 지점까지의 택시 미터기 요금을 입력해주세요.\n'
                  '그 때 탑승하고 있던 모든 사람들의 동의를 받아야 합니다.\n'
                  '만약, 금액이 모두 입력되지 않았거나, 모두 동의하지 않은 경우에는 거리 비율로 정산됩니다.\n'
                  '타당한 요금 정산을 위해 꼭 입력해주세요.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),

          // 사용자 전환 드롭다운 (시뮬레이션용)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButton<User>(
              value: currentUser,
              onChanged: (User? user) {
                if (user != null) {
                  setState(() {
                    currentUser = user;
                  });
                }
              },
              items: passengers.map((user) {
                return DropdownMenuItem(
                  value: user,
                  child: Text('${user.name}로 보기'),
                );
              }).toList(),
            ),
          ),

          // 리스트 뷰: 사용자별 금액 입력 및 승인
          Expanded(
            child: ListView.builder(
              itemCount: passengers.length,
              itemBuilder: (context, index) {
                final user = passengers[index];
                final userId = user.id;
                final isSelf = currentUser.id == userId;
                final amount = enteredAmounts[userId] ?? '';
                final approvers = approvedBy[userId] ?? [];

                return ListTile(
                  leading: Text(user.name),
                  title: isSelf
                      ? TextField(
                    controller: controllers[userId],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: '금액 입력 (₩)'),
                    onChanged: (val) => updateAmount(userId, val),
                  )
                      : Text(amount.isNotEmpty ? '₩$amount' : '미입력'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isSelf && amount.isNotEmpty)
                        ElevatedButton(
                          onPressed: !approvers.contains(currentUser.id)
                              ? () => approveAmount(userId)
                              : null,
                          child: Text('OK'),
                        ),
                      SizedBox(width: 8),
                      ...approvers.map((id) {
                        final approver = passengers.firstWhere((u) => u.id == id);
                        return Padding(
                          padding: const EdgeInsets.only(left: 2.0),
                          child: CircleAvatar(
                            radius: 12,
                            child: Text(approver.name[0]),
                          ),
                        );
                      }).toList()
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
