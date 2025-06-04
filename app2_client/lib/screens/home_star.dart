import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:app2_client/services/review_service.dart';

class ReviewPage extends StatefulWidget {
  final int partyId; //외부에서 받아온 partyId 저장
  const ReviewPage({super.key, required this.partyId});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<Map<String, dynamic>> members = []; // 1. /api/unreview → 리뷰 대상자 가져오기
  final Map<int, double> ratings = {}; // 2. 각 멤버에 대해 리뷰 입력 받기
  final Map<int, Set<String>> selectedTags = {};

  final List<String> allTags = [
    '시간 엄수', '소통 원활', '친절한 태도',
    '상대 존중', '위치 배려', '탑승 만족 👍',
    '굿 매너', '재탑승 희망', '매너 정산러',
  ];

  String maskName(String name) {
    if (name.length <= 2) return name;
    return name[0] + '*' + name.substring(2);
  } // 가운데 이름 => 마스킹 * 처리

  @override
  void initState() {
    super.initState();
    fetchMembers(); // 1. 진입 시 리뷰 대상자 호출
  }

  Future<void> fetchMembers() async {
    final result = await ReviewService.getUnreviewTargets();
    setState(() {
      members = result.map((e) =>
      {
        'name': e['name'],
        'role': e['memberRole'] == 'HOST' ? '방장' : '팀원',
        'email': e['email'],
      }).toList();
    });
  }

  Future<void> submitReviews() async {
    for (int i = 0; i < members.length; i++) {
      final email = members[i]['email'];
      final score = ratings[i] ?? 0;
      final tags = selectedTags[i]?.toList() ?? [];

      final message = await ReviewService
          .submitReview( // 3. /api/{email}/review POST 요청
        email: email,
        partyId: widget.partyId,
        score: score,
        tags: tags,
      );

      if (message == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$email 리뷰 제출 실패')),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모든 리뷰가 제출되었습니다.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('파티원 평가하기')),
      body: members.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
        thumbVisibility: true,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(member, index),
                    const SizedBox(height: 20),
                    _buildKeywordSection(index),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: submitReviews,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '평가 제출하기',
            style: TextStyle(
                fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> member, int index) {
    return Row(
      children: [
        const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
        const SizedBox(width: 20),
        Text(maskName(member['name']),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 17),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCC33),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            member['role'],
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        RatingBar.builder(
          initialRating: ratings[index] ?? 0,
          itemSize: 30,
          minRating: 0,
          allowHalfRating: true,
          itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
          unratedColor: Colors.grey.shade300,
          onRatingUpdate: (value) => setState(() => ratings[index] = value),
        ),
      ],
    );
  }

  Widget _buildKeywordSection(int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF003366),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '후기 키워드',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(3, (rowIndex) {
              final tagsForRow = allTags.skip(rowIndex * 3).take(3).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: tagsForRow.map((tag) {
                    final selected = selectedTags[index]?.contains(tag) ??
                        false;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTags[index] ??= {};
                          if (selected) {
                            selectedTags[index]!.remove(tag);
                          } else {
                            selectedTags[index]!.add(tag);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFEAF1FB) : Colors
                              .grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: selected
                              ? Border.all(
                              color: const Color(0xFF5271FF), width: 1.5)
                              : null,
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? const Color(0xFF1F355F) : Colors
                                .grey,
                            fontWeight: selected ? FontWeight.bold : FontWeight
                                .normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}