import 'dart:convert';

import 'package:ecuisine_mess/config/api_config.dart';
import 'package:ecuisine_mess/models/bill.dart';
import 'package:ecuisine_mess/models/cuisine.dart';
import 'package:ecuisine_mess/models/item.dart';
import 'package:ecuisine_mess/models/item_category.dart';
import 'package:ecuisine_mess/models/member.dart';
import 'package:ecuisine_mess/models/rfid_tap_result.dart';
import 'package:ecuisine_mess/models/uom.dart';
import 'package:ecuisine_mess/models/user.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

typedef UnauthorizedCallback = void Function();

class ApiService {
  /// Set by AuthProvider after login / restore.
  static String? authToken;

  /// Cleared by AuthProvider; do not call logout API from here.
  static UnauthorizedCallback? onUnauthorized;

  String _messageFromBody(dynamic data, int statusCode) {
    if (data is Map) {
      final detail = data['detail'];
      if (detail != null && detail.toString().isNotEmpty) {
        return detail.toString();
      }
      final message = data['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }
    return 'Request failed ($statusCode)';
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
    bool skipUnauthorizedCallback = false,
    String? bearerToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = bearerToken ?? authToken;
    if (auth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    late http.Response res;
    final encoded = body == null ? null : jsonEncode(body);
    switch (method.toUpperCase()) {
      case 'GET':
        res = await http.get(uri, headers: headers);
        break;
      case 'POST':
        res = await http.post(uri, headers: headers, body: encoded);
        break;
      case 'PUT':
        res = await http.put(uri, headers: headers, body: encoded);
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: headers, body: encoded);
        break;
      default:
        throw ApiException(0, 'Unsupported HTTP method: $method');
    }

    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        data = null;
      }
    }

    if (res.statusCode == 401 && !skipUnauthorizedCallback) {
      onUnauthorized?.call();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, _messageFromBody(data, res.statusCode));
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await _send(
      'POST',
      '/api/v1/auth/login',
      body: {'username': username, 'password': password},
      auth: false,
      skipUnauthorizedCallback: true,
    );
    if (data is Map && data['success'] == true) {
      return {
        'token': data['token'] as String,
        'user': AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
      };
    }
    throw ApiException(200, data is Map ? _messageFromBody(data, 200) : 'Login failed');
  }

  Future<void> logout(String token) async {
    await _send(
      'POST',
      '/api/v1/auth/logout',
      bearerToken: token,
      skipUnauthorizedCallback: true,
    );
  }

  Future<AppUser> fetchMe(String token) async {
    final data = await _send(
      'GET',
      '/api/v1/auth/me',
      bearerToken: token,
    );
    return AppUser.fromJson(Map<String, dynamic>.from((data as Map)['user'] as Map));
  }

