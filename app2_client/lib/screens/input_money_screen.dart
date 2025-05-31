import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/services/fare_service.dart';
import 'package:app2_client/providers/auth_provider.dart';

class TaxiFarePage extends StatefulWidget {
  final String partyId;

  const TaxiFarePage({Key? key, required this.partyId}) : super(key: key);

  @override
  State<TaxiFarePage> createState() => _TaxiFarePageState();
}

class _TaxiFarePageState extends State<TaxiFarePage> {
  Map<int, String?> fareInputs = {}; // stopoverId -> 입력된 금액
  Map<int, List<PartyMember>> stopoverGroups = {};
  String? myName;
  PartyDetail? partyDetail;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    myName = auth.user?.name;

    final detail = await PartyService.fetchPartyDetailById(widget.partyId);
    if (detail != null) {
      setState(() {
        partyDetail = detail;
        stopoverGroups = _groupByStopover(detail.members);
        for (var id in stopoverGroups.keys) {
          fareInputs[id] = null;
        }
      });
    }
  }

  Map<int, List<PartyMember>> _groupByStopover(List<PartyMember> members) {
    final map = <int, List<PartyMember>>{};
    for (final m in members) {
      final stopoverId = int.tryParse(m.additionalRole ?? '');
      if (stopoverId != null) {
        map.putIfAbsent(stopoverId, () => []).add(m);
      }
    }
    return map;
  }

  bool _isMyGroup(int stopoverId) {
    return stopoverGroups[stopoverId]?.any((m) => m.name == myName) ?? false;
  }

  void _submitFare(int stopoverId, TextEditingController controller) {
    final input = int.tryParse(controller.text);
    if (input != null) {
      setState(() {
        fareInputs[stopoverId] = input.toString();
      });
      controller.clear();
    }
  }

  Future<void> _submitAllFares() async {
    await FareService.submitFare(widget.partyId, fareInputs);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('요금 제출 완료')));
  }

  @override
  Widget build(BuildContext context) {
    if (partyDetail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('택시비 입력')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final stopoverId in stopoverGroups.keys)
            _buildGroupBox(stopoverId, stopoverGroups[stopoverId]!),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitAllFares,
            child: const Text('요금 전체 제출'),
          )
        ],
      ),
    );
  }

  Widget _buildGroupBox(int stopoverId, List<PartyMember> members) {
    final isMine = _isMyGroup(stopoverId);
    final controller = TextEditingController();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정차 지점 $stopoverId - ${members.map((m) => m.name).join(', ')}'),
            const SizedBox(height: 8),
            if (isMine && fareInputs[stopoverId] == null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '요금 입력'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _submitFare(stopoverId, controller),
                    child: const Text('입력'),
                  )
                ],
              ),
            ] else if (fareInputs[stopoverId] != null) ...[
              Text('입력된 요금: ${fareInputs[stopoverId]} 원'),
            ]
          ],
        ),
      ),
    );
  }
}
