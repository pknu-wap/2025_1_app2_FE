import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PushNotificationService {
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
      String? token = await _fcm.getToken();
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
        },
      );

      // Foreground 메시지 핸들링
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background 메시지 핸들링
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  Future<void> _updateFcmToken(String token) async {
    final baseUrl = dotenv.env['BACKEND_BASE_URL']!;
    try {
      await http.post(
        Uri.parse('$baseUrl/api/users/fcm-token'),
        body: {'token': token},
      );
    } catch (e) {
      print('FCM 토큰 업데이트 실패: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background 메시지 처리
  print('Background message: ${message.messageId}');
} 