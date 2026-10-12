import 'package:ecuisine_mess/core/services/mess_server_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MessServerGuard passes pointer events through to the child',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MessServerGuard(child: child ?? const SizedBox.shrink());
        },
        home: Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Tap me'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap me'));
    await tester.pump();

    expect(taps, 1);
  });
}
