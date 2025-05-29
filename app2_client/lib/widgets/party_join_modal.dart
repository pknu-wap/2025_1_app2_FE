import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app2_client/models/party_model.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/providers/auth_provider.dart';
import '../services/party_service.dart';
import '../services/socket_service.dart';

class PartyJoinModal extends StatefulWidget {
  final PartyModel pot;

  const PartyJoinModal({Key? key, required this.pot}) : super(key: key);

  @override
  State<PartyJoinModal> createState() => _PartyJoinModalState();
}

class _PartyJoinModalState extends State<PartyJoinModal> {
  String? _accessToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 가장 안전한 Provider 접근 위치!
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _accessToken = auth.tokens?.accessToken;

    if (_accessToken == null) {
      // 토큰 없으면 모달 닫고 안내
      Future.microtask(() {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
      });
      return;
    }

    SocketService.connect(_accessToken!);

    final topic = '/sub/party/${widget.pot.id}/result';
    SocketService.subscribe(
      topic: topic,
      onMessage: _handleSocketMessage,
    );
  }

  void _handleSocketMessage(Map<String, dynamic> message) {
    final status = message['status'];
    if (status == 'APPROVED' || status == 'ACCEPTED') {
      Navigator.pop(context);
      Navigator.pushNamed(context, '/party/detail', arguments: widget.pot.id);
    } else if (status == 'REJECTED') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여가 거절되었습니다')),
      );
    }
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, ctl) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: ctl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.pot.creatorName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('yyyy/MM/dd HH:mm').format(widget.pot.createdAt),
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('남은 자리: ${widget.pot.remainingSeats}명'),
              const SizedBox(height: 12),
              Text('출발: ${widget.pot.originAddress}'),
              Text('도착: ${widget.pot.destAddress}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _accessToken == null
                    ? null
                    : () async {
                  try {
                    await PartyService.attendParty(
                      partyId: widget.pot.id,
                      accessToken: _accessToken!,
                    );
                    // 이제 소켓에서 수락/거절 결과를 기다림!
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('참가 실패: $e')),
                    );
                  }
                },
                child: const Text('팟 신청하기'),
              ),
            ],
          ),
        );
      },
    );
  }
}