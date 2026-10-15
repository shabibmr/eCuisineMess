import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/core/router/nav_destinations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nav destinations', () {
    test('admin pages are omitted from the rail', () {
      for (final route in [
        AppRoutes.organizations,
        AppRoutes.mealTimes,
        AppRoutes.itemCategories,
      ]) {
        expect(kNavDestinations.any((d) => d.route == route), isTrue);
        expect(kRailDestinations.any((d) => d.route == route), isFalse);
      }
    });

    test('rail and branch indices skip Organization', () {
      final orgBranch = kNavDestinations.indexWhere(
        (d) => d.route == AppRoutes.organizations,
      );
      final menuBranch = kNavDestinations.indexWhere(
        (d) => d.route == AppRoutes.menu,
      );

      expect(railIndexForBranch(orgBranch), isNull);
      expect(branchIndexForRail(railIndexForBranch(menuBranch)!), menuBranch);
      final labels = kRailDestinations.map((d) => d.label).toList();
      expect(labels, isNot(contains('Organization')));
      expect(labels, isNot(contains('Meal Times')));
      expect(labels, isNot(contains('Item Categories')));
    });
  });
}
