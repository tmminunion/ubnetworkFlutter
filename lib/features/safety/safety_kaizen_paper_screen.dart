import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme.dart';
import '../../models/safety_finding_models.dart';

/// Full-screen pinch-to-zoom lightbox for BEFORE / AFTER Safety photos.
void showSafetyPhotoLightbox(
  BuildContext context, {
  required String url,
  required String label,
  String caption = '',
  bool isAfter = false,
}) {
  final resolved = SafetyRiskMaster.resolveMediaUrl(url);
  if (resolved.isEmpty) return;

  showDialog<void>(
    context: context,
    barrierColor: const Color(0xEB020617),
    builder: (ctx) {
      final accent = isAfter ? UbColors.emerald : UbColors.rose;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.5,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      resolved,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: UbColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_outlined, size: 42, color: UbColors.textMuted),
                            SizedBox(height: 8),
                            Text('Gagal memuat gambar dari server', style: TextStyle(color: UbColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: isAfter ? UbColors.bg : Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.white12),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (caption.trim().isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: UbColors.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// i-Reporter Digital Paper Canvas for `KAIZEN REPORT · SAFETY`
/// 1:1 with `SafetyKaizenA4Viewer.tsx` + Toggleable Horizontal (Landscape A4) & Vertical (Portrait A4)
class SafetyKaizenPaperScreen extends StatefulWidget {
  const SafetyKaizenPaperScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    this.initialVertical = false,
    this.onEdit,
  });

  final List<SafetyFinding> items;
  final int initialIndex;
  final bool initialVertical;
  final Future<SafetyFinding?> Function(SafetyFinding item)? onEdit;

  @override
  State<SafetyKaizenPaperScreen> createState() => _SafetyKaizenPaperScreenState();
}

class _SafetyKaizenPaperScreenState extends State<SafetyKaizenPaperScreen> {
  static const List<String> _categories = ['S', 'Q', 'P', 'C', 'HR', 'E'];

  late List<SafetyFinding> _items;
  late int _index;
  late bool _isVertical;
  bool _exportingPdf = false;

  final TransformationController _tx = TransformationController();
  double _currentScale = 0.65;
  Size _viewportSize = Size.zero;

  double get _paperWidth => _isVertical ? 794.0 : 1123.0;
  double get _paperHeight => _isVertical ? 1123.0 : 794.0;

  SafetyFinding get _current => _items[_index.clamp(0, _items.length - 1)];

  @override
  void initState() {
    super.initState();
    _items = List<SafetyFinding>.from(widget.items);
    _index = widget.initialIndex.clamp(0, _items.isEmpty ? 0 : _items.length - 1);
    _isVertical = widget.initialVertical;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitPaper());
  }

  @override
  void dispose() {
    _tx.dispose();
    super.dispose();
  }

  void _fitPaper() {
    if (!mounted || _viewportSize.width <= 0 || _viewportSize.height <= 0) return;
    final padW = _viewportSize.width - 28;
    final padH = _viewportSize.height - 36;
    final fitScale = (padW / _paperWidth < padH / _paperHeight ? padW / _paperWidth : padH / _paperHeight)
        .clamp(0.24, 1.35);
    _applyZoomAndCenter(fitScale);
  }

  void _setExactScale(double target) {
    _applyZoomAndCenter(target.clamp(0.22, 2.8));
  }

  void _zoomBy(double delta) {
    final next = (_currentScale + delta).clamp(0.22, 2.8);
    _applyZoomAndCenter(next);
  }

  void _applyZoomAndCenter(double scale) {
    if (_viewportSize.width <= 0) return;
    final dx = (_viewportSize.width - _paperWidth * scale) / 2;
    final dy = ((_viewportSize.height - _paperHeight * scale) / 2).clamp(14.0, 240.0);
    final m = Matrix4.identity()
      ..setTranslationRaw(dx, dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0));
    setState(() {
      _currentScale = scale;
      _tx.value = m;
    });
  }

  void _toggleOrientation() {
    setState(() => _isVertical = !_isVertical);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitPaper());
  }

  Future<void> _handleEdit() async {
    if (widget.onEdit == null) return;
    final updated = await widget.onEdit!(_current);
    if (updated != null && mounted) {
      setState(() {
        _items[_index] = updated;
      });
    }
  }

  Future<Uint8List?> _fetchImageBytes(String rawUrl) async {
    final url = SafetyRiskMaster.resolveMediaUrl(rawUrl);
    if (url.isEmpty || !url.startsWith('http')) return null;
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (res.statusCode >= 200 && res.statusCode < 300 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  Future<Uint8List> _buildKaizenPdfBytes(SafetyFinding f) async {
    final results = await Future.wait([
      _fetchImageBytes(f.photo),
      _fetchImageBytes(f.photoAfter),
    ]);
    final beforeBytes = results[0];
    final afterBytes = results[1];

    final doc = pw.Document(
      title: 'Kaizen-Safety-${f.no.isEmpty ? "Report" : f.no}',
      author: 'PT. TMMIN Underbody Assy',
    );

    final format = _isVertical ? PdfPageFormat.a4 : PdfPageFormat.a4.landscape;
    final tag = SafetyRiskMaster.kaizenTag(f.no, 'S');
    final srcText = f.sources
        .where((i) => i >= 0 && i < SafetyRiskMaster.flatSources.length)
        .map((i) => SafetyRiskMaster.flatSources[i])
        .join(', ');
    final beforeSub =
        'Ditemukan ${f.foundAt.isEmpty ? "-" : f.foundAt} · ${SafetyRiskMaster.hazards[f.hazard]}${srcText.isNotEmpty ? " · $srcText" : ""}';
    final afterSub =
        'PIC: ${f.pic.isEmpty ? "-" : f.pic} · ${f.date.isEmpty ? "-" : f.date}${f.closedAt.isNotEmpty ? " · Selesai ${f.closedAt}" : ""}';

    pw.Widget pdfRankBox(SafetyRisk r, {required bool isAfter}) {
      final pt = r.totalPoints;
      final rk = r.effectiveRank.isEmpty ? '-' : r.effectiveRank;
      final borderCol = isAfter ? PdfColor.fromHex('#6EE7B7') : PdfColor.fromHex('#FCA5A5');
      final bgCol = isAfter ? PdfColor.fromHex('#ECFDF5') : PdfColor.fromHex('#FEF2F2');
      final fgCol = isAfter ? PdfColor.fromHex('#047857') : PdfColor.fromHex('#B91C1C');

      return pw.Container(
        width: 118,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: bgCol,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: borderCol, width: 1),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RISK RANK', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: fgCol)),
                pw.Text('Total ${pt ?? "-"} pt', style: pw.TextStyle(fontSize: 7, color: fgCol)),
              ],
            ),
            pw.Text(rk, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: fgCol)),
          ],
        ),
      );
    }

    pw.Widget pdfPanel({
      required String label,
      required Uint8List? imgBytes,
      required String caption,
      required String sub,
      required SafetyRisk risk,
      required bool isAfter,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromHex('#334155'), width: 1.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: isAfter ? PdfColor.fromHex('#ECFDF5') : PdfColor.fromHex('#FEF2F2'),
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColor.fromHex('#334155'), width: 1.2),
                ),
                child: pw.Text(
                  label,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: isAfter ? PdfColor.fromHex('#047857') : PdfColor.fromHex('#B91C1C'),
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Expanded(
              child: pw.Container(
                color: PdfColor.fromHex('#F1F5F9'),
                alignment: pw.Alignment.center,
                child: imgBytes != null
                    ? pw.Image(pw.MemoryImage(imgBytes), fit: pw.BoxFit.contain)
                    : pw.Text(
                        'FOTO $label',
                        style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#94A3B8'), fontWeight: pw.FontWeight.bold),
                      ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        caption.trim().isEmpty ? '-' : caption,
                        textAlign: pw.TextAlign.center,
                        maxLines: 3,
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A')),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        sub,
                        textAlign: pw.TextAlign.center,
                        maxLines: 1,
                        style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#64748B')),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pdfRankBox(risk, isAfter: isAfter),
              ],
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) {
          final beforePanel = pdfPanel(
            label: 'BEFORE',
            imgBytes: beforeBytes,
            caption: f.caption,
            sub: beforeSub,
            risk: f.before,
            isAfter: false,
          );
          final afterPanel = pdfPanel(
            label: 'AFTER',
            imgBytes: afterBytes,
            caption: f.cm.trim().isNotEmpty ? f.cm : f.standard,
            sub: afterSub,
            risk: f.after,
            isAfter: true,
          );

          return pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.all(18),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#F97316'), width: 3)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 44,
                        height: 44,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#16A34A'),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text('S', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PT. TMMIN', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B'))),
                          pw.Text('Underbody Assy', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#64748B'))),
                        ],
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Container(
                          height: 40,
                          alignment: pw.Alignment.center,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F97316'),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'KAIZEN REPORT · SAFETY',
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        SafetyRiskMaster.fyLabelOf(f.closedAt.isNotEmpty ? f.closedAt : f.foundAt),
                        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B')),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                // Metadata row
                pw.Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: pw.WrapCrossAlignment.center,
                  children: [
                    if (tag.isNotEmpty)
                      pw.Text(tag, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E'))),
                    pw.Text('NAMA: ${f.pic.isEmpty ? "GL BOARD" : f.pic}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('LINE: ${f.location.isEmpty ? "UB ASSY" : f.location}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('PROSES: ${f.process.isEmpty ? "-" : f.process}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      'BULAN: ${SafetyRiskMaster.formatBulanId(f.closedAt.isNotEmpty ? f.closedAt : f.foundAt)}',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                // THEMA
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColor.fromHex('#334155'), width: 1.5),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'THEMA : ${(f.theme.trim().isNotEmpty ? f.theme : f.caption).toUpperCase()}',
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A')),
                  ),
                ),
                pw.SizedBox(height: 8),
                // BEFORE vs AFTER
                pw.Expanded(
                  child: _isVertical
                      ? pw.Column(
                          children: [
                            pw.Expanded(child: beforePanel),
                            pw.SizedBox(height: 8),
                            pw.Expanded(child: afterPanel),
                          ],
                        )
                      : pw.Row(
                          children: [
                            pw.Expanded(child: beforePanel),
                            pw.SizedBox(width: 10),
                            pw.Expanded(child: afterPanel),
                          ],
                        ),
                ),
                pw.SizedBox(height: 8),
                // RESULT
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColor.fromHex('#334155'), width: 1.5),
                  ),
                  child: pw.Text(
                    'RESULT : ${f.result.trim().isNotEmpty ? f.result : (f.cm.trim().isNotEmpty ? f.cm : "-")}',
                    maxLines: 2,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  Future<void> _printPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final f = _current;
      final bytes = await _buildKaizenPdfBytes(f);
      final format = _isVertical ? PdfPageFormat.a4 : PdfPageFormat.a4.landscape;
      await Printing.layoutPdf(
        name: 'Kaizen-Safety-${f.no.isEmpty ? "Report" : f.no}',
        format: format,
        onLayout: (_) async => bytes,
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final f = _current;
      final bytes = await _buildKaizenPdfBytes(f);
      final cleanNo = (f.no.isEmpty ? 'Report' : f.no).replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Kaizen-Safety-$cleanNo.pdf',
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _current;
    final hasPrev = _index > 0;
    final hasNext = _index < _items.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF070C17),
      body: SafeArea(
        child: Column(
          children: [
            // Compact Top Control Bar (Hidden in PDF print)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: UbColors.bg.withValues(alpha: 0.95),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kaizen Safety #${f.no.isEmpty ? "-" : f.no}',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              Text(
                                _isVertical ? 'Kertas A4 Vertikal (Before–After)' : 'Kertas A4 Horizontal (1:1 Display)',
                                style: const TextStyle(fontSize: 10, color: UbColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Prev / Next Kaizen Navigation
                          IconButton(
                            onPressed: hasPrev ? () => setState(() => _index -= 1) : null,
                            icon: const Icon(Icons.chevron_left_rounded, size: 20),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Sebelumnya',
                          ),
                          Text(
                            '${_index + 1}/${_items.length}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white70),
                          ),
                          IconButton(
                            onPressed: hasNext ? () => setState(() => _index += 1) : null,
                            icon: const Icon(Icons.chevron_right_rounded, size: 20),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Berikutnya',
                          ),
                          const SizedBox(width: 4),
                          // Toggle Horizontal vs Vertikal
                          InkWell(
                            onTap: _toggleOrientation,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: UbColors.cyan.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: UbColors.cyan.withValues(alpha: 0.45)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isVertical ? Icons.stay_current_portrait_rounded : Icons.stay_current_landscape_rounded,
                                    size: 14,
                                    color: UbColors.cyan,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isVertical ? 'Vertikal' : 'Horizontal',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: UbColors.cyan),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (widget.onEdit != null) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _handleEdit,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: UbColors.emerald.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: UbColors.emerald.withValues(alpha: 0.45)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_rounded, size: 13.5, color: Color(0xFF6EE7B7)),
                                    SizedBox(width: 4),
                                    Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _exportingPdf ? null : _sharePdf,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: UbColors.emerald,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_exportingPdf ? Icons.hourglass_top_rounded : Icons.picture_as_pdf_rounded, size: 14, color: UbColors.bg),
                                  const SizedBox(width: 4),
                                  Text(
                                    _exportingPdf ? 'PDF...' : 'PDF',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.bg),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: _exportingPdf ? null : _printPdf,
                            icon: const Icon(Icons.print_rounded, size: 18, color: UbColors.cyan),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Cetak A4',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Full-Screen i-Reporter Dot-Matrix Canvas + Physical Paper
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final nextSize = Size(constraints.maxWidth, constraints.maxHeight);
                  if (_viewportSize != nextSize) {
                    _viewportSize = nextSize;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _fitPaper());
                  }

                  return Stack(
                    children: [
                      // Dot-matrix background
                      Positioned.fill(
                        child: CustomPaint(painter: _DotMatrixCanvasPainter()),
                      ),

                      // Interactive Pan & Pinch-to-Zoom Paper Stage
                      Positioned.fill(
                        child: InteractiveViewer(
                          transformationController: _tx,
                          constrained: false,
                          boundaryMargin: const EdgeInsets.all(650),
                          minScale: 0.22,
                          maxScale: 2.8,
                          onInteractionEnd: (_) {
                            final s = _tx.value.getMaxScaleOnAxis();
                            if ((s - _currentScale).abs() > 0.005) {
                              setState(() => _currentScale = s);
                            }
                          },
                          child: Container(
                            width: _paperWidth,
                            height: _paperHeight,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xAA000000),
                                  blurRadius: 38,
                                  spreadRadius: 2,
                                  offset: Offset(0, 16),
                                ),
                              ],
                            ),
                            child: _buildPhysicalPaperContent(f),
                          ),
                        ),
                      ),

                      // Floating i-Reporter Zoom HUD Controls (Bottom Right)
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: UbColors.surface.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _hudBtn('−', () => _zoomBy(-0.15)),
                              const SizedBox(width: 4),
                              Text(
                                '${(_currentScale * 100).round()}%',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: UbColors.cyan,
                                ),
                              ),
                              const SizedBox(width: 4),
                              _hudBtn('+', () => _zoomBy(0.15)),
                              const SizedBox(width: 6),
                              _hudBtn('Fit', _fitPaper, accent: true),
                              const SizedBox(width: 4),
                              _hudBtn('100%', () => _setExactScale(1.0)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudBtn(String text, VoidCallback onTap, {bool accent = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: accent ? UbColors.cyan.withValues(alpha: 0.2) : UbColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent ? UbColors.cyan.withValues(alpha: 0.5) : Colors.white12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: accent ? UbColors.cyan : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPhysicalPaperContent(SafetyFinding f) {
    final tag = SafetyRiskMaster.kaizenTag(f.no, 'S');
    final srcText = f.sources
        .where((i) => i >= 0 && i < SafetyRiskMaster.flatSources.length)
        .map((i) => SafetyRiskMaster.flatSources[i])
        .join(', ');
    final beforeSub =
        'Ditemukan ${f.foundAt.isEmpty ? "-" : f.foundAt} · ${SafetyRiskMaster.hazards[f.hazard]}${srcText.isNotEmpty ? " · $srcText" : ""}';
    final afterSub =
        'PIC: ${f.pic.isEmpty ? "-" : f.pic} · ${f.date.isEmpty ? "-" : f.date}${f.closedAt.isNotEmpty ? " · Selesai ${f.closedAt}" : ""}';

    final beforeWidget = _buildPaperBeforeAfterBox(
      label: 'BEFORE',
      photoUrl: f.resolvedPhoto,
      caption: f.caption.trim().isEmpty ? '(Uraian temuan belum diisi)' : f.caption,
      sub: beforeSub,
      risk: f.before,
      isAfter: false,
      findingNo: f.no,
    );

    final afterWidget = _buildPaperBeforeAfterBox(
      label: 'AFTER',
      photoUrl: f.resolvedPhotoAfter,
      caption: f.cm.trim().isNotEmpty
          ? f.cm
          : (f.standard.trim().isNotEmpty ? f.standard : '(Penanggulangan / Foto After belum diisi — Ketuk untuk isi)'),
      sub: afterSub,
      risk: f.after,
      isAfter: true,
      findingNo: f.no,
    );

    return Padding(
      padding: const EdgeInsets.all(22),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFF1E293B), fontFamily: 'sans-serif'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // OFFICIAL HEADER A4 (`PT. TMMIN Underbody Assy` · `KAIZEN REPORT · SAFETY` · `FY26`)
            Container(
              height: 68,
              padding: const EdgeInsets.only(bottom: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF97316), width: 3.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'S',
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('PT. TMMIN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1)),
                      Text('Underbody Assy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.15)),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'KAIZEN REPORT · SAFETY',
                          style: TextStyle(
                            fontSize: _isVertical ? 20 : 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Center(
                    child: Text(
                      SafetyRiskMaster.fyLabelOf(f.closedAt.isNotEmpty ? f.closedAt : f.foundAt),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // METADATA ROW (NAMA, LINE, PROSES, BULAN, KATEGORI S-Q-P-C-HR-E)
            Wrap(
              spacing: 16,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (tag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                        ),
                      ),
                    _metaSpan('NAMA:', f.pic.isEmpty ? 'GL BOARD' : f.pic),
                    _metaSpan('LINE:', f.location.isEmpty ? 'UB ASSY' : f.location),
                    _metaSpan('PROSES:', f.process.isEmpty ? '-' : f.process),
                    _metaSpan('BULAN:', SafetyRiskMaster.formatBulanId(f.closedAt.isNotEmpty ? f.closedAt : f.foundAt)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('KATEGORI ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(width: 4),
                    ..._categories.map((c) {
                      final active = c == 'S';
                      return Container(
                        margin: const EdgeInsets.only(left: 4),
                        constraints: const BoxConstraints(minWidth: 22),
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF16A34A) : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: active ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: active ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // THEMA BOX (Interactive — tap to edit Kaizen)
            InkWell(
              onTap: widget.onEdit != null ? _handleEdit : null,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  'THEMA : ${(f.theme.trim().isNotEmpty ? f.theme : f.caption).toUpperCase()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.15),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // BEFORE vs AFTER PANELS (Side-by-side when Horizontal, Top-Bottom when Vertical)
            Expanded(
              child: _isVertical
                  ? Column(
                      children: [
                        Expanded(child: beforeWidget),
                        const SizedBox(height: 14),
                        Expanded(child: afterWidget),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: beforeWidget),
                        const SizedBox(width: 14),
                        Expanded(child: afterWidget),
                      ],
                    ),
            ),
            const SizedBox(height: 10),

            // RESULT FOOTER BOX (Interactive — tap to edit Kaizen)
            InkWell(
              onTap: widget.onEdit != null ? _handleEdit : null,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155), width: 2),
                ),
                alignment: Alignment.centerLeft,
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.25),
                    children: [
                      const TextSpan(
                        text: 'RESULT',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: ' : ${f.result.trim().isNotEmpty ? f.result : (f.cm.trim().isNotEmpty ? f.cm : "-")}'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaSpan(String key, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
        children: [
          TextSpan(text: '$key ', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildPaperBeforeAfterBox({
    required String label,
    required String photoUrl,
    required String caption,
    required String sub,
    required SafetyRisk risk,
    required bool isAfter,
    required String findingNo,
  }) {
    final rankText = risk.effectiveRank.isEmpty ? '-' : risk.effectiveRank;
    final pt = risk.totalPoints;
    final rankBorder = isAfter ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5);
    final rankBg = isAfter ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final rankFg = isAfter ? const Color(0xFF047857) : const Color(0xFFB91C1C);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155), width: 2),
            ),
            child: Column(
              children: [
                // Photo Frame
                Expanded(
                  child: InkWell(
                    onTap: photoUrl.isNotEmpty
                        ? () => showSafetyPhotoLightbox(
                              context,
                              url: photoUrl,
                              label: '$label · #$findingNo',
                              caption: caption,
                              isAfter: isAfter,
                            )
                        : (widget.onEdit != null ? _handleEdit : null),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.2),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.broken_image_outlined, size: 28, color: Color(0xFF94A3B8)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'FOTO $label TIDAK TERSEDIA',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAfter ? Icons.add_photo_alternate_outlined : Icons.image_outlined,
                                    size: 32,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAfter ? 'BELUM ADA FOTO AFTER' : 'FOTO BEFORE',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bottom Caption + Risk Rank Box
                InkWell(
                  onTap: widget.onEdit != null ? _handleEdit : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              caption,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.2),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 148,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: rankBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rankBorder, width: 1.3),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('RISK RANK', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: rankFg)),
                                Text('Total ${pt ?? "-"} pt', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: rankFg)),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              rankText,
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: rankFg, height: 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Top Center Label (`BEFORE` / `AFTER`)
        Positioned(
          top: -11,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              decoration: BoxDecoration(
                color: isAfter ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF334155), width: 2),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: rankFg,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotMatrixCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    const step = 22.0;
    for (double y = 10; y < size.height; y += step) {
      for (double x = 10; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.15, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
