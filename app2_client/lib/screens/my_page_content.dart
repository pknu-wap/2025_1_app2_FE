import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/services/profile_service.dart';
import 'package:app2_client/providers/auth_provider.dart';

class MyPageCard extends StatelessWidget {
  const MyPageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const MyPage(),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.close, size: 24, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

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
  double rating = 0.0;
  String profileImageUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final profile = await ProfileService.getProfile();
      setState(() {
        if (profile != null) {
          name = profile['name'] ?? '이름 없음';
          phone = profile['phone'] ?? '';
          gender = profile['gender'] == 'MALE' ? '남' : '여';
          age = profile['age'] ?? 0;
          rating = (profile['review_score'] ?? 0.0).toDouble();
          profileImageUrl = profile['profileImageUrl'] ?? '';
        } else {
          name = '불러오기 실패';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        name = '에러 발생';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null,
              backgroundColor: Colors.grey.shade300,
              child: profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 30, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'jua')),
                    const SizedBox(width: 8),
                    Text('$age세 ($gender)',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey, fontFamily: 'jua')),
                  ],
                ),
                const SizedBox(height: 4),
                Text(phone,
                    style: const TextStyle(fontSize: 16, fontFamily: 'jua')),
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
            child: Text('아낀 금액 ‘ ------- 원 ’',
                style: TextStyle(fontSize: 16, fontFamily: 'jua')),
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
                  style: TextStyle(
                      fontSize: 14, color: Colors.white, fontFamily: 'jua')),
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
              child: Text('#${rating.toStringAsFixed(1)}',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFF6C651),
                      fontFamily: 'jua')),
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
              child: const Text('후기 키워드',
                  style: TextStyle(
                      fontSize: 13, color: Colors.white, fontFamily: 'jua')),
            ),
            const SizedBox(width: 8),
            const Text('#친절 #시간 엄수',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F355F),
                    fontFamily: 'jua')),
          ],
        ),
      ],
          ),
          // 로그아웃 버튼 추가
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // 로그아웃 실행
                context.read<AuthProvider>().logout();
              },
              child: const Text('로그아웃', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
