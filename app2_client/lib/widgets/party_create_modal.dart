// lib/screens/party_create_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/models/party_create_request.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/screens/my_party_screen.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/models/party_option.dart';

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
  double _radius = 1000; // meters
  int _maxPerson = 3;
  PartyOption _option = PartyOption.mixed;
  final _descController = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);

    // 1) 요청 바디로 보낼 PartyCreateRequest 객체 생성
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
      // 2) AuthProvider에서 JWT를 가져와서 헤더에 추가
      final token = Provider.of<AuthProvider>(context, listen: false)
          .tokens
          ?.accessToken;
      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      // 3) 실제 파티 생성 API 호출
      final PartyDetail party = await PartyService.createParty(
        request: req,
        accessToken: token,
      );

      // 4) 디버그용으로 "생성 완료" 로그 찍기
      debugPrint('파티 생성 성공: partyId=${party.partyId}, dest=${party.destAddress}');

      // 5) 모달을 닫고 MyPartyScreen으로 이동
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

      // 6) 화면 하단에 스낵바 띄우기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파티가 생성되었습니다')),
      );
    } catch (e) {
      debugPrint('파티 생성 실패: $e');
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
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final token = auth.tokens?.accessToken;
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
                // ─────────────────────────────────────────────────────────────────────────
                // (Drag Handle 표시용)
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const Text('파티 생성',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // 출발/도착 정보 표시
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

                // ───────── 반경 설정 ─────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('반경: ${(_radius / 1000).toStringAsFixed(1)} km'),
                    Expanded(
                      child: Slider(
                        min: 1000,
                        max: 10000,
                        divisions: 9,
                        value: _radius,
                        label: '${(_radius / 1000).toStringAsFixed(1)} km',
                        onChanged: (v) => setState(() => _radius = v),
                      ),
                    ),
                  ],
                ),

                // ───────── 최대 인원 ─────────
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

                // ───────── 옵션 ─────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('팟 옵션'),
                    DropdownButton<PartyOption>(
                      value: _option,
                      items: PartyOption.values
                          .map((option) => DropdownMenuItem(
                                value: option,
                                child: Text(option.label),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _option = v!),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ───────── 생성 버튼 ─────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting || token == null ? null : _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('생성하기'),
                  ),
                ),
                if (token == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}