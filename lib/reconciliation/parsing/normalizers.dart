/// Türkçe muhasebe belgelerinde görülen tutar ve tarih biçimlerini
/// normalize eden yardımcılar. Saf Dart; UI'a bağımlılığı yoktur.
class TrAmountParser {
  const TrAmountParser();

  /// "1.234,56", "1234,56", "1.234", "-1.234,56", "(1.234,56)", "1.234,56 TL",
  /// "₺1.234,56" gibi metinleri kuruş cinsinden tam sayıya çevirir.
  ///
  /// OCR'dan gelen yaygın hatalar için küçük düzeltmeler uygular:
  /// "O" -> "0", "l"/"I" -> "1". Ayrıştırılamıyorsa null döner.
  int? parse(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;

    var negative = false;
    if (s.startsWith('(') && s.endsWith(')')) {
      negative = true;
      s = s.substring(1, s.length - 1);
    }
    s = s
        .replaceAll(RegExp(r'[₺]|TL|TRY', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s'), '');
    if (s.startsWith('-')) {
      negative = !negative;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }

    // OCR düzeltmeleri: yalnızca sayısal bağlamda güvenli olanlar.
    s = s.replaceAll('O', '0').replaceAll('o', '0').replaceAll(RegExp(r'[lI]'), '1');

    if (!RegExp(r'^[\d.,]+$').hasMatch(s)) return null;

    int lira;
    int kurus;
    final commaIdx = s.lastIndexOf(',');
    final dotIdx = s.lastIndexOf('.');

    if (commaIdx >= 0 && commaIdx > dotIdx) {
      // Türkçe: virgül ondalık, nokta binlik.
      final intPart = s.substring(0, commaIdx).replaceAll('.', '');
      final fracPart = s.substring(commaIdx + 1);
      if (fracPart.length > 2 || fracPart.contains(',')) return null;
      lira = int.tryParse(intPart.isEmpty ? '0' : intPart) ?? -1;
      kurus = int.tryParse(fracPart.padRight(2, '0')) ?? -1;
    } else if (dotIdx >= 0 && commaIdx < 0 && s.length - dotIdx - 1 == 2 &&
        s.indexOf('.') == dotIdx) {
      // "1234.56": tek nokta ve iki ondalık basamak; İngilizce biçim varsay.
      lira = int.tryParse(s.substring(0, dotIdx)) ?? -1;
      kurus = int.tryParse(s.substring(dotIdx + 1)) ?? -1;
    } else {
      // Ondalık yok; nokta ve virgüller binlik ayracıdır.
      final intPart = s.replaceAll(RegExp(r'[.,]'), '');
      lira = int.tryParse(intPart) ?? -1;
      kurus = 0;
    }
    if (lira < 0 || kurus < 0) return null;

    final total = lira * 100 + kurus;
    return negative ? -total : total;
  }

  /// Kuruş cinsinden tutarı "1.234,56" biçiminde yazar.
  static String format(int kurus) {
    final negative = kurus < 0;
    final abs = kurus.abs();
    final lira = abs ~/ 100;
    final frac = (abs % 100).toString().padLeft(2, '0');
    final digits = lira.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return '${negative ? '-' : ''}$buf,$frac';
  }
}

class TrDateParser {
  const TrDateParser();

  static final _patterns = <RegExp>[
    // 01.02.2024, 01/02/2024, 01-02-2024
    RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})$'),
    // 01.02.24
    RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{2})$'),
  ];
  static final _iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Gün-ay-yıl sıralı Türkçe tarihleri ve ISO tarihleri ayrıştırır.
  /// Geçersiz tarih (ör. 31.02) için null döner.
  DateTime? parse(String raw) {
    final s = raw.trim();
    final iso = _iso.firstMatch(s);
    if (iso != null) {
      return _safe(int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!));
    }
    for (final p in _patterns) {
      final m = p.firstMatch(s);
      if (m == null) continue;
      final day = int.parse(m[1]!);
      final month = int.parse(m[2]!);
      var year = int.parse(m[3]!);
      if (year < 100) year += 2000;
      return _safe(year, month, day);
    }
    return null;
  }

  DateTime? _safe(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final dt = DateTime(y, m, d);
    // DateTime taşmayı sessizce düzeltir; 31.02 -> 02.03 olmasın.
    if (dt.month != m || dt.day != d) return null;
    return dt;
  }
}
