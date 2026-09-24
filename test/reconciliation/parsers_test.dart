import 'package:comparatorr/reconciliation/extraction/cli_ocr_extractor.dart';
import 'package:comparatorr/reconciliation/models/ledger_entry.dart';
import 'package:comparatorr/reconciliation/parsing/auto_parser.dart';
import 'package:comparatorr/reconciliation/parsing/delimited_parser.dart';
import 'package:comparatorr/reconciliation/parsing/statement_parser.dart';
import 'package:comparatorr/reconciliation/parsing/templates.dart';
import 'package:test/test.dart';

PageText page(List<String> lines) => PageText(pageNumber: 1, lines: lines);

void main() {
  group('şablonlar', () {
    test('belge no sütunu olmayan düzen', () {
      final entries = TemplateStatementParser(StatementTemplates.withoutDocumentNo)
          .parse([page(['02.03.2024  Satış faturası  1.000,00  -  1.000,00 B'])], LedgerSide.a);
      expect(entries.single.documentNo, isNull);
      expect(entries.single.description, 'Satış faturası');
      expect(entries.single.debit, 100000);
    });

    test('belge no açıklamadan sonra', () {
      final entries = TemplateStatementParser(StatementTemplates.documentNoAfterDescription)
          .parse([page(['02.03.2024  Satış faturası  FT-1001  1.000,00  -'])], LedgerSide.a);
      expect(entries.single.documentNo, 'FT-1001');
      expect(entries.single.description, 'Satış faturası');
    });

    test('tek tutar sütunu ve yön harfi', () {
      final entries = TemplateStatementParser(StatementTemplates.singleAmountWithDirection)
          .parse([
        page([
          '02.03.2024  FT-1  Fatura  1.000,00  B',
          '03.03.2024  DK-2  Ödeme   1.000,00  A',
        ])
      ], LedgerSide.a);
      expect(entries.length, 2);
      expect(entries[0].debit, 100000);
      expect(entries[1].credit, 100000);
    });
  });

  group('DelimitedStatementParser', () {
    test('başlıktan sütun eşler, noktalı virgül', () {
      final entries = const DelimitedStatementParser().parse([
        page([
          'Açıklama;Tarih;Alacak;Borç;Belge No',
          '"Alış; iade";05.03.2024;250,00;;FT-9',
          'Ödeme;06.03.2024;;250,00;HV-1',
        ])
      ], LedgerSide.b);
      expect(entries.length, 2);
      expect(entries[0].description, 'Alış; iade');
      expect(entries[0].credit, 25000);
      expect(entries[0].documentNo, 'FT-9');
      expect(entries[1].debit, 25000);
    });

    test('başlık yoksa varsayılan sıra, sekme ayraçlı', () {
      final entries = const DelimitedStatementParser().parse([
        page(['05.03.2024\tFT-9\tAçıklama\t100,00\t\t100,00']),
      ], LedgerSide.b);
      expect(entries.single.debit, 10000);
      expect(entries.single.balance, 10000);
    });
  });

  group('AutoStatementParser', () {
    test('en çok kayıt üreten ayrıştırıcıyı seçer', () {
      final parser = AutoStatementParser();
      final entries = parser.parse([
        page([
          'Tarih;Belge No;Açıklama;Borç;Alacak',
          '01.03.2024;F1;a;10,00;',
          '02.03.2024;F2;b;;10,00',
        ])
      ], LedgerSide.a);
      expect(entries.length, 2);
      expect(parser.lastAttempt?.parserName, 'delimited');
    });

    test('sütunlu metin için şablon seçer', () {
      final parser = AutoStatementParser();
      parser.parse([
        page(['01.03.2024  FT-1  Fatura  10,00  -  10,00 B']),
      ], LedgerSide.a);
      expect(parser.lastAttempt?.parserName, 'generic-tr');
    });
  });

  group('CliOcrExtractor.parseTsv', () {
    test('kelimeleri satırlara gruplar ve güveni hesaplar', () {
      const tsv = 'level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n'
          '1\t1\t0\t0\t0\t0\t0\t0\t100\t100\t-1\t\n'
          '5\t1\t1\t1\t1\t1\t0\t0\t10\t10\t90\t01.03.2024\n'
          '5\t1\t1\t1\t1\t2\t0\t0\t10\t10\t80\tFT-1\n'
          '5\t1\t1\t1\t2\t1\t0\t0\t10\t10\t70\tSonraki\n';
      final page = CliOcrExtractor.parseTsv(tsv, pageNumber: 4);
      expect(page.pageNumber, 4);
      expect(page.lines, ['01.03.2024 FT-1', 'Sonraki']);
      expect(page.ocrConfidence, closeTo(0.8, 0.001));
    });
  });
}
