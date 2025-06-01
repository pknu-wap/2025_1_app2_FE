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
import 'dart:async';

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
    initializeDateFormatting('ko_KR', null);  // 한국어 날짜 포맷 초기화
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
      final now = DateTime.now();
      final message = {
        'text': text,
        'senderId': currentUserId,
        'senderName': currentUserName,
        'timestamp': now,  // 서버 타임스탬프 대신 현재 시간 사용
        'clientTimestamp': now,  // 클라이언트 타임스탬프도 동일한 시간 사용
      };

      // 메시지 전송
      final docRef = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .collection('messages')
          .add({
            'text': text,
            'senderId': currentUserId,
            'senderName': currentUserName,
            'timestamp': FieldValue.serverTimestamp(),  // 서버 타임스탬프는 백그라운드에서 업데이트
            'clientTimestamp': Timestamp.fromDate(now),  // 클라이언트 타임스탬프는 즉시 설정
          });

      _controller.clear();
      
      // 스크롤을 즉시 아래로 이동
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('clientTimestamp', descending: false)
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
                  controller: _scrollController,
                  thickness: 8.0,
                  radius: const Radius.circular(4),
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final doc = messages[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final senderId = data['senderId'] ?? '';
                      final senderName = data['senderName'] ?? userNames[senderId] ?? '알 수 없음';
                      final timestamp = data['timestamp'] as Timestamp?;
                      final clientTimestamp = data['clientTimestamp'] as Timestamp?;
                      
                      return ChatBubble(
                        key: ValueKey('${doc.id}_${clientTimestamp?.millisecondsSinceEpoch}'),
                        isMine: senderId == currentUserId,
                        name: senderName,
                        message: data['text'] ?? '',
                        timestamp: timestamp is Timestamp ? timestamp : (clientTimestamp ?? Timestamp.now()),
                        clientTimestamp: clientTimestamp ?? Timestamp.now(),
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
  final Timestamp? clientTimestamp;
  final String senderId;

  const ChatBubble({
    super.key,
    required this.isMine,
    required this.name,
    required this.message,
    required this.timestamp,
    required this.clientTimestamp,
    required this.senderId,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  late String timeString;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    timeString = _getTimeString();
    // 1분마다 시간 갱신
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          timeString = _getTimeString();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getTimeString() {
    final effectiveTimestamp = widget.clientTimestamp ?? widget.timestamp;
    if (effectiveTimestamp == null) {
      return '';
    }

    final messageTime = effectiveTimestamp.toDate();
    final now = DateTime.now();
    
    // 오늘 날짜인 경우
    if (messageTime.year == now.year && 
        messageTime.month == now.month && 
        messageTime.day == now.day) {
      return DateFormat('a h:mm', 'ko_KR').format(messageTime);
    } 
    // 올해인 경우
    else if (messageTime.year == now.year) {
      return DateFormat('M/d a h:mm', 'ko_KR').format(messageTime);
    }
    // 작년 이전인 경우
    else {
      return DateFormat('y/M/d a h:mm', 'ko_KR').format(messageTime);
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
        Container(
          margin: margin,
          child: Column(
            crossAxisAlignment: alignment,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(widget.message),
              ),
              const SizedBox(height: 2),
              Text(
                timeString,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}