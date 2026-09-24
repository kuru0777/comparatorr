import '../models/ledger_entry.dart';
import '../models/match_result.dart';

/// Eşleştirme sırasında kuralların paylaştığı, henüz eşleşmemiş kayıt havuzu.
///
/// Kurallar sırayla çalışır; her kural bulduğu eşleşmeleri döndürür ve motor
/// bu kayıtları havuzdan düşürür. Kurallar havuzu değiştirmez.
class MatchPool {
  final List<LedgerEntry> a;
  final List<LedgerEntry> b;

  const MatchPool({required this.a, required this.b});

  MatchPool without(Iterable<Match> matches) {
    final usedA = <LedgerEntry>{}..addAll(matches.expand((m) => m.entriesA));
    final usedB = <LedgerEntry>{}..addAll(matches.expand((m) => m.entriesB));
    return MatchPool(
      a: a.where((e) => !usedA.contains(e)).toList(),
      b: b.where((e) => !usedB.contains(e)).toList(),
    );
  }

  bool get isEmpty => a.isEmpty || b.isEmpty;
}

/// Tek bir eşleştirme kuralı. Her kural kendi içinde bir kaydı yalnızca
/// bir eşleşmede kullanmalıdır.
abstract class MatchRule {
  String get name;

  List<Match> apply(MatchPool pool);
}

/// A tarafındaki borç, B tarafındaki alacağa karşılık gelir (ve tersi).
/// Bu yardımcı, iki kaydın "aynı yönde" olup olmadığını söyler.
bool oppositeDirection(LedgerEntry a, LedgerEntry b) {
  if (a.netAmount == 0 || b.netAmount == 0) return false;
  return (a.netAmount > 0) != (b.netAmount > 0);
}
