import 'package:ecuisine_mess/shared/widgets/layout/animated_nav_icon.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimatedNavIcon', () {
    testWidgets('renders the icon glyph correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedNavIcon(
                icon: Icons.dashboard_outlined,
                isSelected: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
    });

    testWidgets('remains at scale 1.0 when unselected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedNavIcon(
                icon: Icons.dashboard_outlined,
                isSelected: false,
              ),
            ),
          ),
        ),
      );

      final transformFinder = find.descendant(
        of: find.byType(AnimatedNavIcon),
        matching: find.byType(Transform),
      );

      expect(transformFinder, findsWidgets);

      // Settle initial frame
      await tester.pump(const Duration(milliseconds: 50));

      final scaleTransforms = tester
          .widgetList<Transform>(transformFinder)
          .where((t) => t.transform.storage[0] == t.transform.storage[5]) // scale matrix
          .toList();

      expect(scaleTransforms.isNotEmpty, isTrue);
      // Scale should be 1.0
      expect(scaleTransforms.last.transform.storage[0], closeTo(1.0, 0.01));
    });

    testWidgets('animates scale and glow when selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedNavIcon(
                icon: Icons.dashboard,
                isSelected: true,
              ),
            ),
          ),
        ),
      );

      // Verify DecoratedBox with BoxShadow is present for glow aura
      expect(find.byType(DecoratedBox), findsWidgets);

      // Advance by 300ms (entrance completed)
      await tester.pump(const Duration(milliseconds: 300));

      // Advance further into ambient breathing (half cycle ~900ms)
      await tester.pump(const Duration(milliseconds: 900));

      final transformFinder = find.descendant(
        of: find.byType(AnimatedNavIcon),
        matching: find.byType(Transform),
      );
      final scaleTransforms = tester
          .widgetList<Transform>(transformFinder)
          .where((t) => t.transform.storage[0] == t.transform.storage[5])
          .toList();

      expect(scaleTransforms.isNotEmpty, isTrue);
      expect(scaleTransforms.last.transform.storage[0], greaterThan(1.0));
    });

    testWidgets('scales up on mouse hover and restores on exit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedNavIcon(
                icon: Icons.restaurant,
                isSelected: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));

      // Hover over the icon
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byIcon(Icons.restaurant)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final transformFinder = find.descendant(
        of: find.byType(AnimatedNavIcon),
        matching: find.byType(Transform),
      );
      final scaleTransforms = tester
          .widgetList<Transform>(transformFinder)
          .where((t) => t.transform.storage[0] == t.transform.storage[5])
          .toList();

      expect(scaleTransforms.last.transform.storage[0], closeTo(1.06, 0.02));

      // Mouse exit
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final restoredTransforms = tester
          .widgetList<Transform>(transformFinder)
          .where((t) => t.transform.storage[0] == t.transform.storage[5])
          .toList();
      expect(restoredTransforms.last.transform.storage[0], closeTo(1.0, 0.01));

      await gesture.removePointer();
    });

    testWidgets('respects disableAnimations setting', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AnimatedNavIcon(
                  icon: Icons.analytics,
                  isSelected: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Since animations are disabled, pumpAndSettle can safely complete
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });
  });
}
