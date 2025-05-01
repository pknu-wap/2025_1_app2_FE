// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:app2_client/services/auth_service.dart';
import 'package:app2_client/screens/destination_select_screen.dart';
import 'package:app2_client/widgets/phone_number_formatter.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatefulWidget {
  final String idToken, accessToken, name, email;
  const SignupScreen({
    super.key,
    required this.idToken,
    required this.accessToken,
    required this.name,
    required this.email,
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
      idToken: widget.idToken,
      accessToken: widget.accessToken,
      name: widget.name,
      phone: _phone,
      age: 20, //현재 나이 필드에대한 가이드 존재 X, 따라서 하드코딩
      gender: _gender,
    );

    if (resp != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 완료!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DestinationSelectScreen()),
      );
    } else {
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
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(13), // 하이픈 포함 시 최대 13자
                    FilteringTextInputFormatter.digitsOnly,
                    PhoneNumberFormatter()],
                  decoration: InputDecoration(
                    hintText: '전화번호 입력',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
