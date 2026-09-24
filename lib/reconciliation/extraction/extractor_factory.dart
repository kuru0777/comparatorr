import 'cli_ocr_extractor.dart';
import 'plain_text_extractor.dart';
import 'syncfusion_pdf_extractor.dart';
import 'text_extractor.dart';

/// Dosya uzantısına göre uygun çıkarıcıyı seçer.
///
/// - pdf: metin katmanı, boş sayfalarda OCR (etkinse)
/// - png/jpg/jpeg/tif: doğrudan OCR
/// - txt/csv/tsv: düz metin
TextExtractor extractorFor(String filePath, {OcrConfig? ocr}) {
  final lower = filePath.toLowerCase();
  final ocrExtractor = ocr == null ? null : CliOcrExtractor(config: ocr);

  if (lower.endsWith('.pdf')) {
    return LayeredTextExtractor(
      textLayer: const SyncfusionPdfTextExtractor(),
      ocr: ocrExtractor,
    );
  }
  if (RegExp(r'\.(png|jpe?g|tiff?|bmp)$').hasMatch(lower)) {
    if (ocrExtractor == null) {
      throw ArgumentError('Görüntü dosyası için OCR etkin olmalı: $filePath');
    }
    return ocrExtractor;
  }
  return const PlainTextExtractor();
}

/// Desteklenen giriş uzantıları (dosya seçici için).
const supportedExtensions = ['pdf', 'txt', 'csv', 'tsv', 'png', 'jpg', 'jpeg', 'tif', 'tiff'];
