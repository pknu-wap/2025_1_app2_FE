// lib/screens/party_join_modal.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app2_client/models/party_model.dart';
import 'package:app2_client/screens/attendee_party_screen.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/providers/auth_provider.dart';
import '../services/party_service.dart';
import '../services/socket_service.dart';
import 'package:dio/dio.dart';
import 'package:app2_client/main.dart'; // navigatorKey import
import 'package:overlay_support/overlay_support.dart';
import 'dart:async';

/// 파티 참여 모달 (팟 신청하기)
/// - STOMP 연결 후 "/user/queue/join-request-response" 개인 응답 채널을 구독
/// - 서버가 "PENDING" → "ACCEPTED"(또는 APPROVED) → "REJECTED" → "CANCELED" 등의 상태를 내려줌
class PartyJoinModal extends StatefulWidget {
  final PartyModel pot;

  const PartyJoinModal({Key? key, required this.pot}) : super(key: key);

  @override
  State<PartyJoinModal> createState() => _PartyJoinModalState();
}

// 파티별 참여 요청 상태를 기억하는 전역 Map
final Map<String, bool> partyJoinPending = {};

class _PartyJoinModalState extends State<PartyJoinModal> {
  String? _accessToken;
  bool _loading = false;
  bool _subscribed = false;
  Timer? _autoDisconnectTimer;

  /// 서버가 내려주는 "요청 ID"를 로컬에 저장해 두면, 취소 시에 사용
  int? _pendingRequestId;

  /// 지금 모달이 어떤 상태인지
  /// - 'IDLE'    : 아직 신청 전
  /// - 'WAIT'    : HTTP 요청 전송 직후 (로딩 중)
  /// - 'PENDING' : 서버에서 "PENDING" 상태를 내려줌 (방장 승인 대기)
  /// - 'APPROVED': 서버에서 승인(또는 ACCEPTED) 상태를 내려줌 → 바로 파티 화면으로 이동
  /// - 'REJECTED': 서버에서 거절 상태를 내려줌 → 스낵바 띄우고 모달 닫힘
  /// - 'CANCELED': 서버에서 취소 상태를 내려줌 → 스낵바 띄우고 모달 닫힘
  String _joinStatus = 'IDLE';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 1) AuthProvider에서 현재 로그인된 액세스 토큰을 가져오기
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _accessToken = auth.tokens?.accessToken;

    if (_accessToken == null) {
      // 토큰이 없으면 모달을 종료하고 "로그인이 필요합니다" 메시지 출력
      Future.microtask(() {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
      });
      return;
    }

    // 모달이 열릴 때 프론트 상태로 참여 요청 중인지 확인
    if (partyJoinPending[widget.pot.id] == true) {
      setState(() {
        _joinStatus = 'PENDING';
      });
    }
  }

  /// STOMP 메시지 수신 처리
  Future<void> _handleSocketMessage(Map<String, dynamic> message) async {
    final status = message['status'] as String?;
    final reqIdField = message.containsKey('requestId')
        ? 'requestId'
        : message.containsKey('request_id')
        ? 'request_id'
        : null;

    final reqIdValue = reqIdField == null ? null : message[reqIdField];
    final int? parsedReqId = reqIdValue is int
        ? reqIdValue
        : (reqIdValue != null ? int.tryParse(reqIdValue.toString()) : null);

    if (status == 'PENDING' && parsedReqId != null) {
      // 서버가 PENDING으로 내려줄 때, 로컬에 request ID를 저장하고 버튼을 "취소" 모드로 변경
      setState(() {
        _pendingRequestId = parsedReqId;
        _joinStatus = 'PENDING';
      });
      // 프론트 상태도 기억
      partyJoinPending[widget.pot.id] = true;
    } else if (status == 'APPROVED' || status == 'ACCEPTED') {
      if (!mounted) return;
      SocketService.disconnect();
      _autoDisconnectTimer?.cancel();
      Navigator.pop(context);
      // 프론트 상태 초기화
      partyJoinPending[widget.pot.id] = false;
      setState(() => _loading = true);
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendeePartyScreen(partyId: widget.pot.id),
            ),
          );
          setState(() => _loading = false);
        }
      });
    } else if (status == 'REJECTED' || status == 'CANCELED') {
      if (!mounted) return;
      SocketService.disconnect();
      _autoDisconnectTimer?.cancel();
      Navigator.pop(context);
      // 프론트 상태 초기화
      partyJoinPending[widget.pot.id] = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'REJECTED' ? '참여가 거절되었습니다' : '참여 요청이 취소되었습니다')),
      );
    }
  }

  /// "팟 신청하기" 버튼 클릭 시 HTTP 호출 → 서버에서 PENDING 메시지를 STOMP로 내려줌
  Future<void> _joinParty() async {
    try {
      setState(() {
        _loading = true;
        _joinStatus = 'WAIT';
      });
      // 1. 소켓 연결 및 구독(이미 연결되어 있으면 생략)
      if (!_subscribed) {
        SocketService.connect(_accessToken!, onConnect: () {
          SocketService.subscribeJoinRequestResponse(onMessage: _handleSocketMessage);
        });
        _subscribed = true;
      }
      // 2. 구독이 등록된 직후에 신청 요청 전송
      await PartyService.attendParty(
        partyId: widget.pot.id,
        accessToken: _accessToken!,
      );
      // 이후 PENDING/ACCEPTED/REJECTED 등은 WebSocket으로 처리
      // 프론트 상태도 기억
      partyJoinPending[widget.pot.id] = true;
      // 3. 5분(300초) 후 자동 해제 타이머 시작
      _autoDisconnectTimer?.cancel();
      _autoDisconnectTimer = Timer(const Duration(minutes: 5), () {
        print('⏰ 5분 경과, 소켓 자동 해제');
        SocketService.disconnect();
      });
    } catch (e) {
      showSimpleNotification(
        Text('참가 실패: $e'),
        background: Colors.red,
        position: NotificationPosition.top,
      );
      setState(() => _joinStatus = 'IDLE');
      partyJoinPending[widget.pot.id] = false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// "참여 요청 취소" 버튼 클릭 시 HTTP 호출 → 서버에서 CANCELED 메시지를 STOMP로 내려줌
  Future<void> _cancelJoinRequest() async {
    if (_pendingRequestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요청 ID를 확인할 수 없습니다.')),
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
      // 이후 CANCELED 메시지는 WebSocket으로 처리
      // 프론트 상태도 초기화는 메시지 수신에서 처리
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
    _autoDisconnectTimer?.cancel();
    // SocketService.disconnect(); // 해제는 응답/타이머에서만!
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
                    style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm')
                        .format(widget.pot.createdAt),
                    style: const TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text('남은 자리: ${widget.pot.remainingSeats}명'),
                  const SizedBox(height: 12),
                  Text('출발: ${widget.pot.originAddress}'),
                  Text('도착: ${widget.pot.destAddress}'),
                  const SizedBox(height: 24),
                  // "팟 신청하기" / "참여 요청 취소" 버튼
                  if (_joinStatus == 'IDLE' || _joinStatus == 'WAIT')
                    ElevatedButton(
                      onPressed:
                      _accessToken == null || _loading ? null : _joinParty,
                      child: const Text('팟 신청하기'),
                    ),
                  if (_joinStatus == 'PENDING')
                    ElevatedButton(
                      onPressed: _loading ? null : _cancelJoinRequest,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
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