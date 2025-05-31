// lib/services/socket_service.dart

import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// SocketService: STOMP over WebSocket 연결용 헬퍼 클래스
/// - 백엔드(Spring)가 registerStompEndpoints("/ws").withSockJS() 로 열어 두었다면,
///   클라이언트에서는 순수 WebSocket(ws://) 으로 직접 연결할 수 있습니다.
/// - 토큰은 query parameter로만 붙여서 보냅니다.
class SocketService {
  // .env에 정의된 백엔드 기본 URL (예: "http://3.105.16.234:8080")
  static final String _backendBase = dotenv.env['BACKEND_BASE_URL'] ?? '';

  static StompClient? _stompClient;
  static bool _connected = false;

  /// “순수 WebSocket”으로 STOMP 연결할 URL을 만들어 줍니다.
  /// 예) BACKEND_BASE_URL이 "http://3.105.16.234:8080" 이라면,
  ///     "ws://3.105.16.234:8080/ws?token={accessToken}" 로 업그레이드 시도합니다.
  static String _webSocketUrl(String token) {
    String wsBase;
    if (_backendBase.startsWith('https://')) {
      wsBase = _backendBase.replaceFirst('https://', 'wss://');
    } else if (_backendBase.startsWith('http://')) {
      wsBase = _backendBase.replaceFirst('http://', 'ws://');
    } else {
      wsBase = _backendBase;
    }
    return '$wsBase/ws?token=$token';
  }

  /// Public Updates 토픽 구독 (파티 생성/업데이트/삭제 등)
  static void subscribePublicUpdates({
    required void Function(Map<String, dynamic>) onMessage,
  }) {
    if (_stompClient == null) {
      debugPrint('❌ STOMP 클라이언트가 초기화되지 않았습니다.');
      return;
    }

    if (!_stompClient!.isActive) {
      debugPrint('❌ STOMP 연결이 활성화되지 않았습니다. 재연결을 시도합니다.');
      _reconnect();
      return;
    }

    debugPrint('📡 Public Updates 토픽 구독 시작: /topic/public-updates');
    
    _stompClient?.subscribe(
      destination: '/topic/public-updates',
      callback: (frame) {
        debugPrint('📨 Public Updates 메시지 수신: ${frame.body}');
        
        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          onMessage(data);
        } catch (e) {
          debugPrint('❌ 메시지 파싱 실패: $e');
        }
      },
    );
  }

  /// STOMP 연결
  static void connect(String token, {
    required VoidCallback onConnect,
    void Function(dynamic)? onError,
  }) {
    debugPrint('🔌 STOMP 연결 시작...');
    
    // 이미 연결된 경우 처리
    if (_stompClient?.isActive ?? false) {
      debugPrint('ℹ️ 이미 STOMP에 연결되어 있습니다.');
      onConnect();
      return;
    }

    // 연결이 끊어진 경우 재연결
    if (_stompClient != null) {
      debugPrint('🔄 STOMP 재연결 시도...');
      _reconnect();
      return;
    }

    final wsUrl = Uri.parse(ApiConstants.wsEndpoint).replace(scheme: 'ws');
    debugPrint('🌐 WebSocket URL: $wsUrl');

    _stompClient = StompClient(
      config: StompConfig.SockJS(
        url: wsUrl.toString(),
        onConnect: (frame) {
          debugPrint('✅ STOMP 연결 성공');
          onConnect();
        },
        onDisconnect: (frame) {
          debugPrint('❌ STOMP 연결 해제됨');
        },
        onError: (frame) {
          debugPrint('❌ STOMP 에러 발생: ${frame?.body}');
          if (onError != null) onError(frame?.body);
        },
        onWebSocketError: (error) {
          debugPrint('❌ WebSocket 에러 발생: $error');
          if (onError != null) onError(error);
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    try {
      _stompClient?.activate();
    } catch (e) {
      debugPrint('❌ STOMP 활성화 실패: $e');
      if (onError != null) onError(e);
    }
  }

  /// 연결 재시도
  static void _reconnect() {
    debugPrint('🔄 STOMP 연결 재시도 중...');
    _stompClient?.deactivate();
    _stompClient = null;
    // 잠시 대기 후 재연결
    Future.delayed(const Duration(seconds: 1), () {
      debugPrint('🔄 STOMP 재연결 시도...');
      _stompClient?.activate();
    });
  }

  /// 파티 외부 사용자용 브로드캐스트(파티 리스트 업데이트) 구독
  ///
  /// 메시지 예시:
  ///   { "partyId":2, "message":"파티 id: 2가 생성되었습니다.", "eventType":"PARTY_CREATE" }
  static void subscribePublicUpdatesOld({
    required void Function(Map<String, dynamic> message) onMessage,
  }) {
    if (!_connected || _stompClient == null) {
      print('⚠️ subscribePublicUpdates: STOMP 클라이언트가 연결되지 않았습니다.');
      return;
    }
    _stompClient!.subscribe(
      destination: '/topic/parties/public-updates',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final data = json.decode(frame.body!);
          if (data is Map<String, dynamic>) {
            onMessage(data);
          }
        }
      },
    );
    print('👂 구독: /topic/parties/public-updates');
  }

  /// 파티 내부 사용자용 브로드캐스트(멤버 Join/Update 등) 구독
  ///
  /// [partyId] : 구독할 파티 ID
  /// 메시지 예시:
  ///   { "partyId":1, "message":"Tom님이 참가하였습니다.", "eventType":"MEMBER_JOIN" }
  static void subscribePartyMembers({
    required int partyId,
    required void Function(Map<String, dynamic> message) onMessage,
  }) {
    if (!_connected || _stompClient == null) {
      print('⚠️ subscribePartyMembers: STOMP 클라이언트가 연결되지 않았습니다.');
      return;
    }
    final destination = '/topic/party/$partyId/members';
    _stompClient!.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final data = json.decode(frame.body!);
          if (data is Map<String, dynamic>) {
            onMessage(data);
          }
        }
      },
    );
    print('👂 구독: $destination');
  }

  /// 개인 응답용 구독 (예: 참여 요청 결과)
  ///
  /// 메시지 예시:
  ///   {
  ///     "partyId":1, "requestId":6, "requesterEmail":"tom@pku.ac.kr",
  ///     "hostEmail":"host@pku.ac.kr", "status":"ACCEPTED",
  ///     "message":"Tom님의 요청을 수락하였습니다.", "respondedAt":"2025-05-30T00:04:02"
  ///   }
  static void subscribeJoinRequestResponse({
    required void Function(Map<String, dynamic> message) onMessage,
  }) {
    if (!_connected || _stompClient == null) {
      print('⚠️ subscribeJoinRequestResponse: STOMP 클라이언트가 연결되지 않았습니다.');
      return;
    }
    _stompClient!.subscribe(
      destination: '/user/queue/join-request-response',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final data = json.decode(frame.body!);
          if (data is Map<String, dynamic>) {
            onMessage(data);
          }
        }
      },
    );
    print('👂 구독: /user/queue/join-request-response');
  }

  /// 연결 종료
  static void disconnect() {
    _stompClient?.deactivate();
    _connected = false;
    print('🔌 STOMP(WebSocket) 연결 해제');
  }
}