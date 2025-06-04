import 'package:flutter/material.dart';
import 'package:app2_client/services/profile_service.dart';

class MyPageCard extends StatelessWidget {
  const MyPageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: const MyPage(),
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
  double rating = 0.0;
  String profileImageUrl = '';
  bool _isLoading = true;
  List<String> topTags = [];
  int totalSavedAmount = 0;

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
          rating = (profile['review_score'] ?? 0.0).toDouble();
          profileImageUrl = profile['profileImageUrl'] ?? '';
          topTags = List<String>.from(profile['top_tags'] ?? []);
          totalSavedAmount = profile['total_saved_amount'] ?? 0;
        } else {
          name = '불러오기 실패';
        }
        _isLoading = false;
      });
    } catch (_) {
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
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _buildProfileSection(),
        const SizedBox(height: 16),
        _buildSavedAmount(),
        const SizedBox(height: 16),
        _buildRatingSection(),
        const SizedBox(height: 12),
        _buildKeywordSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage:
          profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
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
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Text('$gender(성별)',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 3),
            Text(phone, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildSavedAmount() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC33),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black),
            children: [
              const TextSpan(
                text: '현재까지 아낀 금액 ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$totalSavedAmount',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const TextSpan(
                text: ' 원',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: const BoxDecoration(color: Color(0xFFFFCC33)),
          child: const Text('평점',
              style: TextStyle(fontSize: 13, color: Colors.white)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFCC33)),
          ),
          child: Text('#${rating.toStringAsFixed(1)}',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFFFCC33))),
        ),
      ],
    );
  }

  Widget _buildKeywordSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: const BoxDecoration(color: Color(0xFF003366)),
          child: const Text('후기 키워드',
              style: TextStyle(fontSize: 12, color: Colors.white)),
        ),
        Expanded(
          child: Wrap(
            spacing: 0,
            runSpacing: 0,
            children: topTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EEF8),
                    border: Border.all(color: const Color(0xFF003366), width: 0.8)
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF003366)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
