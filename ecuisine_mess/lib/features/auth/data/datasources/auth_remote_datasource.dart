import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/auth/data/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<({String token, UserModel user})> login({
    required String username,
    required String password,
  });

  Future<UserModel> fetchMe(String token);

  Future<void> logout(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<({String token, UserModel user})> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
        options: Options(
          extra: {
            'skipAuth': true,
            'skipUnauthorized': true,
          },
        ),
      );
      final data = res.data;
      if (data != null && data['success'] == true) {
        return (
          token: data['token'] as String,
          user: UserModel.fromJson(
            Map<String, dynamic>.from(data['user'] as Map),
          ),
        );
      }
      throw AppException(
        data?['message']?.toString() ??
            data?['detail']?.toString() ??
            'Login failed',
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<UserModel> fetchMe(String token) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        ApiEndpoints.me,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {'skipAuth': true},
        ),
      );
      final data = res.data!;
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<void> logout(String token) async {
    try {
      await _client.dio.post<void>(
        ApiEndpoints.logout,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {
            'skipAuth': true,
            'skipUnauthorized': true,
          },
        ),
      );
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
