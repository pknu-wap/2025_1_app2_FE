import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void main() => runApp(const MaterialApp(home: ReviewPage(), debugShowCheckedModeBanner: false));

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final List<Map<String, dynamic>> members = [
    {'name': '김*서', 'role': '방장'},
    {'name': '김*서', 'role': '팀원'},
    {'name': '김*서', 'role': '팀원'},
    {'name': '김*서', 'role': '팀원'},
    {'name': '김*서', 'role': '팀원'},
  ];

  final List<String> allTags = [
    '시간 엄수', '소통 원활', '친절한 태도',
    '상대 존중', '위치 배려', '탑승 만족 👍',
    '굿 매너', '재탑승 희망', '매너 정산러',
  ];

  final Map<int, double> ratings = {};
  final Map<int, Set<String>> selectedTags = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('파티원 평가하기')),
      body: Scrollbar( // ✅ 스크롤바 추가
        thumbVisibility: true, // 항상 보이게
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 100), // ✅ 버튼 안 가리도록 여백 추가
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름 + 역할 + 별점
                    Row(
                      children: [
                        const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                        const SizedBox(width: 20),
                        Text(member['name'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 17),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6C651),
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
                          allowHalfRating: false,
                          itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                          unratedColor: Colors.grey.shade300,
                          onRatingUpdate: (value) {
                            setState(() {
                              ratings[index] = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 후기 키워드 전체 행
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "후기 키워드" 박스
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F355F),
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
                        // 키워드들 세 줄 정렬
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(3, (rowIndex) {
                              final tagsForRow = allTags.skip(rowIndex * 3).take(3).toList();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: tagsForRow.map((tag) {
                                    final selected = selectedTags[index]?.contains(tag) ?? false;
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: selected ? const Color(0xFFEAF1FB) : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(20),
                                          border: selected
                                              ? Border.all(color: const Color(0xFF5271FF), width: 1.5)
                                              : null,
                                        ),
                                        child: Text(
                                          '#$tag',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: selected ? const Color(0xFF1F355F) : Colors.grey,
                                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // ✅ 하단 제출 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // TODO: 제출 로직 작성
            print('제출됨!');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F355F),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '평가 제출하기',
            style: TextStyle(fontSize: 16, fontFamily: 'jua', color: Colors.white),
          ),
        ),
      ),
    );
  }
}
