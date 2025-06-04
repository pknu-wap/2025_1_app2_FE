import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app2_client/screens/my_page_content.dart';
import 'package:app2_client/services/auth_service.dart';

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
              padding: const EdgeInsets.only(top: 50, right: 5),
              child: Container(
                width: 320,
                height: 450,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    /// 콘텐츠
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 상단 로고 + 알림 아이콘
                          Row(
                            children: [
                              Image.asset(
                                'assets/app_wide_logo.png',
                                height: 50,
                                width: 130,
                                fit: BoxFit.contain,
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),  // 알림 아이콘 눌렀을 때 닫기
                                child: Image.asset(
                                  'assets/user_notify_icon.png',
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          /// 마이페이지 카드
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 15),
                            child: Text(
                              '----------------------------------------- 내 정보',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                          Stack(
                            children: [
                              const MyPageCard(),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.close, size: 20, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 4, top: 13),
                            child: Text(
                              '-----------------------------------------------',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// 로그아웃 버튼
                    Positioned(
                      bottom: 1,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.grey),
                        tooltip: '로그아웃',
                        onPressed: () async {
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("로그아웃"),
                              content: const Text("정말 로그아웃 하시겠어요?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("취소"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("로그아웃"),
                                ),
                              ],
                            ),
                          );

                          if (shouldLogout == true) {
                            await AuthService().logout();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                                  (route) => false,
                            );
                          }
                        },
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
