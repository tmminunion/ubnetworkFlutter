// 1:1 Native Flutter GL Management Board Viewer (1600x900 16:9 Landscape)
// Matches Next.js `ubnetwork/app/display/layout.tsx`, `LiveSheet.tsx`, `PaperFrame.tsx` & all 28 `templates/*.tsx`.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../data/hub_catalog.dart';
import '../../models/checksheet_models.dart';
import '../../models/chokotei_models.dart';
import '../../models/cost_env_models.dart';
import '../../models/hr_morale_models.dart';
import '../../models/kyt_models.dart';
import '../../models/quality_daily_models.dart';
import '../../models/safety_finding_models.dart';
import '../../services/chokotei_store.dart';
import '../../services/cost_env_store.dart';
import '../../services/hr_morale_store.dart';
import '../../services/kyt_store.dart';
import '../../services/local_store.dart';
import '../../services/productivity_ops_store.dart';
import '../../services/quality_daily_store.dart';
import '../../services/safety_findings_store.dart';
import '../../services/ub_web_api.dart';
import '../hub/display_board_screen.dart';
import 'display_paper_defaults.dart';
import 'display_shared_widgets.dart';
import 'display_templates_hoshin_safety.dart';
import 'display_templates_qpcehr.dart';

class DisplayPaperScreen extends StatefulWidget {
  const DisplayPaperScreen({
    super.key,
    required this.pillar,
    required this.initialRowKey,
    this.restoreOrientationOnExit = true,
  });

  final DisplayPillarItem pillar;
  final String initialRowKey;
  final bool restoreOrientationOnExit;

  @override
  State<DisplayPaperScreen> createState() => _DisplayPaperScreenState();
}

class _DisplayPaperScreenState extends State<DisplayPaperScreen> {
  static const String _kPapersCacheKey = 'ubf_display_papers_cache_v2';
  static String _fyCacheKey(String paper, int fy) => 'ubf_display_fy_${paper}_$fy';

  final GlobalKey _sheetBoundaryKey = GlobalKey();
  final TransformationController _transformCtrl = TransformationController();

  late DisplayPillarItem _pillar;
  late String _rowKey;
  late String _ym;
  late int _fy;
  late int _costFy;

  bool _fullscreen = false;
  bool _loading = true;
  bool _liveSynced = false;
  bool _exportingPdf = false;
  double _zoom = 1.0;
  Offset? _swipeStart;

  // Interactive per-template UI states (1:1 URL state in Next.js templates)
  String _subTeam = 'red'; // quality-sub & hr-dev-sub
  String _safetyProsesFilter = 'all';
  int _safetyProsesPage = 1;
  int _safetyKaizenPage = 1;
  String _qProsesKind = 'all';
  String _qProsesTeam = 'all';
  String _qProsesKz = 'all';
  int _qProsesPage = 1;
  String _cProsesKind = 'all';
  String _cProsesTeam = 'all';
  int _cProsesPage = 1;
  String _hrProsesTeam = 'all';
  String _hrProsesKz = 'all';
  int _hrProsesPage = 1;
  String _envProsesKind = 'all';
  String _envProsesTeam = 'all';
  String _envProsesStatus = 'all';
  String _envProsesKz = 'all';
  int _envProsesPage = 1;
  int _kaizenPage = 1;

  // Loaded data caches across all 28 templates
  Map<String, Map<String, dynamic>> _papersMap = {};

  // Safety
  FyShiftLineSeries _safetyAccident = FyShiftLineSeries(red: List.filled(12, null), white: List.filled(12, null), target: 0);
  FyShiftLineSeries _safetyIncident = FyShiftLineSeries(red: List.filled(12, null), white: List.filled(12, null), target: 0);
  SafetySubData _safetySub = SafetySubData(
    kytTarget: 3,
    kytRedGroups: List.generate(3, (_) => List.filled(12, null)),
    kytWhiteGroups: List.generate(3, (_) => List.filled(12, null)),
    patrolTarget: 100,
    patrolProblemRed: List.filled(12, null),
    patrolProblemWhite: List.filled(12, null),
    patrolImproveRed: List.filled(12, null),
    patrolImproveWhite: List.filled(12, null),
  );
  List<SafetyFinding> _safetyFindings = const [];

  // Quality
  FyShiftLineSeries _qDefectOut = FyShiftLineSeries(red: List.filled(12, null), white: List.filled(12, null), target: 0.025);
  FyShiftLineSeries _qClaimIn = FyShiftLineSeries(red: List.filled(12, null), white: List.filled(12, null), target: 0);
  List<QualitySubMonthSlot> _qSub3Months = const [QualitySubMonthSlot(), QualitySubMonthSlot(), QualitySubMonthSlot()];
  List<QualityFinding> _qFindings = const [];
  List<KaizenSheetEntry> _qKaizens = const [];

  // Productivity
  double _prodTarget = 98.0;
  List<ProdFyMonthSide?> _prodFyRed = List.filled(12, null);
  List<ProdFyMonthSide?> _prodFyWhite = List.filled(12, null);
  List<ProdSubMonthSlot> _prodSub3Months = const [ProdSubMonthSlot(), ProdSubMonthSlot(), ProdSubMonthSlot()];
  List<ChokoteiIssue> _prodChokotei = const [];
  List<KaizenSheetEntry> _prodKaizens = const [];

  // Cost
  CostMainData _costMain = CostMainData(red: List.filled(12, null), white: List.filled(12, null));
  CostDailyMonth _costDaily = CostDailyMonth(ym: '2026-11', items: const [], red: const {}, white: const {});
  List<CostFinding> _costFindings = const [];
  List<KaizenSheetEntry> _costKaizens = const [];

  // HR-Dev
  List<HrFyMonthSide> _hrFyRed = List.filled(12, const HrFyMonthSide());
  List<HrFyMonthSide> _hrFyWhite = List.filled(12, const HrFyMonthSide());
  List<double> _hrFyTargetIdea = List.filled(12, 2.0);
  List<double> _hrFyTargetPart = List.filled(12, 90.0);
  List<HrIdeaMonth> _hrSub3Months = const [];
  List<HrFindingItem> _hrFindings = const [];
  List<KaizenSheetEntry> _hrKaizens = const [];

  // Env
  FyShiftLineSeries _envFound = FyShiftLineSeries(red: List.filled(12, null), white: List.filled(12, null), target: 0);
  FyShiftLineSeries _envOpen = FyShiftLineSeries(red: List.filled(12, null), white: List.filled(12, null), target: 0);
  List<EnvEnergyMonth> _envSub3Months = const [];
  List<EnvFindingItem> _envFindings = const [];
  List<KaizenSheetEntry> _envKaizens = const [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _pillar = widget.pillar;
    _rowKey = widget.initialRowKey;
    _ym = DisplayFyMath.nowYm();
    _fy = DisplayFyMath.currentFy();
    _costFy = DisplayFyMath.costCurrentFy();
    _loadCurrentPillarData();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (widget.restoreOrientationOnExit) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
    setState(() => _zoom = 1.0);
  }

