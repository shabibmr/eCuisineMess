import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/auth/domain/entities/app_user.dart';
import 'package:ecuisine_mess/features/auth/domain/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';

class Login extends UseCase<({String token, AppUser user}), LoginParams> {
  Login(this._repository);

  final AuthRepository _repository;

  @override
  Future<({String token, AppUser user})> call(LoginParams params) {
    return _repository.login(
      username: params.username,
      password: params.password,
    );
  }
}

class LoginParams extends Equatable {
  const LoginParams({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}
