import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/member.dart';
import '../models/cuisine.dart';
import '../models/item.dart';
import '../models/bill.dart';
import '../models/rfid_tap_result.dart';

class ApiService {
  Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/health')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['status'] == 'online';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getCurrentMealWindow() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/meal-times/current'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to fetch meal window');
  }

  Future<RFIDTapResult> tapRfid(String rfidTag) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/counter/tap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rfid_tag': rfidTag}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return RFIDTapResult.fromJson(data);
    }
    throw Exception('Failed to communicate with billing server');
  }

  Future<Map<String, dynamic>> issueToken({
    required int memberId,
    required String mealType,
    int isOverride = 0,
    String? overrideBy,
    String? overrideReason,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/counter/issue-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'member_id': memberId,
        'meal_type': mealType,
        'is_override': isOverride,
        'override_by': overrideBy,
        'override_reason': overrideReason,
      }),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to issue meal token');
  }

  Future<bool> cancelBill(int billId, {required String reason, required String cancelledBy}) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/bills/$billId/cancel'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason, 'cancelled_by': cancelledBy}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<List<Member>> fetchMembers({String? search}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/members';
    if (search != null && search.isNotEmpty) {
      url += '?search=${Uri.encodeComponent(search)}';
    }
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => Member.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Cuisine>> fetchCuisines() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/cuisines'));
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => Cuisine.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<MessItem>> fetchItems({String? category}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/items';
    if (category != null) {
      url += '?category=${Uri.encodeComponent(category)}';
    }
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => MessItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Bill>> fetchBills({String? billDate, String? mealType, String? search}) async {
    final params = <String, String>{};
    if (billDate != null) params['bill_date'] = billDate;
    if (mealType != null) params['meal_type'] = mealType;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/bills').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => Bill.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<dynamic>> fetchHeadcountReport({String? fromDate, String? toDate}) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/reports/headcount').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  Future<List<dynamic>> fetchAttendanceReport({String? fromDate, String? toDate}) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/reports/attendance').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }
}
