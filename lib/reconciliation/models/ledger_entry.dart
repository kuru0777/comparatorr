/// Bir cari hesap ekstresindeki tek bir hareket satırı.
///
/// Ekstrenin hangi taraftan geldiği ([side]) ve kaynağı ([source]) ile birlikte
/// normalize edilmiş alanları taşır. Tutarlar kuruş cinsinden tam sayı olarak
/// tutulur; ondalık hatalarından kaçınmak için double kullanılmaz.
class LedgerEntry {
  /// Kaydın ait olduğu taraf: "A" (bizim ekstremiz) veya "B" (karşı taraf).
  final LedgerSide side;

  /// Ekstre içindeki sıra numarası (0 tabanlı). Eşleşme sonuçlarını
  /// kaynak satıra geri bağlamak için kullanılır.
  final int index;

  final DateTime? date;
  final String? documentNo;
  final String description;

  /// Borç tutarı, kuruş cinsinden. Yoksa 0.
  final int debit;

  /// Alacak tutarı, kuruş cinsinden. Yoksa 0.
  final int credit;

  /// Satırdaki bakiye sütunu, kuruş cinsinden. Ekstrede yoksa null.
  final int? balance;

  /// Kaynak bilgisi: sayfa numarası, ham satır ve OCR güven puanı.
  final EntrySource source;

  const LedgerEntry({
    required this.side,
    required this.index,
    required this.description,
    this.date,
    this.documentNo,
    this.debit = 0,
    this.credit = 0,
    this.balance,
    this.source = const EntrySource(),
  });

  /// Net tutar: borç pozitif, alacak negatif. Eşleştirmede A tarafındaki
  /// borç, B tarafındaki alacağa karşılık geldiği için [signedAmountFor]
  /// kullanılarak karşılaştırılır.
  int get netAmount => debit - credit;

  /// Mutlak tutar. Eşleştirme kurallarının çoğu bu değeri kullanır.
  int get absAmount => netAmount.abs();

  /// Belge numarasını karşılaştırma için normalize eder
  /// (büyük harf, boşluk ve ayraçlar atılır, baştaki sıfırlar kaldırılır).
  String? get normalizedDocumentNo {
    final raw = documentNo;
    if (raw == null) return null;
    final cleaned = raw.toUpperCase().replaceAll(RegExp(r'[\s\-_/\.]'), '');
    if (cleaned.isEmpty) return null;
    // Sadece rakam ise baştaki sıfırları at.
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      return cleaned.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    }
    return cleaned;
  }

  LedgerEntry copyWith({
    LedgerSide? side,
    int? index,
    DateTime? date,
    String? documentNo,
    String? description,
    int? debit,
    int? credit,
    int? balance,
    EntrySource? source,
  }) {
    return LedgerEntry(
      side: side ?? this.side,
      index: index ?? this.index,
      date: date ?? this.date,
      documentNo: documentNo ?? this.documentNo,
      description: description ?? this.description,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      balance: balance ?? this.balance,
      source: source ?? this.source,
    );
  }

  @override
  String toString() =>
      'LedgerEntry(${side.name}#$index ${date?.toIso8601String().substring(0, 10)} '
      'doc=$documentNo debit=$debit credit=$credit "$description")';
}

enum LedgerSide { a, b }

/// Kaydın nereden geldiğine dair izlenebilirlik bilgisi.
class EntrySource {
  /// 1 tabanlı sayfa numarası. Bilinmiyorsa null.
  final int? page;

  /// Ayrıştırılan ham satır. Kullanıcıya "bu kayıt nereden geldi" göstermek için.
  final String? rawLine;

  /// OCR'dan geldiyse 0..1 arası güven puanı. Metin katmanından geldiyse null.
  final double? ocrConfidence;

  const EntrySource({this.page, this.rawLine, this.ocrConfidence});

  /// OCR güveni düşükse kullanıcıya doğrulatılmalı.
  bool get needsReview => ocrConfidence != null && ocrConfidence! < 0.85;
}
