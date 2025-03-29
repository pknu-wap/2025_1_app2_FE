import 'package:flutter/material.dart';
import 'package:app2_client/models/user_model.dart';
import 'package:app2_client/services/auth_service.dart';

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onLoginSuccess; // 콜백 추가

  const GoogleLoginButton({super.key, required this.onLoginSuccess}); // 생성자에 추가

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          // UserModel을 받아오기
          final UserModel? user = await AuthService().loginWithGoogle();

          final message = user != null ? "로그인 성공!" : "로그인 실패";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );

          // 로그인 성공 시 콜백 실행
          if (user != null) {
            onLoginSuccess(); // LoginScreen에서 정의한 화면 전환 함수 실행
          }
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: const BorderSide(color: Colors.grey),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/google_logo.png',
              height: 20,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Sign in with Google',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
