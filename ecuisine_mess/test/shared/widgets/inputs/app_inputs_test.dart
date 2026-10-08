import 'package:ecuisine_mess/shared/widgets/inputs/app_date_picker_field.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_dropdown.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_search_field.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_switch_tile.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_time_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSearchField Tests', () {
    testWidgets('renders search icon, triggers onChanged, and clears on clear click',
        (tester) async {
      String currentText = '';
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              controller: controller,
              hintText: 'Search items...',
              onChanged: (val) => currentText = val,
            ),
          ),
        ),
      );

      expect(find.text('Search items...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);

      await tester.enterText(find.byType(TextField), 'Biryani');
      await tester.pump();

      expect(currentText, 'Biryani');
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(controller.text, '');
      expect(currentText, '');
      expect(find.byIcon(Icons.clear), findsNothing);
    });
  });

  group('AppDatePickerField Tests', () {
    testWidgets('renders formatted date and clear action', (tester) async {
      var cleared = false;
      final selectedDate = DateTime(2026, 10, 8);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDatePickerField(
              value: selectedDate,
              onChanged: (_) {},
              onCleared: () => cleared = true,
              label: 'Filter Date',
            ),
          ),
        ),
      );

      expect(find.text('2026-10-08'), findsOneWidget);
      expect(find.text('Filter Date'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(cleared, isTrue);
    });
  });

  group('AppTimePickerField Tests', () {
    testWidgets('formats time string properly and displays label',
        (tester) async {
      const time = TimeOfDay(hour: 14, minute: 30);
      expect(formatTimeOfDay(time), '14:30');

      final parsed = parseTimeString('08:45');
      expect(parsed?.hour, 8);
      expect(parsed?.minute, 45);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTimePickerField(
              value: time,
              label: 'Start Time',
              onChanged: (_, _) {},
            ),
          ),
        ),
      );

      expect(find.text('14:30'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });
  });

  group('AppDropdown Tests', () {
    testWidgets('renders items and handles placeholder', (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDropdown<String>(
              label: 'Category',
              placeholderLabel: 'All Categories',
              value: selected,
              items: const [
                AppDropdownItem(value: 'cat1', label: 'Beverages'),
                AppDropdownItem(value: 'cat2', label: 'Snacks'),
              ],
              onChanged: (v) => selected = v,
            ),
          ),
        ),
      );

      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);

      await tester.tap(find.text('All Categories'));
      await tester.pumpAndSettle();

      expect(find.text('Beverages').last, findsOneWidget);
      expect(find.text('Snacks').last, findsOneWidget);

      await tester.tap(find.text('Snacks').last);
      await tester.pumpAndSettle();

      expect(selected, 'cat2');
    });
  });

  group('AppSwitchTile Tests', () {
    testWidgets('renders title and triggers callback', (tester) async {
      var state = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSwitchTile(
              title: 'Enable Notifications',
              value: state,
              onChanged: (v) => state = v,
            ),
          ),
        ),
      );

      expect(find.text('Enable Notifications'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(state, isFalse);
    });
  });
}
