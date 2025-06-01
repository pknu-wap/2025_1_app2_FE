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

class _SmsCertificationScreenState extends State<SmsCertificationScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  bool isVerifying = false;
  SmsSessionModel? _session = null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // 앱이 포그라운드로 돌아왔을 때
    if (state == AppLifecycleState.resumed) {
      verifySms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          '기기인증 안내',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepText('① 하단 [인증 메시지 보내기] 눌러주세요'),
            const SizedBox(height: 6),
            _buildStepText('② 메시지 작성 창에서, 인증 메시지가 자동으로 입력되어 있습니다.'),
            const SizedBox(height: 6),
            _buildStepText('③ 인증 메시지를 그대로 보내주세요.'),
            const SizedBox(height: 32),
            Center(child: _buildPhoneMockup()),
            const SizedBox(height: 24),
            Text(
              '· 이용 중인 통신 요금제에 따라 문자 메시지 발송 비용이 청구될 수 있습니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  await showSms();
                  await verifySms();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20C4F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  '인증 메시지 보내기',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600
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
    if (result != 'sent') {
      isVerifying = false;
      return;
    }
  }

  Future<void> verifySms() async {
    if (!isVerifying || !mounted || _session == null) return;

    showLoadingDialog(context);

    await Future.delayed(const Duration(milliseconds: 8000)); // 7초 대기.. 너무 느림
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Stack(
        children: [
          // Phone receiver text
          Positioned(
            top: 30,
            left: 30,
            child: RichText(
              text: const TextSpan(
                text: '받는 사람 : ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                children: [
                  TextSpan(
                    text: '1000-1000',
                    style: TextStyle(
                      color: Color(0xFF20C4F8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Message box
          Positioned(
            top: 60,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.07),
                    blurRadius: 2,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: '인증문자 보내기\n',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: 'kjsu34kjd9fdjflejdnalsmcff8d7djldkfls3k5\n'
                                'k4jfnd9clskhdfwrsk4jfnd9clskhdfwrsk4jfnd9clskhdfwrs',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_upward_rounded,
                    color: const Color(0xFF20C4F8),
                    size: 36,
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
