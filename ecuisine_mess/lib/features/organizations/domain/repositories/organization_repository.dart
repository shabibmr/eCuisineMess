import 'package:ecuisine_mess/features/organizations/domain/entities/organization.dart';

abstract interface class OrganizationRepository {
  Future<List<Organization>> getOrganizations({
    String? search,
    bool includeInactive = false,
  });

  Future<Organization> getOrganization(String id);

  Future<String> createOrganization(Organization organization);

  Future<void> updateOrganization(Organization organization);

  Future<void> deleteOrganization(String id);
}
