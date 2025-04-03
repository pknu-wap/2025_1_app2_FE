import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyPageButton extends StatelessWidget {
  const MyPageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            iconSize: 50.0,
            color: Colors.black38,
            onPressed: () {
              showCupertinoDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 128,
                        left: 115,
                        right: 28,
                      ),
                      child: Container(
                        color: Colors.white,
                        height: 600.0,
                        child: MyPage(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class User {
  final String name;
  final String gender;
  final String phoneNumber;

  User({required this.name, required this.gender, required this.phoneNumber});
}

class MyPage extends StatelessWidget {
  MyPage({super.key});

  final User user = User(
    name: '홍길동',
    gender: '남성',
    phoneNumber: '010-1234-5678',
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 47),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    //  이름과 성별을 같은 줄에 정렬
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.black,
                          fontFamily: 'jua',
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 17), // 이름과 성별 사이 간격 조정
                      Text(
                        user.gender,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontFamily: 'jua',
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10), // 간격 조절
                  Text(
                    user.phoneNumber,
                    style: TextStyle(
                      fontSize: 19,
                      color: Colors.grey,
                      fontFamily: 'jua',
                      decoration: TextDecoration.none, // 노란 밑줄 제거
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
