import 'package:flutter/material.dart';

class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          // TODO: 구글 로그인 연결
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
            // 구글 로고 이미지 호출; 에셋 등록과 경로 확인 필수!
            Image.asset(
              'assets/google_logo.png',
              height: 20,
              errorBuilder: (context, error, stackTrace) {
                // 에셋 로드에 실패하면 빈 컨테이너로 대체하거나, placeholder 이미지 표시
                return const SizedBox();
              },
            ),
            const SizedBox(width: 12),
            // Expanded로 텍스트를 감싸서 남은 공간에 맞게 줄어들도록 함
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