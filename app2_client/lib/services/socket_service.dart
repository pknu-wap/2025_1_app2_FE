import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class SocketService {
  static final _serverUrl = 'ws://3.105.16.234:8080/ws-stomp/websocket'; // 실제 주소
  static StompClient? _client;
  static bool _connected = false;

  static void connect(String token, {void Function()? onConnect}) {
    if (_connected) return;
    _client = StompClient(
      config: StompConfig.SockJS(
        url: '$_serverUrl?token=$token',
        onConnect: (StompFrame frame) {
          _connected = true;
          print('✅ WebSocket 연결됨');
          if (onConnect != null) onConnect();
        },
        onWebSocketError: (error) => print('❌ WebSocket 에러: $error'),
        onDisconnect: (frame) {
          _connected = false;
          print('🔌 WebSocket 연결 종료');
        },
        onStompError: (frame) => print('⚠️ STOMP 에러: ${frame.body}'),
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
      ),
    );
    _client!.activate();
  }

  static void subscribe({
    required String topic,
    required void Function(Map<String, dynamic> message) onMessage,
  }) {
    _client?.subscribe(
      destination: topic,
      callback: (frame) {
        if (frame.body != null) {
          final data = json.decode(frame.body!);
          if (data is Map<String, dynamic>) {
            onMessage(data);
          }
        }
      },
    );
  }

  static void disconnect() {
    _client?.deactivate();
    _connected = false;
  }
}