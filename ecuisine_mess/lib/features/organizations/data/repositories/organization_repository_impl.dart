import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/organizations/data/datasources/organization_remote_datasource.dart';
import 'package:ecuisine_mess/features/organizations/data/models/organization_model.dart';
import 'package:ecuisine_mess/features/organizations/domain/entities/organization.dart';
import 'package:ecuisine_mess/features/organizations/domain/repositories/organization_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  OrganizationRepositoryImpl(this._remote);

  final OrganizationRemoteDataSource _remote;

  @override
  Future<List<Organization>> getOrganizations({
    String? search,
    bool includeInactive = false,
  }) async {
    try {
      final list = await _remote.getOrganizations(
        search: search,
        includeInactive: includeInactive,
      );
      return list.map((m) => m.toEntity()).toList();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Organization> getOrganization(String id) async {
    try {
      final model = await _remote.getOrganization(id);
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<String> createOrganization(Organization organization) async {
    try {
      return await _remote.createOrganization(
        OrganizationModel.fromEntity(organization),
      );
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> updateOrganization(Organization organization) async {
    try {
      await _remote.updateOrganization(
        OrganizationModel.fromEntity(organization),
      );
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> deleteOrganization(String id) async {
    try {
      await _remote.deleteOrganization(id);
    } on Object catch (e) {
      throw mapException(e);
    }
  }
}
