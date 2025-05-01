// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:app2_client/services/auth_service.dart';
import 'package:app2_client/screens/destination_select_screen.dart';

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
  String _phone = '', _age = '', _gender = 'MALE';

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    final resp = await AuthService().registerOnServer(
      idToken: widget.idToken,
      accessToken: widget.accessToken,
      name: widget.name,
      phone: _phone,
      age: int.parse(_age),
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
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.name,
                decoration: const InputDecoration(labelText: '이름'),
                readOnly: true,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '휴대폰 번호'),
                onSaved: (v) => _phone = v!,
                validator: (v) => v!.isEmpty ? '필수 입력' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '나이'),
                onSaved: (v) => _age = v!,
                validator: (v) => v!.isEmpty ? '필수 입력' : null,
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('남성')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                ],
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text('회원가입 완료')),
            ],
          ),
        ),
      ),
    );
  }
}
