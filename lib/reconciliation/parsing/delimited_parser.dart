import '../models/ledger_entry.dart';
import 'normalizers.dart';
import 'statement_parser.dart';

/// CSV / noktalı virgül / sekme ile ayrılmış ekstreler için ayrıştırıcı.
///
/// İlk satırdaki başlıklardan sütunları tanır (Tarih, Belge, Açıklama, Borç,
/// Alacak, Bakiye). Başlık yoksa varsayılan sıra kullanılır:
/// `tarih; belge; açıklama; borç; alacak; bakiye`.
class DelimitedStatementParser implements StatementParser {
  final String? delimiter;
  final TrAmountParser amountParser;
  final TrDateParser dateParser;

  const DelimitedStatementParser({
    this.delimiter,
    this.amountParser = const TrAmountParser(),
    this.dateParser = const TrDateParser(),
  });

  static const _headerAliases = <String, List<String>>{
    'date': ['tarih', 'date', 'islem tarihi', 'işlem tarihi'],
    'docNo': ['belge', 'belge no', 'belgeno', 'fiş no', 'fis no', 'evrak', 'evrak no', 'no'],
    'description': ['açıklama', 'aciklama', 'description', 'izahat'],
    'debit': ['borç', 'borc', 'debit'],
    'credit': ['alacak', 'credit'],
    'balance': ['bakiye', 'balance'],
  };

  static const _defaultOrder = ['date', 'docNo', 'description', 'debit', 'credit', 'balance'];

  @override
  List<LedgerEntry> parse(List<PageText> pages, LedgerSide side) {
    final lines = pages
        .expand((p) => p.lines.map((l) => (page: p, line: l)))
        .where((x) => x.line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return [];

    final delim = delimiter ?? _detectDelimiter(lines.first.line);
    if (delim == null) return [];

    var columns = _defaultOrder;
    var start = 0;
    final headerCells = _split(lines.first.line, delim);
    final mapped = _mapHeader(headerCells);
    if (mapped != null) {
      columns = mapped;
      start = 1;
    }

    final entries = <LedgerEntry>[];
    for (var i = start; i < lines.length; i++) {
      final cells = _split(lines[i].line, delim);
      final row = <String, String>{};
      for (var c = 0; c < cells.length && c < columns.length; c++) {
        row[columns[c]] = cells[c].trim();
      }
      final date = dateParser.parse(row['date'] ?? '');
      final debit = _amount(row['debit']);
      final credit = _amount(row['credit']);
      if (date == null || (debit == null && credit == null)) continue;

      entries.add(LedgerEntry(
        side: side,
        index: entries.length,
        date: date,
        documentNo: (row['docNo'] ?? '').isEmpty ? null : row['docNo'],
        description: row['description'] ?? '',
        debit: debit ?? 0,
        credit: credit ?? 0,
        balance: row['balance'] == null ? null : amountParser.parse(row['balance']!),
        source: EntrySource(
          page: lines[i].page.pageNumber,
          rawLine: lines[i].line,
          ocrConfidence: lines[i].page.ocrConfidence,
        ),
      ));
    }
    return entries;
  }

  int? _amount(String? raw) {
    if (raw == null || raw.isEmpty || raw == '-') return null;
    return amountParser.parse(raw)?.abs();
  }

  String? _detectDelimiter(String line) {
    for (final d in [';', '\t', ',', '|']) {
      if (line.split(d).length >= 4) return d;
    }
    return null;
  }

  /// Tırnak içindeki ayraçları korur.
  List<String> _split(String line, String delim) {
    final out = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == delim && !inQuotes) {
        out.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    out.add(buf.toString());
    return out;
  }

  List<String>? _mapHeader(List<String> cells) {
    final result = <String>[];
    var recognized = 0;
    for (final cell in cells) {
      final key = cell.trim().toLowerCase();
      String? field;
      for (final e in _headerAliases.entries) {
        if (e.value.contains(key)) {
          field = e.key;
          break;
        }
      }
      if (field != null) recognized++;
      result.add(field ?? 'ignore');
    }
    // En az tarih ve bir tutar sütunu tanınmadıysa başlık değildir.
    if (recognized < 2 || !result.contains('date')) return null;
    return result;
  }
}
