import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/members/data/models/cuisine_option_model.dart';
import 'package:ecuisine_mess/features/members/data/models/member_model.dart';
import 'package:ecuisine_mess/features/members/domain/entities/member_delete_result.dart';

abstract interface class MemberRemoteDataSource {
  Future<List<MemberModel>> getMembers({String? search, String? status});

  Future<MemberModel> getMember(String id);

  Future<MemberModel?> getMemberByRfid(String tag);

  Future<String> createMember({
    required String name,
    required String rfidTag,
    String? phone,
    String? email,
    String? cuisineId,
    required String validityStart,
    required String validityEnd,
    String status = 'ACTIVE',
  });

  Future<void> updateMember({
    required String id,
    String? name,
    String? rfidTag,
    String? phone,
    String? email,
    String? cuisineId,
    String? validityStart,
    String? validityEnd,
    String? status,
  });

  Future<MemberDeleteResult> deleteMember(String id);

  Future<List<CuisineOptionModel>> getCuisines({
    bool includeInactive = false,
  });
}

class MemberRemoteDataSourceImpl implements MemberRemoteDataSource {
  MemberRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<MemberModel>> getMembers({
    String? search,
    String? status,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (status != null && status.isNotEmpty) query['status'] = status;
      final res = await _client.dio.get<List<dynamic>>(
        ApiEndpoints.members,
        queryParameters: query.isEmpty ? null : query,
      );
      return (res.data ?? [])
          .map(
            (e) => MemberModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<MemberModel> getMember(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        ApiEndpoints.member(id),
      );
      return MemberModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<MemberModel?> getMemberByRfid(String tag) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        ApiEndpoints.membersByRfid(tag),
      );
      return MemberModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      final err = e.error;
      if (err is NotFoundException || e.response?.statusCode == 404) {
        return null;
      }
      throw _unwrap(e);
    }
  }

  @override
  Future<String> createMember({
    required String name,
    required String rfidTag,
    String? phone,
    String? email,
    String? cuisineId,
    required String validityStart,
    required String validityEnd,
    String status = 'ACTIVE',
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'rfid_tag': rfidTag,
        'validity_start': validityStart,
        'validity_end': validityEnd,
        'status': status,
      };
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (cuisineId != null && cuisineId.isNotEmpty) {
        body['cuisine_id'] = cuisineId;
      }
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.members,
        data: body,
      );
      return res.data?['id']?.toString() ?? '';
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<void> updateMember({
    required String id,
    String? name,
    String? rfidTag,
    String? phone,
    String? email,
    String? cuisineId,
    String? validityStart,
    String? validityEnd,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (rfidTag != null) body['rfid_tag'] = rfidTag;
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;
      if (cuisineId != null) body['cuisine_id'] = cuisineId;
      if (validityStart != null) body['validity_start'] = validityStart;
      if (validityEnd != null) body['validity_end'] = validityEnd;
      if (status != null) body['status'] = status;
      await _client.dio.put<void>(ApiEndpoints.member(id), data: body);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<MemberDeleteResult> deleteMember(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        ApiEndpoints.member(id),
      );
      final data = res.data ?? const <String, dynamic>{};
      return MemberDeleteResult(
        action: data['action']?.toString() ?? 'deleted',
        message: data['message']?.toString() ?? 'Member deleted',
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<List<CuisineOptionModel>> getCuisines({
    bool includeInactive = false,
  }) async {
    try {
      final res = await _client.dio.get<List<dynamic>>(
        ApiEndpoints.cuisines,
        queryParameters:
            includeInactive ? {'include_inactive': '1'} : null,
      );
      return (res.data ?? [])
          .map(
            (e) => CuisineOptionModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Object _unwrap(DioException e) {
    final err = e.error;
    if (err is AppException) return err;
    return AppException(e.message ?? 'Request failed');
  }
}
