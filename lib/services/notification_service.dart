import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance =
      NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// 🔔 Call this ONCE from main()
  Future<void> initialize() async {
    try {
      await _requestPermission();
      await _setupLocalNotifications();
      await _setupFCM();
    } catch (e) {
      debugPrint('❌ Notification init error: $e');
    }
  }

  /// =============================
  /// 🔐 PERMISSIONS
  /// =============================
  Future<void> _requestPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint(
        '🔔 Permission: ${settings.authorizationStatus}',
      );
    }
  }

  /// =============================
  /// 🔧 LOCAL NOTIFICATIONS
  /// =============================
  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('🟢 Notification tapped: ${response.payload}');
      },
    );
  }

  /// =============================
  /// ☁️ FCM SETUP
  /// =============================
  Future<void> _setupFCM() async {
    _fcmToken = await _messaging.getToken();
    debugPrint('🔥 FCM Token: $_fcmToken');

    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('🔄 Token refreshed: $token');
    });

    /// Foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    /// When user taps notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    /// When app opened from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onNotificationTap(initialMessage);
    }
  }

  /// =============================
  /// 📩 MESSAGE HANDLERS
  /// =============================
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('📩 Foreground message received');

    if (message.notification == null) return;

    await showLocalNotification(
      title: message.notification!.title ?? 'New Message',
      body: message.notification!.body ?? '',
      payload: message.data.toString(),
    );
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('👉 Notification tapped');
    debugPrint('📦 Data: ${message.data}');

    // TODO: Navigate to room/chat if needed
    // Example: roomId = message.data['roomId']
  }

  /// =============================
  /// 🔊 SHOW LOCAL NOTIFICATION
  /// =============================
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'confession_channel',
      'Confession Notifications',
      channelDescription: 'Chat & room notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// =============================
  /// 📢 TOPICS
  /// =============================
  Future<void> subscribeToRoom(String roomId) async {
    await _messaging.subscribeToTopic('room_$roomId');
    debugPrint('✅ Subscribed to room_$roomId');
  }

  Future<void> unsubscribeFromRoom(String roomId) async {
    await _messaging.unsubscribeFromTopic('room_$roomId');
    debugPrint('❌ Unsubscribed from room_$roomId');
  }
}
