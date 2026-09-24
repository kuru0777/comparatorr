import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../reconciliation/reconciliation.dart';

/// Mutabakat ekranı: iki ekstre seç, eşleştir, sonucu incele ve dışa aktar.
class ReconciliationPage extends StatefulWidget {
  const ReconciliationPage({super.key});

  @override
  State<ReconciliationPage> createState() => _ReconciliationPageState();
}

class _ReconciliationPageState extends State<ReconciliationPage> {
  String? _pathA;
  String? _pathB;

  final _toleranceCtrl = TextEditingController(text: '5');
  final _partsCtrl = TextEditingController(text: '3');
  bool _ocrEnabled = false;
  final _tesseractCtrl = TextEditingController(text: 'tesseract');
  final _pdftoppmCtrl = TextEditingController(text: 'pdftoppm');
  final _langCtrl = TextEditingController(text: 'tur');

  bool _running = false;
  ReconciliationResult? _result;
  ReconciliationReport? _report;

  final _selectedA = <LedgerEntry>{};
  final _selectedB = <LedgerEntry>{};

  String get _nameA => _result?.sideA.fileName ?? 'A';
  String get _nameB => _result?.sideB.fileName ?? 'B';

  @override
  void dispose() {
    _toleranceCtrl.dispose();
    _partsCtrl.dispose();
    _tesseractCtrl.dispose();
    _pdftoppmCtrl.dispose();
    _langCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(bool sideA) async {
    final res = await FilePicker.platform.pickFiles(
      dialogTitle: sideA ? 'Bizim ekstre (A)' : 'Karşı taraf ekstresi (B)',
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );
    final path = res?.files.single.path;
    if (path == null) return;
    setState(() {
      if (sideA) {
        _pathA = path;
      } else {
        _pathB = path;
      }
    });
  }

  Future<void> _run() async {
    final a = _pathA;
    final b = _pathB;
    if (a == null || b == null) {
      _snack('Önce iki ekstre dosyası seçin.');
      return;
    }
    final ocr = _ocrEnabled
        ? OcrConfig(
            tesseractPath: _tesseractCtrl.text.trim(),
            pdftoppmPath: _pdftoppmCtrl.text.trim(),
            language: _langCtrl.text.trim().isEmpty ? 'tur' : _langCtrl.text.trim(),
          )
        : null;
    if (ocr != null) {
      final missing = await CliOcrExtractor.checkTools(ocr);
      if (missing != null) {
        _snack('OCR araçları hazır değil: $missing');
        return;
      }
    }

    setState(() {
      _running = true;
      _result = null;
      _report = null;
      _selectedA.clear();
      _selectedB.clear();
    });
    try {
      final result = await const ReconciliationService().run(
        a,
        b,
        options: ReconciliationOptions(
          dateToleranceDays: int.tryParse(_toleranceCtrl.text) ?? 5,
          maxSumParts: int.tryParse(_partsCtrl.text) ?? 3,
          ocr: ocr,
        ),
      );
      setState(() {
        _result = result;
        _report = result.report;
      });
    } catch (e) {
      _snack('Mutabakat sırasında hata: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _manualMatch() {
    final r = _report;
    if (r == null || _selectedA.isEmpty || _selectedB.isEmpty) return;
    setState(() {
      _report = r.withManualMatch(_selectedA.toList(), _selectedB.toList());
      _selectedA.clear();
      _selectedB.clear();
    });
  }

  void _unmatch(Match m) {
    final r = _report;
    if (r == null) return;
    setState(() => _report = r.withoutMatch(m));
  }

  Future<void> _export(String kind) async {
    final r = _report;
    if (r == null) return;
    final ext = kind;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Raporu kaydet',
      fileName: 'mutabakat_raporu.$ext',
      type: FileType.custom,
      allowedExtensions: [ext],
    );
    if (path == null) return;
    final target = path.toLowerCase().endsWith('.$ext') ? path : '$path.$ext';
    try {
      switch (kind) {
        case 'txt':
          await File(target).writeAsString(
              const PlainTextReportFormatter().format(r, nameA: _nameA, nameB: _nameB));
        case 'csv':
          await File(target).writeAsString(
              const CsvReportExporter().export(r, nameA: _nameA, nameB: _nameB));
        case 'pdf':
          final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
          final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
          final bytes = await PdfReportExporter(
            regularFont: regular.buffer.asUint8List(),
            boldFont: bold.buffer.asUint8List(),
          ).export(r, nameA: _nameA, nameB: _nameB);
          await File(target).writeAsBytes(bytes);
      }
      _snack('Rapor kaydedildi: $target');
    } catch (e) {
      _snack('Kaydedilemedi: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutabakat'),
        actions: [
          if (_report != null) ...[
            TextButton.icon(
              onPressed: () => _export('txt'),
              icon: const Icon(Icons.description_outlined),
              label: const Text('TXT'),
            ),
            TextButton.icon(
              onPressed: () => _export('csv'),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('CSV'),
            ),
            TextButton.icon(
              onPressed: () => _export('pdf'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildInputs(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: (_selectedA.isNotEmpty && _selectedB.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: _manualMatch,
              icon: const Icon(Icons.link),
              label: Text('Elle eşleştir (${_selectedA.length} ↔ ${_selectedB.length})'),
            )
          : null,
    );
  }

  Widget _buildInputs() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fileRow('Bizim ekstre (A)', _pathA, () => _pick(true)),
          const SizedBox(height: 6),
          _fileRow('Karşı taraf ekstresi (B)', _pathB, () => _pick(false)),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _numberField('Tarih toleransı (gün)', _toleranceCtrl),
              _numberField('En fazla parça (toplam eşleşme)', _partsCtrl),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _ocrEnabled,
                    onChanged: (v) => setState(() => _ocrEnabled = v),
                  ),
                  const Text('Taranmış belgeler için OCR'),
                ],
              ),
              FilledButton.icon(
                onPressed: _running ? null : _run,
                icon: _running
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.compare_arrows),
                label: Text(_running ? 'Çalışıyor...' : 'Mutabakat Yap'),
              ),
            ],
          ),
          if (_ocrEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _textField('tesseract yolu', _tesseractCtrl, width: 260),
                  _textField('pdftoppm yolu', _pdftoppmCtrl, width: 260),
                  _textField('OCR dili', _langCtrl, width: 100),
                  const SizedBox(
                    width: 420,
                    child: Text(
                      'Tesseract (tur dil paketiyle) ve Poppler kurulu olmalı. '
                      'PATH\'te değilse tam yolu yazın.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _fileRow(String label, String? path, VoidCallback onPick) {
    final name = path == null ? 'Dosya seçilmedi' : path.split(RegExp(r'[\\/]')).last;
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _running ? null : onPick,
          icon: const Icon(Icons.folder_open),
          label: Text(label),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontStyle: path == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberField(String label, TextEditingController ctrl) {
    return SizedBox(
      width: 230,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _textField(String label, TextEditingController ctrl, {double width = 200}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildBody() {
    final result = _result;
    final report = _report;
    if (_running) {
      return const Center(child: CircularProgressIndicator());
    }
    if (result == null || report == null) {
      return const Center(
        child: Text('İki ekstre seçip "Mutabakat Yap" düğmesine basın.'),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          _summary(result, report),
          TabBar(
            tabs: [
              Tab(text: 'Eşleşenler (${report.matches.length})'),
              Tab(text: 'Yalnızca A (${report.unmatchedA.length})'),
              Tab(text: 'Yalnızca B (${report.unmatchedB.length})'),
              Tab(text: 'OCR kontrol (${report.needsReview.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _matchesList(report),
                _entryList(report.unmatchedA, _selectedA, selectable: true),
                _entryList(report.unmatchedB, _selectedB, selectable: true),
                _entryList(report.needsReview, {}, selectable: false, showConfidence: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(ReconciliationResult result, ReconciliationReport report) {
    final ok = report.isFullyReconciled;
    final color = ok ? Colors.green : Colors.orange;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ok ? Icons.check_circle : Icons.warning_amber, color: color),
                    const SizedBox(width: 8),
                    Text(
                      ok ? 'MUTABIK' : 'MUTABIK DEĞİL',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                    ),
                  ],
                ),
                Text('Bakiye farkı: ${TrAmountParser.format(report.balanceDifference)}'),
                Text('Yalnızca A toplamı: ${TrAmountParser.format(report.unmatchedTotalA)}'),
                Text('Yalnızca B toplamı: ${TrAmountParser.format(report.unmatchedTotalB)}'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'A: ${result.sideA.fileName} — ${result.sideA.pageCount} sayfa, '
              '${result.sideA.entries.length} kayıt (${result.sideA.parserName})    '
              'B: ${result.sideB.fileName} — ${result.sideB.pageCount} sayfa, '
              '${result.sideB.entries.length} kayıt (${result.sideB.parserName})',
              style: const TextStyle(fontSize: 12),
            ),
            for (final w in result.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Expanded(child: Text(w, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _matchesList(ReconciliationReport report) {
    if (report.matches.isEmpty) {
      return const Center(child: Text('Eşleşen kayıt yok.'));
    }
    return ListView.builder(
      itemCount: report.matches.length,
      itemBuilder: (context, i) {
        final m = report.matches[i];
        final conf = (m.confidence * 100).toStringAsFixed(0);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(_kindLabel(m.kind)), visualDensity: VisualDensity.compact),
                    const SizedBox(width: 8),
                    Text('%$conf'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          if (m.note != null) m.note!,
                          if (m.difference != 0) 'Fark: ${TrAmountParser.format(m.difference)}',
                        ].join('   '),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: m.difference != 0 ? Colors.red : null,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _unmatch(m),
                      icon: const Icon(Icons.link_off, size: 16),
                      label: const Text('Eşleşmeyi boz'),
                    ),
                  ],
                ),
                for (final e in m.entriesA) _entryLine('A', e),
                for (final e in m.entriesB) _entryLine('B', e),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _entryLine(String side, LedgerEntry e) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: Text(
        '$side  ${_date(e.date)}  ${e.documentNo ?? '-'}  ${_amount(e)}  ${e.description}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  Widget _entryList(
    List<LedgerEntry> entries,
    Set<LedgerEntry> selected, {
    required bool selectable,
    bool showConfidence = false,
  }) {
    if (entries.isEmpty) {
      return const Center(child: Text('Kayıt yok.'));
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        final subtitle = StringBuffer();
        if (e.documentNo != null) subtitle.write('Belge: ${e.documentNo}   ');
        if (e.source.page != null) subtitle.write('Sayfa ${e.source.page}   ');
        if (showConfidence && e.source.ocrConfidence != null) {
          subtitle.write('OCR güveni %${(e.source.ocrConfidence! * 100).toStringAsFixed(0)}');
        }
        return CheckboxListTile(
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          enabled: selectable,
          value: selected.contains(e),
          onChanged: selectable
              ? (v) => setState(() {
                    if (v == true) {
                      selected.add(e);
                    } else {
                      selected.remove(e);
                    }
                  })
              : null,
          title: Text('${_date(e.date)}   ${_amount(e)}   ${e.description}'),
          subtitle: subtitle.isEmpty ? null : Text(subtitle.toString()),
        );
      },
    );
  }

  static String _kindLabel(MatchKind k) => switch (k) {
        MatchKind.exactDocumentNo => 'Belge No',
        MatchKind.amountAndDate => 'Tutar + Tarih',
        MatchKind.sum => 'Parçalı toplam',
        MatchKind.manual => 'Elle',
      };

  static String _date(DateTime? d) => d == null
      ? '??.??.????'
      : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _amount(LedgerEntry e) => e.debit > 0
      ? 'B ${TrAmountParser.format(e.debit)}'
      : 'A ${TrAmountParser.format(e.credit)}';
}
