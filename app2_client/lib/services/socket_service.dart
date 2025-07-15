import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/services/dio_client.dart';
import 'package:app2_client/services/secure_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class SocketService {
  static final String _backendBase = dotenv.env['BACKEND_BASE_URL'] ?? '';

  static StompClient? _client;
  static bool _connected = false;
  static String? _lastToken;
  static void Function()? _onConnectCallback;

  static bool _isReissuing = false;
  static Completer<void>? _reissueCompleter;

  static bool get isConnected => _connected;

  // [수정됨] URL 생성 로직을 수정하여 마지막에 붙은 '/'를 제거합니다.
  static String _webSocketUrl(String token) {
    String httpBase = _backendBase;
    // .env의 URL이 '/'로 끝나면 제거합니다.
    if (httpBase.endsWith('/')) {
      httpBase = httpBase.substring(0, httpBase.length - 1);
    }

    String wsBase;
    if (httpBase.startsWith('https://')) {
      wsBase = httpBase.replaceFirst('https://', 'wss://');
    } else if (httpBase.startsWith('http://')) {
      wsBase = httpBase.replaceFirst('http://', 'ws://');
    } else {
      wsBase = httpBase;
    }

    // 이제 '$wsBase/ws'는 항상 'ws://.../ws' 형식을 보장합니다.
    return '$wsBase/ws?token=${token.trim()}';
  }

  static Future<void> connect(String token, {void Function()? onConnect}) async {
    if (_connected && _lastToken == token && _client?.connected == true) {
      print('⚠️ 이미 STOMP에 연결되어 있습니다. 재연결을 건너뜁니다.');
      if (onConnect != null) {
        onConnect();
      }
      return;
    }

    _connected = false;
    _lastToken = token;
    _onConnectCallback = onConnect;

    _client?.deactivate();

    final url = _webSocketUrl(token);
    print('🔌 STOMP(WebSocket) 접속 시도 → $url');

    final completer = Completer<void>();

    _client = StompClient(
      config: StompConfig(
        url: url,
        onConnect: (StompFrame frame) {
          _connected = true;
          print('✅ STOMP/WebSocket 연결 성공');
          if (_onConnectCallback != null) {
            _onConnectCallback!();
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onWebSocketError: (dynamic error) async {
          _connected = false;
          print('❌ WebSocket 오류: $error');

          if (error is WebSocketException && error.httpStatusCode == 403) {
            await _handleReissueAndReconnect();
          }
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDisconnect: (StompFrame frame) {
          _connected = false;
          print('🔌 STOMP/WebSocket 연결이 예기치 않게 종료되었습니다.');
        },
        onStompError: (StompFrame frame) {
          print('⚠️ STOMP 오류: ${frame.body}');
          if (!completer.isCompleted) {
            completer.completeError(Exception(frame.body ?? 'Unknown STOMP error'));
          }
        },
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
      ),
    );

    _client!.activate();
    return completer.future;
  }

  static Future<void> _handleReissueAndReconnect() async {
    if (_isReissuing) {
      print('⚠️ 이미 토큰 재발급 중입니다. 완료될 때까지 대기합니다.');
      await _reissueCompleter?.future;
      print('⌛️ 대기 완료. 재연결을 시도합니다.');
      if (_lastToken != null) {
        await connect(_lastToken!, onConnect: _onConnectCallback);
      }
      return;
    }

    print('🔑 WebSocket 403 에러: 토큰 재발급을 시작합니다.');
    _isReissuing = true;
    _reissueCompleter = Completer<void>();

    try {
      final refreshToken = await SecureStorageService().getRefreshToken();
      if (refreshToken == null) throw Exception('리프레시 토큰이 없습니다.');

      final response = await DioClient.dio.post(
        ApiConstants.reissueEndPoint,
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'] as String?;
      final newRefreshToken = response.data['refreshToken'] as String?;

      if (newAccessToken != null && newRefreshToken != null) {
        await SecureStorageService().saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        _lastToken = newAccessToken;
        print('🔄 토큰 재발급 완료. 새로운 토큰으로 재연결을 시도합니다.');
        await connect(newAccessToken, onConnect: _onConnectCallback);
      } else {
        throw Exception('서버로부터 새로운 토큰을 받지 못했습니다.');
      }
    } catch (e) {
      print('❌ 토큰 재발급 실패: $e');
      disconnect();
    } finally {
      _isReissuing = false;
      _reissueCompleter?.complete();
    }
  }

  static void disconnect() {
    _lastToken = null;
    _client?.deactivate();
    _client = null;
    _connected = false;
    print('🔌 STOMP(WebSocket) 연결을 명시적으로 종료합니다.');
  }

  // --- 기존 구독(subscribe) 및 기타 메서드들은 그대로 유지 ---

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

  static StompClient? get client => _client;
}