import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';
import 'package:ecuisine_mess/features/reports/presentation/cubit/report_cubit.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wires a [ReportCubit] to a [ReportFrame]: generate, export, snackbar notice.
class ReportTab<T> extends StatelessWidget {
  const ReportTab({
    super.key,
    required this.filters,
    required this.buildQuery,
    required this.isEmpty,
    required this.result,
    this.summary,
  });

  final Widget filters;

  /// Reads the current filter selection.
  final ReportQuery Function() buildQuery;
  final bool Function(T data) isEmpty;
  final Widget Function(T data) result;
  final Widget Function(T data)? summary;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportCubit<T>, ReportState<T>>(
      listenWhen: (prev, next) =>
          next.notice != null && next.notice != prev.notice,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.notice!),
              backgroundColor: state.noticeIsError ? Colors.red.shade700 : null,
            ),
          );
        context.read<ReportCubit<T>>().noticeShown();
      },
      builder: (context, state) {
        final data = state.data;
        final cubit = context.read<ReportCubit<T>>();
        return ReportFrame(
          filters: filters,
          loading: state.status == Status.loading,
          exporting: state.exporting,
          error: state.status == Status.failure ? state.error : null,
          hasGenerated: data != null,
          isEmpty: data != null && isEmpty(data),
          summary: data != null && summary != null ? summary!(data) : null,
          onGenerate: () => cubit.generate(buildQuery()),
          onExport: state.query == null ? null : cubit.exportCsv,
          child: data == null ? const SizedBox.shrink() : result(data),
        );
      },
    );
  }
}

/// Builds a [ReportQuery], omitting empty values.
ReportQuery reportQuery(Map<String, String?> raw) => ReportQuery({
  for (final e in raw.entries)
    if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
});
