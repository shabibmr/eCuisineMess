import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/dashboard/data/models/dashboard_summary_model.dart';

abstract interface class DashboardRemoteDataSource {
  Future<DashboardSummaryModel> getSummary();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<DashboardSummaryModel> getSummary() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        ApiEndpoints.dashboardSummary,
      );
      return DashboardSummaryModel.fromJson(
        Map<String, dynamic>.from(res.data ?? const {}),
      );
    } on DioException catch (e) {
      final err = e.error;
      throw err is AppException
          ? err
          : AppException(e.message ?? 'Request failed');
    }
  }
}
