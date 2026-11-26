import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';
import '../../services/auth_service.dart';
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
  late ChecksheetReport _rep;
  List<ShiftTemplate> _templates = UbMasterData.masterTemplates;
  ({String finish, String label})? _prevCarry;

  bool _fetchingOnline = true;
  bool _hasLoadedInitialServer = false;
  bool _isOnline = true;
  bool _foundInServer = false;
  bool _syncing = false;
  bool _printing = false;
  double _currentScale = 0.45;
  int _loadSeq = 0;
  String _loadingStepText = 'Sinkronisasi parameter lini & laporan MySQL...';
  String _loadingTargetDate = '';
  String _loadingTargetShift = '';

  @override
  void initState() {
    super.initState();
    _transformCtrl.addListener(_onMatrixChanged);

    final userShift = (AuthService.instance.currentUser?.shift ?? '').toUpperCase();
    final initDate = widget.initialDate ?? UbMasterData.wibToday();
    final initShift = (widget.initialShift ??
            (userShift == 'RED' || userShift == 'WHITE' ? userShift : 'WHITE'))
        .toUpperCase();
    final cleanShift = initShift == 'RED' ? 'RED' : 'WHITE';
    _loadingTargetDate = initDate;
    _loadingTargetShift = cleanShift;
    _rep = UbMasterData.createTemplateReport(
      date: initDate,
      shift: cleanShift,
      cfg: _cfg,
      sessionOverride: UbMasterData.rotationSessionForShift(initDate, cleanShift),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _fitWidth());
    _bootstrapOnline(initDate, cleanShift);
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

  Future<void> _bootstrapOnline(String date, String shift) async {
    final cfg = await LocalStore.instance.getSettings();
    final cachedTpls = await LocalStore.instance.getCachedTemplates();
    if (!mounted) return;
    _cfg = cfg;
    _templates = cachedTpls;

    final userShift = (AuthService.instance.currentUser?.shift ?? '').toUpperCase();
    final resolvedShift = widget.initialShift != null
        ? shift
        : (userShift == 'RED' || userShift == 'WHITE'
            ? userShift
            : (cfg.role == 'RED' ? 'RED' : 'WHITE'));

    await _loadReport(date, resolvedShift);
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

  /// Alur 1:1 Next.js (`isLoadingMySQL`):
  /// Buka -> Tampilkan Modal Loading & Kunci Input -> Ambil Data dari Server MySQL -> Tampilkan Checksheet!
  Future<void> _loadReport(
    String date,
    String shift, {
    String? sessionOverride,
    String? templateOverride,
    bool forceRefreshFromServer = false,
  }) async {
    final normShift = shift.toUpperCase() == 'RED' ? 'RED' : 'WHITE';
    final seq = ++_loadSeq;

    setState(() {
      _fetchingOnline = true;
      _loadingTargetDate = date;
      _loadingTargetShift = normShift;
      _loadingStepText = 'Menghubungkan ke server UBnetwork...';
    });

    final res = await LocalStore.instance.loadOrCreateReportForDateShift(
      date: date,
      shift: normShift,
      sessionOverride: sessionOverride,
      templateOverride: templateOverride,
      forceRefreshFromServer: forceRefreshFromServer,
      onProgress: (step) {
        if (mounted && seq == _loadSeq) {
          setState(() => _loadingStepText = step);
        }
      },
    );

    if (!mounted || seq != _loadSeq) return;
    final updatedCfg = await LocalStore.instance.getSettings();
    if (!mounted || seq != _loadSeq) return;

    final firstLoad = !_hasLoadedInitialServer;
    setState(() {
      _cfg = updatedCfg;
      _templates = res.templates;
      _rep = res.report;
      _prevCarry = res.prevCarry;
      _isOnline = res.online;
      _foundInServer = res.foundInServer;
      _fetchingOnline = false;
      _hasLoadedInitialServer = true;
    });

    if (firstLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitWidth());
    }

    if (!res.online) {
      _toast(res.message, isErr: true);
    } else if (res.unsyncedLocalDraft != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${res.message}. Ada draft lokal belum terkirim.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: UbColors.surface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Pulihkan Draft',
              textColor: UbColors.cyan,
              onPressed: () {
                if (!mounted) return;
                setState(() {
                  _rep = res.unsyncedLocalDraft!;
                  _foundInServer = false;
                });
              },
            ),
          ),
        );
    } else if (forceRefreshFromServer || res.foundInServer) {
      _toast(res.message);
    }
  }

  Future<void> _persistLocal({bool silent = false}) async {
    final rep = _rep;
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
    if (_syncing) return;
    if (!_cfg.canEditShift(rep.shift)) {
      _toast('Role ${_cfg.role} tidak diizinkan sync shift ${rep.shift}', isErr: true);
      return;
    }
    setState(() => _syncing = true);
    await _persistLocal(silent: true);
    final out = await LocalStore.instance.syncReportToServer(rep);
    if (!mounted) return;
    setState(() {
      _syncing = false;
      if (out.ok) {
        _isOnline = true;
        _foundInServer = true;
      }
    });
    _toast(out.message, isErr: !out.ok);
  }

  Future<void> _printPdf() async {
    final rep = _rep;
    if (_printing) return;
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
          pageFormat: PdfPageFormat.a3.landscape,
          margin: pw.EdgeInsets.zero,
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
    final d = DateTime.tryParse(_rep.tanggal) ?? DateTime.now();
    final next = d.add(Duration(days: delta));
    final iso = '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
    _loadReport(iso, _rep.shift);
  }

  Future<void> _pickDate() async {
    final cur = DateTime.tryParse(_rep.tanggal) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final iso = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await _loadReport(iso, _rep.shift);
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
      final intSum = updated.problems.where((p) => p.category == 'INT').fold<double>(0, (a, p) => a + p.delayMin);
      final extSum = updated.problems.where((p) => p.category == 'EXT').fold<double>(0, (a, p) => a + p.delayMin);
      updated.delayCategory = intSum >= extSum ? 'INT' : 'EXT';
    } else if (updated.isBlocked) {
      updated.act = null;
      updated.plan = 0;
      updated.problem = '';
      updated.countermeasure = '';
      updated.delayMin = 0;
      updated.lossUnits = 0;
    }

    rep.slots[idx] = updated;
    if (res.autoFillPrev && updated.act != null) {
      for (final r in rep.slots) {
        if (r.no < updated.no && !r.isBlocked && r.act == null) {
          r.act = r.plan;
        }
      }
    }

    // Sinkronkan jumlah slot lembur akhir aktif (1:1 Next.js)
    final activeOtCount = rep.slots.where((r) => (r.isOvertime || r.no >= 9) && !r.isBlocked && !r.isEarlyOvertime).length;
    rep.overtimeHours = activeOtCount;

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
    final stats = UbMasterData.computeStats(rep);
    final todayIso = UbMasterData.wibToday();
    final isToday = rep.tanggal == todayIso;

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // TOP CONTROL BAR (1:1 UBNETWORK NEXT.JS — COMPACT & RESPONSIVE)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: UbColors.bg.withValues(alpha: 0.94),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 19),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () => _shiftDate(-1),
                    icon: const Icon(Icons.chevron_left_rounded, size: 19),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
                  ),
                  InkWell(
                    onTap: _pickDate,
                    onLongPress: isToday ? null : () => _loadReport(todayIso, rep.shift),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: UbColors.surface,
                        border: Border.all(color: isToday ? UbColors.cyan.withValues(alpha: 0.55) : UbColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        UbMasterData.formatDDMMYYYY(rep.tanggal),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: UbColors.cyan,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shiftDate(1),
                    icon: const Icon(Icons.chevron_right_rounded, size: 19),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
                  ),
                  if (!isToday)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: InkWell(
                        onTap: () => _loadReport(todayIso, rep.shift),
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: UbColors.cyan.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: UbColors.cyan.withValues(alpha: 0.45)),
                          ),
                          child: const Text(
                            'Hari Ini',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: UbColors.cyan),
                          ),
                        ),
                      ),
                    ),
                  // Shift Toggle (RED / WHITE)
                  InkWell(
                    onTap: () {
                      final nextShift = rep.shift == 'RED' ? 'WHITE' : 'RED';
                      _loadReport(rep.tanggal, nextShift);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      decoration: BoxDecoration(
                        color: rep.shift == 'RED'
                            ? UbColors.rose.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: rep.shift == 'RED'
                              ? UbColors.rose.withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        rep.shift,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: rep.shift == 'RED' ? const Color(0xFFFDA4AF) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Day / Night Session Quick Toggle (☀️D / 🌙N)
                  InkWell(
                    onTap: _fetchingOnline
                        ? null
                        : () {
                            final nextSess = rep.session == 'night' ? 'day' : 'night';
                            final nextTpl = UbMasterData.defaultTemplateCode(
                              rep.tanggal,
                              session: nextSess,
                              workMode: rep.workMode,
                            );
                            _loadReport(
                              rep.tanggal,
                              rep.shift,
                              sessionOverride: nextSess,
                              templateOverride: nextTpl,
                            );
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      decoration: BoxDecoration(
                        color: rep.session == 'night'
                            ? const Color(0xFF1E293B)
                            : UbColors.amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: rep.session == 'night'
                              ? Colors.white.withValues(alpha: 0.25)
                              : UbColors.amber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        rep.session == 'night' ? '🌙N' : '☀️D',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: rep.session == 'night' ? Colors.white : UbColors.amber,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Online / Server vs Template Live Status Pill
                  InkWell(
                    onTap: _fetchingOnline
                        ? null
                        : () => _loadReport(
                              rep.tanggal,
                              rep.shift,
                              forceRefreshFromServer: true,
                            ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _fetchingOnline
                            ? UbColors.amber.withValues(alpha: 0.14)
                            : (!_isOnline
                                ? UbColors.rose.withValues(alpha: 0.14)
                                : (_foundInServer
                                    ? UbColors.emerald.withValues(alpha: 0.14)
                                    : UbColors.cyan.withValues(alpha: 0.14))),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _fetchingOnline
                              ? UbColors.amber.withValues(alpha: 0.45)
                              : (!_isOnline
                                  ? UbColors.rose.withValues(alpha: 0.45)
                                  : (_foundInServer
                                      ? UbColors.emerald.withValues(alpha: 0.45)
                                      : UbColors.cyan.withValues(alpha: 0.45))),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_fetchingOnline)
                            const SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(strokeWidth: 1.8, color: UbColors.amber),
                            )
                          else
                            Icon(
                              !_isOnline
                                  ? Icons.cloud_off_rounded
                                  : (_foundInServer ? Icons.cloud_done_rounded : Icons.description_outlined),
                              size: 13,
                              color: !_isOnline
                                  ? UbColors.rose
                                  : (_foundInServer ? UbColors.emerald : UbColors.cyan),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            _fetchingOnline
                                ? 'Sync'
                                : (!_isOnline
                                    ? 'Lokal'
                                    : (_foundInServer ? 'Server' : 'Template')),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: _fetchingOnline
                                  ? UbColors.amber
                                  : (!_isOnline
                                      ? UbColors.rose
                                      : (_foundInServer ? UbColors.emerald : UbColors.cyan)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Kirim (1x Sync ke MySQL & SharePoint)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: UbColors.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      minimumSize: Size.zero,
                    ),
                    onPressed: _syncing ? null : _syncNow,
                    icon: _syncing
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 13),
                    label: Text(_syncing ? '...' : 'Kirim', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 5),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: UbColors.card,
                      padding: const EdgeInsets.all(7),
                      minimumSize: const Size(34, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _printing ? null : _printPdf,
                    icon: _printing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.print_rounded, size: 17),
                    tooltip: 'Cetak / Export PDF A4',
                  ),
                ],
              ),
            ),

            // INTERACTIVE A3 i-REPORTER CANVAS + 1:1 NEXT.JS LOADING MODAL (`isLoadingMySQL`)
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
                  if (_hasLoadedInitialServer || !_fetchingOnline)
                    AbsorbPointer(
                      absorbing: _fetchingOnline,
                      child: Opacity(
                        opacity: _fetchingOnline ? 0.25 : 1.0,
                        child: InteractiveViewer(
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
                            final res = await ChecksheetModals.showHeaderModal(
                              context,
                              report: rep,
                              availableTemplates: _templates,
                            );
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
                            rep.lineName = (res['lineName'] as String).isNotEmpty
                                ? res['lineName'] as String
                                : rep.lineName;
                            rep.taktTime = res['taktTime'] as double;
                            rep.picName = res['picName'] as String;
                            rep.spvName = res['spvName'] as String;
                            rep.slots = UbMasterData.buildSlotsFromTemplate(
                              rep.templateCode,
                              rep.taktTime,
                              rep.overtimeHours,
                              prevSlots: rep.slots,
                              otAwalMode: rep.otAwal,
                              customTemplates: _templates,
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
                            rep.actOtUnits = (res.otHours * (60 / (rep.taktTime > 0 ? rep.taktTime : 2.4)).round()).round();
                            rep.overtimeHours = res.otHours.ceil().clamp(0, 3);
                            rep.slots = UbMasterData.buildSlotsFromTemplate(
                              rep.templateCode,
                              rep.taktTime,
                              rep.overtimeHours,
                              prevSlots: rep.slots,
                              otAwalMode: rep.otAwal,
                              customTemplates: _templates,
                            );
                            await _persistLocal();
                          },
                        ),
                      ),
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
                                  rep.syncStatus == 'synced'
                                      ? 'Tersinkron Server'
                                      : (_foundInServer ? 'Edit Draft' : 'Sesuai Template'),
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

                  // 1:1 NEXT.JS MODAL LOADING & BLOKIR INPUT SAAT AMBIL DATA MYSQL (`isLoadingMySQL`)
                  if (_fetchingOnline)
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xCC020617),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF0F172A), Color(0xFF020617)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: UbColors.cyan.withValues(alpha: 0.45), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: UbColors.cyan.withValues(alpha: 0.18),
                                  blurRadius: 32,
                                  spreadRadius: 2,
                                ),
                                const BoxShadow(color: Colors.black87, blurRadius: 24),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 58,
                                  height: 58,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: UbColors.cyan.withValues(alpha: 0.45),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.6,
                                          color: UbColors.emerald,
                                        ),
                                      ),
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: UbColors.cyan.withValues(alpha: 0.16),
                                        ),
                                        child: const Icon(Icons.sync_rounded, size: 15, color: UbColors.cyan),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Memuat Data Checksheet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _loadingStepText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xCC020617),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Column(
                                    children: [
                                      _loadingParamRow(
                                        'Tanggal:',
                                        UbMasterData.formatDDMMYYYY(
                                          _loadingTargetDate.isNotEmpty ? _loadingTargetDate : rep.tanggal,
                                        ),
                                        UbColors.cyan,
                                      ),
                                      const SizedBox(height: 6),
                                      _loadingParamRow(
                                        'Shift / Sesi:',
                                        'Regu ${_loadingTargetShift.isNotEmpty ? _loadingTargetShift : rep.shift} (${rep.session.toUpperCase()})',
                                        UbColors.amber,
                                      ),
                                      const SizedBox(height: 6),
                                      _loadingParamRow(
                                        'Lini:',
                                        rep.lineName.isNotEmpty ? rep.lineName : _cfg.lineName,
                                        UbColors.emerald,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: const LinearProgressIndicator(
                                    minHeight: 5,
                                    color: UbColors.emerald,
                                    backgroundColor: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Input dikunci sementara selama memuat data server...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: UbColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  Widget _loadingParamRow(String label, String val, Color valColor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted),
          ),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: valColor,
              ),
            ),
          ),
        ],
      );

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
