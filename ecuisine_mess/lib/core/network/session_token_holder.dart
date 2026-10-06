/// Holds the current Bearer token for Dio [AuthInterceptor].
/// Updated by AuthBloc / AuthRepository on login, restore, logout, and 401.
class SessionTokenHolder {
  String? token;
}
