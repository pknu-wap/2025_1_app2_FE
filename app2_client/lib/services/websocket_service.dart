import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _fareUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get fareUpdates => _fareUpdateController.stream;

  void connect(String partyId, String token) {
    final wsUrl = dotenv.env['WS_BASE_URL']!;
    final uri = Uri.parse('$wsUrl/ws/fare/$partyId');
    
    _channel = WebSocketChannel.connect(uri);
    _channel!.sink.add(token); // 연결 시 토큰 전송

    _channel!.stream.listen(
      (dynamic message) {
        final data = Map<String, dynamic>.from(message);
        _fareUpdateController.add(data);
      },
      onError: (error) {
        print('WebSocket 에러: $error');
        reconnect(partyId, token);
      },
      onDone: () {
        print('WebSocket 연결 종료');
        reconnect(partyId, token);
      },
    );
  }

  void reconnect(String partyId, String token) {
    Future.delayed(const Duration(seconds: 5), () {
      connect(partyId, token);
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _fareUpdateController.close();
  }
} 