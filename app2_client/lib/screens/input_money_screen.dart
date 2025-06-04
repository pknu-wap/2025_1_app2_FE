import 'package:flutter/material.dart';
import 'package:app2_client/models/stopover_model.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/providers/auth_provider.dart';

class TaxiFarePage extends StatefulWidget {
  final String partyId;
  final List<StopoverResponse> stopoverList;
  final String currentUserEmail;

  const TaxiFarePage({
    super.key,
    required this.partyId,
    required this.stopoverList,
    required this.currentUserEmail,
  });

  @override
  State<TaxiFarePage> createState() => _TaxiFarePageState();
}

class _TaxiFarePageState extends State<TaxiFarePage> {
  final TextEditingController _fareController = TextEditingController();
  late String myName;
  late List<String> allUsers;
  late Map<int, List<String>> passengers;
  late Map<int, List<String>> approvals;
  Map<int, String?> fareInputs = {};
  bool _socketSubscribed = false;

  String maskName(String name) {
    if (name.length <= 1) return name;
    return name[0] + '*' + name.substring(name.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _connectAndSubscribe();
  }

  void _initializeData() {
    final currentUser = widget.stopoverList
        .expand((s) => s.partyMembers)
        .firstWhere((m) => m.email == widget.currentUserEmail);
    myName = currentUser.name;

    allUsers = widget.stopoverList
        .expand((s) => s.partyMembers)
        .map((m) => m.name)
        .toSet()
        .toList();

    passengers = {};
    for (int i = 0; i < widget.stopoverList.length; i++) {
      passengers[i + 1] = widget.stopoverList[i].partyMembers.map((m) => m.name).toList();
    }

    approvals = { for (int i = 1; i <= widget.stopoverList.length; i++) i: [] };
    fareInputs = { for (var group in passengers.keys) group: null };
  }

  void submitFare(int groupNumber) async {
    final input = int.tryParse(_fareController.text);
    if (input == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    try {
      await PartyService.submitFare(
        partyId: widget.partyId,
        stopoverId: widget.stopoverList[groupNumber - 1].stopover.id,
        fare: input,
        accessToken: token,
      );

      setState(() {
        fareInputs[groupNumber] = input.toString();
        _fareController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('요금이 입력되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('요금 입력 실패: $e')));
    }
  }

  Future<void> approveFare(int groupNumber) async {
    final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    try {
      await PartyService.approveFare(
        partyId: widget.partyId,
        stopoverId: widget.stopoverList[groupNumber - 1].stopover.id,
        accessToken: token,
      );

      setState(() {
        if (!approvals[groupNumber]!.contains(myName)) {
          approvals[groupNumber]!.add(myName);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('요금이 승인되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('요금 승인 실패: $e')));
    }
  }

  void _handleSocketMessage(Map<String, dynamic> msg) {
    final eventType = msg['eventType'];
    final stopoverId = msg['stopover_id'] as int?;
    if (stopoverId == null) return;

    final groupNumber = widget.stopoverList.indexWhere((s) => s.stopover.id == stopoverId) + 1;
    if (groupNumber == 0) return;

    if (eventType == 'FARE_INPUT') {
      final fare = msg['fare'] as int?;
      if (fare != null) {
        setState(() {
          fareInputs[groupNumber] = fare.toString();
        });
      }
    } else if (eventType == 'FARE_APPROVAL') {
      final memberName = msg['member_name'] as String?;
      if (memberName != null) {
        setState(() {
          if (!approvals[groupNumber]!.contains(memberName)) {
            approvals[groupNumber]!.add(memberName);
          }
        });
      }
    }
  }

  void _connectAndSubscribe() {
    final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    SocketService.connect(token, onConnect: () {
      if (!_socketSubscribed) {
        SocketService.subscribePartyMembers(
          partyId: int.parse(widget.partyId),
          onMessage: _handleSocketMessage,
        );
        _socketSubscribed = true;
      }
    });
  }

  @override
  void dispose() {
    _fareController.dispose();
    SocketService.disconnect();
    super.dispose();
  }

  bool isMyGroup(int group) => passengers[group]!.contains(myName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('택시비 입력하기', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  '하차 시, 그 지점까지의 택시 미터기 요금을 입력해주세요.\n그 때 탑승하고 있던 모든 사람들의 동의를 받아야 합니다.\n만약, 금액이 모두 입력되지 않았거나,\n모두 동의하지 않은 경우에는 거리 비율로 정산됩니다..',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 10),
                Text('타당한 요금 정산을 위해 꼭 입력해주세요 !', style: TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(2, 4))],
            ),
            child: Column(
              children: passengers.keys.map((group) {
                final names = passengers[group]!;
                final approved = approvals[group]!;
                final color = [Colors.amber, Colors.green, Colors.blue][group - 1];
                return buildPassengerRow(group, names, approved, color);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPassengerRow(int group, List<String> names, List<String> approvers, Color color) {
    final isMine = isMyGroup(group);
    final hasInput = fareInputs[group] != null;
    final needsApproval = passengers.entries
        .where((e) => e.key > group)
        .expand((e) => e.value)
        .contains(myName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Image.asset('assets/icons/marker_$group.png', width: 28, height: 32),
          const SizedBox(width: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: Colors.white,
            child: Text(names.map(maskName).join(', '), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 4),
          if (isMine && !hasInput)
            Container(
              padding: const EdgeInsets.only(left: 15, top: 3, right: 3, bottom: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 20,
                    child: TextField(
                      controller: _fareController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '요금',
                        border: UnderlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 30,
                    width: 30,
                    child: ElevatedButton(
                      onPressed: () => submitFare(group),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text('입력', style: TextStyle(fontSize: 9, color: Colors.black)),
                    ),
                  ),
                ],
              ),
            )
          else if (hasInput) ...[
            Text('${fareInputs[group]} 원', style: const TextStyle(fontSize: 13)),
            if (needsApproval && !approvers.contains(myName))
              IconButton(
                icon: const Icon(Icons.check_circle_outline, size: 20),
                onPressed: () => approveFare(group),
                color: Colors.green,
              ),
          ],
          const Spacer(),
          Wrap(
            spacing: 6,
            children: approvers.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(maskName(name), style: TextStyle(color: color, fontSize: 12)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}