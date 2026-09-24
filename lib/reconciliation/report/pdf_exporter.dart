import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/ledger_entry.dart';
import '../models/match_result.dart';
import '../models/reconciliation_report.dart';
import '../parsing/normalizers.dart';

/// Raporu PDF'e yazar. Türkçe karakterler için TTF font baytları verilmelidir
/// (varsayılan PDF fontları ş, ğ, İ gibi harfleri içermez).
class PdfReportExporter {
  final Uint8List regularFont;
  final Uint8List boldFont;

  const PdfReportExporter({required this.regularFont, required this.boldFont});

  Future<Uint8List> export(
    ReconciliationReport report, {
    String nameA = 'A',
    String nameB = 'B',
    String title = 'Mutabakat Raporu',
  }) async {
    final regular = pw.Font.ttf(ByteData.sublistView(regularFont));
    final bold = pw.Font.ttf(ByteData.sublistView(boldFont));
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    final doc = pw.Document(theme: theme, title: title);

    final headers = ['Taraf', 'Tarih', 'Belge No', 'Açıklama', 'Borç', 'Alacak'];

    List<String> row(String side, LedgerEntry e) => [
          side,
          e.date == null ? '' : _date(e.date!),
          e.documentNo ?? '',
          e.description,
          e.debit == 0 ? '' : TrAmountParser.format(e.debit),
          e.credit == 0 ? '' : TrAmountParser.format(e.credit),
        ];

    pw.Widget table(List<List<String>> rows) => pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
          },
          columnWidths: {
            0: const pw.FixedColumnWidth(40),
            1: const pw.FixedColumnWidth(55),
            2: const pw.FixedColumnWidth(70),
            3: const pw.FlexColumnWidth(),
            4: const pw.FixedColumnWidth(65),
            5: const pw.FixedColumnWidth(65),
          },
        );

    pw.Widget heading(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        );

    final content = <pw.Widget>[
      pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text('$nameA  ↔  $nameB'),
      pw.SizedBox(height: 8),
      pw.Table(
        columnWidths: {0: const pw.FixedColumnWidth(160)},
        children: [
          _kv('Durum', report.isFullyReconciled ? 'MUTABIK' : 'MUTABIK DEĞİL'),
          _kv('Eşleşen kayıt', '${report.matchedCount}'),
          _kv('Yalnızca $nameA', '${report.unmatchedA.length}  '
              '(${TrAmountParser.format(report.unmatchedTotalA)})'),
          _kv('Yalnızca $nameB', '${report.unmatchedB.length}  '
              '(${TrAmountParser.format(report.unmatchedTotalB)})'),
          _kv('Bakiye farkı', TrAmountParser.format(report.balanceDifference)),
          _kv('OCR kontrolü gereken', '${report.needsReview.length}'),
        ],
      ),
    ];

    if (report.unmatchedA.isNotEmpty) {
      content.add(heading('Yalnızca $nameA tarafında olan kayıtlar'));
      content.add(table([for (final e in report.unmatchedA) row(nameA, e)]));
    }
    if (report.unmatchedB.isNotEmpty) {
      content.add(heading('Yalnızca $nameB tarafında olan kayıtlar'));
      content.add(table([for (final e in report.unmatchedB) row(nameB, e)]));
    }
    if (report.matches.isNotEmpty) {
      content.add(heading('Eşleşen kayıtlar'));
      var i = 0;
      for (final m in report.matches) {
        i++;
        final label = '#$i  ${_kind(m.kind)}  %${(m.confidence * 100).toStringAsFixed(0)}'
            '${m.note == null ? '' : '  (${m.note})'}';
        content.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ));
        content.add(table([
          for (final e in m.entriesA) row(nameA, e),
          for (final e in m.entriesB) row(nameB, e),
        ]));
      }
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (_) => content,
    ));
    return doc.save();
  }

  pw.TableRow _kv(String k, String v) => pw.TableRow(children: [
        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(k, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(v)),
      ]);

  static String _kind(MatchKind k) => switch (k) {
        MatchKind.exactDocumentNo => 'Belge No',
        MatchKind.amountAndDate => 'Tutar+Tarih',
        MatchKind.sum => 'Toplam',
        MatchKind.manual => 'Elle',
      };

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
