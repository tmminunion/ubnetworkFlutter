import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme.dart';
import '../../models/hr_morale_models.dart';
import '../../services/auth_service.dart';
import '../../services/hr_morale_store.dart';

/// Direct Full-Screen i-Reporter Digital Paper Canvas for `Matrik Baca Doa Asare`
/// 1:1 with `BacaDoaA4Viewer.tsx` (`1180 x 834` A4 Landscape) + Direct Cell Tap Interactivity + Zero-Margin PDF Export.
class BacaDoaScreen extends StatefulWidget {
  const BacaDoaScreen({super.key});

  @override
  State<BacaDoaScreen> createState() => _BacaDoaScreenState();
}

class _BacaDoaScreenState extends State<BacaDoaScreen> {
  static const double _paperWidth = 1180.0;
  static const double _paperHeight = 834.0;
  static const List<String> _monthNamesId = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  static const List<String> _dayInitials = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  final GlobalKey _paperBoundaryKey = GlobalKey();
  final TransformationController _tx = TransformationController();

  String _ym = hrTodayYmd().substring(0, 7);
  String _shift = 'RED';
  List<BacaDoaOperator> _operators = const [];
  String _glName = 'KAMALUDIN';
  List<String> _tlNames = const ['MASRURI', 'TRI RUSTIANTORO'];
  Map<int, BacaDoaAssignment> _records = const {};

