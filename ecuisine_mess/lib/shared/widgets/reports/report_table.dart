import 'package:flutter/material.dart';

/// Scrollable table for report results. A cell is a [String] (rendered as
/// text) or any [Widget].
class ReportTable extends StatelessWidget {
  const ReportTable({
    super.key,
    required this.columns,
    required this.rows,
    this.numericColumns = const {},
  });

  final List<String> columns;
  final List<List<Object>> rows;

  /// Indexes of right-aligned numeric columns.
  final Set<int> numericColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 38,
                dataRowMaxHeight: 44,
                columns: [
                  for (var i = 0; i < columns.length; i++)
                    DataColumn(
                      label: Text(
                        columns[i],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: numericColumns.contains(i),
                    ),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      cells: [
                        for (final cell in row)
                          DataCell(cell is Widget ? cell : Text('$cell')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
