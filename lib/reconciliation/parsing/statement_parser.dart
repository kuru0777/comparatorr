import '../models/ledger_entry.dart';
import 'normalizers.dart';

/// Metin çıkarma katmanından gelen tek sayfa.
class PageText {
  final int pageNumber;
  final List<String> lines;

  /// Sayfa OCR ile okunduysa sayfa geneli güven puanı; aksi halde null.
  final double? ocrConfidence;

  const PageText({
    required this.pageNumber,
    required this.lines,
    this.ocrConfidence,
  });
}

/// Ham sayfa metnini [LedgerEntry] listesine çeviren arayüz.
///
/// Her muhasebe programının ekstre düzeni farklıdır. Uygulamalar, düzeni
/// tanıyan bir [StatementTemplate] ile ya da tamamen özel mantıkla çalışır.
abstract class StatementParser {
  List<LedgerEntry> parse(List<PageText> pages, LedgerSide side);
}

/// Sütun sıralı ekstreler için satır bazlı, düzenli ifade tabanlı şablon.
///
/// Şablon, bir satırın hangi alanlara bölündüğünü tarif eder. Bir satır
/// [linePattern] ile eşleşmezse "devam satırı" kabul edilir ve açıklaması
/// önceki kayda eklenir (uzun açıklamalar alt satıra sarabilir).
class StatementTemplate {
  final String name;

  /// Yakalama grupları isimli olmalı: date, docNo, description, debit,
  /// credit, balance. Zorunlu olanlar: date ve en az biri debit/credit.
  final RegExp linePattern;

  /// Bu ifadelerden biriyle eşleşen satırlar atlanır (başlık, sayfa altı,
  /// "Devir", "Toplam" gibi özet satırları).
  final List<RegExp> skipPatterns;

  const StatementTemplate({
    required this.name,
    required this.linePattern,
    this.skipPatterns = const [],
  });

  /// Yaygın Türkçe cari ekstre düzeni:
  /// `Tarih  BelgeNo  Açıklama ...  Borç  Alacak  Bakiye`
  /// Tutar sütunları boş olabilir; boş sütun "0,00" veya "-" olarak gelir.
  static final StatementTemplate genericTr = StatementTemplate(
    name: 'generic-tr',
    linePattern: RegExp(
      r'^\s*(?<date>\d{1,2}[./-]\d{1,2}[./-]\d{2,4})'
      r'\s+(?<docNo>\S+)'
      r'\s+(?<description>.*?)'
      r'\s+(?<debit>[\d.,]+|-)'
      r'\s+(?<credit>[\d.,]+|-)'
      r'(?:\s+(?<balance>-?[\d.,]+(?:\s?[BA])?))?'
      r'\s*$',
    ),
    skipPatterns: [
      RegExp(r'^\s*(tarih|belge|açıklama|borç|alacak|bakiye)', caseSensitive: false),
      RegExp(r'^\s*(devir|devreden|toplam|genel toplam|sayfa)', caseSensitive: false),
      RegExp(r'^\s*[-=_]{3,}\s*$'),
    ],
  );
}

class TemplateStatementParser implements StatementParser {
  final StatementTemplate template;
  final TrAmountParser amountParser;
  final TrDateParser dateParser;

  const TemplateStatementParser(
    this.template, {
    this.amountParser = const TrAmountParser(),
    this.dateParser = const TrDateParser(),
  });

  @override
  List<LedgerEntry> parse(List<PageText> pages, LedgerSide side) {
    final entries = <LedgerEntry>[];

    for (final page in pages) {
      for (final rawLine in page.lines) {
        final line = rawLine.trimRight();
        if (line.trim().isEmpty) continue;
        if (template.skipPatterns.any((p) => p.hasMatch(line))) continue;

        final m = template.linePattern.firstMatch(line);
        if (m == null) {
          // Devam satırı: önceki kaydın açıklamasına ekle.
          if (entries.isNotEmpty && entries.last.source.page == page.pageNumber) {
            final last = entries.removeLast();
            entries.add(last.copyWith(
              description: '${last.description} ${line.trim()}'.trim(),
            ));
          }
          continue;
        }

        final date = dateParser.parse(m.namedGroup('date') ?? '');
        final debit = _amount(m.namedGroup('debit'));
        final credit = _amount(m.namedGroup('credit'));
        if (date == null || (debit == null && credit == null)) continue;

        final balanceRaw = m.groupNames.contains('balance')
            ? m.namedGroup('balance')
            : null;

        entries.add(LedgerEntry(
          side: side,
          index: entries.length,
          date: date,
          documentNo: m.namedGroup('docNo'),
          description: (m.namedGroup('description') ?? '').trim(),
          debit: debit ?? 0,
          credit: credit ?? 0,
          balance: balanceRaw == null ? null : _balance(balanceRaw),
          source: EntrySource(
            page: page.pageNumber,
            rawLine: rawLine,
            ocrConfidence: page.ocrConfidence,
          ),
        ));
      }
    }
    return entries;
  }

  int? _amount(String? raw) {
    if (raw == null || raw.trim() == '-' || raw.trim().isEmpty) return null;
    return amountParser.parse(raw)?.abs();
  }

  /// "1.234,56 B" (borç bakiye) veya "1.234,56 A" (alacak bakiye) ekini işler.
  int? _balance(String raw) {
    final trimmed = raw.trim();
    final suffix = trimmed.isNotEmpty ? trimmed[trimmed.length - 1] : '';
    final isCreditBalance = suffix == 'A';
    final numeric = (suffix == 'A' || suffix == 'B')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    final v = amountParser.parse(numeric);
    if (v == null) return null;
    return isCreditBalance ? -v.abs() : v;
  }
}
