import 'package:flutter/material.dart';
import 'package:app2_client/models/party_create_request.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/screens/my_party_screen.dart';

class PartyCreateModal extends StatefulWidget {
  final double startLat, startLng;
  final String startAddress;
  final double destLat, destLng;
  final String destAddress;

  const PartyCreateModal({
    super.key,
    required this.startLat,
    required this.startLng,
    required this.startAddress,
    required this.destLat,
    required this.destLng,
    required this.destAddress,
  });

  @override
  State<PartyCreateModal> createState() => _PartyCreateModalState();
}

class _PartyCreateModalState extends State<PartyCreateModal> {
  double _radius = 1000; // m
  int _maxPerson = 3;
  String _option = 'MIXED';
  final _descController = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final req = PartyCreateRequest(
      partyStart: Location(
        address: widget.startAddress,
        lat: widget.startLat,
        lng: widget.startLng,
      ),
      partyDestination: Location(
        address: widget.destAddress,
        lat: widget.destLat,
        lng: widget.destLng,
      ),
      partyRadius: _radius,
      partyMaxPerson: _maxPerson,
      partyOption: _option,
    );

    try {
      final PartyDetail party = await PartyService.createParty(request: req);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyPartyScreen(
            party: party,
            description: _descController.text.trim(),
          ),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파티가 생성되었습니다')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파티 생성 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('파티 생성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Align(alignment: Alignment.centerLeft, child: Text('출발: ${widget.startAddress}')),
            Align(alignment: Alignment.centerLeft, child: Text('도착: ${widget.destAddress}')),
            const Divider(height: 32),

            // 설명 입력란
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "파티 설명 (선택)",
                hintText: "예) 서면까지 갈 사람 구해요~!",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 반경
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('반경: ${(_radius / 1000).toStringAsFixed(1)} km'),
                Expanded(
                  child: Slider(
                    min: 1000, max: 10000, divisions: 9,
                    value: _radius,
                    label: '${(_radius / 1000).toStringAsFixed(1)} km',
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
              ],
            ),

            // 최대 인원
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('최대 인원'),
                DropdownButton<int>(
                  value: _maxPerson,
                  items: [1,2,3,4].map((n) => DropdownMenuItem(
                    value: n, child: Text('$n명'),
                  )).toList(),
                  onChanged: (v) => setState(() => _maxPerson = v!),
                ),
              ],
            ),

            // 옵션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('팟 옵션'),
                DropdownButton<String>(
                  value: _option,
                  items: const [
                    DropdownMenuItem(value: 'MIXED', child: Text('혼성')),
                    DropdownMenuItem(value: 'ONLY_MALE', child: Text('남성만')),
                    DropdownMenuItem(value: 'ONLY_FEMALE', child: Text('여성만')),
                  ],
                  onChanged: (v) => setState(() => _option = v!),
                ),
              ],
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('생성하기'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}