  void _zoomBy(double delta) {
    final next = (_zoom + delta).clamp(1.0, 4.0);
    setState(() => _zoom = next);
    if (next == 1.0) {
      _transformCtrl.value = Matrix4.identity();
    } else {
      _transformCtrl.value = Matrix4.diagonal3Values(next, next, 1.0);
    }
  }

  Future<void> _toggleFullscreen() async {
    final next = !_fullscreen;
    setState(() => _fullscreen = next);
    if (next) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _selectPillar(DisplayPillarItem p) {
    if (p.slug == _pillar.slug) return;
    setState(() {
      _pillar = p;
      _kaizenPage = 1;
    });
    _resetZoom();
    _loadCurrentPillarData();
  }

  void _selectRow(String rKey) {
    if (rKey == _rowKey) return;
    setState(() {
      _rowKey = rKey;
      _kaizenPage = 1;
    });
    _resetZoom();
    _loadCurrentPillarData();
  }

  void _stepGrid(int dCol, int dRow) {
    final cols = HubCatalog.displayPillars;
    final rows = HubCatalog.displayRows;
    final cIdx = cols.indexWhere((c) => c.slug == _pillar.slug);
    final rIdx = rows.indexWhere((r) => r.key == _rowKey);
    if (cIdx < 0 || rIdx < 0) return;
    final nc = (cIdx + dCol).clamp(0, cols.length - 1);
    final nr = (rIdx + dRow).clamp(0, rows.length - 1);
    if (nc == cIdx && nr == rIdx) return;
    setState(() {
      _pillar = cols[nc];
      _rowKey = rows[nr].key;
      _kaizenPage = 1;
    });
    _resetZoom();
    _loadCurrentPillarData();
  }

  void _shiftMonth(int delta) {
    setState(() {
      _ym = DisplayFyMath.shiftYm(_ym, delta);
      _qProsesPage = 1;
      _cProsesPage = 1;
      _hrProsesPage = 1;
      _envProsesPage = 1;
    });
    _loadCurrentPillarData();
  }

  // ===========================================================================
  // PDF PRINT & SHARE (1:1 Next.js `handlePrint` / `handleSharePdf` A4 Landscape)
  // ===========================================================================

  Future<Uint8List> _buildPaperPdfBytes() async {
    final boundary = _sheetBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Kanvas kertas belum siap dirender.');
    }
    final ui.Image img = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Gagal mengekspor gambar kertas.');
    }
    final pngBytes = byteData.buffer.asUint8List();

