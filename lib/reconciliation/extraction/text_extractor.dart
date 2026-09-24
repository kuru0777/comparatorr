import '../parsing/statement_parser.dart';

/// Bir belgeyi sayfa sayfa metne çeviren arayüz.
///
/// Uygulamalar dosyanın tamamını belleğe yüklemek yerine sayfa başına
/// çalışmalı ve sonucu [Stream] olarak vermelidir; böylece yüzlerce sayfalık
/// ekstrelerde ilerleme gösterilebilir ve UI kilitlenmez.
abstract class TextExtractor {
  Stream<PageText> extract(String filePath);
}

/// Bir sayfanın metin katmanı var mı? Çok kısa veya boş sayfalar
/// büyük ihtimalle taranmış görüntüdür ve OCR'a gönderilmelidir.
bool looksLikeScannedPage(PageText page, {int minChars = 40}) {
  final total = page.lines.fold<int>(0, (s, l) => s + l.trim().length);
  return total < minChars;
}

/// Önce metin katmanını dener; sayfa boş görünürse OCR'a düşer.
///
/// [ocr] null ise taranmış sayfalar olduğu gibi (boş) geçer ve rapor
/// katmanı bunu kullanıcıya bildirmelidir.
class LayeredTextExtractor implements TextExtractor {
  final TextExtractor textLayer;
  final TextExtractor? ocr;

  const LayeredTextExtractor({required this.textLayer, this.ocr});

  @override
  Stream<PageText> extract(String filePath) async* {
    final ocrExtractor = ocr;
    // OCR pahalıdır; yalnızca ilk taranmış sayfada, bir kez çalıştırılır ve
    // sonuçlar sayfa numarasına göre saklanır.
    Map<int, PageText>? ocrPages;

    await for (final page in textLayer.extract(filePath)) {
      if (!looksLikeScannedPage(page) || ocrExtractor == null) {
        yield page;
        continue;
      }
      ocrPages ??= {
        await for (final p in ocrExtractor.extract(filePath)) p.pageNumber: p,
      };
      yield ocrPages[page.pageNumber] ?? page;
    }
  }
}
