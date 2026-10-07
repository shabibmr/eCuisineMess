import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardSummary extends UseCase<DashboardSummary, NoParams> {
  GetDashboardSummary(this._repository);

  final DashboardRepository _repository;

  @override
  Future<DashboardSummary> call(NoParams params) => _repository.getSummary();
}
