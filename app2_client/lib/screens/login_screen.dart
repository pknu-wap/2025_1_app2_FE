import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/providers/auth_provider.dart';
import 'package:app2_client/screens/signup_screen.dart';
import 'package:app2_client/screens/destination_select_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_button/sign_in_button.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //현재 마진은 가이드에 정확하게 나와있지않아 대략적으로 설정
              SizedBox(height: 100),
              Image.asset(
                'assets/app_wide_logo.png',
                height: 30,
              ),

              const SizedBox(height: 8),
              Text(
                '택시 모임 서비스',
                style: TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 100),

              Text(
                '이메일로 로그인',
                style: TextStyle(fontSize: 12),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 40,
                width: double.infinity,
                child: SignInButton(
                  Buttons.google,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 1,
                  onPressed: () async {
                    final result = await auth.login();
                    if (result == 'SUCCESS') {
                      // ✅ accessToken 저장
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('accessToken', auth.tokens!.accessToken);
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
            ],
          ),
        ),
      ),
    );
  }
}
