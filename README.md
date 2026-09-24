# Text Extract Comparator

The **Text Extract Comparator** is a powerful desktop application built with Flutter, designed to extract text from PDF documents and compare their contents. This tool enables users to easily analyze differences and similarities between multiple text sources, making it ideal for tasks such as document review, content verification, and textual analysis.

## Features

- **Text Extraction:** Efficiently extracts text from PDF files.
- **Content Comparison:** Compares extracted texts side by side for quick analysis.
- **User-Friendly Interface:** Intuitive UI for seamless navigation and interaction.
- **Cross-Platform Compatibility:** Works on Windows with a responsive design.

## Usage

To use the application, simply upload the PDF documents you wish to compare. The extracted text will be displayed in a clear format, allowing you to review any differences or similarities between the texts.

## Mutabakat (Cari Hesap Eşleştirme)

Uygulama artık iki cari hesap ekstresini **kayıt bazında** eşleştirip mutabakat raporu üretir.
Ana ekrandaki **"Mutabakat Yap"** düğmesi ile açılır.

### Desteklenen girdiler

| Tür | Uzantı | Nasıl okunur |
|-----|--------|--------------|
| Metin katmanlı PDF | `.pdf` | Doğrudan (Syncfusion) |
| Taranmış PDF / görüntü | `.pdf`, `.png`, `.jpg`, `.tif` | OCR (Tesseract + Poppler, aşağıya bakın) |
| Metin / CSV dışa aktarımı | `.txt`, `.csv`, `.tsv` | Doğrudan |

Sütun düzeni otomatik tanınır. Bilinen düzenler:

- `Tarih  Belge No  Açıklama  Borç  Alacak  [Bakiye]`
- `Tarih  Açıklama  Borç  Alacak  [Bakiye]`
- `Tarih  Açıklama  Belge No  Borç  Alacak  [Bakiye]`
- `Tarih  Belge No  Açıklama  Tutar  B/A`
- Başlıklı CSV (`;`, `,`, sekme veya `|` ayraçlı; sütun sırası başlıktan okunur)

Yeni bir düzen eklemek için `lib/reconciliation/parsing/templates.dart` dosyasına bir şablon eklemek yeterlidir.

### Eşleştirme kuralları (sırayla)

1. **Belge No** – belge numarası ve tutar birebir aynı, yönler zıt (bizde borç, karşıda alacak).
2. **Tutar + Tarih** – tutar aynı, tarih farkı tolerans içinde (varsayılan 5 gün). Birden fazla aday varsa en yakın tarih seçilir.
3. **Parçalı toplam** – bir taraftaki tek kayıt, diğer taraftaki en fazla N kaydın toplamı (varsayılan 3 parça, 45 gün pencere).
4. **Elle** – kalan kayıtları listelerden işaretleyip "Elle eşleştir" ile bağlayabilirsiniz. Yanlış eşleşmeler "Eşleşmeyi boz" ile geri alınır.

Rapor; eşleşenleri, yalnızca bir tarafta olan kayıtları, bakiye farkını ve OCR güveni düşük kayıtları gösterir. **TXT, CSV (Excel) ve PDF** olarak kaydedilebilir.

Denemek için `samples/` klasöründeki örnek ekstreleri seçebilirsiniz.

### OCR kurulumu (taranmış belgeler için)

OCR isteğe bağlıdır ve iki ücretsiz araca dayanır; belgeler makineden dışarı çıkmaz.

1. **Tesseract** – Windows için: <https://github.com/UB-Mannheim/tesseract/wiki>. Kurulumda **Turkish** dil paketini seçin (`tur`).
2. **Poppler** (`pdftoppm`) – Windows için: <https://github.com/oschwartz10612/poppler-windows/releases>. Arşivi açıp `Library\bin` klasörünü PATH'e ekleyin.

Uygulamada "Taranmış belgeler için OCR" anahtarını açın. Araçlar PATH'te değilse tam yollarını ilgili alanlara yazın
(ör. `C:\Program Files\Tesseract-OCR\tesseract.exe`).

### Geliştirici notları

Motor `lib/reconciliation/` altında, arayüzden bağımsız saf Dart'tır:

```
extraction/   belgeyi sayfa sayfa metne çevirir (metin katmanı, OCR, düz metin)
parsing/      satırları kayıtlara ayrıştırır (normalizasyon, şablonlar, CSV, otomatik seçim)
matching/     kural zinciri ve eşleştirme motoru
report/       metin, CSV ve PDF çıktıları
reconciliation_service.dart   tüm akışı ayrı bir isolate'te çalıştırır
```

Testler: `flutter test`

## Installation

To install the Text Extract Comparator application on your local machine, follow these steps:

1. Download the installer from the following link:
   [Download Text Extract Comparator](https://github.com/kuru0777/comparatorr/blob/main/installers/comparator.exe)

2. Once the download is complete, locate the downloaded file (`comparator.exe`) on your computer.

3. Double-click the installer to start the installation process.

4. Follow the on-screen instructions to complete the installation.

5. After installation, you can launch the application from your desktop or start menu.

Now you are ready to use the Text Extract Comparator!

---

Feel free to modify any part of it to better fit your project!
