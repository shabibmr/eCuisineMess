/// Notifies listeners when a 401 should clear the local session (no logout API).
class UnauthorizedHandler {
  void Function()? onUnauthorized;

  void notify() => onUnauthorized?.call();
}
