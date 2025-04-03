import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  // 동승자 리스트
  List<String> passengers = ['차은우', '아이유', '지디'];

  // 각 동승자의 별점 저장
  Map<String, double> ratings = {};

  // 각 동승자의 선택한 해시태그 저장
  Map<String, Set<String>> selectedHashtags = {};

  // 별점에 따라 자동으로 해시태그 변경
  List<String> getHashtags(double rating) {
    if (rating == 5) return ['#매너좋음', '#시간약속', '#깔끔'];
    if (rating == 4) return ['#좋아요', '#추천', '#괜찮음'];
    if (rating == 3) return ['#보통이에요', '#무난'];
    if (rating == 2) return ['#별로예요', '#아쉬움', '#지각'];
    if (rating == 1) return ['#비매너', '#악취', '#지각'];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('리뷰 작성')),
      body: ListView.builder(
        itemCount: passengers.length,
        itemBuilder: (context, index) {
          String passenger = passengers[index];
          double rating = ratings[passenger] ?? 0;

          // 선택한 해시태그 가져오기
          Set<String> selectedTags = selectedHashtags[passenger] ?? {};

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      passenger, // 동승자 이름
                      style: TextStyle(fontSize: 20, fontFamily: 'jua'),
                    ),
                    SizedBox(width: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ⭐ 별점 선택
                        RatingBar.builder(
                          initialRating: rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (newRating) {
                            setState(() {
                              ratings[passenger] = newRating; // 개별 동승자 별점 저장
                              selectedHashtags[passenger] = {}; // 별점 바꾸면 해시태그 초기화
                            });
                          },
                        ),

                        SizedBox(height: 10),

                        // 해시태그 (클릭 가능)
                        Wrap(
                          spacing: 8.0,
                          children: getHashtags(rating)
                              .map((tag) => GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedTags.contains(tag)) {
                                  selectedTags.remove(tag);
                                } else {
                                  selectedTags.add(tag);
                                }
                                selectedHashtags[passenger] = selectedTags;
                              });
                            },
                            child: Chip(
                              label: Text(tag),
                              backgroundColor: selectedTags.contains(tag)
                                  ? Colors.blue
                                  : Colors.blue.shade100,
                              labelStyle: TextStyle(
                                color: selectedTags.contains(tag)
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(),
            ],
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: ReviewPage()));
}