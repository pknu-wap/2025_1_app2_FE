import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final List<String> passengers = ['차은우', '아이유', '지디'];

  Map<String, double> ratings = {}; // ⭐ 별점 저장
  Map<String, Set<int>> selections = {}; // ✅ 문장 체크 상태 저장

  void saveReview(String name, double rating, Set<int> selected) {
    setState(() {
      ratings[name] = rating;
      selections[name] = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('리뷰할 팀원 선택')),
      body: ListView.builder(
        itemCount: passengers.length,
        itemBuilder: (context, index) {
          final passenger = passengers[index];
          final hasReview = ratings.containsKey(passenger);

          return ListTile(
            title: Text(passenger, style: const TextStyle(fontSize: 20, fontFamily: 'jua')),
            trailing: hasReview
                ? TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IndividualReviewPage(
                      passenger: passenger,
                      initialRating: ratings[passenger] ?? 0,
                      initialSelections: selections[passenger] ?? {},
                      onComplete: (rating, selected) =>
                          saveReview(passenger, rating, selected),
                    ),
                  ),
                );
              },
              child: const Text('수정', style: TextStyle(color: Colors.orange)),
            )
                : const Icon(Icons.arrow_forward_ios),
            onTap: hasReview
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IndividualReviewPage(
                    passenger: passenger,
                    onComplete: (rating, selected) =>
                        saveReview(passenger, rating, selected),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class IndividualReviewPage extends StatefulWidget {
  final String passenger;
  final double initialRating;
  final Set<int> initialSelections;
  final Function(double, Set<int>) onComplete;

  const IndividualReviewPage({
    super.key,
    required this.passenger,
    this.initialRating = 0,
    this.initialSelections = const {},
    required this.onComplete,
  });

  @override
  State<IndividualReviewPage> createState() => _IndividualReviewPageState();
}

class _IndividualReviewPageState extends State<IndividualReviewPage> {
  late double rating;
  late Set<int> selectedIndexes;

  @override
  void initState() {
    super.initState();
    rating = widget.initialRating;
    selectedIndexes = {...widget.initialSelections};
  }

  List<String> getSentences(double rating) {
    if (rating == 5) return [
      '시간 약속을 잘 지켜요',
      '소통이 잘 돼요',
      '매너가 좋아요',
      '말투와 태도가 친절해요',
      '탑승, 하차 위치를 배려해줬어요',
      '불편한 상황 없이 잘 마무리됐어요',
      '함께 타는 사람들을 존중해요',
      '다음에도 같이 타고 싶어요',
      '목적지까지 경로를 함께 고민해줬어요',
      '인사를 잘 해줘요'
    ];
    if (rating == 4) return [
      '전반적으로 괜찮았어요',
      '대체로 예의 바른 편이에요',
      '편안하게 이동할 수 있었어요',
      '기분 좋은 대화가 있었어요',
      '한두 가지 아쉬움이 있었지만 무난했어요'
    ];
    if (rating == 3) return [
      '무난했어요',
      '크게 문제는 없었어요',
      '조금 어색했지만 괜찮았어요',
      '조용히 갔어요',
    ];
    if (rating == 2) return [
      '약속 시간에 늦었어요',
      '소통이 잘 안 됐어요',
      '탑승 위치가 헷갈렸어요',
      '예의가 조금 아쉬웠어요'
    ];
    if (rating == 1) return [
      '지각을 했어요',
      '불쾌한 태도가 있었어요',
      '대화가 불편했어요',
      '배려가 부족했어요',
      '다시 함께 타고 싶지 않아요'
    ];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final sentences = getSentences(rating);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.passenger} 평가')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: rating == 0
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Center(
              child: Text(widget.passenger,
                  style: const TextStyle(fontSize: 22, fontFamily: 'jua')),
            ),
            const SizedBox(height: 16),
            Center(
              child: RatingBar.builder(
                initialRating: 0,
                minRating: 0,
                itemBuilder: (_, __) =>
                const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                allowHalfRating: false,
                onRatingUpdate: (value) {
                  setState(() {
                    rating = value;
                    selectedIndexes.clear();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('⭐ 별점을 먼저 선택해주세요',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        )
            : Column(
          children: [
            Text(widget.passenger,
                style: const TextStyle(fontSize: 22, fontFamily: 'jua')),
            const SizedBox(height: 10),
            RatingBar.builder(
              initialRating: rating,
              minRating: 0,
              itemBuilder: (_, __) =>
              const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              allowHalfRating: false,
              onRatingUpdate: (value) {
                setState(() {
                  rating = value;
                  selectedIndexes.clear();
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: sentences.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(sentences[index]),
                    value: selectedIndexes.contains(index),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedIndexes.add(index);
                        } else {
                          selectedIndexes.remove(index);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onComplete(rating, selectedIndexes);
                Navigator.pop(context);
              },
              child: const Text('완료'),
            ),
          ],
        ),
      ),
    );
  }
}
