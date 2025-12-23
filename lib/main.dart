import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/security_service.dart';
import 'services/notification_service.dart';

/// 🔕 BACKGROUND HANDLER (MUST BE TOP-LEVEL)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔕 Background notification: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase FIRST
  await Firebase.initializeApp();

  // 🔔 Register background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // 🟢 Initialize Supabase
  await Supabase.initialize(
    url: 'https://uxmvmbohsqnlyhfloceh.supabase.co',
    anonKey: 'sb_publishable_a1O0xCNaJ-U4M5BgWncbxg_ZiGNRslz',
  );

  // 🔔 Initialize Notification Service (SINGLETON)
  final notificationService = NotificationService.instance;
  await notificationService.initialize();

  // 🎨 System UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFE6E6FA),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 🔒 Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
        Provider(create: (_) => SecurityService()),
        Provider.value(value: notificationService),
      ],
      child: const ConfessionApp(),
    ),
  );
}
