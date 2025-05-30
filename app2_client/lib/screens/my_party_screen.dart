import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/services/socket_service.dart';
import 'package:app2_client/services/party_service.dart';

class MyPartyScreen extends StatefulWidget {
  final PartyDetail party;
  final String? description;

  const MyPartyScreen({
    super.key,
    required this.party,
    this.description,
  });

  @override
  State<MyPartyScreen> createState() => _MyPartyScreenState();
}

class _MyPartyScreenState extends State<MyPartyScreen> {
  late PartyDetail party;
  String? _desc;
  bool _editingDesc = false;
  final _descController = TextEditingController();
  List<dynamic> joinRequests = []; // 생략: JoinRequest 모델로 변환 가능

  @override
  void initState() {
    super.initState();
    party = widget.party;
    _desc = widget.description ?? '';
    _descController.text = _desc!;
    _subscribeSocket();
  }

  void _subscribeSocket() {
    final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;
    SocketService.connect(token);
    SocketService.subscribe(
      topic: "/sub/party/${party.partyId}",
      onMessage: (msg) async {
        // 생략: JOIN_REQUEST 처리
        if (msg['eventType'] == 'MEMBER_JOIN' || msg['eventType'] == 'PARTY_UPDATE') {
          final updated = await PartyService.fetchPartyDetailById(party.partyId.toString());
          setState(() => party = updated);
        }
      },
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    SocketService.disconnect();
    super.dispose();
  }

  void _saveDesc() {
    setState(() {
      _desc = _descController.text.trim();
      _editingDesc = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 파티')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _destinationCard(party.destAddress),
            const SizedBox(height: 16),

            // 설명 출력 및 수정
            _editingDesc
                ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '설명을 입력하세요',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _saveDesc,
                ),
              ],
            )
                : Row(
              children: [
                Expanded(
                  child: Text(
                    _desc!.isEmpty ? '설명을 추가하세요' : _desc!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => setState(() => _editingDesc = true),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _tag('#${party.maxPerson}인팟'),
                _tag(party.partyOption == 'MIXED' ? '#혼성' : '#동성만'),
              ],
            ),

            // 이하 기존 파티원 리스트, 참여 요청 처리 UI 등...
          ],
        ),
      ),
    );
  }

  Widget _destinationCard(String address) => Container(
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
        Text(address),
        const SizedBox(height: 12),
        const Center(child: Icon(Icons.location_on, size: 48, color: Colors.amber)),
      ],
    ),
  );

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}