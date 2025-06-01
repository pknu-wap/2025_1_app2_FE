import 'package:app2_client/screens/destination_select_screen.dart';
import 'package:app2_client/screens/login_screen.dart';
import 'package:app2_client/services/secure_storage_service.dart';
import 'package:flutter/material.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SecureStorageService().getAccessToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          return DestinationSelectScreen(); // 지도 선택
        } else {
          return LoginScreen(); // 로그인화면
        }
      },
    );
  }
}
