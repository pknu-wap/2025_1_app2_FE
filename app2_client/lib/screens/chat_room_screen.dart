import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For JWT storage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  const ChatRoomScreen({super.key, required this.roomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String startAddress = '';
  String destinationAddress = '';
  bool isLoading = true;

  Future<String> loadJwtToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'jwt') ?? '';
  }

  Future<void> _loadRouteInfo() async {
    try {
      final jwt = await loadJwtToken();
      final response = await http.get(
        Uri.parse('${dotenv.env['BACKEND_BASE_URL']}/api/party/${widget.roomId}'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        String? start, destination;

        for (var item in data) {
          final stopover = item['stopover'];
          final type = stopover['stopover_type'];
          final address = stopover['location']['address'];

          if (type == 'START') {
            start = address;
          } else if (type == 'DESTINATION') {
            destination = address;
          }
        }

        setState(() {
          startAddress = start ?? '';
          destinationAddress = destination ?? '';
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load route info');
      }
    } catch (e) {
      print('Error loading route info: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRouteInfo();
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
                Navigator.pushNamed(context, '/myInfo');
              },
            ),
          )
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // 목적지 정보 박스
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$startAddress ➤ $destinationAddress',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '출발 예정 시간은 추후 확장 필요',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
          ),

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
                  return Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: messages.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ChatBubble(
                      isMine: data['sender'] == '나', // 사용자 이름 비교 필요
                      name: data['sender'] ?? '',
                      message: data['text'] ?? '',
                      timestamp: data['timestamp'],
                    );
                  }).toList(),
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
                      hintText: '메시지를 입력하세요',
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
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('chat_rooms')
                          .doc(widget.roomId)
                          .collection('messages')
                          .add({
                        'text': text,
                        'sender': '나', // 실제 로그인 사용자 정보로 대체
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      _controller.clear();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                  },
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

// 말풍선 위젯
class ChatBubble extends StatelessWidget {
  final bool isMine;
  final String name;
  final String message;
  final Timestamp? timestamp;

  const ChatBubble({
    super.key,
    required this.isMine,
    required this.name,
    required this.message,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? Colors.amber : Colors.grey.shade300;
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = isMine
        ? const EdgeInsets.only(left: 80, top: 8, bottom: 8)
        : const EdgeInsets.only(right: 80, top: 8, bottom: 8);

    final timeString = timestamp != null
        ? DateFormat('a h:mm', 'ko').format(timestamp!.toDate())
        : '';

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
        Text(timeString, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}