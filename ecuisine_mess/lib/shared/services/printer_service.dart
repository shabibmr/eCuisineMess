import 'dart:typed_data';

import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/shared/services/escpos_slip_builder.dart';
import 'package:ecuisine_mess/shared/services/printer_settings.dart';
import 'package:ecuisine_mess/shared/services/windows_raw_printer.dart';
import 'package:ecuisine_mess/shared/models/token_slip_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Prints the meal entitlement slip. A failure must never void the bill —
/// callers show Retry / Skip and the slip can be reprinted from the register.
abstract interface class PrinterService {
  Future<void> printSlip(TokenSlipData data, {bool duplicate = false});
}

class PrinterException implements Exception {
  const PrinterException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Picks the configured printer, or the system default when none is set.
Future<Printer> resolvePrinter(String wanted) async {
  final printers = await Printing.listPrinters();
  if (printers.isEmpty) {
    throw const PrinterException('No printers installed');
  }
  if (wanted.isNotEmpty) {
    for (final p in printers) {
      if (p.name == wanted) return p;
    }
    throw PrinterException('Printer "$wanted" not found');
  }
  for (final p in printers) {
    if (p.isDefault) return p;
  }
  return printers.first;
}

/// Delegates to the implementation chosen in [PrinterSettings] at print time,
/// so changing the mode in settings takes effect immediately.
class ConfiguredPrinterService implements PrinterService {
  ConfiguredPrinterService(this.settings)
      : _escPos = EscPosPrinterService(settings),
        _pdf = SpoolerPrinterService(settings);

  final PrinterSettings settings;
  final EscPosPrinterService _escPos;
  final SpoolerPrinterService _pdf;

  @override
  Future<void> printSlip(TokenSlipData data, {bool duplicate = false}) =>
      (settings.mode == PrintMode.escPos ? _escPos : _pdf)
          .printSlip(data, duplicate: duplicate);
}

/// Raw ESC/POS to a thermal printer through its Windows queue (USB).
class EscPosPrinterService implements PrinterService {
  EscPosPrinterService(this._settings);

  final PrinterSettings _settings;

  @override
  Future<void> printSlip(TokenSlipData data, {bool duplicate = false}) async {
    final printer = await resolvePrinter(_settings.printerName);
    final bytes = EscPosSlipBuilder(widthMm: _settings.widthMm)
        .build(data, duplicate: duplicate);
    writeRawToPrinter(printer.name, bytes, 'Token ${data.tokenNumber}');
  }
}

/// Windows driver path: renders the slip to a roll-sized PDF and sends it to
/// the configured (or default) printer.
class SpoolerPrinterService implements PrinterService {
  SpoolerPrinterService(this._settings);

  final PrinterSettings _settings;

  int get widthMm => _settings.widthMm;

  @override
  Future<void> printSlip(TokenSlipData data, {bool duplicate = false}) async {
    final printer = await resolvePrinter(_settings.printerName);
    final bytes = await buildSlipPdf(data, duplicate: duplicate);
    final ok = await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) async => bytes,
      name: 'Token ${data.tokenNumber}',
      format: _format,
      usePrinterSettings: true,
    );
    if (!ok) {
      throw PrinterException('Printer "${printer.name}" rejected the job');
    }
  }

  PdfPageFormat get _format => PdfPageFormat(
        widthMm * PdfPageFormat.mm,
        double.infinity,
        marginAll: 3 * PdfPageFormat.mm,
      );

  Future<Uint8List> buildSlipPdf(
    TokenSlipData data, {
    bool duplicate = false,
  }) async {
    final doc = pw.Document();
    const small = pw.TextStyle(fontSize: 8);
    const bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

    pw.Widget row(String l, String r) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [pw.Text(l, style: small), pw.Text(r, style: bold)],
        );

    doc.addPage(
      pw.Page(
        pageFormat: _format,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                AppConstants.appName,
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(child: pw.Text('MEAL ENTITLEMENT TOKEN', style: small)),
            if (duplicate)
              pw.Center(
                child: pw.Text('*** DUPLICATE REPRINT ***', style: bold),
              ),
            pw.Divider(),
            pw.Center(
              child: pw.Text(
                data.tokenNumber,
                style: const pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            row('Member', data.memberName),
            row('Meal', '${data.mealType} - ${data.cuisine}'),
            row('Date', '${data.date} ${data.time}'),
            pw.Divider(),
            for (final i in data.items) row(i.name, 'x${i.quantity}'),
            pw.SizedBox(height: 8),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
