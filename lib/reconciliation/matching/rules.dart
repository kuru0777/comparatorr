import '../models/ledger_entry.dart';
import '../models/match_result.dart';
import 'match_rule.dart';

/// Kural 1: Belge numarası ve tutar birebir aynı, yönler zıt.
///
/// En güvenilir kural. Aynı belge no ile birden fazla kayıt varsa
/// (ör. kısmi faturalar) tutar da eşleşen ilk çift alınır.
class ExactDocumentNoRule implements MatchRule {
  const ExactDocumentNoRule();

  @override
  String get name => 'exact-document-no';

  @override
  List<Match> apply(MatchPool pool) {
    final byDoc = <String, List<LedgerEntry>>{};
    for (final e in pool.b) {
      final key = e.normalizedDocumentNo;
      if (key == null) continue;
      byDoc.putIfAbsent(key, () => []).add(e);
    }

    final matches = <Match>[];
    final usedB = <LedgerEntry>{};
    for (final a in pool.a) {
      final key = a.normalizedDocumentNo;
      if (key == null) continue;
      final candidates = byDoc[key];
      if (candidates == null) continue;
      for (final b in candidates) {
        if (usedB.contains(b)) continue;
        if (a.absAmount != b.absAmount) continue;
        if (!oppositeDirection(a, b)) continue;
        usedB.add(b);
        matches.add(Match(
          entriesA: [a],
          entriesB: [b],
          kind: MatchKind.exactDocumentNo,
          confidence: 1.0,
        ));
        break;
      }
    }
    return matches;
  }
}

/// Kural 2: Tutar aynı, tarih farkı [toleranceDays] içinde, yönler zıt.
///
/// Belge no eşleşmeyen veya bir tarafta belge no olmayan kayıtları yakalar.
/// Aynı tutarlı birden fazla aday varsa tarihi en yakın olan seçilir.
class AmountDateToleranceRule implements MatchRule {
  final int toleranceDays;

  const AmountDateToleranceRule({this.toleranceDays = 5});

  @override
  String get name => 'amount-date-tolerance';

  @override
  List<Match> apply(MatchPool pool) {
    final byAmount = <int, List<LedgerEntry>>{};
    for (final e in pool.b) {
      byAmount.putIfAbsent(e.absAmount, () => []).add(e);
    }

    final matches = <Match>[];
    final usedB = <LedgerEntry>{};
    for (final a in pool.a) {
      if (a.date == null) continue;
      final candidates = byAmount[a.absAmount];
      if (candidates == null) continue;

      LedgerEntry? best;
      int? bestDiff;
      for (final b in candidates) {
        if (usedB.contains(b) || b.date == null) continue;
        if (!oppositeDirection(a, b)) continue;
        final diff = a.date!.difference(b.date!).inDays.abs();
        if (diff > toleranceDays) continue;
        if (bestDiff == null || diff < bestDiff) {
          best = b;
          bestDiff = diff;
        }
      }
      if (best == null) continue;

      usedB.add(best);
      // Tarih farkı büyüdükçe güven düşer: 0 gün -> 0.9, tolerans sınırı -> 0.6
      final conf = toleranceDays == 0
          ? 0.9
          : 0.9 - 0.3 * (bestDiff! / toleranceDays);
      matches.add(Match(
        entriesA: [a],
        entriesB: [best],
        kind: MatchKind.amountAndDate,
        confidence: conf,
        note: bestDiff == 0 ? null : 'Tarih farkı $bestDiff gün',
      ));
    }
    return matches;
  }
}

/// Kural 3: Bir taraftaki tek kayıt, diğer taraftaki en fazla [maxParts]
/// kaydın toplamına eşit (ör. bir fatura, iki taksit ödeme).
///
/// Adaylar [windowDays] gün penceresi içinde aranır ve alt küme toplamı
/// küçük kombinasyonlarla sınırlı tutulur; aksi halde uzun ekstrelerde
/// üstel maliyet oluşur.
class SumMatchRule implements MatchRule {
  final int maxParts;
  final int windowDays;

  const SumMatchRule({this.maxParts = 3, this.windowDays = 45});

  @override
  String get name => 'sum-match';

  @override
  List<Match> apply(MatchPool pool) {
    final matches = <Match>[];
    var remaining = pool;

    // Önce A'daki tek kayıt = B'deki çoklu kayıt, sonra tersi.
    final forward = _oneToMany(remaining.a, remaining.b, aIsSingle: true);
    matches.addAll(forward);
    remaining = remaining.without(forward);
    final backward = _oneToMany(remaining.b, remaining.a, aIsSingle: false);
    matches.addAll(backward);

    return matches;
  }

  List<Match> _oneToMany(
    List<LedgerEntry> singles,
    List<LedgerEntry> parts, {
    required bool aIsSingle,
  }) {
    final matches = <Match>[];
    final usedParts = <LedgerEntry>{};

    for (final single in singles) {
      if (single.date == null || single.absAmount == 0) continue;

      final candidates = parts.where((p) {
        if (usedParts.contains(p) || p.date == null) return false;
        if (!oppositeDirection(single, p)) return false;
        if (p.absAmount == 0 || p.absAmount > single.absAmount) return false;
        return single.date!.difference(p.date!).inDays.abs() <= windowDays;
      }).toList()
        ..sort((x, y) => y.absAmount.compareTo(x.absAmount));

      final combo = _findSubset(candidates, single.absAmount, maxParts);
      if (combo == null || combo.length < 2) continue;

      usedParts.addAll(combo);
      matches.add(Match(
        entriesA: aIsSingle ? [single] : combo,
        entriesB: aIsSingle ? combo : [single],
        kind: MatchKind.sum,
        confidence: 0.7,
        note: '${combo.length} parça toplamı',
      ));
    }
    return matches;
  }

  /// Sınırlı derinlikte geri izleme ile hedef tutarı veren alt kümeyi bulur.
  List<LedgerEntry>? _findSubset(
    List<LedgerEntry> items,
    int target,
    int maxSize,
  ) {
    List<LedgerEntry>? result;

    void search(int start, int remaining, List<LedgerEntry> chosen) {
      if (result != null) return;
      if (remaining == 0) {
        result = List.of(chosen);
        return;
      }
      if (chosen.length >= maxSize) return;
      for (var i = start; i < items.length; i++) {
        final v = items[i].absAmount;
        if (v > remaining) continue;
        chosen.add(items[i]);
        search(i + 1, remaining - v, chosen);
        chosen.removeLast();
        if (result != null) return;
      }
    }

    search(0, target, []);
    return result;
  }
}
