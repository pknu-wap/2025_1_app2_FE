// lib/widgets/party_create_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/models/party_create_request.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/providers/auth_provider.dart';

class PartyCreateModal extends StatefulWidget {
  final double startLat, startLng;
  final String startAddress;
  final double destLat, destLng;
  final String destAddress;

  const PartyCreateModal({
    Key? key,
    required this.startLat,
    required this.startLng,
    required this.startAddress,
    required this.destLat,
    required this.destLng,
    required this.destAddress,
  }) : super(key: key);

  @override
  _PartyCreateModalState createState() => _PartyCreateModalState();
}

class _PartyCreateModalState extends State<PartyCreateModal> {
  double _radius = 1000.0;
  int _maxPerson = 3;
  String _option = 'MIXED';

  void _submit() async {
    final token = context.read<AuthProvider>().tokens?.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

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
      await PartyService.createParty(request: req, accessToken: token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파티가 생성되었습니다!')),
      );
      Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파티 생성 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (_, ctl) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: ctl,
          children: [
            const Center(
              child: Text(
                '파티 생성하기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text('출발: ${widget.startAddress}'),
            Text('도착: ${widget.destAddress}'),
            const SizedBox(height: 16),

            Text('반경 (m): ${_radius.toInt()}'),
            Slider(
              min: 100,
              max: 5000,
              divisions: 49,
              value: _radius,
              label: '${_radius.toInt()}',
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('최대 인원'),
                DropdownButton<int>(
                  value: _maxPerson,
                  items: [1, 2, 3, 4]
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n명')))
                      .toList(),
                  onChanged: (v) => setState(() => _maxPerson = v!),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('팟 옵션'),
                DropdownButton<String>(
                  value: _option,
                  items: ['MIXED', 'ONLY']
                      .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o == 'MIXED' ? '혼성' : '동성만')))
                      .toList(),
                  onChanged: (v) => setState(() => _option = v!),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submit,
              child: const Text('생성하기'),
            ),
          ],
        ),
      ),
    );
  }
}