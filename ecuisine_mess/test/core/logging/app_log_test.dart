import 'dart:io';

import 'package:ecuisine_mess/core/logging/app_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('ecuisine_mess_app_log_');
  });

  tearDown(() {
    AppLog.debugReset();
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  test('log directory prefers LOCALAPPDATA', () {
    expect(
      AppLog.logDirectoryPath(
        environment: {'LOCALAPPDATA': r'C:\Users\counter\AppData\Local'},
      ),
      r'C:\Users\counter\AppData\Local\ecuisine_mess\logs',
    );
  });

  test('log directory falls back to the user profile, then temp', () {
    expect(
      AppLog.logDirectoryPath(
        environment: {'USERPROFILE': r'C:\Users\counter'},
      ),
      r'C:\Users\counter\AppData\Local\ecuisine_mess\logs',
    );
    expect(
      AppLog.logDirectoryPath(environment: const {}, tempPath: r'C:\Temp'),
      r'C:\Temp\ecuisine_mess\logs',
    );
  });

  test('redacts secrets and leaves ordinary text', () {
    const message =
        'login password=secret pin: 1234 '
        'rfid=04A1B2 token: "abc" Authorization: Bearer eyJ.hdr.sig '
        'member Ada served';

    final redacted = AppLog.redact(message);

    expect(redacted, contains('password=[redacted]'));
    expect(redacted, contains('pin: [redacted]'));
    expect(redacted, contains('rfid=[redacted]'));
    expect(redacted, contains('token: [redacted]'));
    expect(redacted, contains('Authorization: [redacted]'));
    expect(redacted, contains('member Ada served'));
    expect(redacted, isNot(contains('secret')));
    expect(redacted, isNot(contains('04A1B2')));
    expect(redacted, isNot(contains('eyJ.hdr.sig')));
  });

  test('appends a flushed line to app.log', () {
    AppLog.debugUseDirectory(temp.path);

    AppLog.info('Flutter binding ready');

    final log = File(p.join(temp.path, 'app.log'));
    expect(log.existsSync(), isTrue);
    final text = log.readAsStringSync();
    expect(text, contains(' info Flutter binding ready'));
    expect(text, endsWith('\r\n'));
  });

  test('rolls the file once it reaches the size cap', () {
    AppLog.debugUseDirectory(temp.path, maxBytes: 40);

    AppLog.info('first startup line that is long enough to rotate');
    AppLog.info('second startup line that is long enough to rotate');

    expect(File(p.join(temp.path, 'app.log')).existsSync(), isTrue);
    expect(File(p.join(temp.path, 'app.log.1')).existsSync(), isTrue);
    expect(
      File(p.join(temp.path, 'app.log')).readAsStringSync(),
      contains('second startup line'),
    );
    expect(
      File(p.join(temp.path, 'app.log.1')).readAsStringSync(),
      contains('first startup line'),
    );
  });

  test('error lines store the exception and a redacted stack', () {
    AppLog.debugUseDirectory(temp.path);

    AppLog.error(
      'startup failed',
      Exception('password=hunter2'),
      StackTrace.current,
    );

    final text = File(p.join(temp.path, 'app.log')).readAsStringSync();
    expect(text, contains(' error startup failed'));
    expect(text, contains('password=[redacted]'));
    expect(text, isNot(contains('hunter2')));
  });
}
