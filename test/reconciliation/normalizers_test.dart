import 'package:comparatorr/reconciliation/parsing/normalizers.dart';
import 'package:test/test.dart';

void main() {
  const amounts = TrAmountParser();
  const dates = TrDateParser();

  group('TrAmountParser', () {
    test('Türkçe biçim', () {
      expect(amounts.parse('1.234,56'), 123456);
      expect(amounts.parse('1234,5'), 123450);
      expect(amounts.parse('0,99'), 99);
      expect(amounts.parse('12.345.678,00'), 1234567800);
    });

    test('ondalıksız', () {
      expect(amounts.parse('1.234'), 123400);
      expect(amounts.parse('1234'), 123400);
    });

    test('para birimi ve işaret', () {
      expect(amounts.parse('1.234,56 TL'), 123456);
      expect(amounts.parse('₺1.234,56'), 123456);
      expect(amounts.parse('-1.234,56'), -123456);
      expect(amounts.parse('(1.234,56)'), -123456);
    });

    test('İngilizce ondalık', () {
      expect(amounts.parse('1234.56'), 123456);
    });

    test('OCR karakter düzeltmesi', () {
      expect(amounts.parse('1.O34,5l'), 103451);
    });

    test('geçersiz', () {
      expect(amounts.parse('abc'), isNull);
      expect(amounts.parse(''), isNull);
      expect(amounts.parse('1,234,56'), isNull);
    });

    test('format', () {
      expect(TrAmountParser.format(123456), '1.234,56');
      expect(TrAmountParser.format(-5), '-0,05');
      expect(TrAmountParser.format(1234567800), '12.345.678,00');
    });
  });

  group('TrDateParser', () {
    test('gün.ay.yıl', () {
      expect(dates.parse('05.03.2024'), DateTime(2024, 3, 5));
      expect(dates.parse('5/3/2024'), DateTime(2024, 3, 5));
      expect(dates.parse('05-03-24'), DateTime(2024, 3, 5));
    });

    test('ISO', () {
      expect(dates.parse('2024-03-05'), DateTime(2024, 3, 5));
    });

    test('geçersiz tarih', () {
      expect(dates.parse('31.02.2024'), isNull);
      expect(dates.parse('bugün'), isNull);
    });
  });
}
