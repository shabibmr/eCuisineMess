import 'package:ecuisine_mess/core/config/app_config.dart';
import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AppConfig config;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    config = AppConfig(prefs);
    await config.load();
  });

  test('setBaseUrl strips trailing slash and persists', () async {
    await config.setBaseUrl('http://127.0.0.1:8000/');
    expect(config.baseUrl, 'http://127.0.0.1:8000');
    expect(
      prefs.getString(AppConstants.apiBaseUrlPrefsKey),
      'http://127.0.0.1:8000',
    );
  });

  test('setBaseUrl rejects non-http(s)', () async {
    expect(
      () => config.setBaseUrl('ftp://bad.example'),
      throwsA(isA<ArgumentError>()),
    );
    expect(config.baseUrl, AppConstants.defaultApiBaseUrl);
  });

  test('load restores saved url', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.apiBaseUrlPrefsKey: 'http://10.0.0.5:9000',
    });
    prefs = await SharedPreferences.getInstance();
    config = AppConfig(prefs);
    await config.load();
    expect(config.baseUrl, 'http://10.0.0.5:9000');
  });

  test('ApiException toString is message only', () {
    final e = ApiException(401, 'Invalid credentials');
    expect(e.toString(), 'Invalid credentials');
    expect(e.toString().contains('Exception:'), isFalse);
  });
}
