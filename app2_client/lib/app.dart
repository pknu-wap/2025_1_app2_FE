import 'package:app2_client/main.dart';
import 'package:app2_client/screens/login_screen.dart';
import 'package:app2_client/screens/root_screen.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gachitayo',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF003366)),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF003366))
          )
        ),
        useMaterial3: true,
      ),
      home: RootScreen(),
    );
  }
}