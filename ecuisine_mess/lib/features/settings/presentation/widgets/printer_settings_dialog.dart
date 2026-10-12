import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/shared/models/token_slip_data.dart';
import 'package:ecuisine_mess/shared/services/printer_service.dart';
import 'package:ecuisine_mess/shared/services/printer_settings.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

Future<void> showPrinterSettingsDialog(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (_) => const _PrinterSettingsDialog(),
    );

class _PrinterSettingsDialog extends StatefulWidget {
  const _PrinterSettingsDialog();

  @override
  State<_PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<_PrinterSettingsDialog> {
  static const _defaultOption = '';

  final _settings = sl<PrinterSettings>();
  final _service = sl<PrinterService>();
  late String _printer = _settings.printerName;
  late int _width = _settings.widthMm;
  late PrintMode _mode = _settings.mode;
  List<String> _names = const [];
  bool _loading = true;
  bool _testing = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    try {
      final printers = await Printing.listPrinters();
      if (!mounted) return;
      setState(() {
        _names = printers.map((p) => p.name).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isError = true;
        _message = 'Could not list printers: $e';
      });
    }
  }

  Future<void> _persist() async {
    await _settings.setPrinterName(_printer);
    await _settings.setWidthMm(_width);
    await _settings.setMode(_mode);
  }

  Future<void> _testPrint() async {
    setState(() {
      _testing = true;
      _message = null;
    });
    try {
      await _persist();
      await _service.printSlip(
        const TokenSlipData(
          tokenNumber: 'T-TEST',
          memberName: 'Test Print',
          cuisine: 'Test',
          mealType: 'Test',
          date: '-',
          time: '-',
          items: [TokenSlipLine(name: 'Sample item')],
        ),
      );
      _isError = false;
      _message = 'Test slip sent to printer';
    } catch (e) {
      _isError = true;
      _message = e.toString();
    }
    if (mounted) setState(() => _testing = false);
  }

  Future<void> _save() async {
    await _persist();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Keep a previously saved name selectable even if it is not installed now.
    final options = {..._names, if (_printer.isNotEmpty) _printer}.toList();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.print_outlined),
          SizedBox(width: 8),
          Text('Printer Settings'),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                initialValue: _printer,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Printer',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _defaultOption,
                    child: Text('System default'),
                  ),
                  for (final n in options)
                    DropdownMenuItem(value: n, child: Text(n)),
                ],
                onChanged: (v) => setState(() => _printer = v ?? ''),
              ),
            const SizedBox(height: 16),
            const Text('Paper width'),
            const SizedBox(height: 6),
            SegmentedButton<int>(
              segments: [
                for (final w in PrinterSettings.supportedWidthsMm)
                  ButtonSegment(value: w, label: Text('$w mm')),
              ],
              selected: {_width},
              onSelectionChanged: (s) => setState(() => _width = s.first),
            ),
            const SizedBox(height: 16),
            const Text('Print method'),
            const SizedBox(height: 6),
            SegmentedButton<PrintMode>(
              segments: const [
                ButtonSegment(
                  value: PrintMode.escPos,
                  label: Text('Thermal (ESC/POS)'),
                ),
                ButtonSegment(
                  value: PrintMode.pdf,
                  label: Text('Windows driver'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            if (_testing) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(
                  fontSize: 12,
                  color: _isError ? Colors.red : Colors.green.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _testing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: _testing || _loading ? null : _testPrint,
          child: const Text('Test Print'),
        ),
        AppSaveButton(
          onPressed: _testing ? null : _save,
        ),
      ],
    );
  }
}
