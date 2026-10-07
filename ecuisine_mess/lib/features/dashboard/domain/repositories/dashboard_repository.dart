import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> getSummary();
}
