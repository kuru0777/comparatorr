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

  Iterable<LedgerEntry> get _allA =>
      matches.expand((m) => m.entriesA).followedBy(unmatchedA);
  Iterable<LedgerEntry> get _allB =>
      matches.expand((m) => m.entriesB).followedBy(unmatchedB);
}
