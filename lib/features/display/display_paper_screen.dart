import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _kPapersCacheKey = 'ubf_display_papers_cache_v1';
  Map<String, Map<String, dynamic>> _papersMap = const {};

  Map<String, dynamic>? get _activePocket => _papersMap['${_pillar.slug}-$_rowKey'];

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

    // 0. Sync 1:1 Next.js `/api/papers` (Atlas MongoDB) + local cache fallback
    if (_papersMap.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedRaw = prefs.getString(_kPapersCacheKey);
        if (cachedRaw != null && cachedRaw.isNotEmpty) {
          final dec = jsonDecode(cachedRaw);
          if (dec is Map) {
            final map = <String, Map<String, dynamic>>{};
            dec.forEach((k, v) {
              if (v is Map) map['$k'] = Map<String, dynamic>.from(v);
            });
            if (map.isNotEmpty) _papersMap = map;
          }
        }
      } catch (_) {}
    }

    final papersRes = await UbWebApi.instance.getJson('/api/papers');
    if (papersRes.ok && papersRes.map['data'] is Map) {
      final rawMap = papersRes.map['data'] as Map;
      final parsed = <String, Map<String, dynamic>>{};
      rawMap.forEach((k, v) {
        if (v is Map) parsed['$k'] = Map<String, dynamic>.from(v);
      });
      if (parsed.isNotEmpty) {
        _papersMap = parsed;
        if (papersRes.map['source'] == 'atlas') synced = true;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kPapersCacheKey, jsonEncode(parsed));
        } catch (_) {}
      }
    }

    // Apply active paper `series` & `comment` from Next.js `/api/papers`
    final activeMainPocket = _papersMap['$slug-main'];
    final activeRowPocket = _papersMap['$slug-$_rowKey'];
    if (activeMainPocket != null && activeMainPocket['series'] is Map) {
      final ser = Map<String, dynamic>.from(activeMainPocket['series'] as Map);
      if (ser['target'] is num) fyTarget = (ser['target'] as num).toDouble();
      if (ser['lower'] is bool) higherIsBetter = !(ser['lower'] as bool);
      if (ser['red'] is List) {
        final rl = ser['red'] as List;
        fyRed = List<double?>.generate(12, (i) => i < rl.length && rl[i] is num ? (rl[i] as num).toDouble() : null);
      }
      if (ser['white'] is List) {
        final wl = ser['white'] as List;
        fyWhite = List<double?>.generate(12, (i) => i < wl.length && wl[i] is num ? (wl[i] as num).toDouble() : null);
      }
    }
    if (activeRowPocket != null) {
      final cmt = (activeRowPocket['comment'] ?? '').toString().trim();
      if (cmt.isNotEmpty) comment = cmt;
      if (activeRowPocket['items'] is List) {
        final items = activeRowPocket['items'] as List;
        for (var i = 0; i < items.length; i++) {
          final it = items[i];
          if (it is List && it.isNotEmpty) {
            final no = it.isNotEmpty ? '${it[0]}' : '${i + 1}';
            final prob = it.length > 1 ? '${it[1]}' : '';
            final cm = it.length > 2 ? '${it[2]}' : '';
            final pic = it.length > 3 ? '${it[3]}' : '';
            final due = it.length > 4 ? '${it[4]}' : '';
            final st = it.length > 5 ? '${it[5]}' : 'OPEN';
            kaizens.add((no: no, theme: prob, before: due, after: cm, pic: pic, status: st));
          }
        }
      }
    }

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
                                  final nextPocket = _papersMap['${_pillar.slug}-${r.key}'];
                                  final nextComment = (nextPocket?['comment'] ?? '').toString().trim();
                                  setState(() {
                                    _rowKey = r.key;
                                    if (nextComment.isNotEmpty) _comment = nextComment;
                                  });
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
          // 1. 1:1 Next.js PaperFrame.tsx HEADER (Blue=Main, Yellow=Sub, Slate=Proses, Orange=Kaizen)
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _rowThemeBg(_rowKey), width: 4)),
            ),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PT. TMMIN · UNDERBODY ASSY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    Text('GL MANAGEMENT BOARD', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _rowThemeBg(_rowKey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _resolvedPaperTitle(meta),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _rowThemeFg(_rowKey), letterSpacing: 0.4),
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

          // 2. BODY CONTENT (1:1 Next.js Atlas Paper Templates + Live Store Fallback)
          Expanded(
            child: _buildPaperBody(meta),
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

  Color _rowThemeBg(String rowKey) => switch (rowKey) {
        'main' => const Color(0xFF2563EB),
        'sub' => const Color(0xFFFDE047),
        'proses' => const Color(0xFF64748B),
        'kaizen' => const Color(0xFFF97316),
        _ => const Color(0xFF2563EB),
      };

  Color _rowThemeFg(String rowKey) =>
      rowKey == 'sub' ? const Color(0xFF0F172A) : Colors.white;

  String _resolvedPaperTitle(DisplayPaperMeta meta) {
    final pocket = _activePocket;
    final pTitle = (pocket?['title'] ?? '').toString().trim();
    if (_rowKey == 'kaizen') return 'KAIZEN REPORT · ${_pillar.shortName}';
    final rowName = switch (_rowKey) {
      'main' => 'MAIN KPI',
      'sub' => 'SUB KPI',
      'proses' => 'PROSES KPI',
      _ => _rowKey.toUpperCase(),
    };
    if (pTitle.isNotEmpty) return '$rowName · ${pTitle.toUpperCase()}';
    return meta.bannerTitle;
  }

  Widget _buildPaperBody(DisplayPaperMeta meta) {
    final pocket = _activePocket;
    if (pocket != null) {
      if (pocket['hoshin'] is Map) {
        return _buildHoshinMainA3(Map<String, dynamic>.from(pocket['hoshin'] as Map));
      }
      if (pocket['actionPlan'] is Map) {
        return _buildActionPlanA3(Map<String, dynamic>.from(pocket['actionPlan'] as Map));
      }
      if (pocket['kpiTree'] is Map) {
        return _buildKpiTreeA3(Map<String, dynamic>.from(pocket['kpiTree'] as Map));
      }
      if (pocket['strategyBoard'] is Map) {
        return _buildStrategyBoardA3(Map<String, dynamic>.from(pocket['strategyBoard'] as Map));
      }
      if (_rowKey == 'proses' && pocket['problemList'] is Map) {
        final pl = Map<String, dynamic>.from(pocket['problemList'] as Map);
        if (pl['rows'] is List && (pl['rows'] as List).isNotEmpty) {
          return _buildProblemListA3(pl);
        }
      }
      if (_rowKey == 'proses' && pocket['causes'] is List && (pocket['causes'] as List).isNotEmpty && _prosesRows.isEmpty) {
        return _buildCausesParetoA3(
          (pocket['causes'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
          (pocket['conclusion'] ?? '').toString(),
        );
      }
      if (_rowKey == 'kaizen' && pocket['kaizenReports'] is List && (pocket['kaizenReports'] as List).isNotEmpty) {
        return _buildKaizenReportsA3(
          (pocket['kaizenReports'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      }
    }

    return switch (_rowKey) {
      'main' => _buildMainKpiA3(meta),
      'sub' => _buildSubKpiA3(meta),
      'proses' => _buildProsesKpiA3(),
      'kaizen' => _buildKaizenA3(),
      _ => _buildMainKpiA3(meta),
    };
  }

  /// 1:1 Next.js `hoshin-main.tsx`
  Widget _buildHoshinMainA3(Map<String, dynamic> h) {
    final reflections = (h['reflection'] is List ? h['reflection'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final strategies = (h['strategy'] is List ? h['strategy'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final kpis = (h['kpi'] is List ? h['kpi'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Coy & Dir Hoshin Banner
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('COY HOSHIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                    const SizedBox(height: 3),
                    Text('${h['coy'] ?? '-'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCE8),
                  border: Border.all(color: const Color(0xFFFDE047), width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DIR / DIV HOSHIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFA16207))),
                    const SizedBox(height: 3),
                    Text('${h['dir'] ?? '-'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reflection Column
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REFLECTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
                        const Divider(height: 10),
                        for (final r in reflections) ...[
                          Text('${r['title'] ?? ''}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          for (final line in (r['lines'] is List ? r['lines'] as List : const []))
                            Padding(
                              padding: const EdgeInsets.only(left: 6, top: 2),
                              child: Text('• $line', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                            ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Strategy Column
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STRATEGY FY26', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                        const Divider(height: 10),
                        for (final s in strategies) ...[
                          Text('${s['heading'] ?? ''}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          for (final it in (s['items'] is List ? s['items'] as List : const []))
                            Padding(
                              padding: const EdgeInsets.only(left: 6, top: 2),
                              child: Text('→ $it', style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
                            ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // KPI Column
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KPI TARGET: ${h['kpiTarget'] ?? ''}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                        const Divider(height: 10),
                        for (final k in kpis) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: k['hl'] == true ? const Color(0xFFDCFCE7) : Colors.white,
                              border: Border.all(color: const Color(0xFF86EFAC)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${k['label'] ?? ''}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                for (final ln in (k['lines'] is List ? k['lines'] as List : const []))
                                  Text('• $ln', style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 1:1 Next.js `hoshin-sub.tsx` (Department Action Plan)
  Widget _buildActionPlanA3(Map<String, dynamic> ap) {
    final rows = (ap['rows'] is List ? ap['rows'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${ap['title'] ?? 'DEPARTMENT ACTION PLAN'} (${ap['subtitle'] ?? ''})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              Text(
                'Div: ${ap['divHead'] ?? '-'} · Dept: ${ap['deptHead'] ?? '-'}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFDE047)),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
              columnWidths: const {
                0: FixedColumnWidth(32),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.1),
                4: FlexColumnWidth(2.4),
                5: FlexColumnWidth(1.7),
                6: FixedColumnWidth(65),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFE2E8F0)),
                  children: [
                    Padding(padding: EdgeInsets.all(5), child: Text('NO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                    Padding(padding: EdgeInsets.all(5), child: Text('KRA / OUTPUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                    Padding(padding: EdgeInsets.all(5), child: Text('KPI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                    Padding(padding: EdgeInsets.all(5), child: Text('TARGET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                    Padding(padding: EdgeInsets.all(5), child: Text('IMPROVEMENT & ACTIVITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                    Padding(padding: EdgeInsets.all(5), child: Text('SCHEDULE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                    Padding(padding: EdgeInsets.all(5), child: Text('PIC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                  ],
                ),
                for (final r in rows)
                  TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(5), child: Text('${r['no'] ?? ''}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          '${r['kra'] ?? ''}${(r['output'] ?? '').toString().isNotEmpty ? '\n${r['output']}' : ''}'.trim(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.all(5), child: Text('${r['kpiName'] ?? ''}', style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)))),
                      Padding(padding: const EdgeInsets.all(5), child: Text('${r['target'] ?? ''}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)))),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          [
                            ...(r['improvement'] is List ? (r['improvement'] as List).map((e) => '• $e') : const <String>[]),
                            ...(r['activity'] is List ? (r['activity'] as List).map((e) => '↳ $e') : const <String>[]),
                          ].join('\n'),
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF334155)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          (r['schedule'] is List ? (r['schedule'] as List).join('\n') : ''),
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF0F766E)),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.all(5), child: Text('${r['main'] ?? ''}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 1:1 Next.js `hoshin-proses.tsx` (KPI Tree)
  Widget _buildKpiTreeA3(Map<String, dynamic> kt) {
    final rows = (kt['rows'] is List ? kt['rows'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(color: const Color(0xFF94A3B8), width: 1.2),
        columnWidths: const {
          0: FixedColumnWidth(130),
          1: FlexColumnWidth(1.4),
          2: FlexColumnWidth(1.8),
          3: FlexColumnWidth(2.4),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFF0F172A)),
            children: [
              Padding(padding: EdgeInsets.all(8), child: Text('PILLAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(8), child: Text('MAIN KPI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF93C5FD)))),
              Padding(padding: EdgeInsets.all(8), child: Text('SUB KPI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFFDE047)))),
              Padding(padding: EdgeInsets.all(8), child: Text('PROCESS KPI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF86EFAC)))),
            ],
          ),
          for (final r in rows)
            TableRow(
              children: [
                Container(
                  color: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(8),
                  child: Text('${r['pillar'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('${r['main'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((r['subHead'] ?? '').toString().isNotEmpty)
                        Text('${r['subHead']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      for (final s in (r['sub'] is List ? r['sub'] as List : const []))
                        Text('• $s', style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B))),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final pr in (r['process'] is List ? r['process'] as List : const []))
                        Text('• $pr', style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 1:1 Next.js `hoshin-kaizen.tsx` (STRATEGY Board with [[highlight]])
  Widget _buildStrategyBoardA3(Map<String, dynamic> sb) {
    final groups = (sb['groups'] is List ? sb['groups'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    List<InlineSpan> parseHighlighted(String line) {
      final spans = <InlineSpan>[];
      final reg = RegExp(r'\[\[(.+?)\]\]');
      var last = 0;
      for (final m in reg.allMatches(line)) {
        if (m.start > last) {
          spans.add(TextSpan(text: line.substring(last, m.start)));
        }
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFBBF7D0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                m.group(1) ?? '',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF14532D)),
              ),
            ),
          ),
        );
        last = m.end;
      }
      if (last < line.length) {
        spans.add(TextSpan(text: line.substring(last)));
      }
      return spans;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in groups)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${g['letter'] ?? ''}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final ln in (g['lines'] is List ? g['lines'] as List : const []))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                children: [
                                  const TextSpan(text: '~ '),
                                  ...parseHighlighted('$ln'),
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
        ],
      ),
    );
  }

  /// 1:1 Next.js `safety-proses.tsx` (`problemList`)
  Widget _buildProblemListA3(Map<String, dynamic> pl) {
    final rows = (pl['rows'] is List ? pl['rows'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(color: const Color(0xFFCBD5E1)),
        columnWidths: const {
          0: FixedColumnWidth(36),
          1: FixedColumnWidth(95),
          2: FlexColumnWidth(2.2),
          3: FlexColumnWidth(1.8),
          4: FixedColumnWidth(90),
          5: FixedColumnWidth(80),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFF1E293B)),
            children: [
              Padding(padding: EdgeInsets.all(6), child: Text('NO', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('PROSES', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('TEMUAN / DESCRIPTION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('COUNTERMEASURE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('PIC / TGL', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('RANK', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
            ],
          ),
          for (final r in rows)
            TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(6), child: Text('${r['no'] ?? ''}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${r['process'] ?? r['location'] ?? ''}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155)))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${r['description'] ?? ''}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${r['cmDescription'] ?? ''}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F766E)))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${r['pic'] ?? ''}\n${r['date'] ?? ''}'.trim(), style: const TextStyle(fontSize: 10, color: Color(0xFF475569)))),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    '${(r['before'] is Map ? (r['before'] as Map)['rank'] : '') ?? ''} → ${(r['after'] is Map ? (r['after'] as Map)['rank'] : '') ?? ''}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 1:1 Next.js Pareto `causes` + `conclusion`
  Widget _buildCausesParetoA3(List<Map<String, dynamic>> causes, String conclusion) {
    final maxV = causes.fold<double>(1, (m, e) {
      final v = (e['v'] as num?)?.toDouble() ?? 0;
      return v > m ? v : m;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final c in causes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 240,
                          child: Text('${c['n'] ?? ''}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ),
                        Expanded(
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (((c['v'] as num?)?.toDouble() ?? 0) / maxV).clamp(0.05, 1.0),
                            child: Container(
                              height: 26,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${c['v'] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (conclusion.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              border: Border.all(color: const Color(0xFFFACC15), width: 1.5),
            ),
            child: Text('KESIMPULAN: $conclusion', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
      ],
    );
  }

  /// 1:1 Next.js `kaizen-report.tsx` (`kaizenReports`)
  Widget _buildKaizenReportsA3(List<Map<String, dynamic>> reports) {
    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(color: const Color(0xFFCBD5E1)),
        columnWidths: const {
          0: FixedColumnWidth(36),
          1: FlexColumnWidth(2.2),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1.5),
          5: FixedColumnWidth(90),
          6: FixedColumnWidth(80),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFEA580C)),
            children: [
              Padding(padding: EdgeInsets.all(6), child: Text('NO', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('THEMA KAIZEN', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('LINE / PROSES', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('BEFORE → AFTER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('RESULT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('PIC / BLN', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
              Padding(padding: EdgeInsets.all(6), child: Text('STATUS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white))),
            ],
          ),
          for (var i = 0; i < reports.length; i++)
            TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(6), child: Text('${i + 1}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${reports[i]['theme'] ?? ''}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${reports[i]['line'] ?? ''} · ${reports[i]['process'] ?? ''}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155)))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${reports[i]['beforeValue'] ?? '-'} → ${reports[i]['afterValue'] ?? '-'}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${reports[i]['result'] ?? ''}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F766E)))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${reports[i]['pic'] ?? ''}\n${reports[i]['month'] ?? ''}'.trim(), style: const TextStyle(fontSize: 10, color: Color(0xFF475569)))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${reports[i]['status'] ?? ''}'.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)))),
              ],
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
