/// Muhasebe mutabakat motoru.
///
/// Katmanlar:
///  1. extraction  – belgeyi sayfa sayfa metne çevirir (metin katmanı, OCR).
///  2. parsing     – ham satırları [LedgerEntry] kayıtlarına ayrıştırır.
///  3. matching    – kural zinciriyle iki tarafın kayıtlarını eşleştirir.
///  4. report      – sonucu rapora dönüştürür (metin, CSV, PDF).
///
/// Uygulama içinden tek çağrı:
/// ```dart
/// final result = await const ReconciliationService().run(pathA, pathB);
/// print(const PlainTextReportFormatter().format(result.report));
/// ```
library;

export 'extraction/cli_ocr_extractor.dart';
export 'extraction/extractor_factory.dart';
export 'extraction/plain_text_extractor.dart';
export 'extraction/syncfusion_pdf_extractor.dart';
export 'extraction/text_extractor.dart';
export 'matching/match_rule.dart';
export 'matching/reconciliation_engine.dart';
export 'matching/rules.dart';
export 'models/ledger_entry.dart';
export 'models/match_result.dart';
export 'models/reconciliation_report.dart';
export 'parsing/auto_parser.dart';
export 'parsing/delimited_parser.dart';
export 'parsing/normalizers.dart';
export 'parsing/statement_parser.dart';
export 'parsing/templates.dart';
export 'reconciliation_service.dart';
export 'report/csv_exporter.dart';
export 'report/pdf_exporter.dart';
export 'report/report_formatter.dart';
