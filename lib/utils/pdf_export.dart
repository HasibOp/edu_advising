import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'formatters.dart';

/// Builds the PDFs behind every "Download PDF" button.
///
/// Text is plain ASCII because the built-in PDF font (Helvetica) cannot
/// draw most Unicode symbols.
class PdfExport {
  PdfExport._();

  static const PdfColor _maroon = PdfColor.fromInt(0xFF861A4C);
  static const PdfColor _gold = PdfColor.fromInt(0xFFC9A24B);
  static const PdfColor _tint = PdfColor.fromInt(0xFFF6E7EE);
  static const PdfColor _grey = PdfColor.fromInt(0xFF6E6168);

  static pw.MemoryImage? _seal;

  static Future<pw.MemoryImage?> _loadSeal() async {
    if (_seal != null) return _seal;
    try {
      final bytes = await rootBundle.load('assets/images/edu_seal.png');
      _seal = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      _seal = null;
    }
    return _seal;
  }

  /// One table, with the university header. Opens the share/save sheet.
  static Future<void> shareTable({
    required String title,
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
    List<String> subtitle = const [],
    List<String> notes = const [],
    bool landscape = false,
    Map<int, double>? columnFlex,
  }) async {
    final seal = await _loadSeal();
    final doc = pw.Document(title: title, author: 'EDU Advising');
    doc.addPage(
      pw.MultiPage(
        pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => _header(seal, title, subtitle),
        footer: _footer,
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: const pw.TextStyle(
                color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9.5),
            headerDecoration: const pw.BoxDecoration(color: _maroon),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            oddRowDecoration: const pw.BoxDecoration(color: _tint),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            columnWidths: columnFlex?.map((k, v) => MapEntry(k, pw.FlexColumnWidth(v))),
          ),
          for (final note in notes)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(note, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: filename);
  }

  static pw.Widget _header(pw.MemoryImage? seal, String title, List<String> subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              if (seal != null) pw.Image(seal, width: 40, height: 40),
              if (seal != null) pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('East Delta University',
                        style: const pw.TextStyle(
                            fontSize: 15, fontWeight: pw.FontWeight.bold, color: _maroon)),
                    pw.Text('EDU Advising - $title',
                        style: const pw.TextStyle(fontSize: 11, color: _grey)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Container(height: 2, color: _gold),
          if (subtitle.isNotEmpty) pw.SizedBox(height: 6),
          for (final line in subtitle) pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Generated ${Formatters.dateTime(DateTime.now())}   Page ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: _grey),
      ),
    );
  }
}
