import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';

class PushNotificationService {
  final _logger = Logger('PushNotificationService');
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // FCM 권한 요청
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // FCM 토큰 가져오기
      final token = await _fcm.getToken();
      if (token != null) {
        await _updateFcmToken(token);
      }

      // 토큰 갱신 리스너
      _fcm.onTokenRefresh.listen(_updateFcmToken);

      // 로컬 알림 초기화
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings();
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // 알림 탭 핸들링
          _logger.info('알림 탭: ${response.payload}');
        },
      );

      // Foreground 메시지 핸들링
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background 메시지 핸들링
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  Future<void> _updateFcmToken(String token) async {
    final baseUrl = dotenv.env['BACKEND_BASE_URL'];
    if (baseUrl == null) {
      _logger.severe('BACKEND_BASE_URL이 설정되지 않았습니다.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/fcm-token'),
        body: {'token': token},
      );
      
      if (response.statusCode != 200) {
        _logger.warning('FCM 토큰 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('FCM 토큰 업데이트 중 오류 발생', e);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fare_channel',
            '정산 알림',
            channelDescription: '정산 관련 알림을 표시합니다.',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = Logger('BackgroundMessageHandler');
  logger.info('Background message received: ${message.messageId}');
} 