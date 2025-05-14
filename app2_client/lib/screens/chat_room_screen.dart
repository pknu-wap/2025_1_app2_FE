import 'package:flutter/material.dart';

class ChatRoomScreen extends StatelessWidget {
  const ChatRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('택시 모임 4', style: TextStyle(fontSize: 18)),
            Text('부경대학교 정문 ➤ 서면 삼정타워',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.person_outline),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '5월 23일 (금) 22:30 출발',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 파티 생성 메시지
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'oo님이 파티를 생성했습니다.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          // 채팅 메시지 영역
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                ChatBubble(isMine: false, name: '이름', message: '채팅 내용'),
                ChatBubble(isMine: true, name: '나', message: '채팅 내용'),
                ChatBubble(isMine: false, name: '이름', message: '채팅 내용'),
                ChatBubble(isMine: false, name: '이름', message: '채팅 내용'),
              ],
            ),
          ),
          // 입력창
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    backgroundColor: Colors.indigo,
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 말풍선 위젯
class ChatBubble extends StatelessWidget {
  final bool isMine;
  final String name;
  final String message;

  const ChatBubble({
    super.key,
    required this.isMine,
    required this.name,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? Colors.amber : Colors.grey.shade300;
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = isMine
        ? const EdgeInsets.only(left: 80, top: 8, bottom: 8)
        : const EdgeInsets.only(right: 80, top: 8, bottom: 8);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (!isMine)
          Text(name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Container(
          margin: margin,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(message),
        ),
        Text('오후 1:30', style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}