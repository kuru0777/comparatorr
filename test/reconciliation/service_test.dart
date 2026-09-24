import 'dart:io';

import 'package:comparatorr/reconciliation/models/match_result.dart';
import 'package:comparatorr/reconciliation/reconciliation_service.dart';
import 'package:comparatorr/reconciliation/report/csv_exporter.dart';
import 'package:comparatorr/reconciliation/report/report_formatter.dart';
import 'package:test/test.dart';

void main() {
  final a = File('samples/ekstre_a_bizim.txt').absolute.path;
  final b = File('samples/ekstre_b_karsi_taraf.csv').absolute.path;

  test('örnek ekstreler uçtan uca eşleşir', () async {
    final result = await const ReconciliationService().run(a, b);

    expect(result.sideA.entries.length, 9);
    expect(result.sideA.parserName, 'generic-tr');
    expect(result.sideB.entries.length, 7);
    expect(result.sideB.parserName, 'delimited');
    expect(result.warnings, isEmpty);

    final report = result.report;
    final kinds = report.matches.map((m) => m.kind).toList();

    // FT-2024-101 / FT2024101 ve FT-2024-102 / FT2024102: belge no ile.
    expect(kinds.where((k) => k == MatchKind.exactDocumentNo).length, 2);
    // Havaleler ve belge nosuz fatura: tutar + tarih ile.
    expect(kinds.where((k) => k == MatchKind.amountAndDate).length, 3);
    // B'deki 8.000 ödeme = A'daki 5.000 + 3.000 havale.
    final sum = report.matches.singleWhere((m) => m.kind == MatchKind.sum);
    expect(sum.entriesA.length, 2);
    expect(sum.entriesB.single.debit, 800000);

    // A'da kalan: FT-2024-104 (1.200) ve FT-2024-105 (640). B'de kalan: iade 450.
    expect(report.unmatchedA.map((e) => e.documentNo), ['FT-2024-104', 'FT-2024-105']);
    expect(report.unmatchedB.single.documentNo, 'FT2024106');
    expect(report.isFullyReconciled, isFalse);
    // 1.200 + 640 borç (A) - 450 alacak (B) = 1.390,00 fark.
    expect(report.balanceDifference, 139000);
  });

  test('elle eşleştirme ve bozma', () async {
    final result = await ReconciliationService.runSync(a, b);
    var report = result.report;
    final before = report.matches.length;

    report = report.withManualMatch([report.unmatchedA.first], [report.unmatchedB.first]);
    expect(report.matches.length, before + 1);
    expect(report.matches.last.kind, MatchKind.manual);
    expect(report.matches.last.difference, 120000 - 45000);
    expect(report.unmatchedB, isEmpty);

    report = report.withoutMatch(report.matches.last);
    expect(report.matches.length, before);
    expect(report.unmatchedA.length, 2);
    expect(report.unmatchedB.length, 1);
  });

  test('CSV ve metin dışa aktarımı', () async {
    final result = await ReconciliationService.runSync(a, b);
    final csv = const CsvReportExporter().export(result.report, nameA: 'Biz', nameB: 'Karşı');
    expect(csv.startsWith('﻿"Durum";"Kural"'), isTrue);
    expect(csv, contains('"Yalnızca Karşı"'));
    expect(csv, contains('"Bakiye farkı";"1.390,00"'));

    final txt = const PlainTextReportFormatter().format(result.report);
    expect(txt, contains('MUTABIK DEĞİL'));
    expect(txt, contains('[TOPLAM %70] (2 parça toplamı)'));
  });

  test('tanınmayan düzen için uyarı üretir', () async {
    final tmp = await File('${Directory.systemTemp.path}/comparatorr_bad.txt').create();
    await tmp.writeAsString('bu bir ekstre değil\nikinci satır\n');
    final result = await ReconciliationService.runSync(tmp.path, tmp.path);
    expect(result.sideA.entries, isEmpty);
    expect(result.warnings.first, contains('hiçbir satır'));
    await tmp.delete();
  });
}
