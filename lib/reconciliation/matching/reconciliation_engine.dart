import '../models/ledger_entry.dart';
import '../models/match_result.dart';
import '../models/reconciliation_report.dart';
import 'match_rule.dart';
import 'rules.dart';

/// Kuralları sırayla uygulayarak iki ekstreyi eşleştirir.
///
/// Sıra önemlidir: kesin kurallar önce çalışır ki belirsiz kurallar
/// yalnızca kalan kayıtlar üzerinde tahmin yürütsün.
class ReconciliationEngine {
  final List<MatchRule> rules;

  const ReconciliationEngine({required this.rules});

  /// Varsayılan kural zinciri.
  factory ReconciliationEngine.standard({
    int dateToleranceDays = 5,
    int maxSumParts = 3,
  }) {
    return ReconciliationEngine(rules: [
      const ExactDocumentNoRule(),
      AmountDateToleranceRule(toleranceDays: dateToleranceDays),
      SumMatchRule(maxParts: maxSumParts),
    ]);
  }

  ReconciliationReport reconcile(
    List<LedgerEntry> entriesA,
    List<LedgerEntry> entriesB,
  ) {
    var pool = MatchPool(a: entriesA, b: entriesB);
    final matches = <Match>[];

    for (final rule in rules) {
      if (pool.isEmpty) break;
      final found = rule.apply(pool);
      if (found.isEmpty) continue;
      matches.addAll(found);
      pool = pool.without(found);
    }

    final all = entriesA.followedBy(entriesB);
    return ReconciliationReport(
      matches: matches,
      unmatchedA: pool.a,
      unmatchedB: pool.b,
      needsReview: all.where((e) => e.source.needsReview).toList(),
    );
  }
}
