import 'package:flutter/material.dart';
import 'package:app2_client/models/stopover_model.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/services/payment_service.dart';
import 'package:app2_client/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/models/payment_info_model.dart';

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
  List<PaymentMemberInfo>? _paymentInfo;
  bool _isBookkeeper = false;

  String maskName(String name) {
    if (name.length <= 1) return name;
    return name[0] + '*' + name.substring(name.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _connectAndSubscribe();
    _checkBookkeeperRole();
  }

  void _checkBookkeeperRole() {
    final currentUser = widget.stopoverList
        .expand((s) => s.partyMembers)
        .firstWhere((m) => m.email == widget.currentUserEmail);
    _isBookkeeper = currentUser.role == 'BOOKKEEPER' || 
                    (currentUser.role == 'HOST' && currentUser.additionalRole == 'BOOKKEEPER');
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

    if (eventType == 'PARTY_UPDATE') {
      setState(() {
        _initializeData();
      });
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

  Future<void> confirmPayment(int groupNumber, String memberName) async {
    final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    if (!_isBookkeeper) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정산자(BOOKKEEPER) 권한이 필요합니다.')),
      );
      return;
    }

    try {
      final stopover = widget.stopoverList[groupNumber - 1];
      final member = stopover.partyMembers.firstWhere((m) => m.name == memberName);
      
      final result = await PaymentService.confirmPayment(
        partyId: widget.partyId,
        partyMemberId: member.id,
        stopoverId: stopover.stopover.id,
        accessToken: token,
      );

      setState(() {
        _paymentInfo = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요금 승인이 완료되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요금 승인 처리 중 오류가 발생했습니다: $e')),
      );
    }
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
          if (_isBookkeeper)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '정산자(BOOKKEEPER) 권한으로 요금 승인이 가능합니다.',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  '하차 시, 그 지점까지의 택시 미터기 요금을 입력해주세요.\n그 때 탑승하고 있던 모든 사람들의 동의를 받아야 합니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_paymentInfo != null) ...[
                  const Text('결제 현황', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._paymentInfo!.map((info) => Card(
                    child: ListTile(
                      title: Text(info.memberInfo.name),
                      subtitle: Text(
                        '기본요금: ${info.paymentInfo.baseFare}원\n'
                        '최종요금: ${info.paymentInfo.finalFare}원'
                      ),
                      trailing: Icon(
                        info.paymentInfo.isPaid ? Icons.check_circle : Icons.pending,
                        color: info.paymentInfo.isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                  )).toList(),
                  const SizedBox(height: 20),
                ],
                ...passengers.keys.map((group) {
                  final names = passengers[group]!;
                  final approved = approvals[group]!;
                  final color = [Colors.amber, Colors.green, Colors.blue][group - 1];
                  return buildPassengerRow(group, names, approved, color);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPassengerRow(int group, List<String> names, List<String> approvers, Color color) {
    final isMine = isMyGroup(group);
    final hasInput = fareInputs[group] != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/icons/marker_$group.png', width: 28, height: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        names.map((name) => maskName(name)).join(', '),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (hasInput)
                        Text(
                          '입력된 요금: ${fareInputs[group]}원',
                          style: const TextStyle(color: Colors.blue),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isBookkeeper && hasInput)
              Wrap(
                spacing: 8,
                children: names.map((name) {
                  final memberInfo = _paymentInfo?.firstWhere(
                    (info) => info.memberInfo.name == name,
                    orElse: () => PaymentMemberInfo(
                      memberInfo: PartyMemberInfo(
                        id: 0,
                        name: name,
                        email: '',
                        gender: '',
                        role: '',
                        additionalRole: '',
                      ),
                      paymentInfo: PaymentInfo(
                        stopoverId: 0,
                        baseFare: 0,
                        finalFare: 0,
                        isPaid: false,
                      ),
                    ),
                  );

                  final isPaid = memberInfo?.paymentInfo.isPaid ?? false;

                  return ActionChip(
                    label: Text(maskName(name)),
                    avatar: Icon(
                      isPaid ? Icons.check_circle : Icons.pending,
                      color: isPaid ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                    onPressed: isPaid ? null : () => confirmPayment(group, name),
                  );
                }).toList(),
              ),
            if (isMine && !hasInput)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fareController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '요금을 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => submitFare(group),
                      child: const Text('입력'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}