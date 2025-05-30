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
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 21, right: 5),
              child: Container(
                width: 320,
                height: 700,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 로고 + 알림 아이콘
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, right: 16, top: 30),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/app_wide_logo.png',
                              height: 50,
                              width: 130,
                              fit: BoxFit.contain,
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Image.asset(
                                'assets/user_notify_icon.png',
                                height: 38,
                                width: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Text(
                        '------------------------------------- 내 정보',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w100,
                          fontFamily: 'jua',
                          color: Colors.black12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    /// 사용자 정보 카드 (디자인 포함)
                    const MyPageCard(),

                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Text(
                        '---------------------------------------- 평가',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w100,
                          fontFamily: 'jua',
                          color: Colors.black12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// 평가 카드
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFFEAF3FB),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '동승자를 평가해주세요!',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'jua',
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F355F),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ReviewPage()),
                                );
                              },
                              child: const Text(
                                '평가하러 가기',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'jua',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
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