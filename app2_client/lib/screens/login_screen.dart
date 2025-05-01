// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/screens/signup_screen.dart';
import 'package:app2_client/screens/destination_select_screen.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text('구글로 로그인하기'),
          onPressed: () async {
            final result = await auth.login();
            if (result == 'SUCCESS') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => DestinationSelectScreen()),
              );
            } else if (result == 'MEMBER_NOT_FOUND') {
              final u = auth.user!;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SignupScreen(
                    idToken: u.idToken,
                    accessToken: u.accessToken,
                    name: u.name,
                    email: u.email,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('로그인 실패: $result')),
              );
            }
          },
        ),
      ),
    );
  }
}