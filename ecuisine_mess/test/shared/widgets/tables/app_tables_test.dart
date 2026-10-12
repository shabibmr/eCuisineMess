import 'package:ecuisine_mess/shared/widgets/tables/app_kpi_card.dart';
import 'package:ecuisine_mess/shared/widgets/tables/app_separated_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSeparatedListCard Tests', () {
    testWidgets('renders Card with separated items and dividers',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSeparatedListCard(
              itemCount: 3,
              itemBuilder: (ctx, i) => Text('Item $i'),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('AppKpiCard Tests', () {
    testWidgets('renders label, value, caption, and responds to onTap',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppKpiCard(
              label: 'Total Orders',
              value: 1250,
              icon: Icons.receipt_long,
              caption: 'Tokens issued today',
              accent: Colors.indigo,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Total Orders'), findsOneWidget);
      expect(find.text('1250'), findsOneWidget);
      expect(find.text('Tokens issued today'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);

      await tester.tap(find.text('1250'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
