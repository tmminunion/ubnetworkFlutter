import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/hub_catalog.dart';
import '../../models/checksheet_models.dart';
import '../../models/cost_env_models.dart';
import '../../models/hr_morale_models.dart';
import '../../models/display_monitor_models.dart';
import '../../services/cost_env_store.dart';
import '../../services/hr_morale_store.dart';
import '../../services/local_store.dart';
import '../../services/productivity_ops_store.dart';
import '../../services/quality_daily_store.dart';
import '../../services/safety_findings_store.dart';

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
  late String _rowKey;
  final String _ym = costEnvTodayYmd().substring(0, 7);
  bool _loading = true;

  // Live pulled metrics for Sub / Proses / Kaizen papers
  List<({String col1, String col2, String col3, String col4})> _tableRows = const [];
  List<({String title, String before, String after, String badge})> _kaizenCards = const [];
  List<({String label, String value, Color color})> _subKpis = const [];

  @override
  void initState() {
    super.initState();
    _rowKey = widget.initialRowKey;
    _loadLiveBoardData();
  }

  Future<void> _loadLiveBoardData() async {
    setState(() => _loading = true);
    final slug = widget.pillar.slug;
    final rows = <({String col1, String col2, String col3, String col4})>[];
    final kaizens = <({String title, String before, String after, String badge})>[];
    final kpis = <({String label, String value, Color color})>[];

    if (slug == 'safety') {
      final sf = await SafetyFindingsStore.instance.listFindings();
      final open = sf.where((f) => f.status.toLowerCase() != 'closed').length;
      kpis.addAll([
        (label: 'SAFE DAYS', value: '1.428 Hr', color: UbColors.emerald),
        (label: 'TEMUAN TOTAL', value: '${sf.length}', color: UbColors.cyan),
        (label: 'OPEN', value: '$open', color: UbColors.rose),
      ]);
      for (final f in sf.take(10)) {
        rows.add((col1: f.foundAt, col2: f.location, col3: f.theme, col4: '${f.shift.toUpperCase()} · ${f.status.toUpperCase()}'));
        if (f.cm.isNotEmpty) {
          kaizens.add((title: f.theme, before: '${f.location} (${f.shift.toUpperCase()})', after: f.cm, badge: f.status.toUpperCase()));
        }
      }
    } else if (slug == 'quality') {
      final outM = await QualityDailyStore.instance.loadRecord(_ym, 'out');
      final inM = await QualityDailyStore.instance.loadRecord(_ym, 'in');
      kpis.addAll([
        (label: 'OUT FLOW', value: '${outM.findings.length} Tmn', color: UbColors.cyan),
        (label: 'IN PROSES', value: '${inM.findings.length} Tmn', color: UbColors.amber),
        (label: 'TARGET D/U', value: '≤ 0.02', color: UbColors.emerald),
      ]);
      for (final f in [...outM.findings, ...inM.findings].take(10)) {
        rows.add((col1: f.date, col2: f.team.toUpperCase(), col3: f.problem, col4: '${f.process} (${f.qty})'));
        if (f.countermeasure.isNotEmpty) {
          kaizens.add((title: f.problem, before: 'Qty ${f.qty} @ ${f.process}', after: f.countermeasure, badge: f.team.toUpperCase()));
        }
      }
    } else if (slug == 'productivity') {
      final reps = await LocalStore.instance.listReports();
      final kz = await ProductivityOpsStore.instance.loadKaizenItems();
      kpis.addAll([
        (label: 'CHECKSHEET A3', value: '${reps.length}', color: UbColors.cyan),
        (label: 'KAIZEN REPORT', value: '${kz.length}', color: UbColors.purple),
        (label: 'TARGET EFF', value: '≥ 95%', color: UbColors.emerald),
      ]);
      for (final r in reps.take(10)) {
        final st = UbMasterData.computeStats(r);
        rows.add((col1: r.tanggal, col2: r.shift, col3: 'Act ${st.totalAct}/${st.totalPlan} U', col4: 'Eff ${st.internalEfficiency}% · Delay ${st.totalDelayMin.round()}m'));
      }
      for (final k in kz.take(6)) {
        kaizens.add((title: k.theme, before: k.beforeValue, after: k.afterValue, badge: k.status));
      }
    } else if (slug == 'cost') {
      final cd = await CostEnvStore.instance.loadCostDaily(_ym);
      final cf = await CostEnvStore.instance.loadCostFindings(_ym);
      final totLoss = cf.fold<int>(0, (acc, e) => acc + e.amount);
      kpis.addAll([
        (label: 'ITEM MONITOR', value: '${cd.items.length}', color: UbColors.amber),
        (label: 'TEMUAN COST', value: '${cf.length}', color: UbColors.rose),
        (label: 'POTENSI LOSS', value: formatRupiah(totLoss), color: UbColors.cyan),
      ]);
      for (final f in cf.take(10)) {
        rows.add((col1: f.date, col2: f.team.toUpperCase(), col3: f.problem, col4: formatRupiah(f.amount)));
        if (f.countermeasure.isNotEmpty) {
          kaizens.add((title: f.problem, before: formatRupiah(f.amount), after: f.countermeasure, badge: f.kindLabel));
        }
      }
    } else if (slug == 'hr-dev') {
      final idea = await HrMoraleStore.instance.loadHrIdea(_ym);
      final hf = await HrMoraleStore.instance.loadHrFindings(_ym);
      final dim = daysInMonthYm(_ym);
      final rm = HrIdeaMath.computeTeamMetrics(idea.red, dim);
      final wm = HrIdeaMath.computeTeamMetrics(idea.white, dim);
      kpis.addAll([
        (label: 'RED IDEA/MP', value: rm.ideaPerMp == null ? '-' : rm.ideaPerMp!.toStringAsFixed(2), color: UbColors.rose),
        (label: 'WHITE IDEA/MP', value: wm.ideaPerMp == null ? '-' : wm.ideaPerMp!.toStringAsFixed(2), color: UbColors.cyan),
        (label: 'TEMUAN HR', value: '${hf.length}', color: UbColors.purple),
      ]);
      for (final f in hf.take(10)) {
        rows.add((col1: f.date, col2: f.team.toUpperCase(), col3: f.problem, col4: 'Qty ${f.qty} · ${f.pic}'));
        if (f.countermeasure.isNotEmpty) {
          kaizens.add((title: f.problem, before: 'Qty ${f.qty}', after: f.countermeasure, badge: f.hasKaizen ? 'KAIZEN H' : 'OPEN'));
        }
      }
    } else if (slug == 'env') {
      final en = await CostEnvStore.instance.loadEnvEnergy(_ym);
      final sum = EnvEnergyMath.computeSummary(en);
      final ef = await CostEnvStore.instance.loadEnvFindings(_ym);
      final air = await CostEnvStore.instance.loadAirFindings();
      kpis.addAll([
        (label: 'TOTAL kWh', value: '${sum.totalCombined}', color: UbColors.emerald),
        (label: 'AIR LEAK #lub', value: '${air.length}', color: UbColors.cyan),
        (label: 'TEMUAN ENV', value: '${ef.length}', color: UbColors.amber),
      ]);
      for (final f in ef.take(10)) {
        rows.add((col1: f.date, col2: f.kindLabel, col3: f.problem, col4: f.status.toUpperCase()));
        if (f.countermeasure.isNotEmpty) {
          kaizens.add((title: f.problem, before: f.location, after: f.countermeasure, badge: f.status.toUpperCase()));
        }
      }
    } else {
      // hoshin
      kpis.addAll(const [
        (label: 'SAFETY', value: '0 LTI', color: UbColors.emerald),
        (label: 'QUALITY', value: '99.82%', color: UbColors.cyan),
        (label: 'PRODUCTIVITY', value: '98.0%', color: UbColors.purple),
      ]);
      rows.addAll(const [
        (col1: 'H-01', col2: 'Safety', col3: 'Zero Accident & 100% KYT SGA Red/White', col4: 'ON TRACK'),
        (col1: 'H-02', col2: 'Quality', col3: 'Zero Defect Out Flow & Built-in Quality', col4: 'ON TRACK'),
        (col1: 'H-03', col2: 'Productivity', col3: 'Efisiensi Lini ≥ 95% & Reduksi Chokotei', col4: 'ON TRACK'),
        (col1: 'H-04', col2: 'Cost & Env', col3: 'Lean O. Supply & Zero Air Leakage #lub', col4: 'ON TRACK'),
      ]);
      kaizens.addAll(const [
        (title: 'Digitalisasi 100% GL Management Board & Checksheet A3', before: 'Input kertas manual & rekap terpisah', after: 'Offline-first Android UBnetwork Flutter + Live Sync', badge: 'HOSHIN FY26'),
      ]);
    }

    if (!mounted) return;
    setState(() {
      _tableRows = rows;
      _kaizenCards = kaizens;
      _subKpis = kpis;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = DisplayMonitorCatalog.metaFor(widget.pillar.slug, _rowKey);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.pillar.shortName} · GL Board 16:9', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            Text('Route: /display/${widget.pillar.slug}/$_rowKey · $_ym', style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 4 Kertas KPI Switcher
          Container(
            color: UbColors.surface.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: HubCatalog.displayRows.map((r) {
                  final sel = r.key == _rowKey;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(r.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                      selected: sel,
                      selectedColor: widget.pillar.gradient.first.withValues(alpha: 0.35),
                      onSelected: (_) => setState(() => _rowKey = r.key),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 16:9 PHYSICAL TOYOTA KPI PAPER (ZOOMABLE)
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : InteractiveViewer(
                    minScale: 0.6,
                    maxScale: 2.5,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black87, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // OFFICIAL TOYOTA HEADER BANNER
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: widget.pillar.gradient),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(widget.pillar.chip, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDE047),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.black87, width: 1.4),
                                    ),
                                    child: Text(
                                      meta.bannerTitle,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('PT. TMMIN · UNDERBODY ASSY', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black87)),
                                Text(meta.targetLabel, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF047857))),
                                Text(meta.docCode, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black54)),
                              ],
                            ),
                            const Divider(color: Colors.black87, thickness: 1.5),

                            // KPI STRIP
                            if (_subKpis.isNotEmpty) ...[
                              Row(
                                children: _subKpis
                                    .map(
                                      (k) => Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.black26),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(k.label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.black54)),
                                              Text(k.value, style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w900, color: k.color)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 10),
                            ],

                            // BODY PER ROW TYPE
                            if (_rowKey == 'main') _buildMainChart(meta),
                            if (_rowKey == 'sub' || _rowKey == 'proses') _buildPaperTable(),
                            if (_rowKey == 'kaizen') _buildKaizenBoard(),

                            const SizedBox(height: 10),
                            // FOOTER STAMP
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: Border.all(color: Colors.black26)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Periode: $_ym · Offline-First Live Data', style: const TextStyle(fontSize: 9, color: Colors.black54)),
                                  const Text('GL Management Board · Pin-to-Zoom Ready', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black87)),
                                ],
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
    );
  }

  Widget _buildMainChart(DisplayPaperMeta meta) {
    final maxVal = meta.fySeries.fold<double>(1, (acc, e) => e.plan > acc ? e.plan : (e.actual > acc ? e.actual : acc));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GRAFIK CAPAIAN FISCAL YEAR (APR – MAR)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.black87)),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: meta.fySeries.map((pt) {
              final hFrac = maxVal > 0 ? (pt.actual / maxVal).clamp(0.0, 1.0) : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (pt.actual > 0)
                        Text(
                          pt.actual == pt.actual.roundToDouble() ? '${pt.actual.toInt()}' : pt.actual.toStringAsFixed(1),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 7.5, fontWeight: FontWeight.w800, color: Colors.black87),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        height: 115 * hFrac,
                        decoration: BoxDecoration(
                          color: pt.actual > 0 ? widget.pillar.gradient.first : Colors.black12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(pt.monthLabel, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.black87)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaperTable() {
    if (_tableRows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text('Belum ada data tercatat di bulan ini — input di modul operasional terkait.', style: TextStyle(fontSize: 11, color: Colors.black54)),
        ),
      );
    }
    return Table(
      border: TableBorder.all(color: Colors.black38, width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(3.0),
        3: FlexColumnWidth(1.6),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFF1E293B)),
          children: [
            _PaperTh('TGL / ID'),
            _PaperTh('AREA / REGU'),
            _PaperTh('ITEM / PROBLEM'),
            _PaperTh('STATUS / NILAI'),
          ],
        ),
        ..._tableRows.map(
          (r) => TableRow(
            children: [
              _PaperTd(r.col1, mono: true),
              _PaperTd(r.col2, bold: true),
              _PaperTd(r.col3),
              _PaperTd(r.col4, mono: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKaizenBoard() {
    if (_kaizenCards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text('Belum ada Kaizen Report pada pilar ini.', style: TextStyle(fontSize: 11, color: Colors.black54)),
        ),
      );
    }
    return Column(
      children: _kaizenCards
          .map(
            (k) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(k.title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.black))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                        child: Text(k.badge, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text('BEFORE: ${k.before}', style: const TextStyle(fontSize: 10, color: Color(0xFFBE123C), fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.black45),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('AFTER: ${k.after}', style: const TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PaperTh extends StatelessWidget {
  const _PaperTh(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

class _PaperTd extends StatelessWidget {
  const _PaperTd(this.text, {this.mono = false, this.bold = false});
  final String text;
  final bool mono;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: mono ? 'monospace' : null,
          fontSize: 9.5,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
