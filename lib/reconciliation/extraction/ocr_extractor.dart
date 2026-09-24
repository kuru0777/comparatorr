import '../parsing/statement_parser.dart';
import 'text_extractor.dart';

/// OCR tabanlı çıkarıcı için yer tutucu.
///
/// Masaüstünde (Windows/Linux/macOS) `google_mlkit_text_recognition`
/// çalışmaz; yalnızca Android/iOS destekler. Masaüstü için seçenekler:
///  - Tesseract (flutter_tesseract_ocr veya doğrudan FFI),
///  - Bulut OCR servisi (belgeler dışarı çıkacağı için müşteri onayı gerekir),
///  - Sayfayı görüntüye render edip (pdfx / pdf_render) yerel bir modele vermek.
///
/// Gerçek uygulama, her sayfa için satırları ve satır bazlı güven puanını
/// döndürmelidir. Güven puanı [PageText.ocrConfidence] üzerinden
/// [LedgerEntry.source] içine taşınır ve düşük güvenli kayıtlar raporda
/// "doğrulanmalı" olarak işaretlenir.
class OcrTextExtractor implements TextExtractor {
  const OcrTextExtractor();

  @override
  Stream<PageText> extract(String filePath) {
    throw UnimplementedError(
      'OCR henüz bağlı değil. Masaüstü için Tesseract tabanlı bir uygulama '
      'ekleyin ve LayeredTextExtractor.ocr alanına verin.',
    );
  }
}
