import 'dart:convert';
import 'dart:async';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/services/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app2_client/screens/review_page.dart';
import 'package:app2_client/models/party_member_model.dart';
import 'package:app2_client/models/payment_info_model.dart';
import 'package:app2_client/services/payment_service.dart';
import 'package:app2_client/services/socket_service.dart';
import 'package:app2_client/widgets/payment_notification.dart';

class FareResultScreen extends StatefulWidget {
  final String partyId;
  final bool isBookkeeper;
  final String bookkeeperEmail;

  const FareResultScreen.bookkeeper({
    super.key,
    required this.partyId,
    required this.bookkeeperEmail,
  }) : isBookkeeper = true;

  const FareResultScreen.user({
    super.key,
    required this.partyId,
    required this.bookkeeperEmail,
  }) : isBookkeeper = false;

  @override
  State<FareResultScreen> createState() => _FareResultScreenState();
}

class _FareResultScreenState extends State<FareResultScreen> {
  List<PartyMember> users = [];
  String? currentUserEmail;
  bool isLoading = true;
  late final WebSocketService _webSocketService;
  StreamSubscription? _fareSubscription;
  bool _socketSubscribed = false;

  @override
  void initState() {
    super.initState();
    _webSocketService = WebSocketService();
    _loadCurrentUserEmail();
    fetchFareData();
    _setupWebSocket();
    _connectAndSubscribe();

    // 정산 완료 이벤트 구독
    SocketService.subscribePaymentComplete(
      partyId: int.parse(widget.partyId),
      onComplete: () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewPage(
                partyId: widget.partyId,
              ),
            ),
          );
        }
      },
    );
  }

  void _setupWebSocket() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.jwtToken;
    
    _webSocketService.connect(widget.partyId, token);
    _fareSubscription = _webSocketService.fareUpdates.listen((data) {
      final usersList = List<Map<String, dynamic>>.from(data['users']);
      setState(() {
        users = usersList.map((user) => PartyMember.fromJson(user)).toList();
      });

      if (widget.isBookkeeper && _isAllUsersConfirmed()) {
        _navigateToPartyEvaluation();
      }
    });
  }

  bool _isAllUsersConfirmed() {
    return users.every((user) => user.confirmed);
  }

  void _navigateToPartyEvaluation() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewPage(partyId: widget.partyId),
      ),
    );
  }

  @override
  void dispose() {
    _fareSubscription?.cancel();
    _webSocketService.dispose();
    SocketService.disconnect();
    super.dispose();
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
        final usersList = List<Map<String, dynamic>>.from(data['users']);
        setState(() {
          users = usersList.map((user) => PartyMember.fromJson(user)).toList();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('확인 처리되었습니다.')),
        );

        if (widget.isBookkeeper && _isAllUsersConfirmed()) {
          _navigateToPartyEvaluation();
        }
      } else {
        throw Exception('Failed to confirm fare');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('처리 중 오류가 발생했습니다.')),
      );
    }
  }

  void _connectAndSubscribe() {
    final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) return;

    SocketService.connect(token, onConnect: () {
      if (!_socketSubscribed) {
        SocketService.subscribePaymentNotification(
          partyId: int.parse(widget.partyId),
          onMessage: _handlePaymentNotification,
        );
        _socketSubscribed = true;
      }
    });
  }

  void _handlePaymentNotification(Map<String, dynamic> data) {
    final memberName = data['member_name'] as String;
    final amount = data['amount'] as int;

    if (widget.isBookkeeper) {
      PaymentNotification(
        memberName: memberName,
        amount: amount,
      ).show();
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
                    final isConfirmed = user.confirmed;
                    final amount = user.amount;
                    
                    bool showButton = false;
                    if (widget.isBookkeeper) {
                      showButton = user.email != widget.bookkeeperEmail;
                    } else {
                      showButton = user.email == currentUserEmail;
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
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$amount원',
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
                              onPressed: isConfirmed ? null : () => _handleFareConfirmation(user.email),
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