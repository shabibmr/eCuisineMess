import 'package:ecuisine_mess/app.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecuisine_mess/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await configureDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('App shows login when no session', (WidgetTester tester) async {
    await tester.pumpWidget(const ECuisineMessApp());

    final auth = sl<AuthBloc>();
    auth.add(const AuthStarted());
    await auth.stream.firstWhere((state) => state is! AuthUnknown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ECuisineMessApp), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
