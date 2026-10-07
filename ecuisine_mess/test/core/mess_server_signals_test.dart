import 'package:ecuisine_mess/core/services/local_mess_services.dart';
import 'package:ecuisine_mess/core/services/mess_server_signals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connection loss is debounced for 8 seconds', () async {
    final signals = MessServerSignals.instance;
    var count = 0;
    final sub = signals.onConnectionLost.listen((_) => count++);
    signals.notifyConnectionLost();
    signals.notifyConnectionLost();
    await Future<void>.delayed(Duration.zero);
    expect(count, 1);
    await sub.cancel();
  });

  test('local host check accepts loopback only', () {
    expect(LocalMessServices.hostIsLocal('http://127.0.0.1:8000'), isTrue);
    expect(LocalMessServices.hostIsLocal('http://localhost:8000'), isTrue);
    expect(LocalMessServices.hostIsLocal('http://192.168.1.10:8000'), isFalse);
    expect(LocalMessServices.hostIsLocal('not a url'), isFalse);
  });
}
