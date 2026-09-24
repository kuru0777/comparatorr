import 'package:comparatorr/reconciliation/matching/reconciliation_engine.dart';
import 'package:comparatorr/reconciliation/models/ledger_entry.dart';
import 'package:comparatorr/reconciliation/models/match_result.dart';
import 'package:comparatorr/reconciliation/report/report_formatter.dart';
import 'package:test/test.dart';

LedgerEntry a(int i, String date, {String? doc, int debit = 0, int credit = 0, String desc = ''}) =>
    LedgerEntry(
      side: LedgerSide.a,
      index: i,
      date: DateTime.parse(date),
      documentNo: doc,
      description: desc,
      debit: debit,
      credit: credit,
    );

LedgerEntry b(int i, String date, {String? doc, int debit = 0, int credit = 0, String desc = ''}) =>
    LedgerEntry(
      side: LedgerSide.b,
      index: i,
      date: DateTime.parse(date),
      documentNo: doc,
      description: desc,
      debit: debit,
      credit: credit,
    );

void main() {
  final engine = ReconciliationEngine.standard();

  test('belge no ile kesin eşleşme', () {
    final report = engine.reconcile(
      [a(0, '2024-03-01', doc: 'FT-001', debit: 125000)],
      [b(0, '2024-03-20', doc: 'ft001', credit: 125000)],
    );
    expect(report.matches.single.kind, MatchKind.exactDocumentNo);
    expect(report.matches.single.confidence, 1.0);
    expect(report.isFullyReconciled, isTrue);
  });

  test('aynı yönde kayıtlar eşleşmez', () {
    final report = engine.reconcile(
      [a(0, '2024-03-01', doc: 'FT-001', debit: 125000)],
      [b(0, '2024-03-01', doc: 'FT-001', debit: 125000)],
    );
    expect(report.matches, isEmpty);
    expect(report.unmatchedA.length, 1);
    expect(report.unmatchedB.length, 1);
  });

  test('tutar ve tarih toleransı ile eşleşme, en yakın tarih seçilir', () {
    final report = engine.reconcile(
      [a(0, '2024-03-05', debit: 50000)],
      [
        b(0, '2024-03-09', credit: 50000),
        b(1, '2024-03-06', credit: 50000),
      ],
    );
    final m = report.matches.single;
    expect(m.kind, MatchKind.amountAndDate);
    expect(m.entriesB.single.index, 1);
    expect(m.note, 'Tarih farkı 1 gün');
    expect(report.unmatchedB.single.index, 0);
  });

  test('tarih toleransı dışındaki kayıt eşleşmez', () {
    final report = engine.reconcile(
      [a(0, '2024-03-01', debit: 50000)],
      [b(0, '2024-03-30', credit: 50000)],
    );
    expect(report.matches, isEmpty);
  });

  test('tek fatura, iki parça ödeme toplamı', () {
    final report = engine.reconcile(
      [a(0, '2024-03-01', doc: 'FT-9', debit: 300000)],
      [
        b(0, '2024-03-10', credit: 100000, desc: 'taksit 1'),
        b(1, '2024-03-25', credit: 200000, desc: 'taksit 2'),
        b(2, '2024-03-25', credit: 999, desc: 'ilgisiz'),
      ],
    );
    final m = report.matches.single;
    expect(m.kind, MatchKind.sum);
    expect(m.entriesB.map((e) => e.index).toSet(), {0, 1});
    expect(m.difference, 0);
    expect(report.unmatchedB.single.index, 2);
    expect(report.balanceDifference, -999);
  });

  test('kesin kural belirsiz kuraldan önce çalışır', () {
    // Aynı tutarlı iki fatura; belge no ile doğru eşleşme, tarih ile yanlış
    // eşleşme yapılabilirdi.
    final report = engine.reconcile(
      [
        a(0, '2024-03-01', doc: 'FT-1', debit: 10000),
        a(1, '2024-03-02', doc: 'FT-2', debit: 10000),
      ],
      [
        b(0, '2024-03-01', doc: 'FT-2', credit: 10000),
        b(1, '2024-03-02', doc: 'FT-1', credit: 10000),
      ],
    );
    expect(report.matches.length, 2);
    for (final m in report.matches) {
      expect(m.kind, MatchKind.exactDocumentNo);
      expect(m.entriesA.single.normalizedDocumentNo,
          m.entriesB.single.normalizedDocumentNo);
    }
  });

  test('rapor metni üretilir', () {
    final report = engine.reconcile(
      [a(0, '2024-03-01', doc: 'FT-1', debit: 10000, desc: 'Fatura')],
      [b(0, '2024-03-01', credit: 4200, desc: 'Kısmi')],
    );
    final text = const PlainTextReportFormatter().format(report, nameA: 'Biz', nameB: 'Karşı');
    expect(text, contains('MUTABIK DEĞİL'));
    expect(text, contains('Yalnızca Biz tarafında'));
    expect(text, contains('Yalnızca Karşı tarafında'));
    expect(text, contains('Bakiye farkı         : 58,00'));
  });
}
