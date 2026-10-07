import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/report_tab.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_filter_fields.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_frame.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_table.dart';
import 'package:flutter/material.dart';

class MembersRegisterTab extends StatefulWidget {
  const MembersRegisterTab({super.key, required this.cuisines});

  final Map<String, String> cuisines;

  @override
  State<MembersRegisterTab> createState() => _MembersRegisterTabState();
}

class _MembersRegisterTabState extends State<MembersRegisterTab> {
  static const _statuses = {
    'ACTIVE': 'Active',
    'EXPIRED': 'Expired',
    'SUSPENDED': 'Suspended',
  };
  static const _expiring = {7: 'Next 7 days', 15: 'Next 15 days', 30: 'Next 30 days'};

  String? _status;
  String? _cuisineId;
  int? _expiringInDays;
  DateTime? _regFrom;
  DateTime? _regTo;

  ReportQuery _query() => reportQuery({
    'status': _status,
    'cuisine_id': _cuisineId,
    'expiring_in_days': _expiringInDays?.toString(),
    'registered_from': _regFrom == null ? null : formatReportDate(_regFrom!),
    'registered_to': _regTo == null ? null : formatReportDate(_regTo!),
  });

  static Color _statusColor(String s) => switch (s) {
    'ACTIVE' => Colors.green.shade700,
    'EXPIRED' => Colors.red.shade700,
    _ => Colors.orange.shade800,
  };

  @override
  Widget build(BuildContext context) {
    return ReportTab<MembersRegister>(
      buildQuery: _query,
      filters: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ReportDropdown<String>(
            label: 'Status',
            value: _status,
            items: _statuses,
            onChanged: (v) => setState(() => _status = v),
            width: 150,
          ),
          ReportDropdown<String>(
            label: 'Cuisine',
            value: _cuisineId,
            items: widget.cuisines,
            onChanged: (v) => setState(() => _cuisineId = v),
          ),
          ReportDropdown<int>(
            label: 'Expiring',
            value: _expiringInDays,
            items: _expiring,
            anyLabel: 'Any time',
            onChanged: (v) => setState(() => _expiringInDays = v),
          ),
          ReportDateField(
            label: 'Registered from',
            value: _regFrom,
            onChanged: (d) => setState(() => _regFrom = d),
            onCleared: () => setState(() => _regFrom = null),
          ),
          ReportDateField(
            label: 'Registered to',
            value: _regTo,
            onChanged: (d) => setState(() => _regTo = d),
            onCleared: () => setState(() => _regTo = null),
          ),
        ],
      ),
      summary: (r) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ReportStat(label: 'Members', value: '${r.total}'),
          ReportStat(label: 'Active', value: '${r.active}'),
          ReportStat(label: 'Expired', value: '${r.expired}'),
          ReportStat(label: 'Suspended', value: '${r.suspended}'),
          for (final e in r.byCuisine.entries)
            ReportStat(label: e.key, value: '${e.value}'),
        ],
      ),
      isEmpty: (r) => r.members.isEmpty,
      result: (r) => ReportTable(
        columns: const [
          'Name',
          'RFID',
          'Cuisine',
          'Phone',
          'Valid from',
          'Valid until',
          'Days left',
          'Status',
        ],
        numericColumns: const {6},
        rows: [
          for (final m in r.members)
            [
              m.name,
              m.rfidTag,
              m.cuisineName,
              m.phone ?? '',
              m.validityStart ?? '',
              m.validityEnd ?? '',
              m.daysLeft?.toString() ?? '',
              Text(
                m.status,
                style: TextStyle(
                  color: _statusColor(m.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
        ],
      ),
    );
  }
}
