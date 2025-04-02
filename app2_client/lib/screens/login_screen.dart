import 'package:flutter/material.dart';
import 'package:app2_client/widgets/google_login_button.dart';
import 'package:app2_client/screens/signup_screen.dart';
import 'package:app2_client/screens/destination_select_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('로그인', style: TextStyle(fontSize: 20, color: Colors.grey)),
              const SizedBox(height: 80),
              const Text('같이타요', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('앱 설명', style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 100),
              const Text('이메일로 로그인', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 10),

              // 수정된 GoogleLoginButton: 콜백 전달
              GoogleLoginButton(
                onLoginSuccess: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DestinationSelectScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  child: const Text(
                    '계정이 없으신가요? 회원가입하러 가기',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