  Future<List<ItemCategory>> fetchItemCategories({bool includeInactive = false}) async {
    final data = await _send(
      'GET',
      '/api/v1/item-categories',
      query: includeInactive ? {'include_inactive': '1'} : null,
      auth: false,
    );
    final List list = data as List;
    return list.map((e) => ItemCategory.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<String> createItemCategory({
    required String categoryName,
    int sortOrder = 0,
    int isActive = 1,
  }) async {
    final data = await _send(
      'POST',
      '/api/v1/item-categories',
      body: {
        'category_name': categoryName,
        'sort_order': sortOrder,
        'is_active': isActive,
      },
      auth: false,
    );
    return (data as Map)['id']?.toString() ?? '';
  }

  Future<void> updateItemCategory({
    required String id,
    String? categoryName,
    int? sortOrder,
    int? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (categoryName != null) body['category_name'] = categoryName;
    if (sortOrder != null) body['sort_order'] = sortOrder;
    if (isActive != null) body['is_active'] = isActive;
    await _send('PUT', '/api/v1/item-categories/$id', body: body, auth: false);
  }

  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/v1/health'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data is Map && data['status'] == 'online';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getCurrentMealWindow() async {
    final data = await _send('GET', '/api/v1/meal-times/current', auth: false);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<RFIDTapResult> tapRfid(String rfidTag) async {
    final data = await _send(
      'POST',
      '/api/v1/counter/tap',
      body: {'rfid_tag': rfidTag},
      auth: false,
    );
    return RFIDTapResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Map<String, dynamic>> issueToken({
    required String memberId,
    required String mealType,
    int isOverride = 0,
    String? overrideBy,
    String? overrideReason,
  }) async {
    final data = await _send(
      'POST',
      '/api/v1/counter/issue-token',
      body: {
        'member_id': memberId,
        'meal_type': mealType,
        'is_override': isOverride,
        'override_by': overrideBy,
        'override_reason': overrideReason,
      },
      auth: false,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<bool> cancelBill(String billId, {required String reason, required String cancelledBy}) async {
    final data = await _send(
      'POST',
      '/api/v1/bills/$billId/cancel',
      body: {'reason': reason, 'cancelled_by': cancelledBy},
      auth: false,
    );
    return data is Map && data['success'] == true;
  }

  Future<List<Member>> fetchMembers({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    final data = await _send(
      'GET',
      '/api/v1/members',
      query: query.isEmpty ? null : query,
      auth: false,
    );
    final List list = data as List;
    return list
        .map((e) => Member.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Cuisine>> fetchCuisines() async {
    final data = await _send('GET', '/api/v1/cuisines', auth: false);
    final List list = data as List;
    return list
        .map((e) => Cuisine.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Uom>> fetchUoms({bool includeInactive = false}) async {
    final data = await _send(
      'GET',
      '/api/v1/uoms',
      query: includeInactive ? {'include_inactive': '1'} : null,
      auth: false,
    );
    final List list = data as List;
    return list.map((e) => Uom.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<MessItem>> fetchItems({
    String? category,
    String? categoryId,
    bool includeInactive = false,
  }) async {
    final params = <String, String>{};
    if (categoryId != null) {
      params['category_id'] = categoryId;
    } else if (category != null) {
      params['category'] = category;
    }
    if (includeInactive) {
      params['include_inactive'] = '1';
    }
    final data = await _send(
      'GET',
      '/api/v1/items',
      query: params.isEmpty ? null : params,
      auth: false,
    );
    final List list = data as List;
    return list.map((e) => MessItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<String> createItem({
    required String itemName,
    required String categoryId,
    required String uomId,
    int isActive = 1,
  }) async {
    final data = await _send(
      'POST',
      '/api/v1/items',
      body: {
        'item_name': itemName,
        'category_id': categoryId,
        'uom_id': uomId,
        'is_active': isActive,
      },
      auth: false,
    );
    return (data as Map)['id']?.toString() ?? '';
  }

  Future<void> updateItem({
    required String id,
    String? itemName,
    String? categoryId,
    String? uomId,
    int? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (itemName != null) body['item_name'] = itemName;
    if (categoryId != null) body['category_id'] = categoryId;
    if (uomId != null) body['uom_id'] = uomId;
    if (isActive != null) body['is_active'] = isActive;
    await _send('PUT', '/api/v1/items/$id', body: body, auth: false);
  }

  Future<List<Bill>> fetchBills({String? billDate, String? mealType, String? search}) async {
    final params = <String, String>{};
    if (billDate != null) params['bill_date'] = billDate;
    if (mealType != null) params['meal_type'] = mealType;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final data = await _send(
      'GET',
      '/api/v1/bills',
      query: params.isEmpty ? null : params,
      auth: false,
    );
    final List list = data as List;
    return list
        .map((e) => Bill.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<dynamic>> fetchHeadcountReport({String? fromDate, String? toDate}) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    final data = await _send(
      'GET',
      '/api/v1/reports/headcount',
      query: params.isEmpty ? null : params,
      auth: false,
    );
    return data as List<dynamic>;
  }

  Future<List<dynamic>> fetchAttendanceReport({String? fromDate, String? toDate}) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    final data = await _send(
      'GET',
      '/api/v1/reports/attendance',
      query: params.isEmpty ? null : params,
      auth: false,
    );
    return data as List<dynamic>;
  }
}
