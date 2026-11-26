import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';
import '../../services/local_store.dart';
import 'checksheet_modals.dart';
import 'checksheet_paper.dart';

class ChecksheetScreen extends StatefulWidget {
  const ChecksheetScreen({
    super.key,
    this.initialDate,
    this.initialShift,
  });

  final String? initialDate;
  final String? initialShift;

  @override
  State<ChecksheetScreen> createState() => _ChecksheetScreenState();
}

class _ChecksheetScreenState extends State<ChecksheetScreen> {
  final _transformCtrl = TransformationController();
  final _paperBoundaryKey = GlobalKey();

  UbSettings _cfg = UbSettings();
  ChecksheetReport? _rep;
  ({String finish, String label})? _prevCarry;
  bool _loading = true;
  bool _syncing = false;
  bool _printing = false;
  double _currentScale = 0.45;

  @override
  void initState() {
    super.initState();
    _transformCtrl.addListener(_onMatrixChanged);
    _init();
  }

  @override
  void dispose() {
    _transformCtrl.removeListener(_onMatrixChanged);
    _transformCtrl.dispose();
    super.dispose();
  }

  void _onMatrixChanged() {
    final s = _transformCtrl.value.getMaxScaleOnAxis();
    if ((s - _currentScale).abs() > 0.01 && mounted) {
      setState(() => _currentScale = s);
    }
  }

