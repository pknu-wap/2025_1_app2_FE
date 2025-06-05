import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class PaymentNotification extends StatelessWidget {
  final String memberName;
  final int amount;

  const PaymentNotification({
    super.key,
    required this.memberName,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text('$memberName님이 입금을 완료했습니다'),
        subtitle: Text('입금액: ${amount.toString()}원'),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            OverlaySupportEntry.of(context)?.dismiss();
          },
        ),
      ),
    );
  }

  void show() {
    showOverlayNotification(
      (context) {
        return SafeArea(child: build(context));
      },
      duration: const Duration(seconds: 4),
    );
  }
} 