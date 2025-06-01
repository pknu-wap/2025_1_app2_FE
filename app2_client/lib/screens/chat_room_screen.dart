import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For JWT storage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app2_client/screens/report_screen.dart';
import 'package:app2_client/services/secure_storage_service.dart';
import 'package:app2_client/screens/my_page_popup.dart';  // 추가

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  const ChatRoomScreen({super.key, required this.roomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? currentUserId;
  String? currentUserName;
  Map<String, String> userNames = {};  // userId to name mapping
  bool isUserInfoLoaded = false;  // 사용자 정보 로딩 상태 추가

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadPartyMembers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final storage = SecureStorageService();
    print('🔍 사용자 정보 로딩 시작');
    
    currentUserId = await storage.getUserId();
    print('📱 userId: $currentUserId');
    
    currentUserName = await storage.getUserName();
    print('📱 userName: $currentUserName');
    
    setState(() {
      isUserInfoLoaded = currentUserId != null && currentUserName != null;
      print('✅ 사용자 정보 로딩 완료: $isUserInfoLoaded');
    });
  }

  Future<void> _loadPartyMembers() async {
    try {
      final partyDoc = await FirebaseFirestore.instance
          .collection('parties')
          .doc(widget.roomId)
          .get();
      
      if (partyDoc.exists) {
        final members = partyDoc.data()?['members'] as List<dynamic>?;
        if (members != null) {
          for (var member in members) {
            userNames[member['userId']] = member['name'];
          }
        }
      }
    } catch (e) {
      print('파티 멤버 정보 로딩 실패: $e');
    }
  }

  Future<void> _sendMessage(String text) async {
    if (!mounted) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': currentUserId,
        'senderName': currentUserName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메시지 전송에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '채팅방',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                MyPagePopup.show(context);
              },
            ),
          )
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // 채팅 메시지 영역 (Firestore 연동)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data!.docs;
                
                // 새 메시지가 오면 자동으로 스크롤
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                
                return Scrollbar(
                  thumbVisibility: true,  // 스크롤바 항상 표시
                  thickness: 8.0,  // 스크롤바 두께
                  radius: const Radius.circular(4),  // 스크롤바 모서리 둥글게
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final doc = messages[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final senderId = data['senderId'] ?? '';
                      final senderName = data['senderName'] ?? userNames[senderId] ?? '알 수 없음';
                      
                      return ChatBubble(
                        isMine: senderId == currentUserId,
                        name: senderName,
                        message: data['text'] ?? '',
                        timestamp: data['timestamp'],
                        senderId: senderId,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // 메시지 입력창
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: isUserInfoLoaded ? '메시지를 입력하세요' : '사용자 정보를 불러오는 중...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: !isUserInfoLoaded ? null : () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      _sendMessage(text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    backgroundColor: Colors.indigo,
                    disabledBackgroundColor: Colors.grey,
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

// 말풍선 위젯
class ChatBubble extends StatefulWidget {
  final bool isMine;
  final String name;
  final String message;
  final Timestamp? timestamp;
  final String senderId;

  const ChatBubble({
    super.key,
    required this.isMine,
    required this.name,
    required this.message,
    required this.timestamp,
    required this.senderId,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool isSelected = false;
  String timeString = '';

  @override
  void initState() {
    super.initState();
    _initializeTimeString();
  }

  Future<void> _initializeTimeString() async {
    await initializeDateFormatting('ko_KR');
    if (mounted && widget.timestamp != null) {
      setState(() {
        timeString = DateFormat('a h:mm', 'ko').format(widget.timestamp!.toDate());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.isMine ? Colors.amber : Colors.grey.shade300;
    final alignment = widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = widget.isMine
        ? const EdgeInsets.only(left: 80, top: 8, bottom: 8)
        : const EdgeInsets.only(right: 80, top: 8, bottom: 8);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (!widget.isMine)
          Text(widget.name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Stack(
          children: [
            GestureDetector(
              onLongPress: () {
                if (!widget.isMine) {  // 자신의 메시지는 신고할 수 없음
                  setState(() {
                    isSelected = true;
                  });
                  // 3초 후 자동으로 선택 해제
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        isSelected = false;
                      });
                    }
                  });
                }
              },
              child: Container(
                margin: margin,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.grey.shade400 : bubbleColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
                ),
                child: Text(widget.message),
              ),
            ),
            if (isSelected && !widget.isMine)
              Positioned(
                top: -5,
                right: widget.isMine ? null : 85,
                left: widget.isMine ? 85 : null,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportScreen(
                          reportedUserName: widget.name,
                          messageContent: widget.message,
                          messageTimestamp: widget.timestamp?.toDate(),
                        ),
                      ),
                    );
                    setState(() {
                      isSelected = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.report_problem, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '신고하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        Text(timeString, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}