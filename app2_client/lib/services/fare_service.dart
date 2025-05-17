import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> confirmPayment({
  required String token,
  required int partyMemberId,
  required int stopoverId,
  required String baseUrl,
}) async {

  final url = Uri.parse('$baseUrl/fare/result');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authentication': token,
    },
    body: jsonEncode({
      'party_member_id': partyMemberId,
      'stopover_id': stopoverId,
    }),
  );

  if (response.statusCode == 200) {
    print('정산 완료 요청 성공');
  } else if (response.statusCode == 403) {
    throw Exception('권한이 없습니다 (403)');
  } else {
    throw Exception('정산 요청 실패: ${response.statusCode}');
  }
}


Future<List<Map<String, dynamic>>> fetchFareResult({
  required String token,
  required int myId,
  required String baseUrl,
}) async {
  final url = Uri.parse('$baseUrl/fare/result');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authentication': token,
    },
  );

  if (response.statusCode != 200) {
    throw Exception('정산 데이터 불러오기 실패');
  }

  final data = jsonDecode(response.body);

  final myInfo = data.firstWhere(
    (e) => e['party_member_info']['id'] == myId,
  );

  final isBookkeeper =
      myInfo['party_member_info']['additional_role'] == 'BOOKKEEPER';

  final users = data.map<Map<String, dynamic>>((entry) {
    final member = entry['party_member_info'];
    final payment = entry['payment_info'];
    return {
      'id': member['id'],
      'name': member['name'],
      'fare': '₩${payment['final_fare']}',
      'confirmed': payment['is_paid'],
      'isMe': member['id'] == myId,
      'stopoverId': payment['stopover_id'],
    };
  }).toList();

  return users;
}