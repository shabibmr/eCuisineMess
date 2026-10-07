import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/organizations/data/models/organization_model.dart';

abstract interface class OrganizationRemoteDataSource {
  Future<List<OrganizationModel>> getOrganizations({
    String? search,
    bool includeInactive = false,
  });

  Future<OrganizationModel> getOrganization(String id);

  Future<String> createOrganization(OrganizationModel model);

  Future<void> updateOrganization(OrganizationModel model);

  Future<void> deleteOrganization(String id);
}

class OrganizationRemoteDataSourceImpl
    implements OrganizationRemoteDataSource {
  OrganizationRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<OrganizationModel>> getOrganizations({
    String? search,
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (includeInactive) queryParams['include_inactive'] = '1';
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final res = await _client.dio.get<List<dynamic>>(
        ApiEndpoints.organizations,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return (res.data ?? [])
          .map(
            (e) => OrganizationModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<OrganizationModel> getOrganization(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        ApiEndpoints.organization(id),
      );
      return OrganizationModel.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<String> createOrganization(OrganizationModel model) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.organizations,
        data: model.toCreateJson(),
      );
      return res.data?['id']?.toString() ?? '';
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<void> updateOrganization(OrganizationModel model) async {
    try {
      await _client.dio.put<void>(
        ApiEndpoints.organization(model.id),
        data: model.toUpdateJson(),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<void> deleteOrganization(String id) async {
    try {
      await _client.dio.delete<void>(ApiEndpoints.organization(id));
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
