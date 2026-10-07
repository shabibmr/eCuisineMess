import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/organizations/domain/entities/organization.dart';
import 'package:ecuisine_mess/features/organizations/domain/repositories/organization_repository.dart';
import 'package:equatable/equatable.dart';

class GetOrganizations
    extends UseCase<List<Organization>, GetOrganizationsParams> {
  GetOrganizations(this._repository);

  final OrganizationRepository _repository;

  @override
  Future<List<Organization>> call(GetOrganizationsParams params) {
    return _repository.getOrganizations(
      search: params.search,
      includeInactive: params.includeInactive,
    );
  }
}

class GetOrganizationsParams extends Equatable {
  const GetOrganizationsParams({
    this.search,
    this.includeInactive = true,
  });

  final String? search;
  final bool includeInactive;

  @override
  List<Object?> get props => [search, includeInactive];
}
