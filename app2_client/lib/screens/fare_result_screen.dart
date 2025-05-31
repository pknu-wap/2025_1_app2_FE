import 'dart:convert';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app2_client/services/fare_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FareResultScreen extends StatefulWidget {
  final String partyId;
  final bool isBookkeeper;
  final String bookkeeperEmail;

  const FareResultScreen.bookkeeper({
    Key? key,
    required this.partyId,
    required this.bookkeeperEmail,
  }) : isBookkeeper = true,
       super(key: key);

  const FareResultScreen.user({
    Key? key,
    required this.partyId,
    required this.bookkeeperEmail,
  }) : isBookkeeper = false,
       super(key: key);

  @override
  _FareResultScreenState createState() => _FareResultScreenState();
}

class _FareResultScreenState extends State<FareResultScreen> {
  List<Map<String, dynamic>> users = [];
  String? currentUserEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    fetchFareData();
  }

  Future<void> _loadCurrentUserEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    currentUserEmail = authProvider.user?.email;
  }

  Future<void> fetchFareData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.jwtToken;
    
    try {
      final baseUrl = dotenv.env['BACKEND_BASE_URL']!;
      final response = await http.get(
        Uri.parse('$baseUrl/api/party/${widget.partyId}/fare'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = List<Map<String, dynamic>>.from(data['users']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load fare data');
      }
    } catch (e) {
      print('정산 데이터 불러오기 실패: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleFareConfirmation(String targetUserEmail) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.jwtToken;

    try {
      final baseUrl = dotenv.env['BACKEND_BASE_URL']!;
      final response = await http.post(
        Uri.parse('$baseUrl/api/party/${widget.partyId}/fare/confirm'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userEmail': targetUserEmail,
          'confirmed': true,
        }),
      );

      if (response.statusCode == 200) {
        // 성공 시 데이터 새로고침
        await fetchFareData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('확인 처리되었습니다.')),
        );
      } else {
        throw Exception('Failed to confirm fare');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('처리 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 현황'),
        elevation: 0,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: const Text(
                  '본인이 타고 간 거리만큼의 비용을 그 당시 함께 \n타고 있던 사람들과 나누어서 내도록 정산했어요 :) \n최종 정산자에게 입금 후 확인 요청 버튼을 누르세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.isBookkeeper) Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: const Text(
                  '최종 정산자는 모두의 입금 내역을 확인하고, \n입금 확인 버튼을 눌러주세요. \n확인이 완료되면 자동으로 이 파티는 폭파됩니다. \n쾌적한 어플 이용을 위해 파티원 평가를 해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userEmail = user['email'] as String;
                    final isConfirmed = user['confirmed'] as bool;
                    final amount = user['amount'] as int;
                    
                    // 버튼 표시 여부 결정
                    bool showButton = false;
                    if (widget.isBookkeeper) {
                      // 결산자는 자신을 제외한 모든 사용자의 버튼을 볼 수 있음
                      showButton = userEmail != widget.bookkeeperEmail;
                    } else {
                      // 일반 사용자는 자신의 버튼만 볼 수 있음
                      showButton = userEmail == currentUserEmail;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${amount.toString()}원',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (showButton) ...[
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: isConfirmed ? null : () => _handleFareConfirmation(userEmail),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isConfirmed ? Colors.grey : Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                widget.isBookkeeper
                                  ? (isConfirmed ? '정산완' : '돈받음')
                                  : (isConfirmed ? '송금완' : '확인요청'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// 이슈번호 16