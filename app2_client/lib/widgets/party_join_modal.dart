// lib/widgets/party_join_modal.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/models/party_model.dart';
import 'package:app2_client/services/party_service.dart';
import 'package:app2_client/services/socket_service.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/screens/attendee_party_screen.dart';

class PartyJoinModal extends StatefulWidget {
  final PartyModel pot;

  const PartyJoinModal({Key? key, required this.pot}) : super(key: key);

  @override
  State<PartyJoinModal> createState() => _PartyJoinModalState();
}

class _PartyJoinModalState extends State<PartyJoinModal> {
  bool _isRequesting = false;        // API 호출 중인지 표시
  bool _subscribed = false;          // 구독 등록 여부
  String? _errorMessage;             // 호출 실패 시 에러 메시지

  @override
  void initState() {
    super.initState();
    _subscribeJoinResponse();        // 모달이 뜰 때 곧바로 구독을 걸어준다.
  }

  @override
  void dispose() {
    // (필요하다면) 구독 해제 로직을 넣어도 된다.
    // 여기서는 단순화하여 SocketService.disconnect()를 호출하지 않고
    // 앱 전체 커넥션을 유지한다고 가정한다.
    super.dispose();
  }

  /// `/queue/join-request-response` 구독:
  /// PENDING, ACCEPTED, REJECTED 등의 메시지를 받는다.
  void _subscribeJoinResponse() {
    // 이미 구독한 상태라면 다시 구독하지 않는다.
    if (_subscribed) return;

    SocketService.subscribeJoinRequestResponse(onMessage: (msg) {
      // msg 예시:
      // {
      //   "partyId": 78,
      //   "requestId": 67,
      //   "requesterEmail": "pdanny79052@pukyong.ac.kr",
      //   "hostEmail": "junyong1102@pukyong.ac.kr",
      //   "status": "ACCEPTED",  // 혹은 PENDING, REJECTED, ...
      //   "message": "파티 참가 요청이 수락되었습니다.",
      //   "respondedAt": "2025-06-05T12:51:06.771340541"
      // }
      final int partyId = msg['partyId'] as int;
      final String status = msg['status'] as String;

      // 내가 요청한 파티 ID와 일치하며, status가 ACCEPTED일 때만 화면 전환
      if (partyId.toString() == widget.pot.id && status == 'ACCEPTED') {
        // 1) 모달을 닫는다.
        if (mounted) Navigator.of(context).pop();

        // 2) 사용자에게 "참여 완료됨" 스낵바 띄우기
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('참여 요청이 수락되었어!')),
          );
        }

        // 3) AttendeePartyScreen 으로 네비게이트
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AttendeePartyScreen(
                partyId: widget.pot.id,
                isHost: false,
              ),
            ),
          );
        }
      }

      // 만약 "REJECTED" 메시지를 받으면 알림만 띄우고 모달은 열어둔 상태로 유지할 수도 있다.
      if (partyId.toString() == widget.pot.id && status == 'REJECTED') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('참여 요청이 거절되었어.')),
          );
        }
        // 필요하다면 모달 닫기:
        // if (mounted) Navigator.of(context).pop();
      }
    });

    _subscribed = true;
  }

  Future<void> _handleJoin() async {
    if (_isRequesting) return;
    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
    if (token == null) {
      setState(() {
        _isRequesting = false;
        _errorMessage = '로그인이 필요합니다.';
      });
      return;
    }

    // partyOption 필터링 로직 추가
    final userGender = Provider.of<AuthProvider>(context, listen: false).userGender; // 사용자 성별 정보 가져오기
    if (widget.pot.partyOption == 'ONLY_MALE' && userGender != 'MALE') {
      setState(() {
        _isRequesting = false;
        _errorMessage = '남성만 참여 가능한 파티입니다.';
      });
      return;
    }
    if (widget.pot.partyOption == 'ONLY_FEMALE' && userGender != 'FEMALE') {
      setState(() {
        _isRequesting = false;
        _errorMessage = '여성만 참여 가능한 파티입니다.';
      });
      return;
    }

    try {
      // 1) 파티 참가 요청 API 호출
      await PartyService.attendParty(
        partyId: widget.pot.id,
        accessToken: token,
      );

      // 2) API 호출 성공 → "승인을 기다리는 중입니다" 스낵바 띄우기
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('승인을 기다리는 중입니다...')),
        );
      }

      // 3) 모달은 닫지 않고 그대로 두어서,
      //    이후 백엔드에서 보내줄 "ACCEPTED" 메시지를 대기한다.
    } catch (e) {
      // 4) API 호출 실패 시 에러 메시지 표시
      setState(() {
        _errorMessage = '참여 요청 실패: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── 드래그 핸들러(선택) ───────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ─── 타이틀 ─────────────────────────────────────────────────────
            Text(
              '"${widget.pot.creatorName}" 님의 팟에 참여하기',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ─── 출발/도착 주소 표시 ─────────────────────────────────────────────
            Text(
              '출발: ${widget.pot.originAddress}\n도착: ${widget.pot.destAddress}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // ─── 참여하기 버튼 ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _handleJoin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isRequesting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('참여하기'),
              ),
            ),

            const SizedBox(height: 12),

            // ─── 에러 메시지가 있을 때 표시 ───────────────────────────────────────
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],

            // ─── 취소 버튼 ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('취소'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}