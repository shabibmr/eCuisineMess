import 'package:ecuisine_mess/shared/widgets/layout/user_account_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens account menu and reports selected action', (tester) async {
    UserAccountMenuAction? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              UserAccountMenu(
                displayName: 'Administrator',
                onSelected: (action) => selected = action,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byTooltip('Email & SMTP Settings'), findsNothing);
    expect(find.byTooltip('Logout'), findsNothing);

    await tester.tap(find.text('Administrator'));
    await tester.pumpAndSettle();

    expect(find.text('Organizations'), findsOneWidget);
    expect(find.text('Email & SMTP Settings'), findsOneWidget);
    expect(find.text('Check for Updates'), findsOneWidget);
    expect(find.text('Printer Settings'), findsOneWidget);
    expect(find.text('Server Connection'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);

    await tester.tap(find.text('Organizations'));
    await tester.pumpAndSettle();

    expect(selected, UserAccountMenuAction.organizations);
  });
}
