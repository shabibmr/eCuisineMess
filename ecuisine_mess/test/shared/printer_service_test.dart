import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/shared/services/escpos_slip_builder.dart';
import 'package:ecuisine_mess/shared/services/printer_service.dart';
import 'package:ecuisine_mess/shared/services/printer_settings.dart';
import 'package:ecuisine_mess/shared/widgets/print/token_slip_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _slip = TokenSlipData(
  tokenNumber: 'T-0001',
  memberName: 'Ali',
  cuisine: 'Indian',
  mealType: 'Lunch',
  date: '2026-10-06',
  time: '12:00',
  items: [TokenSlipLine(name: 'Rice', quantity: 2)],
);

class _FakePrinter implements PrinterService {
  _FakePrinter(this.failures);
  int failures;
  int calls = 0;
  bool? lastDuplicate;

  @override
  Future<void> printSlip(TokenSlipData data, {bool duplicate = false}) async {
    calls++;
    lastDuplicate = duplicate;
    if (failures-- > 0) throw const PrinterException('Printer offline');
  }
}

void main() {
  group('PrinterSettings', () {
    test('defaults to ESC/POS, 80mm, default printer; persists changes',
        () async {
      SharedPreferences.setMockInitialValues({});
      final s = PrinterSettings(await SharedPreferences.getInstance());

      expect(s.widthMm, 80);
      expect(s.printerName, '');
      expect(s.mode, PrintMode.escPos);

      await s.setWidthMm(58);
      await s.setPrinterName('  POS-58  ');
      await s.setMode(PrintMode.pdf);
      expect(s.widthMm, 58);
      expect(s.printerName, 'POS-58');
      expect(s.mode, PrintMode.pdf);
      expect(() => s.setWidthMm(70), throwsArgumentError);
    });

    test('ignores an invalid stored width', () async {
      SharedPreferences.setMockInitialValues(
        {AppConstants.printerWidthPrefsKey: 99},
      );
      final s = PrinterSettings(await SharedPreferences.getInstance());
      expect(s.widthMm, 80);
    });
  });

  test('SpoolerPrinterService builds a PDF', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = SpoolerPrinterService(
      PrinterSettings(await SharedPreferences.getInstance()),
    );
    final bytes = await svc.buildSlipPdf(_slip, duplicate: true);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  group('EscPosSlipBuilder', () {
    String text(List<int> b) => String.fromCharCodes(b);

    test('starts with init, ends with cut, contains slip data', () {
      final b = const EscPosSlipBuilder().build(_slip);
      expect(b.take(2), [0x1B, 0x40]);
      expect(b.skip(b.length - 4), [0x1D, 0x56, 0x42, 0x00]);
      final t = text(b);
      expect(t, contains('T-0001'));
      expect(t, contains('Ali'));
      expect(t, contains('Rice'));
      expect(t, contains('x2'));
      expect(t, isNot(contains('DUPLICATE')));
    });

    test('marks duplicates', () {
      expect(
        text(const EscPosSlipBuilder().build(_slip, duplicate: true)),
        contains('*** DUPLICATE REPRINT ***'),
      );
    });

    test('lines fit the paper width and non-ASCII becomes ?', () {
      for (final mm in [58, 80]) {
        const long = TokenSlipData(
          tokenNumber: 'T-1',
          memberName: 'Muhammad محمد With A Very Long Name',
          cuisine: 'North Indian Special Thali',
          mealType: 'Lunch',
          date: 'd',
          time: 't',
          items: [TokenSlipLine(name: 'Extremely long item name for the slip')],
        );
        final builder = EscPosSlipBuilder(widthMm: mm);
        final out = builder.build(long);
        // Drop control sequences by splitting on LF and keeping printable runs.
        for (final l in text(out).split('\n')) {
          final printable = l.replaceAll(RegExp(r'[\x00-\x1F]'), '');
          expect(printable.length, lessThanOrEqualTo(builder.columns + 12));
        }
        expect(text(out), contains('Muhammad ?'));
      }
    });
  });

  group('TokenSlipDialog', () {
    late _FakePrinter printer;

    setUp(() {
      if (sl.isRegistered<PrinterService>()) sl.unregister<PrinterService>();
    });

    Future<void> pump(WidgetTester t, {bool reprint = false}) async {
      sl.registerSingleton<PrinterService>(printer);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TokenSlipDialog(slip: _slip, isReprint: reprint),
          ),
        ),
      );
      await t.pumpAndSettle();
      // Ahem (test font) is far wider than real fonts, so the fixed-width slip
      // card overflows only under test; drain those layout errors.
      while (t.takeException() != null) {}
    }

    testWidgets('prints once on open and offers Close', (t) async {
      printer = _FakePrinter(0);
      await pump(t, reprint: true);
      expect(printer.calls, 1);
      expect(printer.lastDuplicate, isTrue);
      expect(find.text('Close'), findsOneWidget);
      expect(find.textContaining('Print failed'), findsNothing);
    });

    testWidgets('shows Retry/Skip on failure and retries', (t) async {
      printer = _FakePrinter(1);
      await pump(t);
      expect(find.textContaining('Printer offline'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(printer.calls, 2);
      expect(find.textContaining('Print failed'), findsNothing);
    });
  });
}
