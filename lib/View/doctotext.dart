import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:get/get.dart';

import 'compFile.dart';

class DocToText extends StatefulWidget {
  const DocToText({super.key});

  @override
  State<DocToText> createState() => _DocToTextState();
}

class _DocToTextState extends State<DocToText> {
  List<String> extractedTextLines = [
    "PDF'den metin çıkarılıyor..."
  ]; // Satırlar için liste
  List<String> extractedTextLines2 = ["PDF'den metin çıkarılıyor..."];
  RxList<File> files = <File>[].obs;
  RxList<String> paths = <String>[].obs;

  @override
  void initState() {
    super.initState();
    files = Get.arguments as RxList<File>;
    paths.value = files.map((file) => file.path).toList().obs;
    _extractTextFromPdf();
  }

  Future<void> _extractTextFromPdf() async {
    Get.width;

    if (paths.isEmpty) {
      setState(() {
        extractedTextLines = ["Dosya yolu bulunamadı."];
        extractedTextLines2 = ["Dosya yolu bulunamadı."];
      });
      return;
    }

    try {
      // İlk dosyayı oku
      if (File(paths[0]).existsSync()) {
        PdfDocument document1 =
            PdfDocument(inputBytes: File(paths[0]).readAsBytesSync());
        String text1 = PdfTextExtractor(document1).extractText();
        document1.dispose();
        extractedTextLines = text1.split('\n'); // İlk dosyadan metni ayır
      } else {
        extractedTextLines = ["İlk dosya bulunamadı."];
      }

      // İkinci dosyayı oku (varsa)
      if (paths.length > 1 && File(paths[1]).existsSync()) {
        PdfDocument document2 =
            PdfDocument(inputBytes: File(paths[1]).readAsBytesSync());
        String text2 = PdfTextExtractor(document2).extractText();
        document2.dispose();
        extractedTextLines2 = text2.split('\n'); // İkinci dosyadan metni ayır
      } else {
        extractedTextLines2 = ["İkinci dosya bulunamadı."];
      }

      // Ekranı güncelle
      setState(() {});
    } catch (e) {
      setState(() {
        extractedTextLines = ["Hata oluştu: $e"];
        extractedTextLines2 = ["Hata oluştu: $e"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            paths.isNotEmpty ? 'PDF Metin Çıkarıcı' : 'Dosya Yolu Bulunamadı',
          ),
        ),
        body: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      paths.isNotEmpty
                          ? paths.first.split('\\').last
                          : 'Dosya Yolu Bulunamadı',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      itemCount: extractedTextLines.length, // Eleman sayısı
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            extractedTextLines[index], // Her satırı göster
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.5,
                            ),
                            toolbarOptions: const ToolbarOptions(
                              copy: true,
                              selectAll: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      paths.isNotEmpty
                          ? paths.last.split('\\').last
                          : 'Dosya Yolu Bulunamadı',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      itemCount: extractedTextLines2.length, // Eleman sayısı
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.teal[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            extractedTextLines2[index], // Her satırı göster
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.5,
                            ),
                            toolbarOptions: const ToolbarOptions(
                              copy: true,
                              selectAll: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          label: Text("Metin Karşılaştır"),
          icon: Icon(Icons.compare),
          isExtended: true,
          onPressed: () {
            Get.to(
              () => CompfilePage(
                title: 'Metin Karşılaştır',
              ),
              arguments: {
                'firstText': extractedTextLines
                    .join('\n'), // Metinleri tek bir string olarak gönder
                'secondText': extractedTextLines2.join('\n'),
                'firstFileName': paths.isNotEmpty
                    ? paths.first.split('\\').last
                    : 'Dosya Adı Bulunamadı',
                'secondFileName': paths.length > 1
                    ? paths.last.split('\\').last
                    : 'Dosya Adı Bulunamadı',
              },
            );
          },
        ));
  }
}
