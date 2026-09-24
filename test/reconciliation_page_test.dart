import 'package:comparatorr/View/reconciliation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mutabakat sayfası açılır ve OCR alanları anahtarla gelir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReconciliationPage()));

    expect(find.text('Mutabakat Yap'), findsOneWidget);
    expect(find.textContaining('Mutabakat Yap" düğmesine basın'), findsOneWidget);
    expect(find.text('tesseract yolu'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('tesseract yolu'), findsOneWidget);

    // Dosya seçilmeden çalıştırılırsa uyarı gösterir.
    await tester.tap(find.text('Mutabakat Yap'));
    await tester.pump();
    expect(find.text('Önce iki ekstre dosyası seçin.'), findsOneWidget);
  });
}
