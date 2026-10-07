import 'dart:convert';
import 'dart:typed_data';

import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/shared/models/token_slip_data.dart';

/// Builds ESC/POS bytes for the token slip. Pure — no I/O, easy to test.
///
/// Text is limited to ASCII (non-ASCII becomes `?`) because thermal code
/// pages vary per printer model.
class EscPosSlipBuilder {
  const EscPosSlipBuilder({this.widthMm = 80});

  final int widthMm;

  /// Characters per line in the normal font (Font A).
  int get columns => widthMm == 58 ? 32 : 48;

  Uint8List build(TokenSlipData d, {bool duplicate = false}) {
    final b = BytesBuilder();
    void raw(List<int> bytes) => b.add(bytes);
    void line(String s) => b.add([...ascii.encode(_clean(s)), 0x0A]);

    raw([0x1B, 0x40]); // initialise
    raw([0x1B, 0x61, 0x01]); // centre
    raw([0x1B, 0x45, 0x01]); // bold on
    line(AppConstants.appName);
    raw([0x1B, 0x45, 0x00]);
    line('MEAL ENTITLEMENT TOKEN');
    if (duplicate) line('*** DUPLICATE REPRINT ***');
    line(_rule());
    raw([0x1D, 0x21, 0x11]); // double width + height
    raw([0x1B, 0x45, 0x01]);
    line(d.tokenNumber);
    raw([0x1B, 0x45, 0x00]);
    raw([0x1D, 0x21, 0x00]);
    raw([0x1B, 0x61, 0x00]); // left
    line('');
    line(_pair('Member', d.memberName));
    line(_pair('Meal', '${d.mealType} - ${d.cuisine}'));
    line(_pair('Date', '${d.date} ${d.time}'));
    line(_rule());
    for (final i in d.items) {
      line(_pair(i.name, 'x${i.quantity}'));
    }
    line(_rule());
    raw([0x1B, 0x64, 0x04]); // feed 4 lines
    raw([0x1D, 0x56, 0x42, 0x00]); // feed to cut position + partial cut
    return b.toBytes();
  }

  String _rule() => '-' * columns;

  /// Left text and right text on one line; the left is truncated to fit.
  String _pair(String l, String r) {
    final right = _clean(r);
    final maxLeft = columns - right.length - 1;
    var left = _clean(l);
    if (maxLeft < 1) return right.substring(0, columns);
    if (left.length > maxLeft) left = left.substring(0, maxLeft);
    return left + ' ' * (columns - left.length - right.length) + right;
  }

  String _clean(String s) => s.runes
      .map((c) => c >= 0x20 && c < 0x7F ? String.fromCharCode(c) : '?')
      .join();
}
