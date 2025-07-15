// lib/screens/sms_certification_screen.dart
// [MODIFIED] 시뮬레이터 테스트를 위해 SMS 인증 과정을 우회하도록 수정된 파일입니다.

import 'package:app2_client/models/sms_session_model.dart';
import 'package:app2_client/models/sms_verify_model.dart';
import 'package:app2_client/screens/signup_screen.dart';
import 'package:flutter/material.dart';

// [REMOVED] SMS 전송 기능을 사용하지 않으므로 관련 패키지를 제거합니다.
// import 'package:flutter_sms/flutter_sms.dart';

import '../services/auth_service.dart';

class SmsCertificationScreen extends StatefulWidget {
  final String idToken, accessToken, name, email;
  const SmsCertificationScreen({
    super.key,
    required this.idToken,
    required this.accessToken,
    required this.name,
    required this.email,
  });

  @override
  State<SmsCertificationScreen> createState() => _SmsCertificationScreenState();
}

class _SmsCertificationScreenState extends State<SmsCertificationScreen> {
  final AuthService _authService = AuthService();
  bool isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              '기기인증 안내',
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            // [MODIFIED] 변경된 인증 절차에 맞게 안내 문구를 수정했습니다.
            _buildStepText('① 하단 [인증 진행하기] 버튼을 눌러주세요.'),
            const SizedBox(height: 16),
            _buildStepText('② 시뮬레이터 테스트를 위해 SMS 전송을 건너뛰고, 서버에서 바로 인증을 진행합니다.'),
            const SizedBox(height: 16),
            _buildStepText('③ 잠시 후 인증이 완료되고, 회원가입 화면으로 이동합니다.'),
            const SizedBox(height: 40),
            Center(child: _buildPhoneMockup()),
            const SizedBox(height: 32),
            Text(
              '이용 중인 통신 요금제에 따라 문자 메시지 발송 비용이 청구될 수 있습니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(flex: 5),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                // [MODIFIED] 버튼 클릭 시 새로운 인증 함수를 호출하도록 변경했습니다.
                onPressed: isVerifying ? null : _startVerificationProcess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: Text(
                  // [MODIFIED] 버튼 텍스트를 수정했습니다.
                  isVerifying ? '인증 중...' : '인증 진행하기',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isVerifying ? Colors.grey[600] : Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // [ADDED] 시뮬레이터 테스트를 위해 SMS 전송을 건너뛰고 바로 서버 인증을 처리하는 새로운 함수입니다.
  Future<void> _startVerificationProcess() async {
    if (isVerifying) return;

    setState(() {
      isVerifying = true;
    });
    showLoadingDialog(context);

    try {
      // 1. 세션 키는 여전히 백엔드로부터 받아와야 합니다.
      final SmsSessionModel? session = await _authService.getSessionKey();
      if (!mounted || session == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('세션 정보를 가져오지 못했습니다.')),
          );
        }
        return;
      }

      // 2. [BYPASS] 실제 SMS를 보내는 과정을 생략합니다.
      // 백엔드가 항상 인증 성공을 반환하므로 바로 다음 단계로 진행합니다.
      await Future.delayed(const Duration(seconds: 2)); // 통신 지연 시뮬레이션

      // 3. SMS 인증 API를 호출합니다. 이 호출은 항상 성공하고 전화번호를 반환합니다.
      final SmsVerifyModel? model = await _authService.verifySms(session.key);
      if (!mounted || model == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인증에 실패했습니다. 다시 시도해 주세요.')),
          );
        }
        return;
      }

      // 4. 인증 성공 시, 회원가입 화면으로 이동합니다.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => SignupScreen(
            session: session.key,
            idToken: widget.idToken,
            accessToken: widget.accessToken,
            name: widget.name,
            email: widget.email,
            phone: model.phoneNumber, // 인증 성공 후 받은 전화번호를 전달합니다.
          ),
        ),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      // 5. 성공/실패 여부와 관계없이 UI 상태를 정리합니다.
      if (mounted) {
        hideLoadingDialog(context);
        setState(() {
          isVerifying = false;
        });
      }
    }
  }

  // [REMOVED] 기존의 showSms, verifySms 함수는 새로운 로직으로 대체되어 제거되었습니다.

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Widget _buildStepText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16.5,
        color: Color(0xFF444444),
      ),
    );
  }

  Widget _buildPhoneMockup() {
    return Container(
      width: 320,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '받는 사람',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'verify@gmail.com',
                  style: TextStyle(
                    color: Color(0xFF003366),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'kjsu34kjd9fdjflejdnalsmcff8d7djldkfls3k5',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_upward_rounded,
                          color: Color(0xFF003366),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}