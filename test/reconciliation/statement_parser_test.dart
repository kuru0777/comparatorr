import 'package:comparatorr/reconciliation/models/ledger_entry.dart';
import 'package:comparatorr/reconciliation/parsing/statement_parser.dart';
import 'package:test/test.dart';

void main() {
  final parser = TemplateStatementParser(StatementTemplate.genericTr);

  test('genel Türkçe ekstre düzenini ayrıştırır', () {
    final pages = [
      PageText(pageNumber: 1, lines: [
        'CARİ HESAP EKSTRESİ',
        'Tarih       Belge No   Açıklama              Borç        Alacak      Bakiye',
        '-----------------------------------------------------------------------',
        '01.03.2024  FT-001     Satış faturası        1.250,00    -           1.250,00 B',
        '05.03.2024  DK-77      Havale                -           1.250,00    0,00',
        '10.03.2024  FT-002     Satış faturası        3.000,00    0,00        3.000,00 B',
        '            uzun açıklama devamı',
        'Genel Toplam                                4.250,00    1.250,00',
      ]),
    ];

    final entries = parser.parse(pages, LedgerSide.a);

    expect(entries.length, 3);
    expect(entries[0].date, DateTime(2024, 3, 1));
    expect(entries[0].documentNo, 'FT-001');
    expect(entries[0].debit, 125000);
    expect(entries[0].credit, 0);
    expect(entries[0].balance, 125000);
    expect(entries[0].source.page, 1);

    expect(entries[1].credit, 125000);
    expect(entries[1].balance, 0);

    expect(entries[2].description, 'Satış faturası uzun açıklama devamı');
    expect(entries[2].index, 2);
  });

  test('alacak bakiyesi negatif okunur', () {
    final pages = [
      PageText(pageNumber: 1, lines: [
        '01.03.2024  DK-1  Ödeme  -  500,00  500,00 A',
      ]),
    ];
    final entries = parser.parse(pages, LedgerSide.b);
    expect(entries.single.balance, -50000);
  });

  test('OCR güveni kayda taşınır', () {
    final pages = [
      PageText(
        pageNumber: 3,
        ocrConfidence: 0.6,
        lines: ['01.03.2024  X  Açıklama  10,00  -'],
      ),
    ];
    final entries = parser.parse(pages, LedgerSide.a);
    expect(entries.single.source.ocrConfidence, 0.6);
    expect(entries.single.source.needsReview, isTrue);
  });
}
