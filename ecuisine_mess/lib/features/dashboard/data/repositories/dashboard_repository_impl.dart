import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remote);

  final DashboardRemoteDataSource _remote;

  @override
  Future<DashboardSummary> getSummary() async {
    try {
      final model = await _remote.getSummary();
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }
}
