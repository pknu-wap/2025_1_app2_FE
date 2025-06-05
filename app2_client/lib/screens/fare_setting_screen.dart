import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/models/payment_info_model.dart';
import 'package:app2_client/models/fare_request_model.dart';
import 'package:app2_client/models/fare_confirm_model.dart';
import 'package:app2_client/models/party_member_model.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/providers/auth_provider.dart';

import '../models/stopover_model.dart';

class FareSettingScreen extends StatefulWidget {
  final String partyId;
  final List<PartyMember> members;
  final List<StopoverResponse> stopovers;

  const FareSettingScreen({
    Key? key,
    required this.partyId,
    required this.members,
    required this.stopovers,
  }) : super(key: key);

  @override
  State<FareSettingScreen> createState() => _FareSettingScreenState();
}

class _FareSettingScreenState extends State<FareSettingScreen> {
  List<PaymentInfo> _paymentInfos = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, TextEditingController> _fareControllers = {};

  @override
  void initState() {
    super.initState();
    _loadFareInfo();
  }

  @override
  void dispose() {
    for (var controller in _fareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFareInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
      if (token == null) throw Exception('로그인이 필요합니다.');

      final paymentInfos = await PartyService.getFinalFare(
        partyId: widget.partyId,
        accessToken: token,
      );

      setState(() {
        _paymentInfos = paymentInfos;
        // 각 경유지별로 요금 입력 컨트롤러 초기화
        for (var stopover in widget.stopovers) {
          _fareControllers[stopover.stopover.id] = TextEditingController(
            text: paymentInfos
                .firstWhere(
                  (info) => info.paymentInfo.stopoverId == stopover.stopover.id,
                  orElse: () => PaymentInfo(
                    partyMemberInfo: PartyMember(
                      id: 0,
                      name: '',
                      email: '',
                      gender: '',
                      role: '',
                      additionalRole: '',
                    ),
                    paymentInfo: PaymentDetail(
                      stopoverId: stopover.stopover.id,
                      baseFare: 0,
                      finalFare: 0,
                      isPaid: false,
                    ),
                  ),
                )
                .paymentInfo
                .baseFare
                .toString(),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitFare() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
      if (token == null) throw Exception('로그인이 필요합니다.');

      final fareRequests = _fareControllers.entries.map((entry) {
        return FareRequest(
          stopoverId: entry.key,
          fare: int.tryParse(entry.value.text) ?? 0,
        );
      }).toList();

      final updatedInfos = await PartyService.submitFare(
        partyId: widget.partyId,
        fareRequests: fareRequests,
        accessToken: token,
      );

      setState(() {
        _paymentInfos = updatedInfos;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('요금이 입력되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요금 입력 실패: $e')),
        );
      }
    }
  }

  Future<void> _confirmFare(PaymentInfo paymentInfo) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
      if (token == null) throw Exception('로그인이 필요합니다.');

      final confirm = FareConfirm(
        partyMemberId: paymentInfo.partyMemberInfo.id,
        stopoverId: paymentInfo.paymentInfo.stopoverId,
      );

      final updatedInfos = await PartyService.confirmFare(
        partyId: widget.partyId,
        confirm: confirm,
        accessToken: token,
      );

      setState(() {
        _paymentInfos = updatedInfos;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('요금이 확인되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요금 확인 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('정산')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFareInfo,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('정산')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 경유지별 요금 입력
            const Text(
              '경유지별 요금 입력',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.stopovers.map((stopover) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stopover.stopover.location.address,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fareControllers[stopover.stopover.id],
                        decoration: const InputDecoration(
                          labelText: '요금',
                          suffixText: '원',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // 요금 입력 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitFare,
                child: const Text('요금 입력'),
              ),
            ),

            const SizedBox(height: 32),

            // 파티원별 정산 정보
            const Text(
              '파티원별 정산 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._paymentInfos.map((info) {
              final isBookkeeper = info.partyMemberInfo.role == 'BOOKKEEPER' ||
                  info.partyMemberInfo.additionalRole == 'BOOKKEEPER';
              final isHost = info.partyMemberInfo.role == 'HOST';

              return Card(
                child: ListTile(
                  title: Text(info.partyMemberInfo.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('하차 지점: ${_getStopoverAddress(info.paymentInfo.stopoverId)}'),
                      Text('기본 요금: ${info.paymentInfo.baseFare}원'),
                      Text('최종 요금: ${info.paymentInfo.finalFare}원'),
                      Text(
                        '결제 상태: ${info.paymentInfo.isPaid ? "결제 완료" : "미결제"}',
                        style: TextStyle(
                          color: info.paymentInfo.isPaid ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  trailing: !info.paymentInfo.isPaid &&
                          (isBookkeeper || isHost)
                      ? ElevatedButton(
                          onPressed: () => _confirmFare(info),
                          child: const Text('확인'),
                        )
                      : null,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getStopoverAddress(int stopoverId) {
    final stopover = widget.stopovers.firstWhere(
      (s) => s.stopover.id == stopoverId,
      orElse: () => widget.stopovers.first,
    );
    return stopover.stopover.location.address;
  }
} 