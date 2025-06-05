// lib/services/socket_service.dart

import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/services/dio_client.dart';
import 'package:app2_client/services/secure_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

/// SocketService: STOMP over WebSocket 연결용 헬퍼 클래스
/// - 백엔드(Spring)가 registerStompEndpoints("/ws").withSockJS() 로 열어 두었다면,
///   클라이언트에서는 순수 WebSocket(ws://) 으로 직접 연결할 수 있습니다.
/// - 토큰은 query parameter로만 붙여서 보냅니다.
class SocketService {
  // .env에 정의된 백엔드 기본 URL (예: "http://3.105.16.234:8080")
  static final String _backendBase = dotenv.env['BACKEND_BASE_URL'] ?? '';

  static StompClient? _client;
  static bool _connected = false;
  static bool _isReissuing = false;       // 토큰 재발급 중인지 상태 추적
  static String? _lastToken;              // 마지막에 사용한 액세스 토큰
  static void Function()? _onConnectCallback;

  /// 현재 STOMP/WebSocket 연결 상태
  static bool get isConnected => _connected;

  /// "순수 WebSocket"으로 STOMP 연결할 URL을 만들어 줍니다.
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

  /// STOMP over WebSocket 연결 수행
  ///
  /// - [token]: 현재 유효한 액세스 토큰
  /// - [onConnect]: 연결이 성공했을 때 호출할 콜백 함수
  static Future<void> connect(String token, {void Function()? onConnect}) async {
    // 이미 연결되어 있고, 토큰이 동일하다면 재연결 생략
    if (_connected && _lastToken == token) {
      print('⚠️ 이미 STOMP에 연결되어 있으며, 동일한 토큰을 사용 중입니다. 재연결을 건너뜁니다.');
      return;
    }

    _lastToken = token;
    _onConnectCallback = onConnect;

    final url = _webSocketUrl(token);
    print('🔌 STOMP(WebSocket) 접속 시도 → $url');

    final completer = Completer<void>();

    _client = StompClient(
      config: StompConfig(
        // 순수 WebSocket으로 연결하겠다는 설정
        url: url,
        onConnect: (StompFrame frame) {
          _connected = true;
          print('✅ STOMP/WebSocket 연결 성공 (URL: $url)');
          if (_onConnectCallback != null) {
            _onConnectCallback!();
          }
          completer.complete();
        },
        onWebSocketError: (dynamic error) {
          _connected = false;
          print('❌ WebSocket 오류: $error');

          // HTTP 상태 코드(예: 403)로 인한 실패일 경우, 토큰 재발급 로직을 시도
          if (error is WebSocketException && error.httpStatusCode == 403) {
            if (_isReissuing) {
              print('⚠️ 이미 토큰 재발급 중입니다. 중복 요청을 무시합니다.');
            } else {
              print('🔑 WebSocket 403 에러: 토큰 재발급을 시도합니다.');
              _isReissuing = true;
              _client?.deactivate(); // 기존 클라이언트 해제

              // SecureStorage에서 리프레시 토큰을 가져와 "/auth/reissue" 호출
              SecureStorageService().getRefreshToken().then((refreshToken) {
                return DioClient.dio.post(
                  ApiConstants.reissueEndPoint,
                  data: {'refreshToken': refreshToken},
                );
              }).then((response) async {
                final newAccessToken = response.data['accessToken'] as String?;
                final newRefreshToken = response.data['refreshToken'] as String?;
                if (newAccessToken != null && newRefreshToken != null) {
                  // SecureStorage에 새 토큰 저장
                  await SecureStorageService().saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );
                  print('🔄 토큰 재발급 완료, 새로운 액세스 토큰으로 재연결을 시도합니다.');
                  await connect(newAccessToken, onConnect: _onConnectCallback);
                }
              }).catchError((e) {
                print('❌ 토큰 재발급 실패: $e');
              }).whenComplete(() {
                _isReissuing = false;
              });
            }
          } else {
            // 기타 오류라면 2초 후 재연결을 시도
            Future.delayed(const Duration(seconds: 2), () {
              print('🔄 WebSocket 재연결 시도');
              if (_lastToken != null) {
                connect(_lastToken!, onConnect: _onConnectCallback);
              }
            });
          }

          completer.completeError(error);
        },
        onDisconnect: (StompFrame frame) {
          _connected = false;
          print('🔌 STOMP/WebSocket 연결 종료');

          // 연결이 끊긴 경우 2초 후 자동 재연결 시도
          Future.delayed(const Duration(seconds: 2), () {
            print('🔄 WebSocket 재연결 시도');
            if (_lastToken != null) {
              connect(_lastToken!, onConnect: _onConnectCallback);
            }
          });
        },
        onStompError: (StompFrame frame) {
          print('⚠️ STOMP 오류: ${frame.body}');
          completer.completeError(Exception(frame.body ?? 'Unknown STOMP error'));
        },
        // heartbeat를 10초마다 보내고 받고
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
      ),
    );

