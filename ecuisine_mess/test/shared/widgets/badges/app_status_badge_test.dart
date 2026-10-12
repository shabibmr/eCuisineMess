import 'package:ecuisine_mess/shared/widgets/badges/app_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStatusBadge Tests', () {
    testWidgets('renders all status types with correct default labels',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppStatusBadge.active(),
                AppStatusBadge.inactive(),
                AppStatusBadge.expired(),
                AppStatusBadge.suspended(),
                AppStatusBadge.served(),
                AppStatusBadge.cancelled(),
                AppStatusBadge.locked(),
                AppStatusBadge.unsaved(),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Suspended'), findsOneWidget);
      expect(find.text('Served'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Unsaved'), findsOneWidget);
    });

    testWidgets('fromBool factory works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppStatusBadge.fromBool(true),
                AppStatusBadge.fromBool(false),
                AppStatusBadge.fromBool(true, activeLabel: 'Enabled'),
                AppStatusBadge.fromBool(false, inactiveLabel: 'Disabled'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
    });

    test('tryParse parses valid strings and aliases', () {
      expect(AppStatusType.tryParse('ACTIVE'), AppStatusType.active);
      expect(AppStatusType.tryParse('inactive'), AppStatusType.inactive);
      expect(AppStatusType.tryParse('Expired'), AppStatusType.expired);
      expect(AppStatusType.tryParse('suspended'), AppStatusType.suspended);
      expect(AppStatusType.tryParse('SERVED'), AppStatusType.served);
      expect(AppStatusType.tryParse('cancelled'), AppStatusType.cancelled);
      expect(AppStatusType.tryParse('canceled'), AppStatusType.cancelled);
      expect(AppStatusType.tryParse('locked'), AppStatusType.locked);
      expect(AppStatusType.tryParse('unsaved'), AppStatusType.unsaved);
      expect(AppStatusType.tryParse('draft'), AppStatusType.unsaved);
      expect(AppStatusType.tryParse('invalid'), isNull);
      expect(AppStatusType.tryParse(null), isNull);
    });
  });
}
