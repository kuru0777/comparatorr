import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../parsing/statement_parser.dart';
import 'text_extractor.dart';

/// PDF metin katmanını Syncfusion ile sayfa sayfa okur.
///
/// Mevcut `lib/View/doctotext.dart` tüm belgeyi tek seferde çıkarır; bu sınıf
/// aynı kütüphaneyi sayfa bazlı kullanır. Ağır belgelerde bu akış bir
/// isolate içinde (`compute`) çalıştırılmalıdır; burada yalnızca API yüzeyi
/// tanımlanır.
class SyncfusionPdfTextExtractor implements TextExtractor {
  const SyncfusionPdfTextExtractor();

  @override
  Stream<PageText> extract(String filePath) async* {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final pageCount = document.pages.count;
      for (var i = 0; i < pageCount; i++) {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        yield PageText(
          pageNumber: i + 1,
          lines: text.split(RegExp(r'\r?\n')),
        );
      }
    } finally {
      document.dispose();
    }
  }
}
