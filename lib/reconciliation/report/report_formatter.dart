import '../models/ledger_entry.dart';
import '../models/match_result.dart';
import '../models/reconciliation_report.dart';
import '../parsing/normalizers.dart';

/// Raporu düz metin olarak yazar. UI ve dışa aktarma (PDF/Excel) için
/// başlangıç noktasıdır; ileride tablo modeline dönüştürülebilir.
class PlainTextReportFormatter {
  const PlainTextReportFormatter();

  String format(ReconciliationReport report, {String nameA = 'A', String nameB = 'B'}) {
    final buf = StringBuffer();
    buf.writeln('=== MUTABAKAT RAPORU ===');
    buf.writeln('Eşleşen kayıt sayısı : ${report.matchedCount}');
    buf.writeln('Eşleşmeyen ($nameA)     : ${report.unmatchedA.length}');
    buf.writeln('Eşleşmeyen ($nameB)     : ${report.unmatchedB.length}');
    buf.writeln('Doğrulanmalı (OCR)   : ${report.needsReview.length}');
    buf.writeln('Bakiye farkı         : ${TrAmountParser.format(report.balanceDifference)}');
    buf.writeln('Durum                : ${report.isFullyReconciled ? 'MUTABIK' : 'MUTABIK DEĞİL'}');
    buf.writeln();

    if (report.matches.isNotEmpty) {
      buf.writeln('--- Eşleşenler ---');
      for (final m in report.matches) {
        buf.writeln(_formatMatch(m));
      }
      buf.writeln();
    }

    if (report.unmatchedA.isNotEmpty) {
      buf.writeln('--- Yalnızca $nameA tarafında ---');
      for (final e in report.unmatchedA) {
        buf.writeln('  ${_formatEntry(e)}');
      }
      buf.writeln('  Toplam: ${TrAmountParser.format(report.unmatchedTotalA)}');
      buf.writeln();
    }

    if (report.unmatchedB.isNotEmpty) {
      buf.writeln('--- Yalnızca $nameB tarafında ---');
      for (final e in report.unmatchedB) {
        buf.writeln('  ${_formatEntry(e)}');
      }
      buf.writeln('  Toplam: ${TrAmountParser.format(report.unmatchedTotalB)}');
      buf.writeln();
    }

    if (report.needsReview.isNotEmpty) {
      buf.writeln('--- OCR güveni düşük, kontrol edin ---');
      for (final e in report.needsReview) {
        final conf = ((e.source.ocrConfidence ?? 0) * 100).toStringAsFixed(0);
        buf.writeln('  [%$conf] ${_formatEntry(e)}');
      }
    }
    return buf.toString();
  }

  String _formatMatch(Match m) {
    final label = switch (m.kind) {
      MatchKind.exactDocumentNo => 'BELGE NO',
      MatchKind.amountAndDate => 'TUTAR+TARİH',
      MatchKind.sum => 'TOPLAM',
      MatchKind.manual => 'ELLE',
    };
    final conf = (m.confidence * 100).toStringAsFixed(0);
    final buf = StringBuffer('  [$label %$conf]');
    if (m.note != null) buf.write(' (${m.note})');
    buf.writeln();
    for (final e in m.entriesA) {
      buf.writeln('    A: ${_formatEntry(e)}');
    }
    for (final e in m.entriesB) {
      buf.writeln('    B: ${_formatEntry(e)}');
    }
    return buf.toString().trimRight();
  }

  String _formatEntry(LedgerEntry e) {
    final date = e.date == null
        ? '??.??.????'
        : '${e.date!.day.toString().padLeft(2, '0')}.'
            '${e.date!.month.toString().padLeft(2, '0')}.${e.date!.year}';
    final amount = e.debit > 0
        ? 'B ${TrAmountParser.format(e.debit)}'
        : 'A ${TrAmountParser.format(e.credit)}';
    final doc = e.documentNo ?? '-';
    final page = e.source.page == null ? '' : ' (s.${e.source.page})';
    return '$date  $doc  $amount  ${e.description}$page';
  }
}
