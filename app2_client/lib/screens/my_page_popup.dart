// lib/screens/my_page_popup.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app2_client/screens/home_star.dart';
import 'package:app2_client/screens/my_page_content.dart';

class MyPagePopup {
  static void show(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 320,
              constraints: const BoxConstraints(
                maxHeight: 700,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, size: 20, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 8),
                    MyPage(),
                    const SizedBox(height: 24),
                    const Text(
                      '동승자를 평가해주세요!',
                      style: TextStyle(fontSize: 16, fontFamily: 'jua'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1F355F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReviewPage()),
                          );
                        },
                        child: const Text('평가하러 가기', style: TextStyle(fontSize: 14, fontFamily: 'jua', color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
