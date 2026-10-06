import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/auth/domain/repositories/auth_repository.dart';

class Logout extends UseCase<void, NoParams> {
  Logout(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(NoParams params) => _repository.logout();
}
