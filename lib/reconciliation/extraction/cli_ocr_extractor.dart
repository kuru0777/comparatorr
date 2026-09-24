import 'dart:io';

import '../parsing/statement_parser.dart';
import 'text_extractor.dart';

/// OCR ayarları. Kullanıcı makinesindeki Tesseract ve Poppler yollarını tutar.
class OcrConfig {
  /// `tesseract` çalıştırılabilir dosyası. PATH'te ise sadece adı yeterli.
  final String tesseractPath;

  /// `pdftoppm` (Poppler) çalıştırılabilir dosyası; PDF'i görüntüye çevirir.
  final String pdftoppmPath;

  /// Tesseract dil kodu. Türkçe için `tur` paketi kurulu olmalı.
  final String language;

  /// Render çözünürlüğü (DPI). 300 çoğu ekstre için yeterli.
  final int dpi;

  const OcrConfig({
    this.tesseractPath = 'tesseract',
    this.pdftoppmPath = 'pdftoppm',
    this.language = 'tur',
    this.dpi = 300,
  });
}

/// Harici araçlarla OCR yapan çıkarıcı.
///
/// Neden harici araç: Masaüstünde (Windows/Linux/macOS) çalışan olgun bir
/// Flutter OCR eklentisi yok; ML Kit yalnızca mobilde çalışır. Tesseract ve
/// Poppler açık kaynak, ücretsiz ve Windows kurulumları hazırdır. Belgeler
/// makineden dışarı çıkmaz.
///
/// Akış: PDF → `pdftoppm` ile sayfa başına PNG → `tesseract --tsv` ile satır
/// metni ve kelime güven puanları → [PageText]. Görüntü dosyaları (png/jpg)
/// doğrudan Tesseract'a verilir.
class CliOcrExtractor implements TextExtractor {
  final OcrConfig config;

  const CliOcrExtractor({this.config = const OcrConfig()});

  /// Araçlar kurulu mu? Kurulu değilse hangi aracın eksik olduğunu döner.
  static Future<String?> checkTools(OcrConfig config) async {
    try {
      final t = await Process.run(config.tesseractPath, ['--version']);
      if (t.exitCode != 0) return 'tesseract çalıştırılamadı';
    } catch (_) {
      return 'tesseract bulunamadı (${config.tesseractPath})';
    }
    try {
      final p = await Process.run(config.pdftoppmPath, ['-v']);
      // pdftoppm -v sürümü stderr'e yazar ve 0 ile çıkar.
      if (p.exitCode != 0) return 'pdftoppm çalıştırılamadı';
    } catch (_) {
      return 'pdftoppm bulunamadı (${config.pdftoppmPath})';
    }
    return null;
  }

  @override
  Stream<PageText> extract(String filePath) async* {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.pdf')) {
      yield* _extractPdf(filePath);
    } else {
      yield await _ocrImage(filePath, pageNumber: 1);
    }
  }

  Stream<PageText> _extractPdf(String filePath) async* {
    final tmp = await Directory.systemTemp.createTemp('comparatorr_ocr_');
    try {
      final prefix = '${tmp.path}${Platform.pathSeparator}page';
      final result = await Process.run(config.pdftoppmPath, [
        '-r',
        '${config.dpi}',
        '-png',
        filePath,
        prefix,
      ]);
      if (result.exitCode != 0) {
        throw OcrException('pdftoppm hata verdi: ${result.stderr}');
      }

      final images = tmp
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.png'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      var pageNo = 0;
      for (final img in images) {
        pageNo++;
        yield await _ocrImage(img.path, pageNumber: pageNo);
      }
    } finally {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {
        // Geçici dizin silinemezse akışı bozma.
      }
    }
  }

  Future<PageText> _ocrImage(String imagePath, {required int pageNumber}) async {
    final result = await Process.run(
      config.tesseractPath,
      [imagePath, 'stdout', '-l', config.language, '--psm', '6', 'tsv'],
      stdoutEncoding: const SystemEncoding(),
    );
    if (result.exitCode != 0) {
      throw OcrException('tesseract hata verdi: ${result.stderr}');
    }
    return parseTsv(result.stdout as String, pageNumber: pageNumber);
  }

  /// Tesseract TSV çıktısını satırlara ve sayfa güven puanına çevirir.
  ///
  /// TSV sütunları: level page_num block_num par_num line_num word_num
  /// left top width height conf text. Kelimeler (level 5) aynı
  /// block/par/line üçlüsüne göre gruplanır.
  static PageText parseTsv(String tsv, {required int pageNumber}) {
    final lines = <String, List<String>>{};
    final order = <String>[];
    var confSum = 0.0;
    var confCount = 0;

    for (final row in tsv.split(RegExp(r'\r?\n'))) {
      final cols = row.split('\t');
      if (cols.length < 12 || cols[0] != '5') continue;
      final text = cols[11].trim();
      if (text.isEmpty) continue;
      final key = '${cols[2]}/${cols[3]}/${cols[4]}';
      if (!lines.containsKey(key)) {
        lines[key] = [];
        order.add(key);
      }
      lines[key]!.add(text);
      final conf = double.tryParse(cols[10]);
      if (conf != null && conf >= 0) {
        confSum += conf;
        confCount++;
      }
    }

    return PageText(
      pageNumber: pageNumber,
      lines: [for (final k in order) lines[k]!.join(' ')],
      ocrConfidence: confCount == 0 ? 0.0 : (confSum / confCount) / 100.0,
    );
  }
}

class OcrException implements Exception {
  final String message;
  const OcrException(this.message);
  @override
  String toString() => message;
}
