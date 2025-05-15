import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_star.dart';

void main() {
  runApp(const MaterialApp(
    home: MyPageButton(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyPageButton extends StatelessWidget {
  const MyPageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            iconSize: 50.0,
            color: Colors.black38,
            onPressed: () {
              showCupertinoDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return Material(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        // 🔼 사용자 정보 카드 + 닫기 버튼
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 90, right: 20),
                            child: Stack(
                              children: [
                                // 카드 본체
                                Container(
                                  width: 280,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: MyPage(),
                                ),
                                // 닫기 버튼
                                Positioned(
                                  top: 20,
                                  right: 15,
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: const Icon(
                                      Icons.close,
                                      size: 20,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 🔽 하단 평가 버튼
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 390, right: 20),
                            child: Container(
                              width: 275,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '동승자를 평가해주세요!',
                                    style: TextStyle(fontSize: 16, fontFamily: 'jua'),
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
                                        style: TextStyle(fontSize: 14, fontFamily: 'jua', color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('홈 화면', style: TextStyle(fontSize: 24))),
    );
  }
}

class MyPage extends StatelessWidget {
  MyPage({super.key});

  final String name = '이름 입력';
  final String age = '19';
  final String gender = '여';
  final String phone = '010 - 1234 - 5678';
  final double rating = 3.2;
  final List<String> tags = ['친절', '시간 엄수'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(radius: 30, backgroundColor: Colors.grey),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'jua'),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$age세',
                              style: const TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'jua'),
                            ),
                            Text(
                              '($gender)',
                              style: const TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'jua'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(phone, style: const TextStyle(fontSize: 16, fontFamily: 'jua')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6C651),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('아낀 금액 ‘ ------- 원 ’', style: TextStyle(fontSize: 16, fontFamily: 'jua')),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6C651),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      child: const Text('평점',
                          style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'jua')),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFF6C651)),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        '#${rating.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 14, color: Color(0xFFF6C651), fontFamily: 'jua'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F355F),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      child: const Text(
                        '후기 키워드',
                        style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'jua'),
                      ),
                    ),
                    ...tags.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tag = entry.value;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FB),
                          border: Border.all(color: const Color(0xFF5271FF)),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(index == tags.length - 1 ? 4 : 0),
                            bottomRight: Radius.circular(index == tags.length - 1 ? 4 : 0),
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1F355F), fontFamily: 'jua'),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
