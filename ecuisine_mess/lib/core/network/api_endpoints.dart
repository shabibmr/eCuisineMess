/// Paths relative to `{baseUrl}/api/v1`.
class ApiEndpoints {
  static const String health = '/health';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String itemCategories = '/item-categories';

  static String itemCategory(String id) => '/item-categories/$id';

  static const String items = '/items';

  static String item(String id) => '/items/$id';

  static const String uoms = '/uoms';

  static const String members = '/members';

  static String member(String id) => '/members/$id';

  static String membersByRfid(String tag) =>
      '/members/by-rfid/${Uri.encodeComponent(tag)}';

  static const String cuisines = '/cuisines';

  static const String mealTimesCurrent = '/meal-times/current';
  static const String counterTap = '/counter/tap';
  static const String counterIssueToken = '/counter/issue-token';
  static const String bills = '/bills';

  static String bill(String id) => '/bills/$id';
  static String billCancel(String id) => '/bills/$id/cancel';
}
