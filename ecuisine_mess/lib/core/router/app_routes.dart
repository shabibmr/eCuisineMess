class AppRoute {
  const AppRoute(this.name, this.path);

  final String name;
  final String path;
}

class AppRoutes {
  static const login = AppRoute('login', '/login');
  static const counter = AppRoute('counter', '/counter');
  static const members = AppRoute('members', '/members');
  static const cuisines = AppRoute('cuisines', '/cuisines');
  static const items = AppRoute('items', '/items');
  static const itemCategories = AppRoute('itemCategories', '/item-categories');
  static const bills = AppRoute('bills', '/bills');
  static const reports = AppRoute('reports', '/reports');

  static const defaultAuthenticated = counter;
}
