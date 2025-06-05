import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ PushNotificationService: 이미 초기화되어 있습니다.');
      return;
    }

    try {
      // Firebase 초기화 확인
      if (!Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // FCM 권한 요청
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔔 FCM 권한 상태: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // FCM 토큰 가져오기
        String? token = await _fcm.getToken();
        if (token != null) {
          debugPrint('✅ FCM 토큰 발급 성공');
          await _updateFcmToken(token);
        }

        // 토큰 갱신 리스너
        _fcm.onTokenRefresh.listen((String token) {
          debugPrint('🔄 FCM 토큰 갱신');
          _updateFcmToken(token);
        });

        // 로컬 알림 초기화
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
            
        const DarwinInitializationSettings initializationSettingsIOS =
            DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

        await _flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _handleNotificationTap,
        );

        // Foreground 메시지 핸들링
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Background 메시지 핸들링 설정
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        _isInitialized = true;
        debugPrint('✅ PushNotificationService 초기화 완료');
      } else {
        debugPrint('⚠️ FCM 권한이 거부되었습니다.');
      }
    } catch (e) {
      debugPrint('❌ PushNotificationService 초기화 실패: $e');
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('🔔 알림 탭: ${response.payload}');
    // TODO: 알림 탭 시 처리 로직 구현
  }

  Future<void> _updateFcmToken(String token) async {
    final baseUrl = dotenv.env['BACKEND_BASE_URL']!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM 토큰 서버 등록 성공');
      } else {
        debugPrint('⚠️ FCM 토큰 서버 등록 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FCM 토큰 서버 등록 오류: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('📨 Foreground 메시지 수신: ${message.messageId}');
      
      RemoteNotification? notification = message.notification;

      if (notification != null) {
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
              showWhen: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
        debugPrint('✅ 로컬 알림 표시 완료');
      }
    } catch (e) {
      debugPrint('❌ Foreground 메시지 처리 오류: $e');
    }
  }

  Future<void> dispose() async {
    _isInitialized = false;
    debugPrint('🔌 PushNotificationService 종료');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📨 Background 메시지 수신: ${message.messageId}');
  // TODO: Background 메시지 처리 로직 구현
} 