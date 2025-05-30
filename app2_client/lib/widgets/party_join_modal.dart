import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app2_client/models/party_model.dart';
import 'package:app2_client/screens/attendee_party_screen.dart';
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
  bool _loading = false;
  bool _subscribed = false;

  // 참여 요청 ID와 상태 관리
  int? _pendingRequestId;
  String _joinStatus = 'IDLE'; // 'IDLE', 'WAIT', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELED'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _accessToken = auth.tokens?.accessToken;

    if (_accessToken == null) {
      Future.microtask(() {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
      });
      return;
    }

    if (!_subscribed) {
      SocketService.connect(_accessToken!);
      final topic = '/sub/party/${widget.pot.id}/result';
      SocketService.subscribe(
        topic: topic,
        onMessage: _handleSocketMessage,
      );
      _subscribed = true;
    }
  }

  Future<void> _handleSocketMessage(Map<String, dynamic> message) async {
    final status = message['status'];
    final reqId = message['requestId']; // 서버 명세에 따라 'requestId' 또는 'request_id'

    if (status == 'PENDING' && reqId != null) {
      setState(() {
        _pendingRequestId = reqId is int ? reqId : int.tryParse(reqId.toString());
        _joinStatus = 'PENDING';
      });
    } else if (status == 'APPROVED' || status == 'ACCEPTED') {
      Navigator.pop(context);
      setState(() => _loading = true);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendeePartyScreen(partyId: widget.pot.id),
        ),
      );
      if (mounted) setState(() => _loading = false);
    } else if (status == 'REJECTED') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여가 거절되었습니다')),
      );
    } else if (status == 'CANCELED') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여 요청이 취소되었습니다')),
      );
    }
  }

  Future<void> _joinParty() async {
    try {
      setState(() {
        _loading = true;
        _joinStatus = 'WAIT';
      });
      await PartyService.attendParty(
        partyId: widget.pot.id,
        accessToken: _accessToken!,
      );
      // 수락/거절/취소는 소켓에서!
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('참가 실패: $e')),
      );
      setState(() => _joinStatus = 'IDLE');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelJoinRequest() async {
    if (_pendingRequestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요청ID를 확인할 수 없습니다.')),
      );
      return;
    }
    try {
      setState(() => _loading = true);
      await PartyService.cancelJoinRequest(
        partyId: widget.pot.id,
        requestId: _pendingRequestId!,
        accessToken: _accessToken!,
      );
      // 취소 결과는 소켓에서 반영
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('참여 요청 취소 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DraggableScrollableSheet(
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
                  if (_joinStatus == 'IDLE' || _joinStatus == 'WAIT')
                    ElevatedButton(
                      onPressed: _accessToken == null || _loading
                          ? null
                          : _joinParty,
                      child: const Text('팟 신청하기'),
                    ),
                  if (_joinStatus == 'PENDING')
                    ElevatedButton(
                      onPressed: _loading ? null : _cancelJoinRequest,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('참여 요청 취소'),
                    ),
                ],
              ),
            );
          },
        ),
        if (_loading)
          Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}