    _client!.activate();
    return completer.future;
  }

  /// 파티 외부 사용자용 브로드캐스트(파티 리스트 업데이트) 구독
  /// 메시지 예시:
  ///   { "partyId":2, "message":"파티 id: 2가 생성되었습니다.", "eventType":"PARTY_CREATE" }
  static void subscribePublicUpdates({
    required void Function(Map<String, dynamic> message) onMessage,
  }) {
    if (!_connected || _client == null) {
      print('⚠️ subscribePublicUpdates: STOMP 클라이언트가 연결되지 않았습니다.');
      return;
    }
    _client!.subscribe(
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
  /// [partyId]: 구독할 파티 ID
  /// 메시지 예시:
  ///   { "partyId":1, "message":"Tom님이 참가하였습니다.", "eventType":"MEMBER_JOIN" }
  static void subscribePartyMembers({
    required int partyId,
    required void Function(Map<String, dynamic> message) onMessage,
  }) {
    if (!_connected || _client == null) {
      print('⚠️ subscribePartyMembers: STOMP 클라이언트가 연결되지 않았습니다.');
      return;
    }
    final destination = '/topic/party/$partyId/members';
    _client!.subscribe(
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
  /// 메시지 예시:
  ///   {
  ///     "partyId":1, "requestId":6, "requesterEmail":"tom@pku.ac.kr",
  ///     "hostEmail":"host@pku.ac.kr", "status":"ACCEPTED",
  ///     "message":"Tom님의 요청을 수락하였습니다.", "respondedAt":"2025-05-30T00:04:02"
  ///   }
  static void subscribeJoinRequestResponse({
    required void Function(Map<String, dynamic> message) onMessage,
  }) {
    if (!_connected || _client == null) {
      print('⚠️ subscribeJoinRequestResponse: STOMP 클라이언트가 연결되지 않았습니다.');
      return;
    }
    _client!.subscribe(
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

  /// 호스트용 참여 요청 구독 (새로운 참여 요청 알림)
  /// 메시지 예시:
  ///   {
  ///     "type": "JOIN_REQUEST",
  ///     "request_id": 123,
  ///     "name": "김철수",
  ///     "email": "kim@example.com",
  ///     "partyId": 1
  ///   }
  static void subscribeJoinRequests({
    required void Function(Map<String, dynamic> message) onMessage,
  }) {
    if (!_connected || _client == null) {
      print('⚠️ subscribeJoinRequests: STOMP 클라이언트가 연결되지 않았습니다.');
      return;
    }
    _client!.subscribe(
      destination: '/user/queue/join-requests',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final data = json.decode(frame.body!);
          if (data is Map<String, dynamic>) {
            onMessage(data);
          }
        }
      },
    );
    print('👂 구독: /user/queue/join-requests');
  }

  /// 연결 종료
  static void disconnect() {
    _client?.deactivate();
    _connected = false;
    print('🔌 STOMP(WebSocket) 연결 해제');
  }

  /// 내부에서 STOMP 클라이언트 객체를 가져와야 할 때 사용할 수 있는 Getter
  static StompClient? get client => _client;
}