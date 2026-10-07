import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/reports/data/models/report_models.dart';
import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';

abstract interface class ReportsRemoteDataSource {
  Future<AttendanceReport> getAttendance(ReportQuery query);

  Future<List<ItemMovementRow>> getItemMovement(ReportQuery query);

  Future<TimeDistributionReport> getTimeDistribution(ReportQuery query);

  Future<MembersRegister> getMembersRegister(ReportQuery query);

  Future<Uint8List> exportCsv(ReportKind kind, ReportQuery query);
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  ReportsRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final err = e.error;
      throw err is AppException
          ? err
          : AppException(e.message ?? 'Request failed');
    }
  }

  Future<Object?> _get(ReportKind kind, ReportQuery query) => _guard(() async {
    final res = await _client.dio.get<Object>(
      ApiEndpoints.report(kind.path),
      queryParameters: query.params,
    );
    return res.data;
  });

  Map<String, dynamic> _map(Object? data) =>
      Map<String, dynamic>.from(data as Map? ?? const {});

  @override
  Future<AttendanceReport> getAttendance(ReportQuery query) async =>
      ReportModels.attendance(_map(await _get(ReportKind.attendance, query)));

  @override
  Future<List<ItemMovementRow>> getItemMovement(ReportQuery query) async =>
      ReportModels.itemMovement(await _get(ReportKind.itemMovement, query));

  @override
  Future<TimeDistributionReport> getTimeDistribution(ReportQuery query) async =>
      ReportModels.timeDistribution(
        _map(await _get(ReportKind.timeDistribution, query)),
      );

  @override
  Future<MembersRegister> getMembersRegister(ReportQuery query) async =>
      ReportModels.membersRegister(
        _map(await _get(ReportKind.members, query)),
      );

  @override
  Future<Uint8List> exportCsv(ReportKind kind, ReportQuery query) =>
      _guard(() async {
        final res = await _client.dio.get<List<int>>(
          ApiEndpoints.reportExportCsv(kind.path),
          queryParameters: query.params,
          options: Options(responseType: ResponseType.bytes),
        );
        return Uint8List.fromList(res.data ?? const []);
      });
}
