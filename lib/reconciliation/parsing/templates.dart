import 'statement_parser.dart';

/// Bilinen ekstre düzenleri. Yeni bir muhasebe programı desteklemek için
/// buraya bir şablon eklemek yeterlidir; [AutoStatementParser] hepsini dener.
class StatementTemplates {
  StatementTemplates._();

  static final List<RegExp> _commonSkips = [
    RegExp(r'^\s*(tarih|belge|fiş|açıklama|borç|alacak|bakiye|evrak)',
        caseSensitive: false),
    RegExp(r'^\s*(devir|devreden|önceki dönem|toplam|genel toplam|ara toplam|sayfa|rapor)',
        caseSensitive: false),
    RegExp(r'^\s*[-=_*]{3,}\s*$'),
  ];

  /// `Tarih  BelgeNo  Açıklama  Borç  Alacak  [Bakiye]`
  static final StatementTemplate withDocumentNo = StatementTemplate.genericTr;

  /// `Tarih  Açıklama  Borç  Alacak  [Bakiye]` (belge no sütunu yok)
  static final StatementTemplate withoutDocumentNo = StatementTemplate(
    name: 'tr-no-docno',
    linePattern: RegExp(
      r'^\s*(?<date>\d{1,2}[./-]\d{1,2}[./-]\d{2,4})'
      r'\s+(?<description>.*?)'
      r'\s+(?<debit>[\d.,]+|-)'
      r'\s+(?<credit>[\d.,]+|-)'
      r'(?:\s+(?<balance>-?[\d.,]+(?:\s?[BA])?))?'
      r'\s*$',
    ),
    skipPatterns: _commonSkips,
  );

  /// `Tarih  Açıklama  BelgeNo  Borç  Alacak  [Bakiye]`
  /// (belge no açıklamadan sonra; bazı programlar böyle basar)
  static final StatementTemplate documentNoAfterDescription = StatementTemplate(
    name: 'tr-docno-after-desc',
    linePattern: RegExp(
      r'^\s*(?<date>\d{1,2}[./-]\d{1,2}[./-]\d{2,4})'
      r'\s+(?<description>.*?)'
      r'\s+(?<docNo>[A-Za-z]{1,4}[-/]?\d{2,})'
      r'\s+(?<debit>[\d.,]+|-)'
      r'\s+(?<credit>[\d.,]+|-)'
      r'(?:\s+(?<balance>-?[\d.,]+(?:\s?[BA])?))?'
      r'\s*$',
    ),
    skipPatterns: _commonSkips,
  );

  /// `Tarih  BelgeNo  Açıklama  Tutar  B/A` — tek tutar sütunu ve yön harfi
  static final StatementTemplate singleAmountWithDirection = StatementTemplate(
    name: 'tr-single-amount',
    linePattern: RegExp(
      r'^\s*(?<date>\d{1,2}[./-]\d{1,2}[./-]\d{2,4})'
      r'\s+(?<docNo>\S+)'
      r'\s+(?<description>.*?)'
      r'\s+(?<amount>[\d.,]+)'
      r'\s+(?<direction>[BA])'
      r'(?:\s+(?<balance>-?[\d.,]+(?:\s?[BA])?))?'
      r'\s*$',
    ),
    skipPatterns: _commonSkips,
  );

  static final List<StatementTemplate> all = [
    withDocumentNo,
    documentNoAfterDescription,
    withoutDocumentNo,
    singleAmountWithDirection,
  ];
}
