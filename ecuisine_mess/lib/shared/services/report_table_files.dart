import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Turns the server's pipe-delimited report CSV into Excel and PDF bytes.
class ReportTableFiles {
  const ReportTableFiles._();

  static List<int> xlsx(List<int> csvBytes, {required String sheetName}) {
    final rows = parsePipeCsv(csvBytes);
    final sheet = _sheetXml(rows);
    final safeName = _sheetName(sheetName);
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          '[Content_Types].xml',
          '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>
''',
        ),
      )
      ..addFile(
        ArchiveFile.string(
          '_rels/.rels',
          '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>
''',
        ),
      )
      ..addFile(
        ArchiveFile.string(
          'xl/workbook.xml',
          '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="${_xml(safeName)}" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>
''',
        ),
      )
      ..addFile(
        ArchiveFile.string(
          'xl/_rels/workbook.xml.rels',
          '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
''',
        ),
      )
      ..addFile(ArchiveFile.string('xl/styles.xml', _stylesXml))
      ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', sheet));
    return ZipEncoder().encodeBytes(archive);
  }

  static Future<List<int>> pdf(
    List<int> csvBytes, {
    required String title,
  }) async {
    final rows = _rectangular(parsePipeCsv(csvBytes));
    final headers = rows.first;
    final body = rows.length > 1 ? rows.sublist(1) : const <List<String>>[];
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: body,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
            headerStyle: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF016795),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// Pipe-delimited CSV, including a leading UTF-8 BOM and quoted cells.
  static List<List<String>> parsePipeCsv(List<int> bytes) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    if (text.isEmpty) return const [];

    final rows = <List<String>>[];
    final row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(ch);
        }
        continue;
      }
      if (ch == '"') {
        quoted = true;
      } else if (ch == '|') {
        row.add(cell.toString());
        cell.clear();
      } else if (ch == '\n') {
        row.add(cell.toString());
        cell.clear();
        rows.add(List<String>.of(row));
        row.clear();
      } else if (ch != '\r') {
        cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(List<String>.of(row));
    }
    return rows;
  }

  static List<List<String>> _rectangular(List<List<String>> rows) {
    if (rows.isEmpty) {
      return const [
        [''],
      ];
    }
    var width = 0;
    for (final row in rows) {
      if (row.length > width) width = row.length;
    }
    return [
      for (final row in rows)
        [for (var i = 0; i < width; i++) i < row.length ? row[i] : ''],
    ];
  }

  static String _sheetXml(List<List<String>> rows) {
    final table = _rectangular(rows);
    final buffer = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetData>',
    );
    for (var r = 0; r < table.length; r++) {
      final rowNumber = r + 1;
      buffer.write('<row r="$rowNumber">');
      final style = r == 0 ? ' s="1"' : '';
      for (var c = 0; c < table[r].length; c++) {
        final ref = '${_column(c)}$rowNumber';
        buffer
          ..write('<c r="$ref" t="inlineStr"$style><is><t xml:space="preserve">')
          ..write(_xml(_excelText(table[r][c])))
          ..write('</t></is></c>');
      }
      buffer.write('</row>');
    }
    buffer.write('</sheetData></worksheet>');
    return buffer.toString();
  }

  static String _column(int index) {
    var n = index + 1;
    final letters = <String>[];
    while (n > 0) {
      n--;
      letters.add(String.fromCharCode(65 + (n % 26)));
      n ~/= 26;
    }
    return letters.reversed.join();
  }

  static String _sheetName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[:\\/?*\[\]]'), ' ').trim();
    if (cleaned.isEmpty) return 'Report';
    return cleaned.length <= 31 ? cleaned : cleaned.substring(0, 31);
  }

  static String _excelText(String value) => value.replaceAll(
    RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'),
    '',
  );

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static const _stylesXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2">
    <font><sz val="11"/><name val="Calibri"/></font>
    <font><b/><sz val="11"/><name val="Calibri"/></font>
  </fonts>
  <fills count="2">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
  </fills>
  <borders count="1">
    <border><left/><right/><top/><bottom/><diagonal/></border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="2">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
  </cellXfs>
</styleSheet>
''';
}
