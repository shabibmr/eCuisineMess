import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';
import 'package:ecuisine_mess/features/reports/domain/repositories/reports_repository.dart';
import 'package:ecuisine_mess/shared/services/file_export_service.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class GetAttendanceReport extends UseCase<AttendanceReport, ReportQuery> {
  GetAttendanceReport(this._repository);

  final ReportsRepository _repository;

  @override
  Future<AttendanceReport> call(ReportQuery params) =>
      _repository.getAttendance(params);
}

class GetItemMovementReport
    extends UseCase<List<ItemMovementRow>, ReportQuery> {
  GetItemMovementReport(this._repository);

  final ReportsRepository _repository;

  @override
  Future<List<ItemMovementRow>> call(ReportQuery params) =>
      _repository.getItemMovement(params);
}

class GetTimeDistributionReport
    extends UseCase<TimeDistributionReport, ReportQuery> {
  GetTimeDistributionReport(this._repository);

  final ReportsRepository _repository;

  @override
  Future<TimeDistributionReport> call(ReportQuery params) =>
      _repository.getTimeDistribution(params);
}

class GetMembersRegister extends UseCase<MembersRegister, ReportQuery> {
  GetMembersRegister(this._repository);

  final ReportsRepository _repository;

  @override
  Future<MembersRegister> call(ReportQuery params) =>
      _repository.getMembersRegister(params);
}

class ExportReportCsvParams extends Equatable {
  const ExportReportCsvParams(this.kind, this.query);

  final ReportKind kind;
  final ReportQuery query;

  @override
  List<Object?> get props => [kind, query];
}

/// Downloads the server-built CSV and saves it; returns the saved path.
class ExportReportCsv extends UseCase<String, ExportReportCsvParams> {
  ExportReportCsv(this._repository, this._files, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ReportsRepository _repository;
  final FileExportService _files;
  final DateTime Function() _clock;

  Future<List<int>> getCsvBytes(ExportReportCsvParams params) =>
      _repository.exportCsv(params.kind, params.query);

  @override
  Future<String> call(ExportReportCsvParams params) async {
    final bytes = await getCsvBytes(params);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(_clock());
    return _files.save('${params.kind.fileStem}_$stamp.csv', bytes);
  }
}
