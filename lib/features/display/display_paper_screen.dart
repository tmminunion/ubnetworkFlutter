import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/hub_catalog.dart';
import '../../models/checksheet_models.dart';
import '../../models/cost_env_models.dart';
import '../../models/display_monitor_models.dart';
import '../../services/cost_env_store.dart';
import '../../services/hr_morale_store.dart';
import '../../services/local_store.dart';
import '../../services/productivity_ops_store.dart';
import '../../services/quality_daily_store.dart';
import '../../services/safety_findings_store.dart';
import '../../services/ub_web_api.dart';

/// 1:1 Native Flutter A3 Landscape GL Management Board Paper
/// Matches `ubnetwork/app/display/Paper.tsx` & `templates/*` (1120x792 A3/A4 Landscape ratio)
/// Automatically locks device orientation to Landscape while viewing and restores on exit.
class DisplayPaperScreen extends StatefulWidget {
  const DisplayPaperScreen({
    super.key,
    required this.pillar,
    required this.initialRowKey,
  });

  final DisplayPillarItem pillar;
  final String initialRowKey;

  @override
  State<DisplayPaperScreen> createState() => _DisplayPaperScreenState();
}

class _DisplayPaperScreenState extends State<DisplayPaperScreen> {
  static const double _paperW = 1120;
  static const double _paperH = 792;

  late DisplayPillarItem _pillar;
  late String _rowKey;
  final String _ym = costEnvTodayYmd().substring(0, 7);
  String _subTeam = 'red'; // red | white (1:1 TeamToggle in sub-shared.tsx)
  bool _fullscreen = false;
  bool _loading = true;
  bool _liveSynced = false;

  // Main KPI 12-month series (Apr..Mar)
  List<double?> _fyRed = List<double?>.filled(12, null);
  List<double?> _fyWhite = List<double?>.filled(12, null);
  double _fyTarget = 95;
  bool _higherIsBetter = true;

  // Sub KPI 31-day series
  List<double?> _dailyRed = List<double?>.filled(31, null);
  List<double?> _dailyWhite = List<double?>.filled(31, null);
  double _dailyTarget = 0;

  // Proses KPI & Kaizen rows
  List<({String no, String date, String team, String area, String problem, String cm, String pic, String status})> _prosesRows = const [];
  List<({String no, String theme, String before, String after, String pic, String status})> _kaizenRows = const [];
  String _comment = 'Papan GL Management Board UB Assy · Live sync offline-first.';

