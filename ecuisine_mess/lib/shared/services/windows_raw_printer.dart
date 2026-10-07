import 'dart:ffi';
import 'dart:typed_data';

import 'package:ecuisine_mess/shared/services/printer_service.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Sends raw bytes to a Windows printer queue, bypassing the driver's
/// rendering (datatype RAW). Required for ESC/POS.
void writeRawToPrinter(String printerName, Uint8List bytes, String docName) {
  final hPrinter = calloc<IntPtr>();
  final namePtr = printerName.toNativeUtf16();
  final docPtr = calloc<DOC_INFO_1>();
  final dataPtr = calloc<Uint8>(bytes.length);
  final written = calloc<Uint32>();
  var opened = false;
  var docStarted = false;
  var pageStarted = false;

  try {
    if (OpenPrinter(namePtr, hPrinter, nullptr) == 0) {
      throw PrinterException('Cannot open printer "$printerName"');
    }
    opened = true;
    final h = hPrinter.value;

    docPtr.ref
      ..pDocName = docName.toNativeUtf16()
      ..pOutputFile = nullptr
      ..pDatatype = 'RAW'.toNativeUtf16();
    if (StartDocPrinter(h, 1, docPtr) == 0) {
      throw const PrinterException('Printer rejected the print job');
    }
    docStarted = true;
    if (StartPagePrinter(h) == 0) {
      throw const PrinterException('Printer rejected the page');
    }
    pageStarted = true;

    dataPtr.asTypedList(bytes.length).setAll(0, bytes);
    final ok = WritePrinter(h, dataPtr, bytes.length, written);
    if (ok == 0 || written.value != bytes.length) {
      throw const PrinterException('Failed to send data to printer');
    }
  } finally {
    if (opened) {
      final h = hPrinter.value;
      if (pageStarted) EndPagePrinter(h);
      if (docStarted) EndDocPrinter(h);
      ClosePrinter(h);
    }
    free(docPtr.ref.pDocName);
    free(docPtr.ref.pDatatype);
    free(namePtr);
    free(docPtr);
    free(dataPtr);
    free(written);
    free(hPrinter);
  }
}
