import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase 추가 시 사용
import 'firebase_options.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/app.dart';
import 'package:overlay_support/overlay_support.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authProvider = AuthProvider();
  await authProvider.initTokens();

  runApp(
    OverlaySupport.global(
      child: ChangeNotifierProvider.value(
        value: authProvider,
        child: Platform.isAndroid
          ? SafeArea(child: const MyApp())
          : const MyApp(),
      ),
    ),
  );
}