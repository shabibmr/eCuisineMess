import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/auth/domain/entities/app_user.dart';
import 'package:ecuisine_mess/features/auth/domain/repositories/auth_repository.dart';

class RestoreSession extends UseCase<AppUser?, NoParams> {
  RestoreSession(this._repository);

  final AuthRepository _repository;

  @override
  Future<AppUser?> call(NoParams params) => _repository.restoreSession();
}
