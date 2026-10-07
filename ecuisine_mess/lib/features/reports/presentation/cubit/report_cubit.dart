import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';
import 'package:ecuisine_mess/features/reports/domain/usecases/reports_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class ReportState<T> extends Equatable {
  const ReportState({
    this.status = Status.initial,
    this.data,
    this.query,
    this.error,
    this.exporting = false,
    this.notice,
    this.noticeIsError = false,
  });

  final Status status;
  final T? data;

  /// The query [data] was generated for; exports reuse it.
  final ReportQuery? query;
  final String? error;
  final bool exporting;

  /// One-shot message (e.g. where the CSV was saved); the UI clears it.
  final String? notice;
  final bool noticeIsError;

  ReportState<T> copyWith({
    Status? status,
    T? data,
    ReportQuery? query,
    String? error,
    bool clearError = false,
    bool? exporting,
    String? notice,
    bool noticeIsError = false,
    bool clearNotice = false,
  }) {
    return ReportState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
      exporting: exporting ?? this.exporting,
      notice: clearNotice ? null : (notice ?? this.notice),
      noticeIsError: clearNotice ? false : noticeIsError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    data,
    query,
    error,
    exporting,
    notice,
    noticeIsError,
  ];
}

/// Runs one report and exports it as CSV. The same class backs every report;
/// only the use case and [kind] differ.
class ReportCubit<T> extends Cubit<ReportState<T>> {
  ReportCubit({
    required this.kind,
    required UseCase<T, ReportQuery> load,
    required ExportReportCsv export,
  }) : _load = load,
       _export = export,
       super(ReportState<T>());

  final ReportKind kind;
  final UseCase<T, ReportQuery> _load;
  final ExportReportCsv _export;

  Future<void> generate(ReportQuery query) async {
    if (state.status == Status.loading) return;
    emit(state.copyWith(status: Status.loading, clearError: true));
    try {
      final data = await _load(query);
      emit(state.copyWith(status: Status.success, data: data, query: query));
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  /// Exports exactly what is on screen; no-op until a report was generated.
  Future<void> exportCsv() async {
    final query = state.query;
    if (query == null || state.exporting) return;
    emit(state.copyWith(exporting: true, clearNotice: true));
    try {
      final path = await _export(ExportReportCsvParams(kind, query));
      emit(state.copyWith(exporting: false, notice: 'Saved to $path'));
    } on Failure catch (e) {
      emit(
        state.copyWith(
          exporting: false,
          notice: 'Export failed: ${e.message}',
          noticeIsError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          exporting: false,
          notice: 'Export failed: $e',
          noticeIsError: true,
        ),
      );
    }
  }

  /// Fetches raw pipe-delimited CSV bytes for the currently active report query.
  Future<List<int>> getCsvBytes() async {
    final query = state.query;
    if (query == null) throw StateError('No report generated yet.');
    return _export.getCsvBytes(ExportReportCsvParams(kind, query));
  }

  void noticeShown() => emit(state.copyWith(clearNotice: true));
}
