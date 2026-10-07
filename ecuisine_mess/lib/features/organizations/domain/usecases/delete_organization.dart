import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/organizations/domain/repositories/organization_repository.dart';
import 'package:equatable/equatable.dart';

class DeleteOrganization extends UseCase<void, DeleteOrganizationParams> {
  DeleteOrganization(this._repository);

  final OrganizationRepository _repository;

  @override
  Future<void> call(DeleteOrganizationParams params) {
    return _repository.deleteOrganization(params.id);
  }
}

class DeleteOrganizationParams extends Equatable {
  const DeleteOrganizationParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
