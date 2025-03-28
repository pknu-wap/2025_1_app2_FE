import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _age = '';
  String? _gender;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final additionalInfo = {
        'name': _name,
        'phone': _phone,
        'age': _age,
        'gender': _gender,
      };

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.completeSignup(additionalInfo);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원가입이 완료되었습니다!")),
        );
        // 임시: 홈 화면이 없으므로 로그인 화면 등 다른 적절한 화면으로 이동하거나
        // 그냥 현재 상태를 유지할 수 있습니다.
        // 예: Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원가입 실패")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final genderOptions = ['남', '여'];

    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "이름"),
                onSaved: (val) => _name = val ?? '',
                validator: (val) =>
                val == null || val.isEmpty ? "이름을 입력하세요" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "휴대폰 번호"),
                keyboardType: TextInputType.phone,
                onSaved: (val) => _phone = val ?? '',
                validator: (val) =>
                val == null || val.isEmpty ? "휴대폰 번호를 입력하세요" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "나이"),
                keyboardType: TextInputType.number,
                onSaved: (val) => _age = val ?? '',
                validator: (val) =>
                val == null || val.isEmpty ? "나이를 입력하세요" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("회원가입 완료"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}