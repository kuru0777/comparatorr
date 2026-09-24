import '../models/ledger_entry.dart';
import 'delimited_parser.dart';
import 'statement_parser.dart';
import 'templates.dart';

/// Bir ayrıştırma denemesinin sonucu.
class ParseAttempt {
  final String parserName;
  final List<LedgerEntry> entries;

  const ParseAttempt(this.parserName, this.entries);
}

/// Tüm bilinen ayrıştırıcıları dener ve en çok kayıt üreteni seçer.
///
/// Kullanıcı hangi programdan ekstre aldığını bilmek zorunda kalmaz.
/// Seçilen ayrıştırıcının adı [lastAttempt] üzerinden raporlanır.
class AutoStatementParser implements StatementParser {
  final List<StatementParser> candidates;
  final List<String> candidateNames;

  ParseAttempt? lastAttempt;

  AutoStatementParser({List<StatementParser>? candidates, List<String>? names})
      : candidates = candidates ??
            [
              for (final t in StatementTemplates.all) TemplateStatementParser(t),
              const DelimitedStatementParser(),
            ],
        candidateNames = names ??
            [
              for (final t in StatementTemplates.all) t.name,
              'delimited',
            ];

  @override
  List<LedgerEntry> parse(List<PageText> pages, LedgerSide side) {
    ParseAttempt? best;
    for (var i = 0; i < candidates.length; i++) {
      final entries = candidates[i].parse(pages, side);
      final name = i < candidateNames.length ? candidateNames[i] : 'parser-$i';
      if (best == null || entries.length > best.entries.length) {
        best = ParseAttempt(name, entries);
      }
    }
    lastAttempt = best;
    return best?.entries ?? [];
  }
}
