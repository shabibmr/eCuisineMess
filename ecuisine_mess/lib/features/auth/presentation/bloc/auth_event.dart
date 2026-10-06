part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

final class SessionExpired extends AuthEvent {
  const SessionExpired();
}
