import 'package:flutter/material.dart';

class PartyCreateScreen extends StatelessWidget {
  const PartyCreateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("팟 생성하기"),
      ),
      body: const Center(
        child: Text(
          "팟 생성하기 페이지 - 구현 예정",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}