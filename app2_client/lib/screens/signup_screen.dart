import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _phone = '';
  String _age = '';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // 여기서 백엔드에 회원가입 정보 POST 요청을 보낼 수 있습니다.
      print('이름: $_name, 휴대폰: $_phone, 나이: $_age');
      // 예를 들어, API 호출 후 홈 화면으로 이동:
      // Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: '이름'),
                onSaved: (value) => _name = value ?? '',
                validator: (value) =>
                value == null || value.isEmpty ? '이름을 입력하세요' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '휴대폰 번호'),
                keyboardType: TextInputType.phone,
                onSaved: (value) => _phone = value ?? '',
                validator: (value) =>
                value == null || value.isEmpty ? '휴대폰 번호를 입력하세요' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '나이'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _age = value ?? '',
                validator: (value) =>
                value == null || value.isEmpty ? '나이를 입력하세요' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('회원가입 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}