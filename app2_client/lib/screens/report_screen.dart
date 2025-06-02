import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _controller = TextEditingController();
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _charCount = _controller.text.length;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitReport() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      // TODO: 서버에 신고 내용 전송
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("신고가 접수되었습니다.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 신고하기 제목
            const Text(
              '신고하기',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15),

            // 본문 설명
            const Text(
              '택시팟 채팅방에서 본 목적과 관련 없는 채팅을 받으면 상대방을 신고할 수 있어요. '
                  '원하지 않는 채팅을 받아 불쾌하다면 신고할 수 있어요.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            // 입력창
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 6,
                maxLength: 300,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '신고 내용을 입력해주세요. (최대 300자)',
                  hintStyle: TextStyle(color: Colors.grey),
                  counterText: '',
                ),
              ),
            ),

            const SizedBox(height: 5),

            // 글자 수 표시
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_charCount/300',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),

            const Spacer(),

            // 신고하기 버튼
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF443A), // 빨간색
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '신고하기',
                  style: TextStyle(fontSize: 16,
                    color: Colors.white,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
