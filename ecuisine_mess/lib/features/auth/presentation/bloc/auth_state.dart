part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class Authenticated extends AuthState {
  const Authenticated({required this.user, required this.token});

  final AppUser user;
  final String token;

  @override
  List<Object?> get props => [user, token];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Transient UI state while login request is in flight.
final class AuthLoginInProgress extends AuthState {
  const AuthLoginInProgress({required this.username, this.previousMessage});

  final String username;
  final String? previousMessage;

  @override
  List<Object?> get props => [username, previousMessage];
}
