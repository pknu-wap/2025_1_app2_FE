// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:app2_client/services/auth_service.dart';
import 'package:app2_client/screens/destination_select_screen.dart';
import 'package:app2_client/widgets/phone_number_formatter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app2_client/services/secure_storage_service.dart';

class SignupScreen extends StatefulWidget {
  final String session, idToken, accessToken, name, email, phone;
  const SignupScreen({
    super.key,
    required this.session,
    required this.idToken,
    required this.accessToken,
    required this.name,
    required this.email,
    required this.phone
  });
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  String _phone = '', _age = '20', _gender = 'MALE';

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    final resp = await AuthService().registerOnServer(
      session: widget.session,
      idToken: widget.idToken,
      accessToken: widget.accessToken,
      name: widget.name,
      phone: widget.phone,
      age: 20, //현재 나이 필드에대한 가이드 존재 X, 따라서 하드코딩
      gender: _gender,
    );

    if (resp != null) {
      // ✅ accessToken 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', widget.accessToken);

      // 사용자 정보 저장
      await SecureStorageService().saveUserInfo(
        userId: widget.email,
        userName: widget.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 완료!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DestinationSelectScreen()),
      );
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '회원 정보 입력',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '회원여부 확인 및 가입을 진행합니다.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 32),

                // 이름
                Text('이름'),
                SizedBox(height: 8),
                TextFormField(
                  initialValue: widget.name,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: '이름',
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                Text('성별'),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _gender = 'MALE'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: null,
                          side: BorderSide(
                            color: _gender == 'MALE'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                          ),
                          foregroundColor: _gender == 'MALE'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('남자'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _gender = 'FEMALE'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: null,
                          side: BorderSide(
                            color: _gender == 'FEMALE'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                          ),
                          foregroundColor: _gender == 'FEMALE'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('여자'),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                Text('전화번호'),
                SizedBox(height: 8),
                TextFormField(
                  initialValue: widget.phone,
                  keyboardType: TextInputType.phone,
                  readOnly: true,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(13), // 하이픈 포함 시 최대 13자
                    FilteringTextInputFormatter.digitsOnly,
                    PhoneNumberFormatter()],
                  decoration: InputDecoration(
                    hintText: '전화번호 입력',
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  onSaved: (v) => _phone = v!,
                  validator: (v) {
                    if (v == null || v.isEmpty) return '필수 입력';
                    if (!v.startsWith('010')) return '알맞지 않은 전화번호입니다';
                    return null;
                  },
                ),
                SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF003366),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('회원가입',style: TextStyle(color: Colors.white, fontSize: 18),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
