import 'ledger_entry.dart';
import 'match_result.dart';

/// Eşleştirme motorunun nihai çıktısı.
class ReconciliationReport {
  final List<Match> matches;

  /// A tarafında olup B'de karşılığı bulunamayan kayıtlar.
  final List<LedgerEntry> unmatchedA;

  /// B tarafında olup A'da karşılığı bulunamayan kayıtlar.
  final List<LedgerEntry> unmatchedB;

  /// OCR güveni düşük olduğu için kullanıcı doğrulaması bekleyen kayıtlar.
  final List<LedgerEntry> needsReview;

  const ReconciliationReport({
    required this.matches,
    required this.unmatchedA,
    required this.unmatchedB,
    required this.needsReview,
  });

  int get matchedCount => matches.length;

  /// A tarafının net toplamı (borç - alacak), kuruş.
  int get netTotalA =>
      _allA.fold(0, (s, e) => s + e.netAmount);

  /// B tarafının net toplamı (borç - alacak), kuruş.
  int get netTotalB =>
      _allB.fold(0, (s, e) => s + e.netAmount);

  /// İki tarafın bakiye farkı. Karşı tarafın ekstresinde bizim borcumuz
  /// onların alacağı olarak göründüğü için işaretler toplanır.
  int get balanceDifference => netTotalA + netTotalB;

  /// Eşleşmeyen kayıtların tutar toplamı. Mutabakatsızlığın kaynağı.
  int get unmatchedTotalA => unmatchedA.fold(0, (s, e) => s + e.netAmount);
  int get unmatchedTotalB => unmatchedB.fold(0, (s, e) => s + e.netAmount);

  bool get isFullyReconciled =>
      unmatchedA.isEmpty && unmatchedB.isEmpty && balanceDifference == 0;

  /// Kullanıcının elle seçtiği A ve B kayıtlarını eşleştirir.
  ///
  /// Kayıtlar eşleşmemiş listelerden alınır; tutarlar farklı olsa da
  /// eşleşme kurulur ve fark [Match.difference] ile raporlanır.
  ReconciliationReport withManualMatch(
    List<LedgerEntry> fromA,
    List<LedgerEntry> fromB,
  ) {
    if (fromA.isEmpty || fromB.isEmpty) return this;
    final setA = fromA.toSet();
    final setB = fromB.toSet();
    final match = Match(
      entriesA: fromA,
      entriesB: fromB,
      kind: MatchKind.manual,
      confidence: 1.0,
      note: 'Elle eşleştirildi',
    );
    return ReconciliationReport(
      matches: [...matches, match],
      unmatchedA: unmatchedA.where((e) => !setA.contains(e)).toList(),
      unmatchedB: unmatchedB.where((e) => !setB.contains(e)).toList(),
      needsReview: needsReview,
    );
  }

  /// Bir eşleşmeyi bozar; kayıtlar eşleşmemiş listelere geri döner
  /// (ekstre sırasına göre yerleştirilir).
  ReconciliationReport withoutMatch(Match match) {
    if (!matches.contains(match)) return this;
    List<LedgerEntry> sorted(List<LedgerEntry> list) =>
        list..sort((x, y) => x.index.compareTo(y.index));
    return ReconciliationReport(
      matches: matches.where((m) => m != match).toList(),
      unmatchedA: sorted([...unmatchedA, ...match.entriesA]),
      unmatchedB: sorted([...unmatchedB, ...match.entriesB]),
      needsReview: needsReview,
    );
  }

  Iterable<LedgerEntry> get _allA =>
      matches.expand((m) => m.entriesA).followedBy(unmatchedA);
  Iterable<LedgerEntry> get _allB =>
      matches.expand((m) => m.entriesB).followedBy(unmatchedB);
}
