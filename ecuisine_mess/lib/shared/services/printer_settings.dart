import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PrintMode {
  /// Raw ESC/POS bytes straight to a thermal printer (fast, auto-cut).
  escPos,

  /// Slip rendered as a PDF and printed through the Windows driver.
  pdf,
}

class PrinterSettings {
  PrinterSettings(this._prefs);

  final SharedPreferences _prefs;

  static const supportedWidthsMm = [58, 80];

  /// Empty means "use the system default printer".
  String get printerName =>
      _prefs.getString(AppConstants.printerNamePrefsKey) ?? '';

  int get widthMm {
    final w = _prefs.getInt(AppConstants.printerWidthPrefsKey) ?? 80;
    return supportedWidthsMm.contains(w) ? w : 80;
  }

  PrintMode get mode =>
      _prefs.getString(AppConstants.printerModePrefsKey) == PrintMode.pdf.name
          ? PrintMode.pdf
          : PrintMode.escPos;

  Future<void> setPrinterName(String name) =>
      _prefs.setString(AppConstants.printerNamePrefsKey, name.trim());

  Future<void> setWidthMm(int mm) {
    if (!supportedWidthsMm.contains(mm)) {
      throw ArgumentError('Width must be 58 or 80 mm');
    }
    return _prefs.setInt(AppConstants.printerWidthPrefsKey, mm);
  }

  Future<void> setMode(PrintMode mode) =>
      _prefs.setString(AppConstants.printerModePrefsKey, mode.name);
}
