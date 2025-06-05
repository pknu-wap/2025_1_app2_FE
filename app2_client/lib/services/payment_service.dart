import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app2_client/models/payment_info_model.dart';

class PaymentService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

  /// 파티원의 요금 지불 상태를 확인(승인)합니다.
  static Future<List<PaymentMemberInfo>> confirmPayment({
    required String partyId,
    required int partyMemberId,
    required int stopoverId,
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/api/party/$partyId/fare/confirm');
    
    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': accessToken,
        },
        body: jsonEncode({
          'party_member_id': partyMemberId,
          'stopover_id': stopoverId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => PaymentMemberInfo.fromJson(json)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('권한이 없습니다. BOOKKEEPER 권한이 필요합니다.');
      } else {
        throw Exception('요금 승인 처리 중 오류가 발생했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('요금 승인 처리 중 오류가 발생했습니다: $e');
    }
  }

  static Future<List<PaymentMemberInfo>> getPaymentInfo({
    required String partyId,
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/api/party/$partyId/fare/info');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': accessToken,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => PaymentMemberInfo.fromJson(json)).toList();
      } else {
        throw Exception('정산 정보를 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('정산 정보를 가져오는데 실패했습니다: $e');
    }
  }
} 