    final doc = pw.Document();
    final pwImg = pw.MemoryImage(pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(
          child: pw.Image(pwImg, fit: pw.BoxFit.contain),
        ),
      ),
    );
    return doc.save();
  }

  Future<void> _handlePrintPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final bytes = await _buildPaperPdfBytes();
      final name = 'KPI_${_pillar.slug}_${_rowKey}_${DisplayFyMath.todayYmd()}.pdf';
      await Printing.layoutPdf(name: name, onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal cetak PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _handleSharePdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final bytes = await _buildPaperPdfBytes();
      final name = 'KPI_${_pillar.slug}_${_rowKey}_${DisplayFyMath.todayYmd()}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal bagikan PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  // ===========================================================================
  // LIVE 1:1 NEXT.JS API + OFFLINE-FIRST DATA SYNC
  // ===========================================================================

  List<double?> _parseNum12(dynamic raw) {
    if (raw is! List) return List<double?>.filled(12, null);
    return List<double?>.generate(12, (i) {
      if (i >= raw.length || raw[i] == null) return null;
      final v = raw[i];
      if (v is num && v.isFinite) return v.toDouble();
      return double.tryParse('$v');
    });
  }

  FyShiftLineSeries _parseShiftLineSeries(dynamic raw, {double defTarget = 0}) {
    if (raw is! Map) {
      return FyShiftLineSeries(red: List.filled(12, null), white: List.filled(12, null), target: defTarget);
    }
    final m = Map<String, dynamic>.from(raw);
    final tgt = m['target'] is num ? (m['target'] as num).toDouble() : defTarget;
    final title = '${m['title'] ?? ''}'.trim();
    final label = '${m['label'] ?? ''}'.trim();
    return FyShiftLineSeries(
      red: _parseNum12(m['red']),
      white: _parseNum12(m['white']),
      target: tgt,
      title: title.isEmpty ? null : title,
      label: label.isEmpty ? null : label,
    );
  }

  Future<Map<String, dynamic>?> _fetchFyPaper(String paper, int fy, SharedPreferences prefs) async {
    final res = await UbWebApi.instance.getJson('/api/fy', query: {'paper': paper, 'fy': '$fy'});
    if (res.ok && res.map['data'] is Map) {
      final d = Map<String, dynamic>.from(res.map['data'] as Map);
      await prefs.setString(_fyCacheKey(paper, fy), jsonEncode(d));
      if (res.map['source'] == 'atlas') _liveSynced = true;
      return d;
    }
    final cached = prefs.getString(_fyCacheKey(paper, fy));
    if (cached != null && cached.isNotEmpty) {
      try {
        final dec = jsonDecode(cached);
        if (dec is Map) return Map<String, dynamic>.from(dec);
      } catch (_) {}
    }
    return null;
  }

  Future<List<KaizenSheetEntry>> _fetchAreaKaizens(String area, String paperId) async {
    final merged = <Map<String, dynamic>>[];
    final query = <String, String>{'status': 'sudah', if (area.isNotEmpty) 'area': area};
    final res = await UbWebApi.instance.getJson('/api/kaizen-reports', query: query);
    if (res.ok && res.map['items'] is List) {
      _liveSynced = true;
      for (final raw in (res.map['items'] as List).whereType<Map>()) {
        merged.add(Map<String, dynamic>.from(raw));
      }
    }
    final pocket = _papersMap[paperId];
    if (pocket != null && pocket['kaizenReports'] is List) {
      for (final raw in (pocket['kaizenReports'] as List).whereType<Map>()) {
        final m = Map<String, dynamic>.from(raw);
        final id = '${m['id'] ?? ''}';
        if (id.isEmpty || !merged.any((x) => '${x['id'] ?? ''}' == id)) {
          merged.add(m);
        }
      }
    }
    if (merged.isEmpty && area == 'P') {
      final localKz = await ProductivityOpsStore.instance.loadKaizenItems();
      for (final k in localKz) {
        merged.add({
          'id': k.id,
          'theme': k.theme,
          'line': 'UB Assy',
          'process': k.lineProcess,
          'pic': k.pic,
          'month': k.month,
          'status': k.status,
          'beforeCaption': k.rootCause,
          'afterCaption': k.countermeasure,
          'beforeValue': k.beforeValue,
          'afterValue': k.afterValue,
          'result': k.countermeasure,
        });
      }
    }
    final filtered = merged.where(isKaizenMapSudah).toList()
      ..sort((a, b) => '${b['month'] ?? ''}'.compareTo('${a['month'] ?? ''}'));
    return filtered.map(kaizenEntryFromMap).toList();
  }

  Future<ProdSubMonthSlot> _loadProdSubMonthSlot(String targetYm, List<ChecksheetReport> localReports) async {
    final parts = targetYm.split('-');
    if (parts.length >= 2) {
      final res = await UbWebApi.instance.getUb({
        'action': 'get_monthly_monitoring',
        'year': parts[0],
        'month': parts[1],
      });
      if (res.ok && res.map['status'] == 'success' && res.map['days'] is List) {
        _liveSynced = true;
        final days = res.map['days'] as List;
        ProdSubDayCell? parseDay(dynamic raw) {
          if (raw is! Map) return null;
          final o = Map<String, dynamic>.from(raw);
          final saved = o['isSaved'] == true;
          final act = (o['act'] is num) ? (o['act'] as num).toInt() : (int.tryParse('${o['act'] ?? 0}') ?? 0);
          final stop = (o['intDelayMin'] ?? o['delayMin']);
          final stopMin = (stop is num) ? stop.toInt() : (int.tryParse('${stop ?? 0}') ?? 0);
          final effRaw = (o['effInt'] ?? o['efficiency']);
          final eff = (effRaw is num) ? effRaw.toDouble() : (double.tryParse('${effRaw ?? 0}') ?? 0.0);
          return ProdSubDayCell(act: act, stopMin: stopMin, eff: eff, isSaved: saved);
        }

        ({int totalAct, int totalStop, double avgEff})? parseKpi(dynamic raw) {
          if (raw is! Map) return null;
          final o = Map<String, dynamic>.from(raw);
          final act = (o['totalAct'] is num) ? (o['totalAct'] as num).toInt() : 0;
          final stopRaw = o['totalIntDelay'] ?? o['totalDelayMin'];
          final stop = (stopRaw is num) ? stopRaw.toInt() : 0;
          final effRaw = o['avgEffInt'] ?? o['avgEff'];
          final eff = (effRaw is num) ? effRaw.toDouble() : 0.0;
          return (totalAct: act, totalStop: stop, avgEff: eff);
        }

        return ProdSubMonthSlot(
          redDays: days.map((d) => d is Map ? parseDay(d['red']) : null).toList(),
          whiteDays: days.map((d) => d is Map ? parseDay(d['white']) : null).toList(),
          weekend: days.map((d) => d is Map && d['isWeekend'] == true).toList(),
          redSummary: parseKpi(res.map['kpiRed']),
          whiteSummary: parseKpi(res.map['kpiWhite']),
        );
      }
    }

    // Offline fallback from local Checksheet reports
    final dim = DisplayFyMath.daysInMonth(targetYm);
    final rDays = List<ProdSubDayCell?>.filled(31, null);
    final wDays = List<ProdSubDayCell?>.filled(31, null);
    var rAct = 0, rStop = 0, rCnt = 0;
    var rEffSum = 0.0;
    var wAct = 0, wStop = 0, wCnt = 0;
    var wEffSum = 0.0;

    for (final rep in localReports) {
      if (!rep.tanggal.startsWith(targetYm)) continue;
      final d = int.tryParse(rep.tanggal.split('-').last) ?? 0;
      if (d < 1 || d > 31) continue;
      final st = UbMasterData.computeStats(rep);
      final eff = double.tryParse(st.internalEfficiency) ?? 0.0;
      final cell = ProdSubDayCell(act: st.totalAct, stopMin: st.totalDelayMin.round(), eff: eff, isSaved: true);
      if (rep.shift.toUpperCase() == 'RED') {
        rDays[d - 1] = cell;
        rAct += cell.act;
        rStop += cell.stopMin;
        rEffSum += eff;
        rCnt++;
      } else {
        wDays[d - 1] = cell;
        wAct += cell.act;
        wStop += cell.stopMin;
        wEffSum += eff;
        wCnt++;
      }
    }

    return ProdSubMonthSlot(
      redDays: rDays,
      whiteDays: wDays,
      weekend: List.generate(31, (i) => i < dim && DisplayFyMath.isWeekend(targetYm, i + 1)),
      redSummary: rCnt > 0 ? (totalAct: rAct, totalStop: rStop, avgEff: rEffSum / rCnt) : null,
      whiteSummary: wCnt > 0 ? (totalAct: wAct, totalStop: wStop, avgEff: wEffSum / wCnt) : null,
    );
  }

  Future<QualitySubMonthSlot> _loadQualitySubMonthSlot(String targetYm, List<ChecksheetReport> localReports) async {
    final prod = await _loadProdSubMonthSlot(targetYm, localReports);
    final defRes = await UbWebApi.instance.getJson('/api/quality/defect', query: {'month': targetYm});

    List<int?> parseDays31(dynamic raw) {
      if (raw is! List) return List<int?>.filled(31, null);
      return List<int?>.generate(31, (i) => i < raw.length && raw[i] is num ? (raw[i] as num).toInt() : null);
    }

    if (defRes.ok && defRes.map['data'] is Map) {
      final d = Map<String, dynamic>.from(defRes.map['data'] as Map);
      return QualitySubMonthSlot(
        prodRed: prod.redDays.map((e) => e?.isSaved == true ? e!.act : null).toList(),
        prodWhite: prod.whiteDays.map((e) => e?.isSaved == true ? e!.act : null).toList(),
        weekend: prod.weekend,
        totProdRed: prod.redSummary?.totalAct ?? 0,
        totProdWhite: prod.whiteSummary?.totalAct ?? 0,
        outDefRed: parseDays31(d['red']),
        outDefWhite: parseDays31(d['white']),
        inDefRed: parseDays31(d['inRed']),
        inDefWhite: parseDays31(d['inWhite']),
        targetOut: (d['target'] is num && (d['target'] as num) > 0) ? (d['target'] as num).toDouble() : 0.025,
        targetIn: (d['inTarget'] is num && (d['inTarget'] as num) > 0) ? (d['inTarget'] as num).toDouble() : 0.025,
      );
    }

    // Local store fallback
    final outRec = await QualityDailyStore.instance.loadRecord(targetYm, 'out');
    final inRec = await QualityDailyStore.instance.loadRecord(targetYm, 'in');
    return QualitySubMonthSlot(
      prodRed: prod.redDays.map((e) => e?.isSaved == true ? e!.act : null).toList(),
      prodWhite: prod.whiteDays.map((e) => e?.isSaved == true ? e!.act : null).toList(),
      weekend: prod.weekend,
      totProdRed: prod.redSummary?.totalAct ?? 0,
      totProdWhite: prod.whiteSummary?.totalAct ?? 0,
      outDefRed: List.generate(31, (i) => QualityMath.dayDefect(outRec, 'red', i + 1)),
      outDefWhite: List.generate(31, (i) => QualityMath.dayDefect(outRec, 'white', i + 1)),
      inDefRed: List.generate(31, (i) => QualityMath.dayDefect(inRec, 'red', i + 1)),
      inDefWhite: List.generate(31, (i) => QualityMath.dayDefect(inRec, 'white', i + 1)),
      targetOut: outRec.targetDu,
      targetIn: inRec.targetDu,
    );
  }

  Future<void> _loadCurrentPillarData() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();

    // 1. Load `/api/papers` cache & refresh once or on demand
    if (_papersMap.isEmpty) {
      final cachedRaw = prefs.getString(_kPapersCacheKey);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        try {
          final dec = jsonDecode(cachedRaw);
          if (dec is Map) {
            _papersMap = {
              for (final e in dec.entries)
                if (e.value is Map) '${e.key}': Map<String, dynamic>.from(e.value as Map),
            };
          }
        } catch (_) {}
      }
    }
    final papersRes = await UbWebApi.instance.getJson('/api/papers');
    if (papersRes.ok && papersRes.map['data'] is Map) {
      final raw = papersRes.map['data'] as Map;
      _papersMap = {
        for (final e in raw.entries)
          if (e.value is Map) '${e.key}': Map<String, dynamic>.from(e.value as Map),
      };
      if (papersRes.map['source'] == 'atlas') _liveSynced = true;
      await prefs.setString(_kPapersCacheKey, jsonEncode(_papersMap));
    }

    final slug = _pillar.slug;

    // 2. Load pillar-specific live endpoints + offline fallbacks
    if (slug == 'safety') {
      final sfList = await SafetyFindingsStore.instance.listFindings();
      _safetyFindings = sfList.isNotEmpty ? sfList : buildSafetyProsesFallbackFindings();

      if (_rowKey == 'main') {
        final d = await _fetchFyPaper('safety-main', _fy, prefs);
        _safetyAccident = _parseShiftLineSeries(d?['accident']);
        _safetyIncident = _parseShiftLineSeries(d?['incident']);
      } else if (_rowKey == 'sub') {
        final d = await _fetchFyPaper('safety-sub', _fy, prefs);
        final kyt = d?['kyt'] is Map ? Map<String, dynamic>.from(d!['kyt'] as Map) : const <String, dynamic>{};
        final pat = d?['patrol'] is Map ? Map<String, dynamic>.from(d!['patrol'] as Map) : const <String, dynamic>{};

        List<List<double?>> parseGroups(dynamic raw) {
          if (raw is! List) return List.generate(3, (_) => List<double?>.filled(12, null));
          return List.generate(3, (g) => g < raw.length ? _parseNum12(raw[g]) : List<double?>.filled(12, null));
        }

        var redG = parseGroups(kyt['red']);
        var whiteG = parseGroups(kyt['white']);

        // Fallback to KytStore if KYT groups are completely empty
        if (redG.every((g) => g.every((v) => v == null)) && whiteG.every((g) => g.every((v) => v == null))) {
          final kytMon = await KytStore.instance.fetchMonitoring(_fy);
          final rRows = kytMon.rows.where((r) => r.group.shift == 'RED').take(3).toList();
          final wRows = kytMon.rows.where((r) => r.group.shift == 'WHITE').take(3).toList();
          double? statusVal(SgaMonitoringRow row, int fyIdx) {
            final calMonthIdx = (fyIdx + 3) % 12; // Apr=3 .. Mar=2
            if (calMonthIdx >= row.months.length) return null;
            final st = row.months[calMonthIdx].status;
            return st == 'done' ? 1.0 : (st == 'pending' ? 0.0 : null);
          }

          redG = List.generate(3, (g) => g < rRows.length ? List.generate(12, (m) => statusVal(rRows[g], m)) : List.filled(12, null));
          whiteG = List.generate(3, (g) => g < wRows.length ? List.generate(12, (m) => statusVal(wRows[g], m)) : List.filled(12, null));
        }

        final probMap = pat['problem'] is Map ? Map<String, dynamic>.from(pat['problem'] as Map) : const <String, dynamic>{};
        final impMap = pat['improve'] is Map ? Map<String, dynamic>.from(pat['improve'] as Map) : const <String, dynamic>{};
        var probR = _parseNum12(probMap['red']);
        var probW = _parseNum12(probMap['white']);
        var impR = _parseNum12(impMap['red']);
        var impW = _parseNum12(impMap['white']);

        // Auto-sync patrol counts from _safetyFindings if empty
        if (probR.every((v) => v == null) && probW.every((v) => v == null)) {
          for (var i = 0; i < 12; i++) {
            final mYm = DisplayFyMath.fyYm(_fy, i);
            final mFinds = _safetyFindings.where((f) => f.foundAt.startsWith(mYm)).toList();
            if (mFinds.isNotEmpty) {
              final rF = mFinds.where((f) => f.shift == 'red').toList();
              final wF = mFinds.where((f) => f.shift == 'white').toList();
              probR[i] = rF.length.toDouble();
              impR[i] = rF.where((f) => f.status == 'closed').length.toDouble();
              probW[i] = wF.length.toDouble();
              impW[i] = wF.where((f) => f.status == 'closed').length.toDouble();
            }
          }
        }

        _safetySub = SafetySubData(
          kytTarget: kyt['target'] is num ? (kyt['target'] as num).toDouble() : 3,
          kytRedGroups: redG,
          kytWhiteGroups: whiteG,
          patrolTarget: pat['target'] is num ? (pat['target'] as num).toDouble() : 100,
          patrolProblemRed: probR,
          patrolProblemWhite: probW,
          patrolImproveRed: impR,
          patrolImproveWhite: impW,
        );
      }
    } else if (slug == 'quality') {
      final localReps = await LocalStore.instance.listReports();
      if (_rowKey == 'main') {
        final d = await _fetchFyPaper('quality-main', _fy, prefs);
        final baseDef = _parseShiftLineSeries(d?['defect'], defTarget: 0.025);
        final baseClaim = _parseShiftLineSeries(d?['claim'], defTarget: 0);
        // Merge current month D/U if available
        final curIdx = List.generate(12, (i) => DisplayFyMath.fyYm(_fy, i)).indexOf(_ym);
        final outRed = List<double?>.from(baseDef.red);
        final outWhite = List<double?>.from(baseDef.white);
        final inRed = List<double?>.from(baseClaim.red);
        final inWhite = List<double?>.from(baseClaim.white);
        if (curIdx >= 0) {
          final slot = await _loadQualitySubMonthSlot(_ym, localReps);
          double? calcDu(List<int?> defs, int totProd) {
            final nonNull = defs.whereType<int>().toList();
            if (nonNull.isEmpty || totProd <= 0) return null;
            final sum = nonNull.fold<int>(0, (a, b) => a + b);
            return ((sum / totProd) * 10000).round() / 10000.0;
          }

          outRed[curIdx] = calcDu(slot.outDefRed, slot.totProdRed) ?? outRed[curIdx];
          outWhite[curIdx] = calcDu(slot.outDefWhite, slot.totProdWhite) ?? outWhite[curIdx];
          inRed[curIdx] = calcDu(slot.inDefRed, slot.totProdRed) ?? inRed[curIdx];
          inWhite[curIdx] = calcDu(slot.inDefWhite, slot.totProdWhite) ?? inWhite[curIdx];
        }
        _qDefectOut = FyShiftLineSeries(red: outRed, white: outWhite, target: baseDef.target, title: baseDef.title, label: baseDef.label);
        _qClaimIn = FyShiftLineSeries(red: inRed, white: inWhite, target: baseClaim.target, title: baseClaim.title, label: baseClaim.label);
      } else if (_rowKey == 'sub') {
        final yms = [-2, -1, 0].map((d) => DisplayFyMath.shiftYm(_ym, d)).toList();
        _qSub3Months = await Future.wait(yms.map((m) => _loadQualitySubMonthSlot(m, localReps)));
      } else if (_rowKey == 'proses') {
        final res = await UbWebApi.instance.getJson('/api/quality/findings', query: {'month': _ym});
        if (res.ok && res.map['items'] is List) {
          _liveSynced = true;
          _qFindings = (res.map['items'] as List)
              .whereType<Map>()
              .map((m) {
                final map = Map<String, dynamic>.from(m);
                map['hasKaizen'] = map['kaizen'] == true || map['hasKaizen'] == true;
                return QualityFinding.fromJson(map);
              })
              .toList();
        } else {
          final outR = await QualityDailyStore.instance.loadRecord(_ym, 'out');
          final inR = await QualityDailyStore.instance.loadRecord(_ym, 'in');
          _qFindings = [...outR.findings, ...inR.findings];
        }
      } else if (_rowKey == 'kaizen') {
        _qKaizens = await _fetchAreaKaizens('Q', 'quality-kaizen');
      }
    } else if (slug == 'productivity') {
      final localReps = await LocalStore.instance.listReports();
      if (_rowKey == 'main') {
        final res = await UbWebApi.instance.getJson('/api/productivity/fy', query: {'fy': '$_fy'});
        if (res.ok && res.map['months'] is List) {
          _liveSynced = true;
          if (res.map['target'] is num) _prodTarget = (res.map['target'] as num).toDouble();
          final ms = res.map['months'] as List;
          ProdFyMonthSide? parseSide(dynamic raw) {
            if (raw is! Map) return null;
            final m = Map<String, dynamic>.from(raw);
            if (m['eff'] is! num) return null;
            return ProdFyMonthSide(
              act: (m['act'] is num) ? (m['act'] as num).toInt() : 0,
              delayMin: (m['delayMin'] is num) ? (m['delayMin'] as num).toInt() : 0,
              eff: (m['eff'] as num).toDouble(),
            );
          }

          _prodFyRed = List.generate(12, (i) => i < ms.length && ms[i] is Map ? parseSide((ms[i] as Map)['red']) : null);
          _prodFyWhite = List.generate(12, (i) => i < ms.length && ms[i] is Map ? parseSide((ms[i] as Map)['white']) : null);
        } else {
          // Local checksheet fallback
          for (var i = 0; i < 12; i++) {
            final slot = await _loadProdSubMonthSlot(DisplayFyMath.fyYm(_fy, i), localReps);
            _prodFyRed[i] = slot.redSummary == null
                ? null
                : ProdFyMonthSide(act: slot.redSummary!.totalAct, delayMin: slot.redSummary!.totalStop, eff: slot.redSummary!.avgEff);
            _prodFyWhite[i] = slot.whiteSummary == null
                ? null
                : ProdFyMonthSide(act: slot.whiteSummary!.totalAct, delayMin: slot.whiteSummary!.totalStop, eff: slot.whiteSummary!.avgEff);
          }
        }
      } else if (_rowKey == 'sub') {
        final yms = [-2, -1, 0].map((d) => DisplayFyMath.shiftYm(_ym, d)).toList();
        _prodSub3Months = await Future.wait(yms.map((m) => _loadProdSubMonthSlot(m, localReps)));
      } else if (_rowKey == 'proses') {
        final res = await UbWebApi.instance.getJson(
          '/api/productivity/chokotei',
          query: {'month': _ym, 'limit': '10', 'status': 'all'},
        );
        if (res.ok && res.map['items'] is List) {
          _liveSynced = true;
          _prodChokotei = (res.map['items'] as List).whereType<Map>().map((raw) {
            final m = Map<String, dynamic>.from(raw);
            return ChokoteiIssue(
              id: '${m['key'] ?? m['id'] ?? ''}',
              tanggal: '${m['tanggal'] ?? ''}',
              shift: '${m['shift'] ?? 'RED'}'.toUpperCase(),
              machine: '${m['machine'] ?? ''}',
              category: 'INT',
              problem: '${m['problem'] ?? ''}',
              countermeasure: '${m['countermeasure'] ?? ''}',
              lossUnits: (m['loss'] is num) ? (m['loss'] as num).toInt() : 0,
              delayMin: (m['delay'] is num) ? (m['delay'] as num).toInt() : 0,
              actionPlan: '${m['plan'] ?? ''}',
              actionPic: '${m['pic'] ?? ''}',
              actionStatus: '${m['status'] ?? 'open'}',
              isManual: m['source'] == 'manual',
            );
          }).toList();
        } else {
          final rList = await ChokoteiStore.instance.fetchChokoteiList(_ym, 'RED');
          final wList = await ChokoteiStore.instance.fetchChokoteiList(_ym, 'WHITE');
          final man = await ChokoteiStore.instance.listManual(_ym);
          _prodChokotei = [...rList.issues, ...wList.issues, ...man];
        }
      } else if (_rowKey == 'kaizen') {
        _prodKaizens = await _fetchAreaKaizens('P', 'productivity-kaizen');
      }
    } else if (slug == 'cost') {
      if (_rowKey == 'main') {
        final d = await _fetchFyPaper('cost-main', _costFy, prefs);
        List<CostLiveReading?> parseLives(dynamic raw) {
          if (raw is! List) return List.filled(12, null);
          return List.generate(12, (i) {
            if (i >= raw.length || raw[i] is! Map) return null;
            final m = Map<String, dynamic>.from(raw[i] as Map);
            if (m['pct'] is! num || m['day'] is! num) return null;
            return CostLiveReading(pct: (m['pct'] as num).toDouble(), day: (m['day'] as num).toInt());
          });
        }

        _costMain = CostMainData(
          target: (d?['target'] is num && (d!['target'] as num) > 0) ? (d['target'] as num).toDouble() : 80,
          red: _parseNum12(d?['red']),
          white: _parseNum12(d?['white']),
          liveRed: parseLives(d?['liveRed']),
          liveWhite: parseLives(d?['liveWhite']),
          budgetNoRed: '${d?['budgetNoRed'] ?? ''}',
          budgetNoWhite: '${d?['budgetNoWhite'] ?? ''}',
        );
      } else if (_rowKey == 'sub') {
        _costDaily = await CostEnvStore.instance.loadCostDaily(_ym);
      } else if (_rowKey == 'proses') {
        _costFindings = await CostEnvStore.instance.loadCostFindings(_ym);
      } else if (_rowKey == 'kaizen') {
        _costKaizens = await _fetchAreaKaizens('C', 'cost-kaizen');
      }
    } else if (slug == 'hr-dev') {
      if (_rowKey == 'main') {
        final res = await UbWebApi.instance.getJson('/api/hr/idea', query: {'fy': '$_fy'});
        if (res.ok && res.map['months'] is List) {
          _liveSynced = true;
          final ms = res.map['months'] as List;
          final defTi = (res.map['targetIdea'] is num) ? (res.map['targetIdea'] as num).toDouble() : 2.0;
          final defTp = (res.map['targetPart'] is num) ? (res.map['targetPart'] as num).toDouble() : 90.0;
          HrFyMonthSide parseSide(dynamic raw) {
            if (raw is! Map) return const HrFyMonthSide();
            final m = Map<String, dynamic>.from(raw);
            return HrFyMonthSide(
              idea: m['idea'] is num ? (m['idea'] as num).toInt() : null,
              maker: m['maker'] is num ? (m['maker'] as num).toInt() : null,
              mp: m['mp'] is num ? (m['mp'] as num).toInt() : null,
            );
          }

          _hrFyRed = List.generate(12, (i) => i < ms.length && ms[i] is Map ? parseSide((ms[i] as Map)['red']) : const HrFyMonthSide());
          _hrFyWhite = List.generate(12, (i) => i < ms.length && ms[i] is Map ? parseSide((ms[i] as Map)['white']) : const HrFyMonthSide());
          _hrFyTargetIdea = List.generate(
            12,
            (i) => i < ms.length && ms[i] is Map && (ms[i] as Map)['tIdea'] is num
                ? ((ms[i] as Map)['tIdea'] as num).toDouble()
                : defTi,
          );
          _hrFyTargetPart = List.generate(
            12,
            (i) => i < ms.length && ms[i] is Map && (ms[i] as Map)['tPart'] is num
                ? ((ms[i] as Map)['tPart'] as num).toDouble()
                : defTp,
          );
        } else {
          final curIdea = await HrMoraleStore.instance.loadHrIdea(_ym);
          final curIdx = List.generate(12, (i) => DisplayFyMath.fyYm(_fy, i)).indexOf(_ym);
          final dim = DisplayFyMath.daysInMonth(_ym);
          final rMet = HrIdeaMath.computeTeamMetrics(curIdea.red, dim);
          final wMet = HrIdeaMath.computeTeamMetrics(curIdea.white, dim);
          _hrFyRed = List.generate(
            12,
            (i) => i == curIdx ? HrFyMonthSide(idea: rMet.totalIdea, maker: rMet.totalMaker, mp: curIdea.red.mp) : const HrFyMonthSide(),
          );
          _hrFyWhite = List.generate(
            12,
            (i) => i == curIdx ? HrFyMonthSide(idea: wMet.totalIdea, maker: wMet.totalMaker, mp: curIdea.white.mp) : const HrFyMonthSide(),
          );
        }
      } else if (_rowKey == 'sub') {
        final yms = [-2, -1, 0].map((d) => DisplayFyMath.shiftYm(_ym, d)).toList();
        _hrSub3Months = await Future.wait(yms.map(HrMoraleStore.instance.loadHrIdea));
      } else if (_rowKey == 'proses') {
        _hrFindings = await HrMoraleStore.instance.loadHrFindings(_ym);
      } else if (_rowKey == 'kaizen') {
        _hrKaizens = await _fetchAreaKaizens('H', 'hr-dev-kaizen');
      }
    } else if (slug == 'env') {
      if (_rowKey == 'main') {
        final d = await _fetchFyPaper('env-main', _fy, prefs);
        _envFound = _parseShiftLineSeries(d?['found']);
        _envOpen = _parseShiftLineSeries(d?['open']);
      } else if (_rowKey == 'sub') {
        final yms = [-2, -1, 0].map((d) => DisplayFyMath.shiftYm(_ym, d)).toList();
        _envSub3Months = await Future.wait(yms.map(CostEnvStore.instance.loadEnvEnergy));
      } else if (_rowKey == 'proses') {
        _envFindings = await CostEnvStore.instance.loadEnvFindings(_ym);
      } else if (_rowKey == 'kaizen') {
        _envKaizens = await _fetchAreaKaizens('E', 'env-kaizen');
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ===========================================================================
  // UI BUILD (1:1 Next.js `/display/layout.tsx` + `LiveSheet.tsx`)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final wideRail = screenW >= 980;
    final pocket = _papersMap['${_pillar.slug}-$_rowKey'];
    final customTitle = pocket != null ? '${pocket['title'] ?? ''}' : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // TOP HEADER BAR (1:1 `layout.tsx`)
            if (!_fullscreen)
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF020617),
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Semua kertas',
                      onPressed: () {
                        if (!widget.restoreOrientationOnExit) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute<void>(builder: (_) => const DisplayBoardScreen()),
                          );
                        }
                      },
                      icon: const Icon(Icons.grid_view_rounded, size: 17, color: Colors.white),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Kembali',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: HubCatalog.displayPillars.map((p) {
                            final sel = p.slug == _pillar.slug;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: InkWell(
                                onTap: () => _selectPillar(p),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(0xFF0284C7) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.shortName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? Colors.white : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Perkecil (-)',
                      onPressed: () => _zoomBy(-0.5),
                      icon: const Icon(Icons.zoom_out_rounded, size: 17, color: Colors.white70),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Perbesar (+)',
                      onPressed: () => _zoomBy(0.5),
                      icon: const Icon(Icons.zoom_in_rounded, size: 17, color: Colors.white70),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Layar Penuh',
                      onPressed: _toggleFullscreen,
                      icon: const Icon(Icons.open_in_full_rounded, size: 15, color: Colors.white70),
                    ),
                    Container(width: 1, height: 18, margin: const EdgeInsets.symmetric(horizontal: 4), color: Colors.white12),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Cetak Kertas A4 Landscape',
                      onPressed: _exportingPdf ? null : _handlePrintPdf,
                      icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFFCBD5E1)),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Kirim / Bagikan PDF',
                      onPressed: _exportingPdf ? null : _handleSharePdf,
                      icon: _exportingPdf
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: UbColors.emerald))
                          : const Icon(Icons.share_rounded, size: 16, color: UbColors.emerald),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Segarkan Data Live',
                      onPressed: _loadCurrentPillarData,
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: UbColors.cyan),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _liveSynced ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ),

            // LEFT SIDEBAR + 16:9 PAPER STAGE
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_fullscreen)
                    Container(
                      width: wideRail ? 144 : 60,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: Column(
                        children: HubCatalog.displayRows.map((r) {
                          final sel = r.key == _rowKey;
                          final shortLabel = switch (r.key) {
                            'main' => 'Main',
                            'sub' => 'Sub',
                            'proses' => 'Proses',
                            'kaizen' => 'Kaizen',
                            _ => r.name,
                          };
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                              child: InkWell(
                                onTap: () => _selectRow(r.key),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(0xFF0284C7) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    wideRail ? r.name : shortLabel,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: wideRail ? 13 : 11,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? Colors.white : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // 16:9 STAGE (`#0a0e16`)
                  Expanded(
                    child: Container(
                      color: const Color(0xFF0A0E16),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onDoubleTap: () => _zoom > 1.0 ? _resetZoom() : _zoomBy(1.0),
                            onPanStart: _zoom <= 1.01 ? (d) => _swipeStart = d.globalPosition : null,
                            onPanEnd: _zoom <= 1.01
                                ? (d) {
                                    final start = _swipeStart;
                                    _swipeStart = null;
                                    if (start == null) return;
                                    final vx = d.velocity.pixelsPerSecond.dx;
                                    final vy = d.velocity.pixelsPerSecond.dy;
                                    if (math.max(vx.abs(), vy.abs()) < 260) return;
                                    if (vx.abs() > vy.abs()) {
                                      _stepGrid(vx < 0 ? 1 : -1, 0);
                                    } else {
                                      _stepGrid(0, vy < 0 ? 1 : -1);
                                    }
                                  }
                                : null,
                            child: InteractiveViewer(
                              transformationController: _transformCtrl,
                              panEnabled: _zoom > 1.01,
                              minScale: 1.0,
                              maxScale: 4.0,
                              onInteractionEnd: (_) {
                                final s = _transformCtrl.value.getMaxScaleOnAxis();
                                if ((s - _zoom).abs() > 0.02) {
                                  setState(() => _zoom = s);
                                }
                              },
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          blurRadius: 40,
                                          offset: const Offset(0, 16),
                                        ),
                                      ],
                                    ),
                                    child: RepaintBoundary(
                                      key: _sheetBoundaryKey,
                                      child: DisplayPaperFrame(
                                        pillarChip: _pillar.chip,
                                        pillarSlug: _pillar.slug,
                                        pillarShort: _pillar.shortName,
                                        rowKey: _rowKey,
                                        fy: _pillar.slug == 'cost' && _rowKey == 'main' ? _costFy : _fy,
                                        customTitle: customTitle,
                                        child: _loading
                                            ? const Center(child: CircularProgressIndicator())
                                            : _buildLiveTemplate(pocket),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_fullscreen)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: _handlePrintPdf,
                                      icon: const Icon(Icons.print_rounded, color: Colors.white, size: 17),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: _handleSharePdf,
                                      icon: const Icon(Icons.share_rounded, color: UbColors.emerald, size: 17),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: _toggleFullscreen,
                                      icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white, size: 17),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  /// Exact 1:1 router matching `ubnetwork/app/display/templates/index.ts` (all 28 keys)
  Widget _buildLiveTemplate(Map<String, dynamic>? pocket) {
    final key = '${_pillar.slug}-$_rowKey';
    switch (key) {
      // HOSHIN (4)
      case 'hoshin-main':
        return HoshinMainTemplate(
          hoshinData: pocket?['hoshin'] is Map ? Map<String, dynamic>.from(pocket!['hoshin'] as Map) : null,
        );
      case 'hoshin-sub':
        return HoshinSubTemplate(
          actionPlanData: pocket?['actionPlan'] is Map ? Map<String, dynamic>.from(pocket!['actionPlan'] as Map) : null,
        );
      case 'hoshin-proses':
        return HoshinProsesTemplate(
          kpiTreeData: pocket?['kpiTree'] is Map ? Map<String, dynamic>.from(pocket!['kpiTree'] as Map) : null,
        );
      case 'hoshin-kaizen':
        return HoshinKaizenTemplate(
          strategyData: pocket?['strategyBoard'] is Map ? Map<String, dynamic>.from(pocket!['strategyBoard'] as Map) : null,
        );

      // SAFETY (4)
      case 'safety-main':
        return SafetyMainTemplate(
          fy: _fy,
          accident: _safetyAccident,
          incident: _safetyIncident,
        );
      case 'safety-sub':
        return SafetySubTemplate(fy: _fy, data: _safetySub);
      case 'safety-proses':
        return SafetyProsesTemplate(
          findings: _safetyFindings,
          filter: _safetyProsesFilter,
          page: _safetyProsesPage,
          onFilterChanged: (f) => setState(() {
            _safetyProsesFilter = f;
            _safetyProsesPage = 1;
          }),
          onPageChanged: (p) => setState(() => _safetyProsesPage = p),
          onPrintPdf: _handlePrintPdf,
          onSharePdf: _handleSharePdf,
        );
      case 'safety-kaizen':
        final closed = _safetyFindings.where((f) => f.status == 'closed').toList();
        return SafetyKaizenTemplate(
          closedFindings: closed,
          page: _safetyKaizenPage,
          onPageChanged: (p) => setState(() => _safetyKaizenPage = p),
        );

      // QUALITY (4)
      case 'quality-main':
        return QualityMainTemplate(
          fy: _fy,
          defectOutSeries: _qDefectOut,
          inProsesSeries: _qClaimIn,
        );
      case 'quality-sub':
        return QualitySubTemplate(
          ym: _ym,
          team: _subTeam,
          threeMonths: _qSub3Months,
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
          onTeamChanged: (t) => setState(() => _subTeam = t),
        );
      case 'quality-proses':
        return QualityProsesTemplate(
          ym: _ym,
          findings: _qFindings,
          kindFilter: _qProsesKind,
          teamFilter: _qProsesTeam,
          kaizenFilter: _qProsesKz,
          page: _qProsesPage,
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
          onKindChanged: (v) => setState(() {
            _qProsesKind = v;
            _qProsesPage = 1;
          }),
          onTeamChanged: (v) => setState(() {
            _qProsesTeam = v;
            _qProsesPage = 1;
          }),
          onKaizenChanged: (v) => setState(() {
            _qProsesKz = v;
            _qProsesPage = 1;
          }),
          onPageChanged: (p) => setState(() => _qProsesPage = p),
        );
      case 'quality-kaizen':
        return KaizenReportSheetWidget(
          chip: 'Q',
          pillarName: 'Quality',
          entries: _qKaizens,
          page: _kaizenPage,
          onPageChanged: (p) => setState(() => _kaizenPage = p),
          emptyTitle: 'Belum ada Kaizen Quality',
          emptyHint: 'Buat lewat tombol Kaizen pada temuan di Daily Quality Record (/quality/daily)',
        );

      // PRODUCTIVITY (4)
      case 'productivity-main':
        return ProdMainTemplate(
          fy: _fy,
          target: _prodTarget,
          redMonths: _prodFyRed,
          whiteMonths: _prodFyWhite,
        );
      case 'productivity-sub':
        return ProductivitySubTemplate(
          ym: _ym,
          threeMonths: _prodSub3Months,
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
        );
      case 'productivity-proses':
        return ProductivityProsesTemplate(
          ym: _ym,
          issues: _prodChokotei,
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
        );
      case 'productivity-kaizen':
        return KaizenReportSheetWidget(
          chip: 'P',
          pillarName: 'Productivity',
          entries: _prodKaizens,
          page: _kaizenPage,
          onPageChanged: (p) => setState(() => _kaizenPage = p),
          emptyTitle: 'Belum ada Kaizen Productivity',
          emptyHint: 'Isi lewat halaman Kaizen di Productivity (/productivity/kaizen)',
        );

      // COST (4)
      case 'cost-main':
        return CostMainTemplate(costFy: _costFy, data: _costMain);
      case 'cost-sub':
        return CostSubTemplate(
          ym: _ym,
          monthData: _costDaily,
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
        );
      case 'cost-proses':
        return CostProsesTemplate(
          ym: _ym,
          findings: _costFindings,
          kindFilter: _cProsesKind,
          teamFilter: _cProsesTeam,
          page: _cProsesPage,
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
          onKindChanged: (v) => setState(() {
            _cProsesKind = v;
            _cProsesPage = 1;
          }),
          onTeamChanged: (v) => setState(() {
            _cProsesTeam = v;
            _cProsesPage = 1;
          }),
          onPageChanged: (p) => setState(() => _cProsesPage = p),
        );
      case 'cost-kaizen':
        return KaizenReportSheetWidget(
          chip: 'C',
          pillarName: 'Cost',
          entries: _costKaizens,
          page: _kaizenPage,
          onPageChanged: (p) => setState(() => _kaizenPage = p),
          emptyTitle: 'Belum ada Kaizen Cost',
          emptyHint: 'Isi lewat /display/edit?p=cost-kaizen',
        );

      // HR-DEV (4)
      case 'hr-dev-main':
        return HrDevMainTemplate(
          fy: _fy,
          redMonths: _hrFyRed,
          whiteMonths: _hrFyWhite,
          targetIdea: _hrFyTargetIdea,
          targetPart: _hrFyTargetPart,
        );
      case 'hr-dev-sub':
        return HrDevSubTemplate(
          ym: _ym,
          team: _subTeam,
          threeMonths: _hrSub3Months,
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
          onTeamChanged: (t) => setState(() => _subTeam = t),
        );
      case 'hr-dev-proses':
        return HrDevProsesTemplate(
          ym: _ym,
          findings: _hrFindings,
          teamFilter: _hrProsesTeam,
          kaizenFilter: _hrProsesKz,
          page: _hrProsesPage,
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
          onTeamChanged: (v) => setState(() {
            _hrProsesTeam = v;
            _hrProsesPage = 1;
          }),
          onKaizenChanged: (v) => setState(() {
            _hrProsesKz = v;
            _hrProsesPage = 1;
          }),
          onPageChanged: (p) => setState(() => _hrProsesPage = p),
        );
      case 'hr-dev-kaizen':
        return KaizenReportSheetWidget(
          chip: 'HR',
          pillarName: 'HR-Dev',
          entries: _hrKaizens,
          page: _kaizenPage,
          onPageChanged: (p) => setState(() => _kaizenPage = p),
          emptyTitle: 'Belum ada Kaizen HR-Dev',
          emptyHint: 'Buat lewat tombol Kaizen di Temuan HR-Dev (/hr/temuan)',
        );

      // ENV (4)
      case 'env-main':
        return EnvMainTemplate(
          fy: _fy,
          foundSeries: _envFound,
          openSeries: _envOpen,
        );
      case 'env-sub':
        return EnvSubTemplate(
          ym: _ym,
          threeMonths: _envSub3Months,
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
        );
      case 'env-proses':
        return EnvProsesTemplate(
          ym: _ym,
          findings: _envFindings,
          kindFilter: _envProsesKind,
          teamFilter: _envProsesTeam,
          statusFilter: _envProsesStatus,
          kaizenFilter: _envProsesKz,
          page: _envProsesPage,
          onPrevMonth: () => _shiftMonth(-1),
          onNextMonth: () => _shiftMonth(1),
          onKindChanged: (v) => setState(() {
            _envProsesKind = v;
            _envProsesPage = 1;
          }),
          onTeamChanged: (v) => setState(() {
            _envProsesTeam = v;
            _envProsesPage = 1;
          }),
          onStatusChanged: (v) => setState(() {
            _envProsesStatus = v;
            _envProsesPage = 1;
          }),
          onKaizenChanged: (v) => setState(() {
            _envProsesKz = v;
            _envProsesPage = 1;
          }),
          onPageChanged: (p) => setState(() => _envProsesPage = p),
        );
      case 'env-kaizen':
        return KaizenReportSheetWidget(
          chip: 'E',
          pillarName: 'Environment',
          entries: _envKaizens,
          page: _kaizenPage,
          onPageChanged: (p) => setState(() => _kaizenPage = p),
          emptyTitle: 'Belum ada Kaizen Environment',
          emptyHint: 'Buat lewat tombol Kaizen di Temuan Lingkungan (/env/temuan)',
        );

      default:
        return Center(child: Text('Template [$key] sedang disiapkan.'));
    }
  }
}
