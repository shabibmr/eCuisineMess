import 'dart:typed_data';

import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';

abstract interface class ReportsRepository {
  Future<AttendanceReport> getAttendance(ReportQuery query);

  Future<List<ItemMovementRow>> getItemMovement(ReportQuery query);

  Future<TimeDistributionReport> getTimeDistribution(ReportQuery query);

  Future<MembersRegister> getMembersRegister(ReportQuery query);

  /// Server-generated pipe-delimited CSV (UTF-8 BOM) for [kind].
  Future<Uint8List> exportCsv(ReportKind kind, ReportQuery query);
}
