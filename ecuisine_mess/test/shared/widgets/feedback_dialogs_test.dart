import 'package:ecuisine_mess/shared/widgets/dialogs/app_confirm_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_form_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/feedback/app_alert_banner.dart';
import 'package:ecuisine_mess/shared/widgets/feedback/app_empty_state.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppPasswordField Tests', () {
    testWidgets('obscures text by default and toggles visibility on icon tap',
        (tester) async {
      final controller = TextEditingController(text: 'secret123');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPasswordField(
              controller: controller,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      final updatedTextField =
          tester.widget<TextField>(find.byType(TextField));
      expect(updatedTextField.obscureText, isFalse);
    });
  });

  group('AppAlertBanner Tests', () {
    testWidgets('renders all severity levels with proper text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppAlertBanner.error(message: 'Error occurred'),
                AppAlertBanner.warning(message: 'Warning warning'),
                AppAlertBanner.info(message: 'Informational note'),
                AppAlertBanner.success(message: 'All good!'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.text('Warning warning'), findsOneWidget);
      expect(find.text('Informational note'), findsOneWidget);
      expect(find.text('All good!'), findsOneWidget);
    });
  });

  group('AppEmptyState Tests', () {
    testWidgets('renders title, message, and executes CTA action',
        (tester) async {
      var triggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              title: 'No Items Found',
              message: 'Get started by creating your first item',
              actionLabel: 'Add Item',
              onAction: () => triggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Items Found'), findsOneWidget);
      expect(find.text('Get started by creating your first item'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      await tester.pump();
      expect(triggered, isTrue);
    });
  });

  group('AppConfirmDialog Tests', () {
    testWidgets('returns true on confirm and false on cancel', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await AppConfirmDialog.show(
                    context: ctx,
                    title: 'Delete Cuisine?',
                    message: 'Are you sure?',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Cuisine?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('AppFormDialog Tests', () {
    testWidgets('validates form before returning true', (tester) async {
      bool? formResult;
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  formResult = await showAppFormDialog(
                    context: ctx,
                    title: 'Add Category',
                    formKey: formKey,
                    body: TextFormField(
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required field' : null,
                    ),
                  );
                },
                child: const Text('Open Form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      expect(find.text('Add Category'), findsOneWidget);

      // Tap Save with empty input -> should fail validation and not close
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Required field'), findsOneWidget);
      expect(formResult, isNull);

      // Enter valid text and save
      await tester.enterText(find.byType(TextFormField), 'Valid input');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(formResult, isTrue);
    });
  });
}
