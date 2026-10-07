import 'dart:typed_data';

import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';
import 'package:ecuisine_mess/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._remote);

  final ReportsRemoteDataSource _remote;

  Future<T> _map<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<AttendanceReport> getAttendance(ReportQuery query) =>
      _map(() => _remote.getAttendance(query));

  @override
  Future<List<ItemMovementRow>> getItemMovement(ReportQuery query) =>
      _map(() => _remote.getItemMovement(query));

  @override
  Future<TimeDistributionReport> getTimeDistribution(ReportQuery query) =>
      _map(() => _remote.getTimeDistribution(query));

  @override
  Future<MembersRegister> getMembersRegister(ReportQuery query) =>
      _map(() => _remote.getMembersRegister(query));

  @override
  Future<Uint8List> exportCsv(ReportKind kind, ReportQuery query) =>
      _map(() => _remote.exportCsv(kind, query));
}
