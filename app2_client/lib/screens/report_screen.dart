import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/providers/auth_provider.dart';

import '../services/dio_client.dart';

class ReportScreen extends StatefulWidget {
  /// 서버에 보낼 실제 신고 대상자의 이메일
  final String reportedUserEmail;
  final String reportedUserName;
  final String messageContent;
  final DateTime? messageTimestamp;

  const ReportScreen({
    Key? key,
    required this.reportedUserEmail,
    required this.reportedUserName,
    required this.messageContent,
    this.messageTimestamp,
  }) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _controller = TextEditingController();
  int _charCount = 0;
  bool _isSubmitting = false;

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

  /// 신고 API 호출
  Future<void> _submitReport() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("신고 내용을 입력해주세요.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. AuthProvider에서 토큰을 가져옴
      final token =
          Provider.of<AuthProvider>(context, listen: false).tokens?.accessToken;
      if (token == null || token.isEmpty) {
        throw Exception("로그인 정보가 없습니다.");
      }

      // 2. DioClient를 이용해 /api/report 호출
      final dio = DioClient.dio;
      dio.options.headers['Content-Type'] = "application/json";
      // (TokenInterceptor가 이미 Authorization 헤더를 붙여 줍니다.)

      final response = await dio.post(
        "/api/report",
        data: {
          "email": widget.reportedUserEmail,
          "content": content,
        },
        options: Options(validateStatus: (status) {
          return status != null && status < 500;
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 신고 성공
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("신고가 정상적으로 접수되었습니다.")),
          );
          Navigator.of(context).pop(); // 이전 화면으로 돌아가기
        }
      } else if (response.statusCode == 404) {
        // 서버가 “회원을 찾을 수 없다”고 응답한 경우
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("신고 대상 회원을 찾을 수 없습니다.")),
          );
        }
      } else {
        // 기타 오류
        final msg = (response.data is Map)
            ? (response.data['message'] ?? "알 수 없는 오류")
            : "status code: ${response.statusCode}";
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("신고 중 오류 발생: $msg")),
          );
        }
      }
    } catch (e) {
      // 네트워크 오류, JSON 파싱 오류 등
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("신고 중 오류 발생: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
        title: const Text(
          '신고하기',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 신고 대상 정보
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '신고 대상: ${widget.reportedUserName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '메시지 내용: ${widget.messageContent}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (widget.messageTimestamp != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '작성 시간: ${widget.messageTimestamp}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),

              // 설명 텍스트
              const Text(
                '택시팟 채팅방에서 본 목적과 관련 없는 채팅을 받으면 '
                    '상대방을 신고할 수 있어요.\n원하지 않는 채팅을 받아 불쾌하다면 신고해주세요.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),

              // 신고 입력란
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '신고 내용을 입력해주세요. (최대 500자)',
                    hintStyle: TextStyle(color: Colors.grey),
                    counterText: '',
                  ),
                ),
              ),

              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_charCount/500',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),

              const SizedBox(height: 30),

              // 신고하기 버튼
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF443A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    '신고하기',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}