  bool _loading = true;
  bool _printing = false;
  double _currentScale = 0.62;
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    final userShift = (AuthService.instance.currentUser?.shift ?? '').toUpperCase();
    if (userShift == 'WHITE' || userShift == 'RED') {
      _shift = userShift;
    }
    _load();
  }

  @override
  void dispose() {
    _tx.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      HrMoraleStore.instance.fetchShiftRoster(_shift),
      HrMoraleStore.instance.loadBacaDoa(_ym, _shift),
    ]);
    if (!mounted) return;
    final roster = results[0] as ({List<BacaDoaOperator> operators, String glName, List<String> tlNames, bool fromServer});
    final recs = results[1] as Map<int, BacaDoaAssignment>;

    setState(() {
      _operators = roster.operators;
      _glName = roster.glName;
      _tlNames = roster.tlNames;
      _records = recs;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitPaper());
  }

  void _fitPaper() {
    if (!mounted || _viewportSize.width <= 0 || _viewportSize.height <= 0) return;
    final padW = _viewportSize.width - 24;
    final padH = _viewportSize.height - 32;
    final fit = (padW / _paperWidth < padH / _paperHeight ? padW / _paperWidth : padH / _paperHeight)
        .clamp(0.28, 1.35);
    _applyZoomAndCenter(fit);
  }

  void _zoomBy(double delta) {
    _applyZoomAndCenter((_currentScale + delta).clamp(0.26, 2.6));
  }

  void _applyZoomAndCenter(double scale) {
    if (_viewportSize.width <= 0) return;
    final dx = (_viewportSize.width - _paperWidth * scale) / 2;
    final dy = ((_viewportSize.height - _paperHeight * scale) / 2).clamp(12.0, 220.0);
    final m = Matrix4.identity()
      ..setTranslationRaw(dx, dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0));
    setState(() {
      _currentScale = scale;
      _tx.value = m;
    });
  }

  void _shiftMonth(int delta) {
    final p = _ym.split('-');
    final d = DateTime(int.parse(p[0]), int.parse(p[1]) + delta, 1);
    setState(() => _ym = '${d.year}-${d.month.toString().padLeft(2, '0')}');
    _load();
  }

  Future<void> _persistRecords(Map<int, BacaDoaAssignment> next) async {
    setState(() => _records = next);
    await HrMoraleStore.instance.saveBacaDoa(
      _ym,
      _shift,
      next,
      glName: _glName,
      tlName: _tlNames.join(' / '),
    );
  }

  Future<void> _autoSchedule() async {
    final generated = BacaDoaEngine.generateTueToFriRotation(ym: _ym, operators: _operators);
    await _persistRecords(generated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rotasi otomatis Selasa–Jumat dibuat untuk ${generated.length} hari efektif!'),
        backgroundColor: UbColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Direct paper cell tap:
  /// - Empty cell -> Assign operator as `scheduled` (`○`)
  /// - `scheduled` for this operator -> Mark `done` (`●`)
  /// - `done` for this operator -> Clear assignment
  Future<void> _onTapMatrixCell(BacaDoaOperator op, int day) async {
    final dim = hrDaysInMonth(_ym);
    if (day > dim || BacaDoaEngine.isMonday(_ym, day) || BacaDoaEngine.isWeekend(_ym, day)) return;

    final next = Map<int, BacaDoaAssignment>.from(_records);
    final cur = next[day];
    if (cur == null || cur.memberId != op.id) {
      next[day] = BacaDoaAssignment(
        day: day,
        memberId: op.id,
        memberName: op.name,
        noreg: op.noreg,
        pos: op.pos,
        status: 'scheduled',
      );
    } else if (cur.status != 'done') {
      next[day] = cur.copyWith(status: 'done');
    } else {
      next.remove(day);
    }
    await _persistRecords(next);
  }

  Future<void> _openDayModal(int day) async {
    final dim = hrDaysInMonth(_ym);
    if (day > dim || _operators.isEmpty) return;

    final existing = _records[day];
    final validId = _operators.any((o) => o.id == existing?.memberId)
        ? existing!.memberId
        : _operators.first.id;
    var selectedMemberId = validId;
    var status = existing?.status ?? 'scheduled';
    final subCtrl = TextEditingController(text: existing?.substituteName ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final isMon = BacaDoaEngine.isMonday(_ym, day);

    try {
      final action = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setM) => Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Petugas Doa · $_ym-${day.toString().padLeft(2, '0')} (Shift $_shift)',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  if (isMon)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: UbColors.amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Hari Senin: BRIEFING MASAL Shopfloor (secara standar off giliran doa perorangan).',
                        style: TextStyle(fontSize: 11.5, color: UbColors.amber),
                      ),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedMemberId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Operator (TM)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _operators
                        .map((op) => DropdownMenuItem(value: op.id, child: Text('${op.name} (${op.noreg})')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setM(() => selectedMemberId = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Status Pelaksanaan',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'scheduled', child: Text('○ Terjadwal (Rencana)')),
                      DropdownMenuItem(value: 'done', child: Text('● Selesai Sesuai (Aktual TL)')),
                      DropdownMenuItem(value: 'replaced', child: Text('Digantikan (Substituted)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setM(() => status = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Pengganti (opsional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Briefing Asare',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (existing != null)
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, 'delete'),
                          child: const Text('Kosongkan', style: TextStyle(color: UbColors.rose)),
                        ),
                      const Spacer(),
                      OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg),
                        onPressed: () => Navigator.pop(ctx, 'save'),
                        child: const Text('Simpan Jadwal', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (action == 'delete') {
        final next = Map<int, BacaDoaAssignment>.from(_records)..remove(day);
        await _persistRecords(next);
      } else if (action == 'save') {
        final op = _operators.firstWhere((e) => e.id == selectedMemberId, orElse: () => _operators.first);
        final next = Map<int, BacaDoaAssignment>.from(_records);
        next[day] = BacaDoaAssignment(
          day: day,
          memberId: op.id,
          memberName: op.name,
          noreg: op.noreg,
          pos: op.pos,
          status: status,
          substituteName: subCtrl.text.trim(),
          note: noteCtrl.text.trim(),
        );
        await _persistRecords(next);
      }
    } finally {
      subCtrl.dispose();
      noteCtrl.dispose();
    }
  }

  Future<void> _openHistoryModal() async {
    final hist = await HrMoraleStore.instance.fetchBacaDoaHistory(shift: 'ALL');
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riwayat Arsip Matrik Baca Doa (Server)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 10),
            if (hist.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('Belum ada arsip riwayat bulan tersimpan di server.', style: TextStyle(fontSize: 12, color: UbColors.textMuted)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: hist.length,
                  itemBuilder: (_, idx) {
                    final h = hist[idx];
                    return ListTile(
                      dense: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _ym = h.ym;
                          if (h.shift == 'RED' || h.shift == 'WHITE') _shift = h.shift;
                        });
                        _load();
                      },
                      title: Text('${h.ym} · Shift ${h.shift}', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                      subtitle: Text('Terjadwal ${h.scheduledCount} hr · Aktual ● ${h.doneCount} hr', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: UbColors.cyan),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _printOrSharePdf({required bool share}) async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      final boundary = _paperBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final doc = pw.Document(title: 'Matrik-Baca-Doa-$_ym-$_shift');
      final memImg = pw.MemoryImage(pngBytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Center(child: pw.Image(memImg, fit: pw.BoxFit.contain)),
        ),
      );
      final pdfBytes = await doc.save();
      if (share) {
        await Printing.sharePdf(bytes: pdfBytes, filename: 'Matrik-Baca-Doa-$_ym-$_shift.pdf');
      } else {
        await Printing.layoutPdf(
          name: 'Matrik-Baca-Doa-$_ym-$_shift',
          format: PdfPageFormat.a4.landscape,
          onLayout: (_) async => pdfBytes,
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ymParts = _ym.split('-');
    final year = int.tryParse(ymParts[0]) ?? 2026;
    final month = (int.tryParse(ymParts.length > 1 ? ymParts[1] : '1') ?? 1).clamp(1, 12);
    final monthName = _monthNamesId[month - 1];

    return Scaffold(
      backgroundColor: const Color(0xFF070C17),
      body: SafeArea(
        child: Column(
          children: [
            // Compact Control Bar (Hidden in PDF Print)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Month Nav
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: UbColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _shiftMonth(-1),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.chevron_left_rounded, size: 18, color: UbColors.cyan),
                                  ),
                                ),
                                Text(
                                  '$monthName $year',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                                InkWell(
                                  onTap: () => _shiftMonth(1),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.chevron_right_rounded, size: 18, color: UbColors.cyan),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Shift Toggle
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: UbColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _shiftPill('RED', UbColors.rose, Colors.white),
                                _shiftPill('WHITE', Colors.white, UbColors.bg),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _loading ? null : _autoSchedule,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: UbColors.cyan,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 14, color: UbColors.bg),
                                  SizedBox(width: 4),
                                  Text('Rotasi Sel–Jum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.bg)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: _openHistoryModal,
                            icon: const Icon(Icons.history_rounded, size: 19, color: Colors.white70),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Riwayat Arsip Bulan',
                          ),
                          IconButton(
                            onPressed: _printing ? null : () => _printOrSharePdf(share: true),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: UbColors.emerald),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Share PDF A4',
                          ),
                          IconButton(
                            onPressed: _printing ? null : () => _printOrSharePdf(share: false),
                            icon: const Icon(Icons.print_rounded, size: 18, color: UbColors.cyan),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Cetak Printer A4',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Full-Screen i-Reporter Dot-Matrix Canvas + Interactive Physical Paper
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
                      Positioned.fill(child: CustomPaint(painter: _BacaDoaDotPainter())),

                      Positioned.fill(
                        child: InteractiveViewer(
                          transformationController: _tx,
                          constrained: false,
                          boundaryMargin: const EdgeInsets.all(600),
                          minScale: 0.26,
                          maxScale: 2.6,
                          onInteractionEnd: (_) {
                            final s = _tx.value.getMaxScaleOnAxis();
                            if ((s - _currentScale).abs() > 0.005) {
                              setState(() => _currentScale = s);
                            }
                          },
                          child: RepaintBoundary(
                            key: _paperBoundaryKey,
                            child: Container(
                              width: _paperWidth,
                              constraints: const BoxConstraints(minHeight: _paperHeight),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFF334155), width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xAA000000),
                                    blurRadius: 38,
                                    spreadRadius: 2,
                                    offset: Offset(0, 16),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: _buildA4MatrixSheet(year: year, monthName: monthName),
                            ),
                          ),
                        ),
                      ),

                      // Floating i-Reporter Zoom HUD Controls
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
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900, color: UbColors.cyan),
                              ),
                              const SizedBox(width: 4),
                              _hudBtn('+', () => _zoomBy(0.15)),
                              const SizedBox(width: 6),
                              _hudBtn('Fit', _fitPaper, accent: true),
                              const SizedBox(width: 4),
                              _hudBtn('100%', () => _applyZoomAndCenter(1.0)),
                            ],
                          ),
                        ),
                      ),

                      if (_loading)
                        Positioned.fill(
                          child: Container(
                            color: const Color(0xAA020617),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                              decoration: BoxDecoration(
                                color: UbColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: UbColors.cyan.withValues(alpha: 0.4)),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: UbColors.cyan),
                                  SizedBox(height: 10),
                                  Text(
                                    'Memuat Matrik Baca Doa & Roster Server...',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ],
                              ),
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

  Widget _shiftPill(String val, Color bg, Color fg) {
    final active = _shift == val;
    return InkWell(
      onTap: () {
        if (_shift == val) return;
        setState(() => _shift = val);
        _load();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? bg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          val,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? fg : Colors.white70),
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

  Widget _buildA4MatrixSheet({
    required int year,
    required String monthName,
  }) {
    final dim = hrDaysInMonth(_ym);
    var effectiveDays = 0;
    for (var d = 1; d <= dim; d++) {
      if (!BacaDoaEngine.isWeekend(_ym, d) && !BacaDoaEngine.isMonday(_ym, d)) {
        effectiveDays++;
      }
    }

    final memberCounts = <int, int>{};
    for (final r in _records.values) {
      memberCounts[r.memberId] = (memberCounts[r.memberId] ?? 0) + 1;
    }

    const numW = 28.0;
    const noregW = 68.0;
    const nameW = 166.0;
    const totW = 34.0;
    final dayW = (_paperWidth - 36 - numW - noregW - nameW - totW) / 31;

    return DefaultTextStyle(
      style: const TextStyle(color: Color(0xFF0F172A), fontFamily: 'sans-serif'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. OFFICIAL KPI HEADER (`HR` + `JADWAL PIMPIN SENAM DAN DOA BRIEFING`)
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFFACC15), width: 3.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'HR',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PT. TMMIN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('Underbody Assy', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE047),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF0F172A), width: 1.3),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'JADWAL PIMPIN SENAM DAN DOA BRIEFING',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: ['S', 'Q', 'P', 'C', 'HR', 'E'].map((c) {
                            final active = c == 'HR';
                            return Container(
                              margin: const EdgeInsets.only(left: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: active ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: active ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                c,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: active ? Colors.white : const Color(0xFF94A3B8),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _shift == 'RED' ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SHIFT $_shift',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${monthName.toUpperCase()} $year',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // 2. SUBHEADER METADATA BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'JUMLAH OPERATOR: ${_operators.length} TM (TL & GL Tidak Ditugaskan)',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                    ),
                    Text(
                      'HARI EFEKTIF BACA DOA: $effectiveDays Hari (Selasa s/d Jumat)',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE68A),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'SENIN: BRIEFING MASAL (OFF DOA)',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                      ),
                    ),
                    const Text(
                      'KETUK SEL LANGSUNG: ○ RENCANA ➔ ● SELESAI',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // 3. MATRIK TABLE 01..31
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0F172A), width: 1.6),
                ),
                child: Column(
                  children: [
                    // Table Header Row 1 + 2
                    Container(
                      color: const Color(0xFF1E293B),
                      child: Row(
                        children: [
                          _hdrCell('NO', numW, height: 34),
                          _hdrCell('NOREG', noregW, height: 34),
                          _hdrCell('NAMA OPERATOR (TM)', nameW, height: 34, alignLeft: true),
                          Column(
                            children: [
                              Container(
                                width: dayW * 31,
                                height: 15,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Color(0xFF475569), width: 0.8),
                                    right: BorderSide(color: Color(0xFF475569), width: 0.8),
                                  ),
                                ),
                                child: Text(
                                  'TANGGAL PIMPIN SENAM & DOA BRIEFING (01 S/D 31 ${monthName.toUpperCase()}) — KETUK ANGKA UNTUK DETAIL',
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ),
                              Row(
                                children: List.generate(31, (i) {
                                  final d = i + 1;
                                  final out = d > dim;
                                  final wd = out ? -1 : BacaDoaEngine.weekdayOf(_ym, d);
                                  final mon = !out && wd == DateTime.monday;
                                  final wk = !out && (wd == DateTime.saturday || wd == DateTime.sunday);
                                  final bg = out
                                      ? const Color(0xFFCBD5E1)
                                      : (mon
                                          ? const Color(0xFFFDE68A)
                                          : (wk ? const Color(0xFFFFE4E6) : const Color(0xFFF8FAFC)));
                                  final fg = out
                                      ? const Color(0xFF94A3B8)
                                      : (mon
                                          ? const Color(0xFF78350F)
                                          : (wk ? const Color(0xFF9F1239) : const Color(0xFF1E293B)));

                                  return InkWell(
                                    onTap: out ? null : () => _openDayModal(d),
                                    child: Container(
                                      width: dayW,
                                      height: 19,
                                      decoration: BoxDecoration(
                                        color: bg,
                                        border: const Border(
                                          right: BorderSide(color: Color(0xFFCBD5E1), width: 0.6),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('$d', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: fg, height: 1)),
                                          Text(
                                            out ? '-' : (mon ? 'Sen*' : _dayInitials[wd]),
                                            style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w800, color: fg, height: 1.05),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                          _hdrCell('TOT', totW, height: 34, isLast: true),
                        ],
                      ),
                    ),

                    // Operator Rows
                    ...List.generate(_operators.length, (idx) {
                      final m = _operators[idx];
                      final count = memberCounts[m.id] ?? 0;
                      final rowBg = idx.isOdd ? const Color(0xFFF8FAFC) : Colors.white;

                      return Container(
                        height: 22,
                        decoration: BoxDecoration(
                          color: rowBg,
                          border: const Border(top: BorderSide(color: Color(0xFFCBD5E1), width: 0.7)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: numW,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                border: Border(right: BorderSide(color: Color(0xFF94A3B8), width: 0.8)),
                              ),
                              child: Text('${idx + 1}', style: const TextStyle(fontFamily: 'monospace', fontSize: 8.5, fontWeight: FontWeight.w800)),
                            ),
                            Container(
                              width: noregW,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                border: Border(right: BorderSide(color: Color(0xFF94A3B8), width: 0.8)),
                              ),
                              child: Text(m.noreg.isEmpty ? '-' : m.noreg, style: const TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              width: nameW,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              alignment: Alignment.centerLeft,
                              decoration: const BoxDecoration(
                                border: Border(right: BorderSide(color: Color(0xFF94A3B8), width: 0.8)),
                              ),
                              child: Text(
                                m.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                            ...List.generate(31, (i) {
                              final d = i + 1;
                              final out = d > dim;
                              final wd = out ? -1 : BacaDoaEngine.weekdayOf(_ym, d);
                              final mon = !out && wd == DateTime.monday;
                              final wk = !out && (wd == DateTime.saturday || wd == DateTime.sunday);
                              final rec = _records[d];
                              final assigned = rec != null && rec.memberId == m.id;
                              final isDone = assigned && rec.status == 'done';

                              final cellBg = out
                                  ? const Color(0xFFE2E8F0)
                                  : (mon
                                      ? const Color(0xFFFFFBEB)
                                      : (wk ? const Color(0xFFFFF1F2) : Colors.transparent));

                              return InkWell(
                                onTap: (out || mon || wk) ? null : () => _onTapMatrixCell(m, d),
                                child: Container(
                                  width: dayW,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: cellBg,
                                    border: const Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 0.6)),
                                  ),
                                  child: assigned
                                      ? Container(
                                          width: 13,
                                          height: 13,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDone ? const Color(0xFF0F172A) : Colors.white,
                                            border: Border.all(color: const Color(0xFF0F172A), width: 1.6),
                                          ),
                                        )
                                      : (mon
                                          ? const Text('•', style: TextStyle(fontSize: 8, color: Color(0xFFF59E0B)))
                                          : null),
                                ),
                              );
                            }),
                            Container(
                              width: totW,
                              alignment: Alignment.center,
                              color: const Color(0xFFF1F5F9),
                              child: Text(
                                count > 0 ? '$count' : '-',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Bottom Daily Status Summary Row
                    Container(
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        border: Border(top: BorderSide(color: Color(0xFF0F172A), width: 1.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: numW + noregW + nameW,
                            padding: const EdgeInsets.only(right: 8),
                            alignment: Alignment.centerRight,
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: Color(0xFF0F172A), width: 1.0)),
                            ),
                            child: const Text(
                              'STATUS & PETUGAS HARIAN:',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                          ...List.generate(31, (i) {
                            final d = i + 1;
                            final out = d > dim;
                            final wd = out ? -1 : BacaDoaEngine.weekdayOf(_ym, d);
                            final mon = !out && wd == DateTime.monday;
                            final wk = !out && (wd == DateTime.saturday || wd == DateTime.sunday);
                            final rec = _records[d];

                            String txt = '';
                            Color fg = const Color(0xFF0F172A);
                            Color bg = const Color(0xFFF1F5F9);
                            if (out) {
                              bg = const Color(0xFFCBD5E1);
                            } else if (mon) {
                              txt = 'MASAL';
                              bg = const Color(0xFFFDE68A);
                              fg = const Color(0xFF78350F);
                            } else if (wk) {
                              txt = 'OFF';
                              bg = const Color(0xFFFFE4E6);
                              fg = const Color(0xFFBE123C);
                            } else if (rec != null && rec.memberName.isNotEmpty) {
                              final first = rec.memberName.split(' ').first;
                              txt = first.length > 3 ? first.substring(0, 3) : first;
                            } else {
                              txt = '-';
                              fg = const Color(0xFF94A3B8);
                            }

                            return InkWell(
                              onTap: out ? null : () => _openDayModal(d),
                              child: Container(
                                width: dayW,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: bg,
                                  border: const Border(right: BorderSide(color: Color(0xFFCBD5E1), width: 0.6)),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    txt,
                                    style: TextStyle(fontFamily: 'monospace', fontSize: 7, fontWeight: FontWeight.w900, color: fg),
                                  ),
                                ),
                              ),
                            );
                          }),
                          Container(
                            width: totW,
                            alignment: Alignment.center,
                            color: const Color(0xFFCBD5E1),
                            child: Text(
                              '${_records.length}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 4. FOOTER SOP & GL / TL APPROVAL STAMP BOX
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // SOP Box
                Container(
                  width: 520,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFF94A3B8)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STANDAR PROSEDUR BRIEFING PAGI (ASARE):',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '1. Hari SENIN: Seluruh regu mengikuti BRIEFING MASAL shopfloor (tidak ada giliran doa perorangan).\n'
                        '2. Hari SELASA s/d JUMAT: Petugas TM terpilih memimpin doa tepat pukul 07.15 WIB.\n'
                        '3. Simbol KPI: ○ = Jadwal Rencana · ● = Aktual Pimpin Sesuai (Verifikasi TL Daily Activity).',
                        style: TextStyle(fontSize: 8, height: 1.3, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),

                // Approval Stamp Table
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _stampCol('DISETUJUI (GL)', _glName, isLast: _tlNames.isEmpty),
                      ...List.generate(_tlNames.length, (i) {
                        return _stampCol('DIPERIKSA (TL)', _tlNames[i], isLast: i == _tlNames.length - 1);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hdrCell(String label, double width, {required double height, bool alignLeft = false, bool isLast = false}) {
    return Container(
      width: width,
      height: height,
      padding: alignLeft ? const EdgeInsets.symmetric(horizontal: 6) : EdgeInsets.zero,
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          right: isLast ? BorderSide.none : const BorderSide(color: Color(0xFF475569), width: 0.8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }

  Widget _stampCol(String roleTitle, String personName, {required bool isLast}) {
    return Container(
      width: 112,
      decoration: BoxDecoration(
        border: Border(
          right: isLast ? BorderSide.none : const BorderSide(color: Color(0xFF0F172A), width: 1.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            color: const Color(0xFFE2E8F0),
            alignment: Alignment.center,
            child: Text(roleTitle, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFF0F172A), width: 0.9)),
            ),
            alignment: Alignment.center,
            child: Text(
              personName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _BacaDoaDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    const step = 24.0;
    for (double y = 12; y < size.height; y += step) {
      for (double x = 12; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
