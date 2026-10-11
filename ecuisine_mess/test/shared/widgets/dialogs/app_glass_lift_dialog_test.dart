import 'package:ecuisine_mess/shared/widgets/dialogs/app_confirm_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_glass_lift_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppGlassLiftDialog', () {
    testWidgets('enters with scale and fade, then settles at identity',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showAppGlassLiftDialog<void>(
                  context: ctx,
                  builder: (_) => const AppGlassLiftShell(
                    header: Text('Glass title'),
                    body: Text('Glass body'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('Glass title'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);

      await tester.pumpAndSettle();

      final scales = tester
          .widgetList<Transform>(find.byType(Transform))
          .map((t) => t.transform.storage[0])
          .where((s) => s > 0.5)
          .toList();
      expect(scales, isNotEmpty);
      expect(scales.last, closeTo(1.0, 0.02));
    });

    testWidgets('reduced motion skips scale and uses fade only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => AppConfirmDialog.show(
                  context: ctx,
                  title: 'Skip motion?',
                  message: 'Reduced',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(find.text('Skip motion?'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Skip motion?'), findsOneWidget);
    });

    testWidgets('barrier tap dismisses when allowed', (tester) async {
      bool? closed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () async {
                  closed = await showAppGlassLiftDialog<bool>(
                    context: ctx,
                    builder: (_) => const AppGlassLiftShell(
                      body: SizedBox(
                        width: 200,
                        height: 80,
                        child: Text('Dismiss me'),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dismiss me'), findsOneWidget);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(find.text('Dismiss me'), findsNothing);
      expect(closed, isNull);
    });
  });
}
