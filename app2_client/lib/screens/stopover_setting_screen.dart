// lib/screens/stopover_setting_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/models/stopover_model.dart';
import 'package:app2_client/models/location_model.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/services/party_service.dart';

import '../models/party_member_model.dart';

class StopoverSettingScreen extends StatefulWidget {
  final String partyId;
  final StopoverResponse stopoverData;

  const StopoverSettingScreen({
    Key? key,
    required this.partyId,
    required this.stopoverData,
  }) : super(key: key);

  @override
  State<StopoverSettingScreen> createState() => _StopoverSettingScreenState();
}

class _StopoverSettingScreenState extends State<StopoverSettingScreen> {
  late StopoverResponse _stopover;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _stopover = widget.stopoverData;
  }

  Future<void> _updateMemberDropoff({
    required String memberEmail,
    required String address,
    required double lat,
    required double lng,
  }) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    try {
      setState(() => _loading = true);
      final updatedList = await PartyService.updateStopover(
        partyId: widget.partyId,
        stopoverId: _stopover.stopover.id,
        memberEmail: memberEmail,
        location: LocationModel(
          address: address,
          lat: lat,
          lng: lng,
        ),
        accessToken: token,
      );
      // 화면에 반영하려면 업데이트된 리스트 중 해당 아이템만 찾아서 덮어쓰기
      final updated = updatedList.firstWhere((e) =>
      e.stopover.id == _stopover.stopover.id);
      setState(() => _stopover = updated);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('수정 실패: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeMemberFromStopover(String memberEmail) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    try {
      setState(() => _loading = true);
      // PATCH API 호출: “member_email”만 보내면 해당 멤버가 경유지에서 내려집니다.
      final updatedList = await PartyService.updateStopover(
        partyId: widget.partyId,
        stopoverId: _stopover.stopover.id,
        memberEmail: memberEmail,
        location: null,
        accessToken: token,
      );
      final updated = updatedList.firstWhere((e) =>
      e.stopover.id == _stopover.stopover.id);
      setState(() => _stopover = updated);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('멤버 제거 실패: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showEditDialog(PartyMember member) async {
    String email = member.email;
    String address = _stopover.stopover.location.address;
    String latStr = _stopover.stopover.location.lat.toString();
    String lngStr = _stopover.stopover.location.lng.toString();

    final _addressController = TextEditingController(text: address);
    final _latController = TextEditingController(text: latStr);
    final _lngController = TextEditingController(text: lngStr);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${member.name}님 하차 지점 수정'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: '주소'),
                ),
                TextField(
                  controller: _latController,
                  decoration: const InputDecoration(labelText: '위도'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: _lngController,
                  decoration: const InputDecoration(labelText: '경도'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('저장'),
              onPressed: () async {
                final updatedAddress = _addressController.text.trim();
                final updatedLat = double.tryParse(_latController.text.trim());
                final updatedLng = double.tryParse(_lngController.text.trim());
                if (updatedAddress.isEmpty ||
                    updatedLat == null ||
                    updatedLng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모든 필드를 올바르게 입력해주세요.')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                await _updateMemberDropoff(
                  memberEmail: email,
                  address: updatedAddress,
                  lat: updatedLat,
                  lng: updatedLng,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = _stopover.partyMembers;
    return Scaffold(
      appBar: AppBar(
        title: const Text('하차 지점 설정'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '경유지: ${_stopover.stopover.location.address}',
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text('내릴 멤버 목록', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...members.map((m) {
              return Card(
                child: ListTile(
                  title: Text(m.name),
                  subtitle: Text('${m.email}  |  역할: ${m.role}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == '수정') {
                        await _showEditDialog(m);
                      } else if (value == '제거') {
                        await _removeMemberFromStopover(m.email);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: '수정',
                        child: Text('하차 위치 수정'),
                      ),
                      const PopupMenuItem(
                        value: '제거',
                        child: Text('경유지에서 제거'),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}