import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:app2_client/widgets/custom_back_button.dart';
import 'package:app2_client/models/party_detail_model.dart';
import 'package:app2_client/models/fare_input_model.dart';
import 'package:app2_client/models/payment_info_model.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/providers/auth_provider.dart';

class InputMoneyScreen extends StatefulWidget {
  final PartyDetail partyDetail;

  const InputMoneyScreen({
    super.key,
    required this.partyDetail,
  });

  @override
  State<InputMoneyScreen> createState() => _InputMoneyScreenState();
}

class _InputMoneyScreenState extends State<InputMoneyScreen> {
  final Map<int, TextEditingController> _fareControllers = {};
  bool _isLoading = false;
  List<PartyPaymentModel>? _paymentResults;

  @override
  void initState() {
    super.initState();
    _initializeFareControllers();
  }

  @override
  void dispose() {
    for (final controller in _fareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeFareControllers() {
    // 각 경유지별로 TextEditingController 생성
    for (final stopover in widget.partyDetail.stopovers) {
      _fareControllers[stopover.id] = TextEditingController();
    }
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }

  Future<void> _submitFares() async {
    final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) {
      _showErrorSnackBar('로그인이 필요합니다.');
      return;
    }

    // 입력값 검증
    final List<FareInputModel> fares = [];
    for (final entry in _fareControllers.entries) {
      final stopoverId = entry.key;
      final controller = entry.value;
      
      if (controller.text.isEmpty) {
        _showErrorSnackBar('모든 경유지의 택시비를 입력해주세요.');
        return;
      }
      
      final fare = int.tryParse(controller.text.replaceAll(',', ''));
      if (fare == null || fare <= 0) {
        _showErrorSnackBar('올바른 금액을 입력해주세요.');
        return;
      }
      
      fares.add(FareInputModel(stopoverId: stopoverId, fare: fare));
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payments = await PartyService.submitFares(
        partyId: widget.partyDetail.partyId,
        fares: fares,
        accessToken: token,
      );
      
      setState(() {
        _paymentResults = payments;
        _isLoading = false;
      });
      
      _showSuccessSnackBar('택시비 입력이 완료되었습니다.');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (e.toString().contains('403')) {
        _showErrorSnackBar('정산자만 택시비를 입력할 수 있습니다.');
      } else {
        _showErrorSnackBar('택시비 입력에 실패했습니다: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildFareInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '경유지별 택시비 입력',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '각 경유지에서 미터기에 표시된 금액을 입력해주세요.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        ...widget.partyDetail.stopovers.map((stopover) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stopover.location.address,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (stopover.memberEmail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '하차자: ${stopover.memberEmail}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fareControllers[stopover.id],
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        if (newValue.text.isEmpty) return newValue;
                        final int value = int.parse(newValue.text);
                        final formatted = value.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},',
                        );
                        return newValue.copyWith(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }),
                    ],
                    decoration: const InputDecoration(
                      labelText: '택시비 (원)',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      suffixText: '원',
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentResultSection() {
    if (_paymentResults == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        const Text(
          '정산 결과',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._paymentResults!.map((payment) {
          final member = payment.partyMemberInfo;
          final paymentInfo = payment.paymentInfo;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: member.role == 'HOST' ? Colors.red.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          member.role,
                          style: TextStyle(
                            fontSize: 12,
                            color: member.role == 'HOST' ? Colors.red : Colors.blue,
                          ),
                        ),
                      ),
                      if (member.additionalRole == 'BOOKKEEPER') ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '정산자',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('미터기 요금:'),
                      Text(_formatCurrency(paymentInfo.baseFare)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '실제 지불 금액:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatCurrency(paymentInfo.finalFare),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        paymentInfo.isPaid ? Icons.check_circle : Icons.pending,
                        color: paymentInfo.isPaid ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        paymentInfo.isPaid ? '결제 완료' : '결제 대기중',
                        style: TextStyle(
                          color: paymentInfo.isPaid ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('택시비 입력'),
        leading: const CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_paymentResults == null) ...[
              _buildFareInputSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFares,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          '택시비 입력 완료',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
            _buildPaymentResultSection(),
          ],
        ),
      ),
    );
  }
} 