  Future<void> _init() async {
    final cfg = await LocalStore.instance.getSettings();
    final dt = widget.initialDate ?? UbMasterData.wibToday();
    final sh = (widget.initialShift ?? (cfg.role == 'RED' ? 'RED' : 'WHITE')).toUpperCase();
    _cfg = cfg;
    await _loadReport(dt, sh == 'RED' ? 'RED' : 'WHITE');
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitWidth());
  }

  void _fitWidth() {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final targetScale = ((w - 20) / 950).clamp(0.32, 1.15);
    final dx = ((w - 950 * targetScale) / 2).clamp(0.0, double.infinity);
    _transformCtrl.value = Matrix4.identity()
      ..setTranslationRaw(dx, 12.0, 0.0)
      ..multiply(Matrix4.diagonal3Values(targetScale, targetScale, 1.0));
  }

  void _zoomBy(double delta) {
    final cur = _transformCtrl.value;
    final curScale = cur.getMaxScaleOnAxis();
    final nextScale = (curScale + delta).clamp(0.32, 2.2);
    final tx = cur.storage[12];
    final ty = cur.storage[13];
    _transformCtrl.value = Matrix4.identity()
      ..setTranslationRaw(tx, ty, 0.0)
      ..multiply(Matrix4.diagonal3Values(nextScale, nextScale, 1.0));
  }

  void _panBy(double dx, double dy) {
    final m = _transformCtrl.value.clone();
    m.storage[12] += dx;
    m.storage[13] += dy;
    _transformCtrl.value = m;
  }

  Future<void> _loadReport(String date, String shift) async {
    setState(() => _loading = true);
    final id = UbMasterData.makeReportId(date, shift, _cfg.lineName);
    final existing = await LocalStore.instance.getReport(id);
    final prev = await LocalStore.instance.findLatestPrevFinish(date, shift, false);

    ChecksheetReport loaded;
    if (existing != null) {
      loaded = existing;
    } else {
      final dtObj = DateTime.tryParse(date);
      final isFri = dtObj != null && dtObj.weekday == DateTime.friday;
      final tpl = isFri ? 'jumat_normal' : 'pagi_normal';
      final defCcr = shift == 'RED' ? _cfg.ccrTargetRed : _cfg.ccrTargetWhite;
      final autoStart = prev != null ? UbMasterData.addNumberPreservePad(prev.finish, 1) : '';
      final autoFin = (autoStart.isNotEmpty && defCcr > 0)
          ? UbMasterData.addNumberPreservePad(autoStart, defCcr - 1)
          : '';
      loaded = ChecksheetReport(
        id: id,
        tanggal: date,
        shift: shift,
        session: 'day',
        workMode: 'normal',
        templateCode: tpl,
        overtimeHours: 2,
        lineName: _cfg.lineName,
        taktTime: _cfg.taktTime,
        ccrPlan: defCcr,
        picName: shift == 'RED' ? 'KAMALUDIN' : 'DWI MULYONO',
        spvName: shift == 'RED' ? 'MASRURI / TRI RUSTIANTORO' : 'DADANG SURYADI / NUNU FATULAH',
        noBodyStart: autoStart,
        noBodyFinish: autoFin,
        cbuModels: UbMasterData.defaultCbuModels(),
        ckdParts: UbMasterData.defaultCkdParts(),
        members: UbMasterData.defaultMembers(shift),
        slots: UbMasterData.buildSlotsFromTemplate(tpl, _cfg.taktTime, 2),
      );
    }

    if (!mounted) return;
    setState(() {
      _rep = loaded;
      _prevCarry = prev;
      _loading = false;
    });
  }

  Future<void> _persistLocal({bool silent = false}) async {
    final rep = _rep;
    if (rep == null) return;
    if (!_cfg.canEditShift(rep.shift)) {
      _toast('Role ${_cfg.role} hanya dapat melihat shift ${rep.shift}', isErr: true);
      return;
    }
    if (rep.syncStatus == 'synced') rep.syncStatus = 'draft';
    await LocalStore.instance.saveReport(rep);
    if (!mounted) return;
    setState(() {});
    if (!silent) _toast('Tersimpan di penyimpanan lokal HP');
  }

  Future<void> _syncNow() async {
    final rep = _rep;
    if (rep == null || _syncing) return;
    if (!_cfg.canEditShift(rep.shift)) {
      _toast('Role ${_cfg.role} tidak diizinkan sync shift ${rep.shift}', isErr: true);
      return;
    }
    setState(() => _syncing = true);
    await _persistLocal(silent: true);
    final out = await LocalStore.instance.syncReportToServer(rep);
    if (!mounted) return;
    setState(() => _syncing = false);
    _toast(out.message, isErr: !out.ok);
  }

  Future<void> _printPdf() async {
    final rep = _rep;
    if (rep == null || _printing) return;
    setState(() => _printing = true);
    try {
      final boundary = _paperBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Kanvas belum siap dicetak');
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Gagal merender gambar kertas');
      final pngBytes = byteData.buffer.asUint8List();
      final memImage = pw.MemoryImage(pngBytes);

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (_) => pw.Center(
            child: pw.Image(memImage, fit: pw.BoxFit.contain),
          ),
        ),
      );
      await Printing.layoutPdf(
        name: 'Checksheet_${rep.tanggal}_${rep.shift}.pdf',
        onLayout: (_) async => doc.save(),
      );
    } catch (e) {
      _toast('Gagal cetak PDF: $e', isErr: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  void _shiftDate(int delta) {
    final rep = _rep;
    if (rep == null) return;
    final d = DateTime.tryParse(rep.tanggal) ?? DateTime.now();
    final next = d.add(Duration(days: delta));
    final iso = '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
    _loadReport(iso, rep.shift);
  }

  Future<void> _pickDate() async {
    final rep = _rep;
    if (rep == null) return;
    final cur = DateTime.tryParse(rep.tanggal) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final iso = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await _loadReport(iso, rep.shift);
    }
  }

  void _toast(String msg, {bool isErr = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isErr ? UbColors.rose : UbColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleTapSlot(int slotNo) async {
    final rep = _rep;
    if (rep == null) return;
    final idx = rep.slots.indexWhere((s) => s.no == slotNo);
    if (idx < 0) return;
    final unfilledPrev = rep.slots.where((r) => r.no < slotNo && !r.isBlocked && r.act == null).length;
    final res = await ChecksheetModals.showSlotModal(
      context,
      initialSlot: rep.slots[idx],
      taktTime: rep.taktTime,
      unfilledPrevCount: unfilledPrev,
    );
    if (res == null) return;

    final updated = res.slot;
    if (updated.problems.isNotEmpty) {
      updated.delayMin = double.parse(updated.problems.fold<double>(0, (a, p) => a + p.delayMin).toStringAsFixed(1));
      updated.lossUnits = updated.problems.fold<int>(0, (a, p) => a + p.lossUnits);
      updated.lineStation = updated.problems.first.lineStation;
      updated.problem = updated.problems.map((p) => p.problem).where((x) => x.isNotEmpty).join('; ');
      updated.countermeasure = updated.problems.map((p) => p.countermeasure).where((x) => x.isNotEmpty).join('; ');
    }

    rep.slots[idx] = updated;
    if (res.autoFillPrev && updated.act != null) {
      for (final r in rep.slots) {
        if (r.no < updated.no && !r.isBlocked && r.act == null) {
          r.act = r.plan;
        }
      }
    }
    final nextTotAct = rep.slots.fold<int>(0, (a, r) => a + (!r.isBlocked && r.act != null ? r.act! : 0));
    if (rep.cbuSource != 'manual') {
      rep.cbuModels = UbMasterData.calculateCbuByRatio(nextTotAct, rep.cbuModels);
    }

    if (res.syncNow) {
      await _syncNow();
    } else {
      await _persistLocal();
    }
  }

  Future<void> _handleAutoFillAll() async {
    final rep = _rep;
    if (rep == null) return;
    var filled = 0;
    for (final r in rep.slots) {
      if (!r.isBlocked && r.act == null) {
        r.act = r.plan;
        filled++;
      }
    }
    if (filled == 0) {
      _toast('Semua slot aktif sudah terisi!');
      return;
    }
    final nextTotAct = rep.slots.fold<int>(0, (a, r) => a + (!r.isBlocked && r.act != null ? r.act! : 0));
    if (rep.cbuSource != 'manual') {
      rep.cbuModels = UbMasterData.calculateCbuByRatio(nextTotAct, rep.cbuModels);
    }
    await _persistLocal();
  }

  @override
  Widget build(BuildContext context) {
    final rep = _rep;
    final stats = rep != null ? UbMasterData.computeStats(rep) : null;

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // TOP CONTROL BAR (IDENTIK UBNETWORK)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: UbColors.bg.withValues(alpha: 0.92),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => _shiftDate(-1),
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: UbColors.surface,
                        border: Border.all(color: UbColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rep != null ? UbMasterData.formatDDMMYYYY(rep.tanggal) : '-',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w800, color: UbColors.cyan),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shiftDate(1),
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  // Sync Status Dot
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rep?.syncStatus == 'synced'
                          ? UbColors.emerald
                          : (rep?.syncStatus == 'failed' ? UbColors.rose : UbColors.amber),
                    ),
                  ),
                  // Kirim (1x Sync)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: UbColors.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: _syncing ? null : _syncNow,
                    icon: _syncing
                        ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 14),
                    label: Text(_syncing ? '...' : 'Kirim', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: UbColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _printing ? null : _printPdf,
                    icon: _printing
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.print_rounded, size: 18),
                    tooltip: 'Cetak / Export PDF A4',
                  ),
                ],
              ),
            ),

            // INTERACTIVE A3 CANVAS
            Expanded(
              child: _loading || rep == null || stats == null
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
                        InteractiveViewer(
                          transformationController: _transformCtrl,
                          constrained: false,
                          boundaryMargin: const EdgeInsets.all(320),
                          minScale: 0.30,
                          maxScale: 2.20,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: RepaintBoundary(
                              key: _paperBoundaryKey,
                              child: ChecksheetPaper(
                                report: rep,
                                stats: stats,
                                onTapHeader: () async {
                                  final res = await ChecksheetModals.showHeaderModal(context, report: rep);
                                  if (res == null) return;
                                  final newShift = res['shift'] as String;
                                  if (newShift != rep.shift) {
                                    await _loadReport(rep.tanggal, newShift);
                                    return;
                                  }
                                  rep.session = res['session'] as String;
                                  rep.workMode = res['workMode'] as String;
                                  rep.templateCode = res['templateCode'] as String;
                                  rep.overtimeHours = res['overtimeHours'] as int;
                                  rep.otAwal = res['otAwal'] as String;
                                  rep.lineName = (res['lineName'] as String).isNotEmpty ? res['lineName'] as String : rep.lineName;
                                  rep.taktTime = res['taktTime'] as double;
                                  rep.picName = res['picName'] as String;
                                  rep.spvName = res['spvName'] as String;
                                  rep.slots = UbMasterData.buildSlotsFromTemplate(
                                    rep.templateCode,
                                    rep.taktTime,
                                    rep.overtimeHours,
                                    prevSlots: rep.slots,
                                    otAwalMode: rep.otAwal,
                                  );
                                  await _persistLocal();
                                },
                                onTapSlot: _handleTapSlot,
                                onAutoFillAll: _handleAutoFillAll,
                                onTapCbu: () async {
                                  final res = await ChecksheetModals.showCbuModal(
                                    context,
                                    initialModels: rep.cbuModels,
                                    initialSource: rep.cbuSource,
                                    totalAct: stats.totalAct,
                                    totalPlan: stats.totalPlan,
                                  );
                                  if (res == null) return;
                                  rep.cbuModels = res.models;
                                  rep.cbuSource = res.source;
                                  await _persistLocal();
                                },
                                onTapCkd: () async {
                                  final res = await ChecksheetModals.showCkdModal(context, initialParts: rep.ckdParts);
                                  if (res == null) return;
                                  rep.ckdParts = res;
                                  await _persistLocal();
                                },
                                onTapAbsen: () async {
                                  final res = await ChecksheetModals.showAbsenModal(
                                    context,
                                    shift: rep.shift,
                                    initialMembers: rep.members,
                                  );
                                  if (res == null) return;
                                  rep.members = res;
                                  await _persistLocal();
                                },
                                onTapNoBody: () async {
                                  final res = await ChecksheetModals.showNoBodyModal(
                                    context,
                                    start: rep.noBodyStart,
                                    finish: rep.noBodyFinish,
                                    jamStop: rep.jamStopProduksi,
                                    sysTime: stats.estimatedFinishTime,
                                    effectiveCcr: stats.effectiveCcrPlan,
                                    totalAct: stats.totalAct,
                                    prevCarry: _prevCarry,
                                  );
                                  if (res == null) return;
                                  rep.noBodyStart = res.start;
                                  rep.noBodyFinish = res.finish;
                                  rep.jamStopProduksi = res.jamStop;
                                  await _persistLocal();
                                },
                                onTapOvertime: () async {
                                  final res = await ChecksheetModals.showOvertimeModal(
                                    context,
                                    ccrPlan: stats.effectiveCcrPlan,
                                    otHours: rep.actOtHours,
                                  );
                                  if (res == null) return;
                                  rep.ccrPlan = res.ccrPlan;
                                  rep.actOtHours = res.otHours;
                                  rep.actOtUnits = (res.otHours * 32).round();
                                  rep.overtimeHours = res.otHours.ceil().clamp(0, 3);
                                  rep.slots = UbMasterData.buildSlotsFromTemplate(
                                    rep.templateCode,
                                    rep.taktTime,
                                    rep.overtimeHours,
                                    prevSlots: rep.slots,
                                    otAwalMode: rep.otAwal,
                                  );
                                  await _persistLocal();
                                },
                              ),
                            ),
                          ),
                        ),

                        // FLOATING SAVE BUTTON (BOTTOM LEFT)
                        Positioned(
                          left: 14,
                          bottom: 14,
                          child: InkWell(
                            onTap: () => _persistLocal(),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: UbColors.surface.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: UbColors.cyan.withValues(alpha: 0.45)),
                                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.storage_rounded, size: 17, color: UbColors.cyan),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Simpan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                                      Text(
                                        rep.syncStatus == 'synced' ? 'Tersinkron' : 'Draft Lokal',
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: UbColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // FLOATING ZOOM & D-PAD (BOTTOM RIGHT)
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: UbColors.surface.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: UbColors.border),
                              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18)],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: UbColors.bg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: UbColors.card),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _dpadBtn('−', () => _zoomBy(-0.15), bg: Colors.transparent),
                                      InkWell(
                                        onTap: _fitWidth,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(
                                            '${(_currentScale * 100).round()}%',
                                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.cyan),
                                          ),
                                        ),
                                      ),
                                      _dpadBtn('+', () => _zoomBy(0.15), bg: Colors.transparent),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _dpadBtn('▲', () => _panBy(0, 120)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _dpadBtn('◀', () => _panBy(120, 0)),
                                    const SizedBox(width: 4),
                                    _dpadBtn('⛶', _fitWidth, bg: UbColors.cyan.withValues(alpha: 0.2), fg: UbColors.cyan),
                                    const SizedBox(width: 4),
                                    _dpadBtn('▶', () => _panBy(-120, 0)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _dpadBtn('▼', () => _panBy(0, -120)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dpadBtn(String label, VoidCallback onTap, {Color? bg, Color? fg}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg ?? UbColors.card,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg ?? UbColors.textPrimary)),
        ),
      );
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = UbColors.cyan.withValues(alpha: 0.14);
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
