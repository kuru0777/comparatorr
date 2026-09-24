import 'dart:convert';
import 'dart:io';

import '../parsing/statement_parser.dart';
import 'text_extractor.dart';

/// .txt / .csv dosyalarını tek sayfa olarak okur.
///
/// Muhasebe programlarının "metin olarak dışa aktar" çıktıları için.
/// UTF-8 ile okunamazsa Latin-5 (Windows-1254 yakını) olarak dener.
class PlainTextExtractor implements TextExtractor {
  const PlainTextExtractor();

  @override
  Stream<PageText> extract(String filePath) async* {
    final bytes = await File(filePath).readAsBytes();
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      text = latin1.decode(bytes);
    }
    yield PageText(pageNumber: 1, lines: text.split(RegExp(r'\r?\n')));
  }
}
