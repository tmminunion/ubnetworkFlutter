import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme.dart';

/// Kanvas Kertas Fisik Digital A3 Landscape berstandar i-Reporter UBnetwork:
/// 1. Bebas di-seret (Pan / Drag)
/// 2. Bebas di-zoom (Pinch 2 jari + Floating HUD [-], %, [+], [Fit], [100%])
/// 3. Interaktif langsung di atas kertas
/// 4. Cetak presisi A3 Landscape penuh tanpa margin & tanpa terpotong
class IReporterPaperCanvas extends StatefulWidget {
  const IReporterPaperCanvas({
    super.key,
    required this.paperBoundaryKey,
    required this.paperChild,
    this.paperWidth = 1420,
    this.paperMinHeight = 1004,
    this.dotColor = const Color(0xFF38BDF8),
  });

  final GlobalKey paperBoundaryKey;
  final Widget paperChild;
  final double paperWidth;
  final double paperMinHeight;
  final Color dotColor;

  static Future<void> printA3Landscape({
    required BuildContext context,
    required GlobalKey boundaryKey,
    required String fileName,
  }) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Kanvas kertas belum siap dicetak');
    }
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Gagal merender gambar kertas A3');
    }
    final pngBytes = byteData.buffer.asUint8List();
    final memImage = pw.MemoryImage(pngBytes);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a3.landscape,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.SizedBox.expand(
          child: pw.FittedBox(
            fit: pw.BoxFit.contain,
            child: pw.Image(memImage),
          ),
        ),
      ),
    );
    await Printing.layoutPdf(
      name: fileName,
      format: PdfPageFormat.a3.landscape,
      onLayout: (_) async => doc.save(),
    );
  }

  @override
  State<IReporterPaperCanvas> createState() => _IReporterPaperCanvasState();
}

class _IReporterPaperCanvasState extends State<IReporterPaperCanvas> {
  final TransformationController _ctrl = TransformationController();
  double _scale = 0.35;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onMatrixChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToScreen());
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onMatrixChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onMatrixChanged() {
    final s = _ctrl.value.getMaxScaleOnAxis();
    if ((s - _scale).abs() > 0.01 && mounted) {
      setState(() => _scale = s);
    }
  }

  void _fitToScreen() {
    if (!mounted) return;
    final viewW = MediaQuery.of(context).size.width;
    final targetScale = ((viewW - 24) / widget.paperWidth).clamp(0.24, 1.15);
    final dx = ((viewW - widget.paperWidth * targetScale) / 2).clamp(0.0, double.infinity);
    _ctrl.value = Matrix4.identity()
      ..setTranslationRaw(dx, 14.0, 0.0)
      ..multiply(Matrix4.diagonal3Values(targetScale, targetScale, 1.0));
  }

  void _reset100() {
    _ctrl.value = Matrix4.identity()..setTranslationRaw(16.0, 14.0, 0.0);
  }

  void _zoomBy(double delta) {
    final cur = _ctrl.value;
    final curScale = cur.getMaxScaleOnAxis();
    final nextScale = (curScale + delta).clamp(0.24, 2.20);
    final tx = cur.storage[12];
    final ty = cur.storage[13];
    _ctrl.value = Matrix4.identity()
      ..setTranslationRaw(tx, ty, 0.0)
      ..multiply(Matrix4.diagonal3Values(nextScale, nextScale, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_scale * 100).round();

    return Stack(
      children: [
        // Latar kanvas bertotol (dot-matrix pattern)
        Positioned.fill(
          child: CustomPaint(
            painter: _DotMatrixPainter(color: widget.dotColor.withValues(alpha: 0.22)),
          ),
        ),
        // Kanvas bebas Pan & Pinch-to-Zoom
        InteractiveViewer(
          transformationController: _ctrl,
          constrained: false,
          panEnabled: true,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(380),
          minScale: 0.24,
          maxScale: 2.20,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: widget.paperBoundaryKey,
              child: Container(
                width: widget.paperWidth,
                constraints: BoxConstraints(minHeight: widget.paperMinHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF334155), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.78),
                      blurRadius: 48,
                      spreadRadius: -8,
                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 11,
                    height: 1.3,
                  ),
                  child: widget.paperChild,
                ),
              ),
            ),
          ),
        ),
        // Floating HUD Kontrol Zoom ([-], %, [+], [Fit], [100%])
        Positioned(
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: UbColors.bg.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _hudBtn(
                  label: '-',
                  onTap: () => _zoomBy(-0.12),
                  tooltip: 'Perkecil',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$pct%',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: UbColors.cyan,
                    ),
                  ),
                ),
                _hudBtn(
                  label: '+',
                  onTap: () => _zoomBy(0.12),
                  tooltip: 'Perbesar',
                ),
                Container(
                  width: 1,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: Colors.white12,
                ),
                _hudBtn(
                  label: 'Fit',
                  onTap: _fitToScreen,
                  tooltip: 'Paskan ke Lebar Layar',
                ),
                const SizedBox(width: 4),
                _hudBtn(
                  label: '100%',
                  onTap: _reset100,
                  tooltip: 'Ukuran Asli 100%',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hudBtn({
    required String label,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  const _DotMatrixPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 22.0;
    for (double y = 10; y < size.height; y += step) {
      for (double x = 10; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.15, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotMatrixPainter oldDelegate) =>
      oldDelegate.color != color;
}
