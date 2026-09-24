import 'dart:isolate';

import 'extraction/cli_ocr_extractor.dart';
import 'extraction/extractor_factory.dart';
import 'extraction/text_extractor.dart';
import 'matching/reconciliation_engine.dart';
import 'models/ledger_entry.dart';
import 'models/reconciliation_report.dart';
import 'parsing/auto_parser.dart';
import 'parsing/statement_parser.dart';

/// Mutabakat işinin ayarları. Isolate'e gönderilebilmesi için yalnızca
/// basit değerler içerir.
class ReconciliationOptions {
  final int dateToleranceDays;
  final int maxSumParts;

  /// null ise OCR kapalı; taranmış sayfalar boş geçer.
  final OcrConfig? ocr;

  const ReconciliationOptions({
    this.dateToleranceDays = 5,
    this.maxSumParts = 3,
    this.ocr,
  });
}

/// Tek bir tarafın (A veya B) okunma özeti.
class SideSummary {
  final String filePath;
  final int pageCount;
  final int scannedPageCount;
  final int lineCount;
  final String parserName;
  final List<LedgerEntry> entries;

  const SideSummary({
    required this.filePath,
    required this.pageCount,
    required this.scannedPageCount,
    required this.lineCount,
    required this.parserName,
    required this.entries,
  });

  String get fileName => filePath.split(RegExp(r'[\\/]')).last;
}

class ReconciliationResult {
  final SideSummary sideA;
  final SideSummary sideB;
  final ReconciliationReport report;
  final List<String> warnings;

  const ReconciliationResult({
    required this.sideA,
    required this.sideB,
    required this.report,
    required this.warnings,
  });
}

/// İki dosyayı okuyup ayrıştırır ve eşleştirir. Ağır iş ayrı bir isolate'te
/// yapılır; UI iş parçacığı kilitlenmez.
class ReconciliationService {
  const ReconciliationService();

  Future<ReconciliationResult> run(
    String pathA,
    String pathB, {
    ReconciliationOptions options = const ReconciliationOptions(),
  }) {
    return Isolate.run(() => runSync(pathA, pathB, options: options));
  }

  /// Aynı işi çağıran isolate'te yapar. Testlerde ve isolate içinde kullanılır.
  static Future<ReconciliationResult> runSync(
    String pathA,
    String pathB, {
    ReconciliationOptions options = const ReconciliationOptions(),
  }) async {
    final warnings = <String>[];
    final sideA = await _readSide(pathA, LedgerSide.a, options, warnings);
    final sideB = await _readSide(pathB, LedgerSide.b, options, warnings);

    final engine = ReconciliationEngine.standard(
      dateToleranceDays: options.dateToleranceDays,
      maxSumParts: options.maxSumParts,
    );
    final report = engine.reconcile(sideA.entries, sideB.entries);

    return ReconciliationResult(
      sideA: sideA,
      sideB: sideB,
      report: report,
      warnings: warnings,
    );
  }

  static Future<SideSummary> _readSide(
    String path,
    LedgerSide side,
    ReconciliationOptions options,
    List<String> warnings,
  ) async {
    final extractor = extractorFor(path, ocr: options.ocr);
    final isPdf = path.toLowerCase().endsWith('.pdf');
    final pages = <PageText>[];
    var scanned = 0;
    await for (final page in extractor.extract(path)) {
      pages.add(page);
      // "Taranmış sayfa" sezgisi yalnızca PDF için anlamlıdır; kısa bir
      // metin dosyası taranmış değildir.
      if (isPdf && looksLikeScannedPage(page)) scanned++;
    }

    final name = path.split(RegExp(r'[\\/]')).last;
    if (scanned > 0 && options.ocr == null) {
      warnings.add('$name: $scanned sayfa taranmış görünüyor ve OCR kapalı. '
          'Bu sayfalardaki kayıtlar okunamadı.');
    }

    final parser = AutoStatementParser();
    final entries = parser.parse(pages, side);
    final lineCount = pages.fold<int>(0, (s, p) => s + p.lines.length);
    if (entries.isEmpty && lineCount > 0) {
      warnings.add('$name: metin okundu ($lineCount satır) ama hiçbir satır '
          'ekstre kaydı olarak tanınmadı. Sütun düzeni bilinen şablonlara '
          'uymuyor olabilir.');
    }

    return SideSummary(
      filePath: path,
      pageCount: pages.length,
      scannedPageCount: scanned,
      lineCount: lineCount,
      parserName: parser.lastAttempt?.parserName ?? '-',
      entries: entries,
    );
  }
}
