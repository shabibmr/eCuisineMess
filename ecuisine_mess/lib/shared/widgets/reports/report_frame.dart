import 'package:flutter/material.dart';

/// Shared layout for a report tab: filter bar, Generate / Export CSV actions,
/// then loading / error / empty / result. Holds no report logic.
class ReportFrame extends StatelessWidget {
  const ReportFrame({
    super.key,
    required this.filters,
    required this.onGenerate,
    required this.onExport,
    required this.child,
    this.loading = false,
    this.exporting = false,
    this.error,
    this.hasGenerated = false,
    this.isEmpty = false,
    this.emptyMessage = 'No records for the selected filters',
    this.summary,
  });

  final Widget filters;
  final VoidCallback onGenerate;

  /// Null disables the button (nothing generated yet).
  final VoidCallback? onExport;
  final bool loading;
  final bool exporting;
  final String? error;
  final bool hasGenerated;
  final bool isEmpty;
  final String emptyMessage;
  final Widget? summary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: filters),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: loading ? null : onGenerate,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Generate'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: loading || exporting ? null : onExport,
                  icon: exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download, size: 18),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
          ),
        ),
        if (summary != null && hasGenerated && error == null && !loading) ...[
          const SizedBox(height: 12),
          summary!,
        ],
        const SizedBox(height: 12),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (!hasGenerated) {
      return const Center(
        child: Text(
          'Choose filters and press Generate',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    if (isEmpty) return Center(child: Text(emptyMessage));
    return Card(child: child);
  }
}

/// A labelled figure for report summaries.
class ReportStat extends StatelessWidget {
  const ReportStat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
