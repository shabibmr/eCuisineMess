import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/menu_history_record.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/copy_from_date.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/menu_history_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuHistoryCopyDialog extends StatefulWidget {
  const MenuHistoryCopyDialog({
    super.key,
    required this.sourceRecord,
  });

  final MenuHistoryRecord sourceRecord;

  static Future<void> show(BuildContext context, {required MenuHistoryRecord sourceRecord}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => MenuHistoryCopyDialog(sourceRecord: sourceRecord),
    );
  }

  @override
  State<MenuHistoryCopyDialog> createState() => _MenuHistoryCopyDialogState();
}

class _MenuHistoryCopyDialogState extends State<MenuHistoryCopyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateCtrl;
  bool _overwrite = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _dateCtrl = TextEditingController(text: MenuHistoryBloc.formatDate(tomorrow));
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      _dateCtrl.text = MenuHistoryBloc.formatDate(picked);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final toDate = _dateCtrl.text.trim();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final copyFromDate = sl<CopyFromDate>();
      final result = await copyFromDate(
        CopyFromDateParams(
          fromDate: widget.sourceRecord.date,
          toDate: toDate,
          overwrite: _overwrite,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied ${result.copiedSlotsCount} slots from ${widget.sourceRecord.date} to $toDate. Opening editor...',
          ),
        ),
      );

      context.goNamed(
        AppRoutes.menu.name,
        queryParameters: {
          'date': toDate,
          'cuisine_id': widget.sourceRecord.cuisineId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.copy, size: 20),
          SizedBox(width: 8),
          Text('Copy Menu to Date'),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy ${widget.sourceRecord.cuisineName} menu from ${widget.sourceRecord.date}:',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateCtrl,
                decoration: InputDecoration(
                  labelText: 'Target date (YYYY-MM-DD)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    onPressed: _submitting ? null : _pickDate,
                  ),
                ),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(val)) {
                    return 'Please enter date in YYYY-MM-DD format';
                  }
                  if (val == widget.sourceRecord.date) {
                    return 'Target date must be different from source date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Overwrite existing unlocked slots'),
                value: _overwrite,
                onChanged: _submitting ? null : (v) => setState(() => _overwrite = v ?? false),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Copy & Open Editor'),
        ),
      ],
    );
  }
}
