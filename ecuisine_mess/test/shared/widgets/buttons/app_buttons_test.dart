import 'package:ecuisine_mess/shared/widgets/buttons/app_create_button.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_danger_button.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_refresh_button.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shared Buttons Tests', () {
    testWidgets('AppSaveButton shows label and responds to taps', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSaveButton(
              onPressed: () => pressed = true,
              label: 'Save Cuisine',
            ),
          ),
        ),
      );

      expect(find.text('Save Cuisine'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.byType(AppSaveButton));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('AppSaveButton shows spinner and disables when isLoading is true',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSaveButton(
              onPressed: () => pressed = true,
              isLoading: true,
              loadingLabel: 'Saving now...',
            ),
          ),
        ),
      );

      expect(find.text('Saving now...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);

      await tester.tap(find.byType(AppSaveButton));
      await tester.pump();
      expect(pressed, isFalse);
    });

    testWidgets('AppDangerButton shows delete styling and executes callback',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDangerButton(
              onPressed: () => pressed = true,
              label: 'Delete Organization',
            ),
          ),
        ),
      );

      expect(find.text('Delete Organization'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(find.byType(AppDangerButton));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('AppDangerButton shows loading state and disables callback',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDangerButton(
              onPressed: () => pressed = true,
              isLoading: true,
              loadingLabel: 'Deleting item...',
            ),
          ),
        ),
      );

      expect(find.text('Deleting item...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(AppDangerButton));
      await tester.pump();
      expect(pressed, isFalse);
    });

    testWidgets('AppCreateButton renders label, icon, and triggers onTap',
        (tester) async {
      var created = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCreateButton(
              onPressed: () => created = true,
              label: 'Add Member',
            ),
          ),
        ),
      );

      expect(find.text('Add Member'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byType(AppCreateButton));
      await tester.pump();
      expect(created, isTrue);
    });

    testWidgets('AppRefreshButton renders icon and tooltip and handles clicks',
        (tester) async {
      var refreshed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppRefreshButton(
              onPressed: () => refreshed = true,
              tooltip: 'Refresh list',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byTooltip('Refresh list'), findsOneWidget);

      await tester.tap(find.byType(AppRefreshButton));
      await tester.pump();
      expect(refreshed, isTrue);
    });

    testWidgets('AppRefreshButton shows spinner when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppRefreshButton(
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });
  });
}
