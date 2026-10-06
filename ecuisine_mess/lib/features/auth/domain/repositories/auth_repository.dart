import 'package:ecuisine_mess/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  Future<({String token, AppUser user})> login({
    required String username,
    required String password,
  });

  Future<AppUser?> restoreSession();

  Future<void> logout();

  Future<void> clearLocalSession();

  String? get currentToken;
}
