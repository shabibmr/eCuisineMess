import 'dart:async';

/// Connection-loss signal for the local service prompt.
/// Kept free of Flutter and dart:io so the Dio interceptor can use it.
class MessServerSignals {
  MessServerSignals._();

  static final MessServerSignals instance = MessServerSignals._();

  final StreamController<void> _controller = StreamController<void>.broadcast();
  DateTime? _last;

  Stream<void> get onConnectionLost => _controller.stream;

  void notifyConnectionLost() {
    final now = DateTime.now();
    final last = _last;
    if (last != null && now.difference(last) < const Duration(seconds: 8)) {
      return;
    }
    _last = now;
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
