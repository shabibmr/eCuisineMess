import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/network/session_token_holder.dart';
import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/auth/domain/entities/app_user.dart';
import 'package:ecuisine_mess/features/auth/domain/repositories/auth_repository.dart';
import 'package:ecuisine_mess/features/auth/domain/usecases/login.dart';
import 'package:ecuisine_mess/features/auth/domain/usecases/logout.dart';
import 'package:ecuisine_mess/features/auth/domain/usecases/restore_session.dart';
import 'package:ecuisine_mess/services/api_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RestoreSession restoreSession,
    required Login login,
    required Logout logout,
    required AuthRepository authRepository,
    required SessionTokenHolder sessionTokenHolder,
  })  : _restoreSession = restoreSession,
        _login = login,
        _logout = logout,
        _authRepository = authRepository,
        _sessionTokenHolder = sessionTokenHolder,
        super(const AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<LoginSubmitted>(_onLoginSubmitted, transformer: droppable());
    on<LogoutRequested>(_onLogoutRequested, transformer: droppable());
    on<SessionExpired>(_onSessionExpired);
  }

  final RestoreSession _restoreSession;
  final Login _login;
  final Logout _logout;
  final AuthRepository _authRepository;
  final SessionTokenHolder _sessionTokenHolder;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthUnknown());
    final AppUser? user;
    try {
      user = await _restoreSession(const NoParams());
    } on Failure catch (e) {
      // Saved token is kept; only the session could not be verified.
      _bridgeToken(null);
      emit(Unauthenticated(message: e.message));
      return;
    }
    final token = _authRepository.currentToken;
    if (user != null && token != null) {
      _bridgeToken(token);
      emit(Authenticated(user: user, token: token));
    } else {
      _bridgeToken(null);
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    emit(
      AuthLoginInProgress(
        username: event.username,
        previousMessage: current is Unauthenticated ? current.message : null,
      ),
    );
    try {
      final result = await _login(
        LoginParams(username: event.username, password: event.password),
      );
      _bridgeToken(result.token);
      emit(Authenticated(user: result.user, token: result.token));
    } on Failure catch (e) {
      _bridgeToken(null);
      emit(Unauthenticated(message: e.message));
    } catch (e) {
      _bridgeToken(null);
      emit(Unauthenticated(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _logout(const NoParams());
    } catch (_) {
      await _authRepository.clearLocalSession();
    }
    _bridgeToken(null);
    emit(const Unauthenticated());
  }

  Future<void> _onSessionExpired(
    SessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.clearLocalSession();
    _bridgeToken(null);
    emit(const Unauthenticated(message: 'Session expired'));
  }

  /// Strangler bridge: keep legacy [ApiService] and Dio interceptor in sync.
  void _bridgeToken(String? token) {
    _sessionTokenHolder.token = token;
    ApiService.authToken = token;
  }
}
