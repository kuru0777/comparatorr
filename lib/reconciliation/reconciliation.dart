/// Muhasebe mutabakat motoru.
///
/// Katmanlar:
///  1. extraction  – belgeyi sayfa sayfa metne çevirir (metin katmanı, OCR).
///  2. parsing     – ham satırları [LedgerEntry] kayıtlarına ayrıştırır.
///  3. matching    – kural zinciriyle iki tarafın kayıtlarını eşleştirir.
///  4. report      – sonucu rapora dönüştürür.
///
/// Kullanım:
/// ```dart
/// final parser = TemplateStatementParser(StatementTemplate.genericTr);
/// final a = parser.parse(pagesA, LedgerSide.a);
/// final b = parser.parse(pagesB, LedgerSide.b);
/// final report = ReconciliationEngine.standard().reconcile(a, b);
/// print(const PlainTextReportFormatter().format(report));
/// ```
library;

export 'extraction/ocr_extractor.dart';
export 'extraction/syncfusion_pdf_extractor.dart';
export 'extraction/text_extractor.dart';
export 'matching/match_rule.dart';
export 'matching/reconciliation_engine.dart';
export 'matching/rules.dart';
export 'models/ledger_entry.dart';
export 'models/match_result.dart';
export 'models/reconciliation_report.dart';
export 'parsing/normalizers.dart';
export 'parsing/statement_parser.dart';
export 'report/report_formatter.dart';
