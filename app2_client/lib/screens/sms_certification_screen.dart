import 'package:app2_client/models/sms_session_model.dart';
import 'package:app2_client/models/sms_verify_model.dart';
import 'package:app2_client/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';

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
  SmsSessionModel? _session;

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
            _buildStepText('① 하단 [인증 메시지 보내기] 눌러주세요'),
            const SizedBox(height: 16),
            _buildStepText('② 메시지 작성 창에서, 인증 메시지가 자동으로 입력되어 있습니다.'),
            const SizedBox(height: 16),
            _buildStepText('③ 인증 메시지를 그대로 보내주세요.'),
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
                onPressed: isVerifying ? null : () async {
                  await showSms();
                  await verifySms();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: Text(
                  isVerifying ? '인증 중...' : '인증 메시지 보내기',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isVerifying ? Colors.grey[600] : Colors.white
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> showSms() async {
    _session = await _authService.getSessionKey();
    if (_session == null) return;

    final String sendTo = _session!.sendTo; // ex: "@gmail.com"
    final String smsBody = _session!.key; // ex: "인증용 키"

    isVerifying = true;
    String result = await sendSMS(message: smsBody, recipients: [sendTo], sendDirect: false)
        .catchError((error) {
          if (!mounted) return '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SMS 전송을 지원하지 않는 단말기입니다.')),
      );
      isVerifying = false;
      print(error);
      return '';
    });
    if (result != 'sent' && result != 'SMS Sent!') {
      isVerifying = false;
      return;
    }
  }

  Future<void> verifySms() async {
    if (!isVerifying || !mounted || _session == null) return;

    showLoadingDialog(context);

    await Future.delayed(const Duration(milliseconds: 6000)); // 대기안하면 에러..
    SmsVerifyModel? model = await _authService.verifySms(_session!.key);
    if (!mounted) return;

    hideLoadingDialog(context);
    isVerifying = false;

    if (model == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증에 실패했습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => SignupScreen(
          session: _session!.key,
          idToken: widget.idToken,
          accessToken: widget.accessToken,
          name: widget.name,
          email: widget.email,
          phone: model.phoneNumber,
        ),
      ),
          (Route<dynamic> route) => false,
    );
  }

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
    Navigator.of(context, rootNavigator: true).pop();
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
          // 받는 사람 영역
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
          // 구분선
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          // 메시지 입력 영역
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
                  // 메시지 입력창
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        Icon(
                          Icons.arrow_upward_rounded,
                          color: const Color(0xFF003366),
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
