import '../models/ledger_entry.dart';
import '../models/match_result.dart';
import '../models/reconciliation_report.dart';
import '../parsing/normalizers.dart';

/// Raporu Excel'in doğrudan açabileceği noktalı virgüllü CSV'ye yazar.
/// Türkçe Excel varsayılan ayracı `;` olduğu için bu seçildi; UTF-8 BOM
/// eklenir ki Türkçe karakterler doğru görünsün.
class CsvReportExporter {
  const CsvReportExporter();

  String export(ReconciliationReport report, {String nameA = 'A', String nameB = 'B'}) {
    final buf = StringBuffer('﻿');
    buf.writeln(_row([
      'Durum', 'Kural', 'Güven', 'Not', 'Taraf', 'Tarih', 'Belge No',
      'Açıklama', 'Borç', 'Alacak', 'Sayfa',
    ]));

    var i = 0;
    for (final m in report.matches) {
      i++;
      for (final e in m.entriesA) {
        buf.writeln(_entryRow('Eşleşti #$i', _kind(m.kind), m.confidence, m.note, nameA, e));
      }
      for (final e in m.entriesB) {
        buf.writeln(_entryRow('Eşleşti #$i', _kind(m.kind), m.confidence, m.note, nameB, e));
      }
    }
    for (final e in report.unmatchedA) {
      buf.writeln(_entryRow('Yalnızca $nameA', '', null, null, nameA, e));
    }
    for (final e in report.unmatchedB) {
      buf.writeln(_entryRow('Yalnızca $nameB', '', null, null, nameB, e));
    }
    buf.writeln();
    buf.writeln(_row(['Bakiye farkı', TrAmountParser.format(report.balanceDifference)]));
    buf.writeln(_row(['Eşleşmeyen $nameA toplamı', TrAmountParser.format(report.unmatchedTotalA)]));
    buf.writeln(_row(['Eşleşmeyen $nameB toplamı', TrAmountParser.format(report.unmatchedTotalB)]));
    return buf.toString();
  }

  String _entryRow(String status, String rule, double? conf, String? note, String side, LedgerEntry e) {
    return _row([
      status,
      rule,
      conf == null ? '' : '%${(conf * 100).toStringAsFixed(0)}',
      note ?? '',
      side,
      e.date == null ? '' : _date(e.date!),
      e.documentNo ?? '',
      e.description,
      e.debit == 0 ? '' : TrAmountParser.format(e.debit),
      e.credit == 0 ? '' : TrAmountParser.format(e.credit),
      e.source.page?.toString() ?? '',
    ]);
  }

  static String _kind(MatchKind k) => switch (k) {
        MatchKind.exactDocumentNo => 'Belge No',
        MatchKind.amountAndDate => 'Tutar+Tarih',
        MatchKind.sum => 'Toplam',
        MatchKind.manual => 'Elle',
      };

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _row(List<String> cells) =>
      cells.map((c) => '"${c.replaceAll('"', '""')}"').join(';');
}
