import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/core/router/nav_destinations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nav destinations', () {
    test('Organizations is omitted from the rail', () {
      expect(
        kNavDestinations.any((d) => d.route == AppRoutes.organizations),
        isTrue,
      );
      expect(
        kRailDestinations.any((d) => d.route == AppRoutes.organizations),
        isFalse,
      );
    });

    test('rail and branch indices skip Organizations', () {
      final orgBranch = kNavDestinations.indexWhere(
        (d) => d.route == AppRoutes.organizations,
      );
      final menuBranch = kNavDestinations.indexWhere(
        (d) => d.route == AppRoutes.menu,
      );

      expect(railIndexForBranch(orgBranch), isNull);
      expect(branchIndexForRail(railIndexForBranch(menuBranch)!), menuBranch);
      expect(
        kRailDestinations.map((d) => d.label),
        isNot(contains('Organizations')),
      );
    });
  });
}