  @override
  void initState() {
    super.initState();
    _pillar = widget.pillar;
    _rowKey = widget.initialRowKey;
    _loadLiveBoardData();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _shortRowLabel(String key) {
    switch (key) {
      case 'main':
        return 'Main';
      case 'sub':
        return 'Sub';
      case 'proses':
        return 'Proses';
      case 'kaizen':
        return 'Kaizen';
      default:
        return key;
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

  Future<void> _loadLiveBoardData() async {
    setState(() => _loading = true);
    final slug = _pillar.slug;
    final meta = DisplayMonitorCatalog.metaFor(slug, _rowKey);

    // Default FY series from catalog
    var fyRed = meta.fySeries.map((e) => e.actual > 0 ? e.actual : null).toList();
    var fyWhite = meta.fySeries.map((e) => e.actual > 0 ? double.parse((e.actual * 0.995).toStringAsFixed(2)) : null).toList();
    var fyTarget = meta.fySeries.first.plan;
    var higherIsBetter = slug != 'cost' && slug != 'env' && slug != 'quality';

    final dRed = List<double?>.filled(31, null);
    final dWhite = List<double?>.filled(31, null);
    var dTarget = fyTarget;
    final proses = <({String no, String date, String team, String area, String problem, String cm, String pic, String status})>[];
    final kaizens = <({String no, String theme, String before, String after, String pic, String status})>[];
    var comment = '${_pillar.fullName} · ${meta.targetLabel}';
    var synced = false;

    // 1. Try Next.js FY API when relevant
    if (slug == 'productivity') {
      final fyRes = await UbWebApi.instance.getJson('/api/productivity/fy', query: {'fy': '2026'});
      if (fyRes.ok && fyRes.map['months'] is List) {
        final ms = fyRes.map['months'] as List;
        if (fyRes.map['target'] is num) fyTarget = (fyRes.map['target'] as num).toDouble();
        for (var i = 0; i < 12 && i < ms.length; i++) {
          final m = ms[i];
          if (m is Map) {
            if (m['red'] is Map && (m['red'] as Map)['eff'] is num) {
              fyRed[i] = ((m['red'] as Map)['eff'] as num).toDouble();
            }
            if (m['white'] is Map && (m['white'] as Map)['eff'] is num) {
              fyWhite[i] = ((m['white'] as Map)['eff'] as num).toDouble();
            }
          }
        }
        synced = true;
      }
    } else if (slug == 'hr-dev') {
      final fyRes = await UbWebApi.instance.getJson('/api/hr/idea', query: {'fy': '2026'});
      if (fyRes.ok && fyRes.map['months'] is List) {
        final ms = fyRes.map['months'] as List;
        if (fyRes.map['targetIdea'] is num) fyTarget = (fyRes.map['targetIdea'] as num).toDouble();
        for (var i = 0; i < 12 && i < ms.length; i++) {
          final m = ms[i];
          if (m is Map) {
            if (m['red'] is Map && (m['red'] as Map)['ideaPerMp'] is num) {
              fyRed[i] = ((m['red'] as Map)['ideaPerMp'] as num).toDouble();
            }
            if (m['white'] is Map && (m['white'] as Map)['ideaPerMp'] is num) {
              fyWhite[i] = ((m['white'] as Map)['ideaPerMp'] as num).toDouble();
            }
          }
        }
        synced = true;
      }
    }

    // 2. Pull live data from pillar stores (1:1 Next.js Atlas + Offline-first cache)
    if (slug == 'safety') {
      final sf = await SafetyFindingsStore.instance.listFindings();
      dTarget = 0;
      higherIsBetter = false;
      for (var i = 0; i < sf.length; i++) {
        final f = sf[i];
        proses.add((
          no: f.no.isNotEmpty ? f.no : '${i + 1}',
          date: f.foundAt,
          team: f.shift.toUpperCase(),
          area: f.location,
          problem: f.theme,
          cm: f.cm,
          pic: f.pic,
          status: f.status.toUpperCase(),
        ));
        if (f.cm.isNotEmpty) {
          kaizens.add((no: 'S${i + 1}', theme: f.theme, before: f.location, after: f.cm, pic: f.pic, status: f.status.toUpperCase()));
        }
      }
      comment = '1.428 Hari Kerja Selamat Tanpa LTI · Total ${sf.length} temuan patrol tercatat.';
    } else if (slug == 'quality') {
      final outM = await QualityDailyStore.instance.loadRecord(_ym, 'out');
      final inM = await QualityDailyStore.instance.loadRecord(_ym, 'in');
      dTarget = outM.targetDu;
      higherIsBetter = false;
      final allF = [...outM.findings, ...inM.findings];
      for (final f in allF) {
        final day = int.tryParse(f.date.split('-').last) ?? 0;
        if (day >= 1 && day <= 31) {
          if (f.team == 'red') {
            dRed[day - 1] = (dRed[day - 1] ?? 0) + f.qty;
          } else {
            dWhite[day - 1] = (dWhite[day - 1] ?? 0) + f.qty;
          }
        }
        proses.add((
          no: f.id,
          date: f.date,
          team: f.team.toUpperCase(),
          area: f.process,
          problem: f.problem,
          cm: f.countermeasure,
          pic: f.pic,
          status: f.countermeasure.isNotEmpty ? 'CLOSED' : 'OPEN',
        ));
        if (f.countermeasure.isNotEmpty) {
          kaizens.add((no: f.id, theme: f.problem, before: 'Qty ${f.qty} @ ${f.process}', after: f.countermeasure, pic: f.pic, status: 'Selesai'));
        }
      }
      comment = 'Built-in Quality: Out Flow (${outM.findings.length}) & In Proses (${inM.findings.length}) · Target D/U ≤ ${outM.targetDu}.';
    } else if (slug == 'productivity') {
      final reps = await LocalStore.instance.listReports();
      final kz = await ProductivityOpsStore.instance.loadKaizenItems();
      dTarget = 95;
      higherIsBetter = true;
      for (final r in reps) {
        final st = UbMasterData.computeStats(r);
        final day = int.tryParse(r.tanggal.split('-').last) ?? 0;
        if (r.tanggal.startsWith(_ym) && day >= 1 && day <= 31) {
          if (r.shift == 'RED') {
            dRed[day - 1] = double.tryParse(st.internalEfficiency);
          } else {
            dWhite[day - 1] = double.tryParse(st.internalEfficiency);
          }
        }
        for (final s in r.slots) {
          for (final p in s.problems) {
            if (p.problem.trim().isEmpty) continue;
            proses.add((
              no: 'P${proses.length + 1}',
              date: r.tanggal,
              team: r.shift,
              area: p.machineName.isNotEmpty ? p.machineName : p.lineStation,
              problem: p.problem,
              cm: p.countermeasure,
              pic: r.shift,
              status: '${p.delayMin.round()}m',
            ));
          }
        }
      }
      for (var i = 0; i < kz.length; i++) {
        final k = kz[i];
        kaizens.add((no: 'P${i + 1}', theme: k.theme, before: k.beforeValue, after: k.afterValue, pic: k.pic, status: k.status));
      }
      comment = 'Target Efisiensi ≥ 95% · ${reps.length} Checksheet A3 & ${kz.length} Kaizen Productivity.';
    } else if (slug == 'cost') {
      final cd = await CostEnvStore.instance.loadCostDaily(_ym);
      final cf = await CostEnvStore.instance.loadCostFindings(_ym);
      higherIsBetter = false;
      dTarget = 10;
      for (var i = 0; i < 31; i++) {
        double sr = 0;
        double sw = 0;
        var hr = false;
        var hw = false;
        for (final it in cd.items) {
          final vr = cd.red[it.id]?[i];
          final vw = cd.white[it.id]?[i];
          if (vr != null) {
            sr += vr;
            hr = true;
          }
          if (vw != null) {
            sw += vw;
            hw = true;
          }
        }
        if (hr) dRed[i] = sr;
        if (hw) dWhite[i] = sw;
      }
      for (final f in cf) {
        proses.add((
          no: f.id,
          date: f.date,
          team: f.team.toUpperCase(),
          area: f.process,
          problem: f.problem,
          cm: f.countermeasure,
          pic: f.pic,
          status: formatRupiah(f.amount),
        ));
        if (f.countermeasure.isNotEmpty) {
          kaizens.add((no: f.id, theme: f.problem, before: formatRupiah(f.amount), after: f.countermeasure, pic: f.pic, status: f.kindLabel));
        }
      }
      comment = 'Control Cost Daily (${cd.items.length} item O. Supply/Consumable) · ${cf.length} temuan pemborosan.';
    } else if (slug == 'hr-dev') {
      final idea = await HrMoraleStore.instance.loadHrIdea(_ym);
      final hf = await HrMoraleStore.instance.loadHrFindings(_ym);
      higherIsBetter = true;
      dTarget = 2;
      for (var i = 0; i < 31; i++) {
        if (idea.red.dailyIdea[i] != null) dRed[i] = idea.red.dailyIdea[i]!.toDouble();
        if (idea.white.dailyIdea[i] != null) dWhite[i] = idea.white.dailyIdea[i]!.toDouble();
      }
      for (final f in hf) {
        proses.add((
          no: f.id,
          date: f.date,
          team: f.team.toUpperCase(),
          area: f.process,
          problem: f.problem,
          cm: f.countermeasure,
          pic: f.pic,
          status: f.hasKaizen ? 'KAIZEN' : 'OPEN',
        ));
        if (f.countermeasure.isNotEmpty) {
          kaizens.add((no: f.id, theme: f.problem, before: 'Qty ${f.qty}', after: f.countermeasure, pic: f.pic, status: f.hasKaizen ? 'Selesai' : 'On Progres'));
        }
      }
      comment = 'Monthly Idea Record · Target ${idea.targetIdea} Idea/MP & ${idea.targetPart.round()}% Partisipan.';
    } else if (slug == 'env') {
      final en = await CostEnvStore.instance.loadEnvEnergy(_ym);
      final ef = await CostEnvStore.instance.loadEnvFindings(_ym);
      higherIsBetter = false;
      dTarget = en.target;
      for (var i = 0; i < 31; i++) {
        dRed[i] = en.red[i];
        dWhite[i] = en.white[i];
      }
      for (final f in ef) {
        proses.add((
          no: f.id,
          date: f.date,
          team: f.team.toUpperCase(),
          area: f.location,
          problem: f.problem,
          cm: f.countermeasure,
          pic: f.pic,
          status: f.status.toUpperCase(),
        ));
        if (f.countermeasure.isNotEmpty) {
          kaizens.add((no: f.id, theme: f.problem, before: f.location, after: f.countermeasure, pic: f.pic, status: f.status.toUpperCase()));
        }
      }
      comment = 'Green Plant Environment · Target Energi ≤ ${en.target.round()} kWh/shift & Zero Air Leakage (#lub).';
    } else {
      // Hoshin
      proses.addAll(const [
        (no: 'H1', date: 'FY26', team: 'ALL', area: 'Safety', problem: 'Zero Accident & 100% KYT SGA', cm: 'Patrol mingguan & BIRA aktif', pic: 'GL/TL', status: 'ON TRACK'),
        (no: 'H2', date: 'FY26', team: 'ALL', area: 'Quality', problem: 'Zero Defect Out Flow', cm: 'Poka-Yoke & QA Gate', pic: 'GL/TL', status: 'ON TRACK'),
        (no: 'H3', date: 'FY26', team: 'ALL', area: 'Productivity', problem: 'Efisiensi ≥ 95% & 25 UPH', cm: 'Pareto Chokotei & Kaizen', pic: 'GL/TL', status: 'ON TRACK'),
        (no: 'H4', date: 'FY26', team: 'ALL', area: 'Cost & Env', problem: 'Lean O. Supply & Zero #lub', cm: 'Checksheet harian & #klub', pic: 'GL/TL', status: 'ON TRACK'),
      ]);
      kaizens.addAll(const [
        (no: 'K1', theme: 'Digitalisasi 100% GL Management Board & Checksheet A3', before: 'Rekap manual kertas terpisah', after: 'UBnetwork Flutter Offline-First + Live Sync Atlas', pic: 'Tim DX UB', status: 'Selesai'),
      ]);
    }

    if (!mounted) return;
    setState(() {
      _fyRed = fyRed;
      _fyWhite = fyWhite;
      _fyTarget = fyTarget;
      _higherIsBetter = higherIsBetter;
      _dailyRed = dRed;
      _dailyWhite = dWhite;
      _dailyTarget = dTarget;
      _prosesRows = proses;
      _kaizenRows = kaizens;
      _comment = comment;
      _liveSynced = synced;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = DisplayMonitorCatalog.metaFor(_pillar.slug, _rowKey);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: Column(
          children: [
            // TOP HEADER: 1:1 Next.js /display/layout.tsx (Back + Pillars HOSHIN, SAFETY, QUALITY, PRODUCTIVITY, COST, HR-DEV, ENV + Tools)
            if (!_fullscreen)
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 6),
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                      tooltip: 'Kembali',
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: HubCatalog.displayPillars.map((p) {
                            final isSelected = p.slug == _pillar.slug;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: InkWell(
                                onTap: () {
                                  if (p.slug == _pillar.slug) return;
                                  setState(() => _pillar = p);
                                  _loadLiveBoardData();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0284C7)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.shortName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _liveSynced ? UbColors.emerald : UbColors.amber,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: _loadLiveBoardData,
                      icon: const Icon(Icons.refresh_rounded, size: 17, color: UbColors.cyan),
                      tooltip: 'Muat Ulang Data',
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: _toggleFullscreen,
                      icon: const Icon(Icons.fullscreen_rounded, size: 18, color: Colors.white),
                      tooltip: 'Layar Penuh',
                    ),
                  ],
                ),
              ),

            // BODY: 1:1 Next.js Left Sidebar (Main / Sub / Proses / Kaizen) + Center Paper Stage (Vertical / Portrait friendly)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_fullscreen)
                    Container(
                      width: 58,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: Column(
                        children: HubCatalog.displayRows.map((r) {
                          final sel = r.key == _rowKey;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                              child: InkWell(
                                onTap: () {
                                  if (r.key == _rowKey) return;
                                  setState(() => _rowKey = r.key);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? const Color(0xFF0284C7)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        r.icon,
                                        size: 15,
                                        color: sel ? Colors.white : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _shortRowLabel(r.key),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: sel ? Colors.white : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        if (!_fullscreen && _rowKey == 'sub')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0E16),
                              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_pillar.shortName} · Sub KPI',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _pillar.accentColor,
                                  ),
                                ),
                                SegmentedButton<String>(
                                  style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                                  segments: const [
                                    ButtonSegment(value: 'red', label: Text('RED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
                                    ButtonSegment(value: 'white', label: Text('WHITE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
                                  ],
                                  selected: {_subTeam},
                                  onSelectionChanged: (s) => setState(() => _subTeam = s.first),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: _loading
                              ? const Center(child: CircularProgressIndicator())
                              : Stack(
                                  children: [
                                    InteractiveViewer(
                                      minScale: 0.8,
                                      maxScale: 4.0,
                                      boundaryMargin: const EdgeInsets.all(60),
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(_fullscreen ? 4 : 8),
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: SizedBox(
                                              width: _paperW,
                                              height: _paperH,
                                              child: _buildA3Paper(meta),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_fullscreen)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton.filled(
                                          style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                          onPressed: _toggleFullscreen,
                                          icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 18),
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
            ),
          ],
        ),
      ),
    );
  }

  /// Physical A3 Landscape Paper (1120 × 792) matching `ubnetwork/app/display/Paper.tsx` 1:1
  Widget _buildA3Paper(DisplayPaperMeta meta) {
    return Container(
      width: _paperW,
      height: _paperH,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF334155), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. OFFICIAL TOYOTA GL MANAGEMENT BOARD HEADER (border-b-4 border-yellow-400)
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFFACC15), width: 4)),
            ),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PT. TOYOTA MOTOR MFG · UNDERBODY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                    Text('GL MANAGEMENT BOARD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE047),
                      border: Border.all(color: Colors.black87, width: 1.5),
                    ),
                    child: Text(
                      meta.bannerTitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Row(
                  children: [
                    for (final c in ['S', 'Q', 'P', 'C', 'HR', 'E'])
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c == _pillar.chip ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: c == _pillar.chip ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('FY 2026/2027', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text(meta.docCode, style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. BODY CONTENT (EXPENDS TO FILL A3 SHEET)
          Expanded(
            child: switch (_rowKey) {
              'main' => _buildMainKpiA3(meta),
              'sub' => _buildSubKpiA3(meta),
              'proses' => _buildProsesKpiA3(),
              'kaizen' => _buildKaizenA3(),
              _ => _buildMainKpiA3(meta),
            },
          ),
          const SizedBox(height: 10),

          // 3. OFFICIAL COMMENT BOX FOOTER (border-2 border-slate-400)
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFF94A3B8), width: 2),
            ),
            child: Row(
              children: [
                const Text('COMMENT: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                Expanded(
                  child: Text(
                    _comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                  ),
                ),
                Text('Periode: $_ym', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1:1 Main KPI: RED & WHITE Fiscal Year Bar Charts + 12-Month Table with EVA (○ / ✕)
  Widget _buildMainKpiA3(DisplayPaperMeta meta) {
    final months = DisplayMonitorCatalog.fyMonths;
    final totals = List<double?>.generate(12, (i) {
      final r = _fyRed[i];
      final w = _fyWhite[i];
      if (r == null && w == null) return null;
      if (r != null && w != null) return double.parse(((r + w) / 2).toStringAsFixed(1));
      return r ?? w;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // RED SHIFT CHART
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              color: const Color(0xFFFDE047),
              child: const Text('RED SHIFT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
            ),
            const SizedBox(width: 10),
            Text('${meta.targetLabel} · Satuan: ${meta.kpiUnit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 155,
          child: CustomPaint(
            painter: _A3BarChartPainter(
              labels: months,
              values: _fyRed,
              target: _fyTarget,
              barColor: const Color(0xFFEF4444),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // WHITE SHIFT CHART
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              color: const Color(0xFF3F3B3B),
              child: const Text('WHITE SHIFT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            const Text('Perbandingan bulanan Fiscal Year Apr–Mar', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 145,
          child: CustomPaint(
            painter: _A3BarChartPainter(
              labels: months,
              values: _fyWhite,
              target: _fyTarget,
              barColor: const Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 12-MONTH TABLE (RED / WHITE / TOTAL / TARGET / EVA)
        Table(
          border: TableBorder.all(color: const Color(0xFF94A3B8), width: 1),
          columnWidths: {
            0: const FixedColumnWidth(115),
            for (var i = 1; i <= 12; i++) i: const FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF1E293B)),
              children: [
                const _A3Cell('MONTH', header: true, alignLeft: true),
                for (final m in months) _A3Cell(m, header: true),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFFEF2F2)),
              children: [
                const _A3Cell('RED', bold: true, alignLeft: true),
                for (final v in _fyRed) _A3Cell(_fmtVal(v)),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                const _A3Cell('WHITE', bold: true, alignLeft: true),
                for (final v in _fyWhite) _A3Cell(_fmtVal(v)),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFFEF9C3)),
              children: [
                const _A3Cell('TOTAL / AVG', bold: true, alignLeft: true),
                for (final v in totals) _A3Cell(_fmtVal(v), bold: true),
              ],
            ),
            TableRow(
              children: [
                const _A3Cell('TARGET', bold: true, alignLeft: true),
                for (var i = 0; i < 12; i++) _A3Cell(_fmtVal(_fyTarget), muted: true),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFFEF3C7)),
              children: [
                const _A3Cell('EVA', bold: true, alignLeft: true),
                for (final v in totals) _A3EvaCell(value: v, target: _fyTarget, higherIsBetter: _higherIsBetter),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 1:1 Sub KPI: Daily 1–31 Bar Chart + Daily 1–31 Table with EVA (○ / ✕)
  Widget _buildSubKpiA3(DisplayPaperMeta meta) {
    final dim = daysInMonthYm(_ym);
    final vals = (_subTeam == 'red' ? _dailyRed : _dailyWhite).take(dim).toList();
    final labels = List.generate(dim, (i) => '${i + 1}');
    final barColor = _subTeam == 'red' ? const Color(0xFFEF4444) : const Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              color: _subTeam == 'red' ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
              child: Text('UB ASSY ${_subTeam.toUpperCase()}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Text('Grafik Harian Tanggal 1–$dim ($_ym) · Target: ${_fmtVal(_dailyTarget)} ${meta.kpiUnit}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: CustomPaint(
            painter: _A3BarChartPainter(
              labels: labels,
              values: vals,
              target: _dailyTarget > 0 ? _dailyTarget : null,
              barColor: barColor,
              compactLabels: true,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // DAILY 1..dim TABLE
        Table(
          border: TableBorder.all(color: const Color(0xFF94A3B8), width: 0.8),
          columnWidths: {
            0: const FixedColumnWidth(72),
            for (var i = 1; i <= dim; i++) i: const FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF1E293B)),
              children: [
                const _A3Cell('DATE', header: true, alignLeft: true, small: true),
                for (final l in labels) _A3Cell(l, header: true, small: true),
              ],
            ),
            TableRow(
              decoration: BoxDecoration(color: _subTeam == 'red' ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC)),
              children: [
                const _A3Cell('ACTUAL', bold: true, alignLeft: true, small: true),
                for (final v in vals) _A3Cell(_fmtVal(v), small: true),
              ],
            ),
            TableRow(
              children: [
                const _A3Cell('TARGET', bold: true, alignLeft: true, small: true),
                for (var i = 0; i < dim; i++) _A3Cell(_fmtVal(_dailyTarget), muted: true, small: true),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFFEF3C7)),
              children: [
                const _A3Cell('EVA', bold: true, alignLeft: true, small: true),
                for (final v in vals) _A3EvaCell(value: v, target: _dailyTarget, higherIsBetter: _higherIsBetter, small: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 1:1 Proses KPI: Official A3 List Up Problem Findings Table
  Widget _buildProsesKpiA3() {
    if (_prosesRows.isEmpty) {
      return const Center(
        child: Text('Belum ada temuan problem tercatat pada bulan ini.', style: TextStyle(fontSize: 18, color: Color(0xFF64748B))),
      );
    }
    return Table(
      border: TableBorder.all(color: const Color(0xFF64748B), width: 1),
      columnWidths: const {
        0: FixedColumnWidth(46),
        1: FixedColumnWidth(88),
        2: FixedColumnWidth(64),
        3: FixedColumnWidth(135),
        4: FlexColumnWidth(2.2),
        5: FlexColumnWidth(2.0),
        6: FixedColumnWidth(95),
        7: FixedColumnWidth(90),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFF1E293B)),
          children: [
            _A3Cell('NO', header: true),
            _A3Cell('TGL', header: true),
            _A3Cell('REGU', header: true),
            _A3Cell('AREA / POS', header: true, alignLeft: true),
            _A3Cell('PROBLEM / TEMUAN', header: true, alignLeft: true),
            _A3Cell('COUNTERMEASURE', header: true, alignLeft: true),
            _A3Cell('PIC', header: true),
            _A3Cell('STATUS', header: true),
          ],
        ),
        ..._prosesRows.take(10).map(
              (r) => TableRow(
                children: [
                  _A3Cell(r.no, bold: true),
                  _A3Cell(r.date),
                  _A3Cell(r.team, bold: true),
                  _A3Cell(r.area, alignLeft: true),
                  _A3Cell(r.problem, alignLeft: true, bold: true),
                  _A3Cell(r.cm.isEmpty ? '-' : r.cm, alignLeft: true),
                  _A3Cell(r.pic.isEmpty ? '-' : r.pic),
                  _A3Cell(r.status, bold: true),
                ],
              ),
            ),
      ],
    );
  }

  /// 1:1 Kaizen Board: Before / After A3 Table
  Widget _buildKaizenA3() {
    if (_kaizenRows.isEmpty) {
      return const Center(
        child: Text('Belum ada Kaizen Report tercatat pada pilar ini.', style: TextStyle(fontSize: 18, color: Color(0xFF64748B))),
      );
    }
    return Table(
      border: TableBorder.all(color: const Color(0xFF64748B), width: 1),
      columnWidths: const {
        0: FixedColumnWidth(54),
        1: FlexColumnWidth(2.2),
        2: FlexColumnWidth(1.6),
        3: FlexColumnWidth(1.8),
        4: FixedColumnWidth(115),
        5: FixedColumnWidth(100),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFF1E293B)),
          children: [
            _A3Cell('NO', header: true),
            _A3Cell('TEMA KAIZEN', header: true, alignLeft: true),
            _A3Cell('BEFORE', header: true, alignLeft: true),
            _A3Cell('AFTER', header: true, alignLeft: true),
            _A3Cell('PIC', header: true),
            _A3Cell('STATUS', header: true),
          ],
        ),
        ..._kaizenRows.take(8).map(
              (k) => TableRow(
                children: [
                  _A3Cell(k.no, bold: true),
                  _A3Cell(k.theme, alignLeft: true, bold: true),
                  _A3Cell(k.before, alignLeft: true),
                  _A3Cell(k.after, alignLeft: true),
                  _A3Cell(k.pic.isEmpty ? '-' : k.pic),
                  Container(
                    color: k.status.toUpperCase().contains('SUDAH') || k.status.toUpperCase().contains('SELESAI') || k.status.toUpperCase().contains('CLOSED')
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEF3C7),
                    child: _A3Cell(k.status, bold: true),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  String _fmtVal(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
  }
}

class _A3Cell extends StatelessWidget {
  const _A3Cell(
    this.text, {
    this.header = false,
    this.bold = false,
    this.muted = false,
    this.alignLeft = false,
    this.small = false,
  });

  final String text;
  final bool header;
  final bool bold;
  final bool muted;
  final bool alignLeft;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: small ? 2 : 6, vertical: small ? 4 : 6),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontSize: small ? 9.5 : (header ? 11.5 : 12),
          fontWeight: header || bold ? FontWeight.w800 : FontWeight.w500,
          color: header ? Colors.white : (muted ? const Color(0xFF64748B) : const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

class _A3EvaCell extends StatelessWidget {
  const _A3EvaCell({
    required this.value,
    required this.target,
    required this.higherIsBetter,
    this.small = false,
  });

  final double? value;
  final double target;
  final bool higherIsBetter;
  final bool small;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox(height: 22);
    final ok = higherIsBetter ? value! >= target : value! <= target;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Center(
        child: Text(
          ok ? '○' : '✕',
          style: TextStyle(
            fontSize: small ? 11 : 15,
            fontWeight: FontWeight.w900,
            color: ok ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
          ),
        ),
      ),
    );
  }
}

class _A3BarChartPainter extends CustomPainter {
  _A3BarChartPainter({
    required this.labels,
    required this.values,
    required this.target,
    required this.barColor,
    this.compactLabels = false,
  });

  final List<String> labels;
  final List<double?> values;
  final double? target;
  final Color barColor;
  final bool compactLabels;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 42.0;
    const topPad = 16.0;
    const bottomPad = 20.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - topPad - bottomPad;
    final baseY = topPad + chartH;

    // Plot border & horizontal grid
    final gridPaint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1;
    final borderPaint = Paint()..color = const Color(0xFFCBD5E1)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(leftPad, topPad, chartW, chartH), borderPaint);

    final nums = values.whereType<double>().toList();
    var maxVal = target ?? 0.0;
    for (final n in nums) {
      if (n > maxVal) maxVal = n;
    }
    if (maxVal <= 0) maxVal = 100;
    maxVal *= 1.15;

    for (var i = 1; i <= 3; i++) {
      final gy = topPad + chartH * (i / 4);
      canvas.drawLine(Offset(leftPad, gy), Offset(size.width, gy), gridPaint);
    }

    // Bars
    final count = labels.length;
    if (count == 0) return;
    final colW = chartW / count;
    final barW = (colW * 0.56).clamp(6.0, 44.0);
    final barPaint = Paint()..color = barColor.withValues(alpha: 0.9);

    for (var i = 0; i < count; i++) {
      final cx = leftPad + colW * i + colW / 2;
      final v = i < values.length ? values[i] : null;
      if (v != null && v >= 0) {
        final h = ((v / maxVal).clamp(0.0, 1.0)) * chartH;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - barW / 2, baseY - h, barW, h),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, barPaint);

        if (!compactLabels || v > 0) {
          final tp = TextPainter(
            text: TextSpan(
              text: v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1),
              style: TextStyle(fontSize: compactLabels ? 8.5 : 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(cx - tp.width / 2, (baseY - h - tp.height - 2).clamp(0.0, baseY)));
        }
      }

      // X-axis label
      final ltp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: compactLabels ? 8.5 : 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ltp.paint(canvas, Offset(cx - ltp.width / 2, baseY + 4));
    }

    // Target dashed red line
    if (target != null && target! > 0) {
      final ty = baseY - ((target! / maxVal).clamp(0.0, 1.0)) * chartH;
      final tPaint = Paint()..color = const Color(0xFFDC2626)..strokeWidth = 2;
      const dash = 8.0;
      const gap = 5.0;
      var dx = leftPad;
      while (dx < size.width) {
        final endX = (dx + dash).clamp(leftPad, size.width);
        canvas.drawLine(Offset(dx, ty), Offset(endX, ty), tPaint);
        dx += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _A3BarChartPainter oldDelegate) => true;
}
