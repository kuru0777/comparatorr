import 'ledger_entry.dart';

/// Eşleşmenin hangi kuralla kurulduğu.
enum MatchKind {
  /// Belge no + tutar birebir aynı.
  exactDocumentNo,

  /// Tutar aynı, tarih toleransı içinde.
  amountAndDate,

  /// Bir taraftaki tek kayıt, diğer taraftaki birden fazla kaydın toplamı.
  sum,

  /// Kullanıcı elle eşleştirdi.
  manual,
}

/// A ve B tarafından bir veya daha fazla kaydın birbirine bağlanması.
///
/// Çoğu eşleşme 1-1'dir. [MatchKind.sum] durumunda bir taraf tek, diğer taraf
/// birden fazla kayıt içerir. Tutarlar her zaman kuruş cinsindendir.
class Match {
  final List<LedgerEntry> entriesA;
  final List<LedgerEntry> entriesB;
  final MatchKind kind;

  /// 0..1 arası güven. Kesin belge no eşleşmesi 1.0, tarih toleranslı
  /// eşleşmeler daha düşük olur. Raporda sıralama ve renklendirme için.
  final double confidence;

  /// Kuralın eklemek istediği açıklama (ör. "tarih farkı 2 gün").
  final String? note;

  const Match({
    required this.entriesA,
    required this.entriesB,
    required this.kind,
    required this.confidence,
    this.note,
  }) : assert(entriesA.length > 0 && entriesB.length > 0);

  int get totalA => entriesA.fold(0, (s, e) => s + e.absAmount);
  int get totalB => entriesB.fold(0, (s, e) => s + e.absAmount);

  /// Eşleşme içi tutar farkı. Tam eşleşmede 0 olmalı.
  int get difference => totalA - totalB;

  @override
  String toString() =>
      'Match(${kind.name} conf=${confidence.toStringAsFixed(2)} '
      'A=${entriesA.map((e) => e.index).toList()} '
      'B=${entriesB.map((e) => e.index).toList()})';
}
