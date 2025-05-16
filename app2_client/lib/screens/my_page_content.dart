import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app2_client/services/profile_service.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String name = '';
  String phone = '';
  String gender = '';
  int age = 0;
  double rating = 3.2;
  List<String> tags = ['친절', '시간 엄수'];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final accessToken = await getAccessToken();
      final profile = await ProfileService().getProfile(accessToken);

      if (profile != null) {
        setState(() {
          name = profile['name'] ?? '이름 없음';
          phone = profile['phone'] ?? '';
          gender = profile['gender'] == 'MALE' ? '남' : '여';
          age = profile['age'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          name = '불러오기 실패';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        name = '에러 발생';
        _isLoading = false;
      });
    }
  }

  Future<String> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) throw Exception('accessToken이 없습니다.');
    return token;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                // 👤 사용자 정보
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
                              '$age세 ($gender)',
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

                // 💰 아낀 금액
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

                // 🌟 평점
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

                // 🏷️ 후기 키워드
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
