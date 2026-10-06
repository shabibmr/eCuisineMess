import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/network/session_token_holder.dart';
import 'package:ecuisine_mess/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ecuisine_mess/features/auth/data/datasources/session_local_datasource.dart';
import 'package:ecuisine_mess/features/auth/domain/entities/app_user.dart';
import 'package:ecuisine_mess/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SessionLocalDataSource local,
    required SessionTokenHolder sessionTokenHolder,
  })  : _remote = remote,
        _local = local,
        _session = sessionTokenHolder;

  final AuthRemoteDataSource _remote;
  final SessionLocalDataSource _local;
  final SessionTokenHolder _session;

  @override
  String? get currentToken => _session.token;

  @override
  Future<({String token, AppUser user})> login({
    required String username,
    required String password,
  }) async {
    try {
      final result = await _remote.login(
        username: username,
        password: password,
      );
      await _local.saveToken(result.token);
      _session.token = result.token;
      return (token: result.token, user: result.user.toEntity());
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    try {
      final saved = await _local.readToken();
      if (saved == null || saved.isEmpty) {
        _session.token = null;
        return null;
      }
      _session.token = saved;
      final user = await _remote.fetchMe(saved);
      return user.toEntity();
    } on Object catch (e) {
      final failure = mapException(e);
      if (failure is UnauthorizedFailure) {
        await clearLocalSession();
        return null;
      }
      // Transient failure (offline, 5xx): keep the saved token for the next
      // attempt, but do not leave it active on the in-memory holder.
      _session.token = null;
      throw failure;
    }
  }

  @override
  Future<void> logout() async {
    final token = _session.token;
    if (token != null) {
      try {
        await _remote.logout(token);
      } catch (_) {
        // Local clear still proceeds.
      }
    }
    await clearLocalSession();
  }

  @override
  Future<void> clearLocalSession() async {
    await _local.clearToken();
    _session.token = null;
  }
}
