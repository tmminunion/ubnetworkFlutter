// 1:1 Dart port of Next.js templates (20 sheets):
// quality-main, quality-sub, quality-proses, quality-kaizen,
// productivity-main, productivity-sub, productivity-proses, productivity-kaizen,
// cost-main, cost-sub, cost-proses, cost-kaizen,
// hr-dev-main, hr-dev-sub, hr-dev-proses, hr-dev-kaizen,
// env-main, env-sub, env-proses, env-kaizen.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/chokotei_models.dart';
import '../../models/cost_env_models.dart';
import '../../models/hr_morale_models.dart';
import '../../models/quality_daily_models.dart';
import 'display_paper_defaults.dart';
import 'display_shared_widgets.dart';

// =============================================================================
// 1. QUALITY MAIN — 1:1 `quality-main.tsx`
// =============================================================================

class QualityMainTemplate extends StatelessWidget {
  const QualityMainTemplate({
    super.key,
    required this.fy,
    required this.defectOutSeries,
    required this.inProsesSeries,
  });

  final int fy;
  final FyShiftLineSeries defectOutSeries;
  final FyShiftLineSeries inProsesSeries;

  @override
  Widget build(BuildContext context) {
    final months = DisplayFyMath.fyMonths(fy);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FyLineBlockWidget(
            title: defectOutSeries.title ?? 'DATA DEFECT PER UNIT (D/U) OUT FLOW RED & WHITE',
            balloonLabel: defectOutSeries.label ?? 'D/U',
            axisLabel: defectOutSeries.label ?? 'D/U',
            months: months,
            series: defectOutSeries,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FyLineBlockWidget(
            title: inProsesSeries.title ?? 'QUALITY IN PROSES (D/U) RED & WHITE',
            balloonLabel: inProsesSeries.label ?? 'D/U',
            axisLabel: inProsesSeries.label ?? 'D/U',
            months: months,
            series: inProsesSeries,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 2. QUALITY SUB — 1:1 `quality-sub.tsx`
// =============================================================================

class QualitySubMonthSlot {
  const QualitySubMonthSlot({
    this.prodRed = const [],
    this.prodWhite = const [],
    this.weekend = const [],
    this.totProdRed = 0,
    this.totProdWhite = 0,
    this.outDefRed = const [],
    this.outDefWhite = const [],
    this.inDefRed = const [],
    this.inDefWhite = const [],
    this.targetOut = 0.025,
    this.targetIn = 0.025,
  });

  final List<int?> prodRed; // 31
  final List<int?> prodWhite; // 31
  final List<bool> weekend; // 31
  final int totProdRed;
  final int totProdWhite;
  final List<int?> outDefRed; // 31
  final List<int?> outDefWhite; // 31
  final List<int?> inDefRed; // 31
  final List<int?> inDefWhite; // 31
  final double targetOut;
  final double targetIn;
}

class QualitySubTemplate extends StatelessWidget {
  const QualitySubTemplate({
    super.key,
    required this.ym,
    required this.team,
    required this.threeMonths, // length 3: [-2, -1, 0]
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onTeamChanged,
  });

  final String ym;
  final String team; // 'red' | 'white'
  final List<QualitySubMonthSlot> threeMonths;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String> onTeamChanged;

  @override
  Widget build(BuildContext context) {
    final cur = threeMonths.length >= 3 ? threeMonths[2] : const QualitySubMonthSlot();
    final tgtsOut = List<double>.generate(3, (i) => i < threeMonths.length ? threeMonths[i].targetOut : 0.025);
    final tgtsIn = List<double>.generate(3, (i) => i < threeMonths.length ? threeMonths[i].targetIn : 0.025);
    final teamName = team == 'red' ? 'UB Assy Red' : 'UB Assy White';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperMonthNav(ym: ym, onPrev: onPrevMonth, onNext: onNextMonth),
              const SizedBox(width: 20),
              PaperTeamToggle(team: team, onChanged: onTeamChanged),
              const SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  children: [
                    const TextSpan(text: 'Target D/U · Out Flow '),
                    TextSpan(text: DisplayFyMath.fmtNum(cur.targetOut), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                    const TextSpan(text: ' · In Proses '),
                    TextSpan(text: DisplayFyMath.fmtNum(cur.targetIn), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'O = memenuhi target, X = di atas · Produksi: Monitoring Produksi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _buildBlock('DEFECT OUT FLOW · $teamName', isOut: true, targets: tgtsOut),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _buildBlock('DEFECT IN PROSES · $teamName', isOut: false, targets: tgtsIn),
        ),
      ],
    );
  }

  Widget _buildBlock(String name, {required bool isOut, required List<double> targets}) {
    final dim = DisplayFyMath.daysInMonth(ym);
    final labels = [-2, -1, 0].map((d) => DisplayFyMath.labelOfYm(DisplayFyMath.shiftYm(ym, d))).toList();
    final cur = threeMonths.length >= 3 ? threeMonths[2] : const QualitySubMonthSlot();
    final weekend = List<bool>.generate(
      31,
      (i) => i < cur.weekend.length ? cur.weekend[i] : DisplayFyMath.isWeekend(ym, i + 1),
    );

    final mActs = <int?>[];
    final mDefs = <int?>[];
    final mDus = <double?>[];
    for (var i = 0; i < 3; i++) {
      final s = i < threeMonths.length ? threeMonths[i] : const QualitySubMonthSlot();
      final totAct = team == 'red' ? s.totProdRed : s.totProdWhite;
      final defs = isOut
          ? (team == 'red' ? s.outDefRed : s.outDefWhite)
          : (team == 'red' ? s.inDefRed : s.inDefWhite);
      final nonNullDefs = defs.whereType<int>().toList();
      final totDef = nonNullDefs.isEmpty ? null : nonNullDefs.fold<int>(0, (a, b) => a + b);
      final actVal = totAct > 0 ? totAct : null;
      final du = (totDef != null && actVal != null && actVal > 0) ? totDef / actVal : null;
      mActs.add(actVal);
      mDefs.add(totDef);
      mDus.add(du);
    }

    final curActs = team == 'red' ? cur.prodRed : cur.prodWhite;
    final curDefs = isOut
        ? (team == 'red' ? cur.outDefRed : cur.outDefWhite)
        : (team == 'red' ? cur.inDefRed : cur.inDefWhite);

    final dActs = List<int?>.generate(31, (i) => i < dim && i < curActs.length ? curActs[i] : null);
    final dDefs = List<int?>.generate(31, (i) => i < dim && i < curDefs.length ? curDefs[i] : null);
    final dDus = List<double?>.generate(31, (i) {
      if (i >= dim) return null;
      final a = dActs[i];
      final d = dDefs[i];
      if (d == null || a == null || a <= 0) return null;
      return d / a;
    });

    final target = targets[2];
    Color? duColor(double? v, double t) => v == null ? null : (v <= t ? const Color(0xFF047857) : const Color(0xFFDC2626));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _teamTitleBadge(name, team),
        Expanded(
          child: Sub3MonthDailyChart(
            monthVals: mDus,
            dayVals: dDus,
            weekend: weekend,
            targets: targets,
            yLabel: 'D/U',
            lowerIsBetter: true,
            fractional: true,
          ),
        ),
        Sub3MonthDailyGrid(
          ym: ym,
          monthLabels: labels,
          weekend: weekend,
          cellHeight: 20,
          rows: [
            SubGridRowSpec(
              label: 'Produksi',
              monthCells: mActs.map(DisplayFyMath.formatInt).toList(),
              dayCells: dActs.map(DisplayFyMath.formatInt).toList(),
            ),
            SubGridRowSpec(
              label: 'Defect',
              monthCells: mDefs.map(DisplayFyMath.formatInt).toList(),
              dayCells: dDefs.map(DisplayFyMath.formatInt).toList(),
            ),
            SubGridRowSpec(
              label: 'D/U',
              monthCells: mDus.map((v) => DisplayFyMath.fmtDu(v)).toList(),
              dayCells: dDus.map((v) => DisplayFyMath.fmtDu(v)).toList(),
              monthColors: List.generate(3, (i) => duColor(mDus[i], targets[i])),
              dayColors: List.generate(31, (i) => duColor(dDus[i], target)),
            ),
            SubGridRowSpec(
              label: 'Target',
              monthCells: targets.map((t) => DisplayFyMath.fmtDu(t)).toList(),
              dayCells: List.filled(31, DisplayFyMath.fmtDu(target)),
              rowBg: const Color(0xFFCBD5E1),
            ),
          ],
          monthEva: List.generate(3, (i) => mDus[i] == null ? null : mDus[i]! <= targets[i]),
          dayEva: List.generate(31, (i) => dDus[i] == null ? null : dDus[i]! <= target),
        ),
      ],
    );
  }
}

Widget _teamTitleBadge(String name, String team) {
  final isRed = team == 'red';
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: 460,
      height: 24,
      padding: const EdgeInsets.only(left: 12),
      color: const Color(0xFF3F3B3B),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRed ? const Color(0xFFEF4444) : Colors.white,
              border: Border.all(color: isRed ? const Color(0xFFEF4444) : Colors.white, width: 2),
            ),
          ),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    ),
  );
}

// =============================================================================
// 3. QUALITY PROSES — 1:1 `quality-proses.tsx`
// =============================================================================

class QualityProsesTemplate extends StatelessWidget {
  const QualityProsesTemplate({
    super.key,
    required this.ym,
    required this.findings,
    required this.kindFilter,
    required this.teamFilter,
    required this.kaizenFilter,
    required this.page,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onKindChanged,
    required this.onTeamChanged,
    required this.onKaizenChanged,
    required this.onPageChanged,
  });

  final String ym;
  final List<QualityFinding> findings;
  final String kindFilter; // all | out | in
  final String teamFilter; // all | red | white
  final String kaizenFilter; // all | no | yes
  final int page;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String> onKindChanged;
  final ValueChanged<String> onTeamChanged;
  final ValueChanged<String> onKaizenChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final sumOut = findings.where((f) => f.kind == 'out').fold<int>(0, (s, f) => s + f.qty);
    final sumIn = findings.where((f) => f.kind == 'in').fold<int>(0, (s, f) => s + f.qty);
    final kzCount = findings.where((f) => f.hasKaizen).length;

    final filtered = findings.where((f) {
      if (kindFilter != 'all' && f.kind != kindFilter) return false;
      if (teamFilter != 'all' && f.team != teamFilter) return false;
      if (kaizenFilter != 'all' && (kaizenFilter == 'yes') != f.hasKaizen) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final pages = math.max(1, (filtered.length / 10).ceil());
    final cur = page.clamp(1, pages);
    final start = (cur - 1) * 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperMonthNav(ym: ym, onPrev: onPrevMonth, onNext: onNextMonth),
              const SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  children: [
                    const TextSpan(text: 'Temuan defect: '),
                    TextSpan(text: '${findings.length}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const TextSpan(text: ' · Defect '),
                    TextSpan(text: '${sumOut + sumIn}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                    const TextSpan(text: ' pcs'),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              buildPaperChip('Out Flow', '$sumOut', const Color(0xFFCFFAFE), const Color(0xFF0E7490)),
              const SizedBox(width: 6),
              buildPaperChip('In Proses', '$sumIn', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
              const SizedBox(width: 6),
              buildPaperChip('Kaizen', '$kzCount', const Color(0xFFD1FAE5), const Color(0xFF047857)),
              const Spacer(),
              PaperPager(page: cur, pages: pages, onPageChanged: onPageChanged),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperFilterSeg(
                label: 'JENIS',
                value: kindFilter,
                options: const [('all', 'Semua'), ('out', 'Out Flow'), ('in', 'In Proses')],
                onChanged: onKindChanged,
              ),
              const SizedBox(width: 18),
              PaperFilterSeg(
                label: 'REGU',
                value: teamFilter,
                options: const [('all', 'Semua'), ('red', 'Red'), ('white', 'White')],
                onChanged: onTeamChanged,
              ),
              const SizedBox(width: 18),
              PaperFilterSeg(
                label: 'KAIZEN',
                value: kaizenFilter,
                options: const [('all', 'Semua'), ('no', 'Belum'), ('yes', 'Sudah')],
                onChanged: onKaizenChanged,
              ),
              const SizedBox(width: 16),
              Text(
                '${filtered.length} temuan · terbaru di atas · Sumber: Daily Quality Record',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _TenRowProsesGrid(
            columns: const [
              (36, 'NO'),
              (78, 'TANGGAL'),
              (44, 'REGU'),
              (96, 'JENIS'),
              (170, 'LOKASI PROBLEM'),
              (150, 'DITEMUKAN DI'),
              (-12, 'PROBLEM / TEMUAN'),
              (-10, 'COUNTERMEASURE'),
              (70, 'DEFECT (pcs)'),
              (90, 'KAIZEN'),
              (140, 'PIC'),
            ],
            rowBuilder: (i) {
              final idx = start + i;
              final it = idx < filtered.length ? filtered[idx] : null;
              if (it == null) return List.filled(11, const SizedBox.shrink());
              final belum = !it.hasKaizen;
              return [
                _cText('${idx + 1}', bold: true, color: const Color(0xFF64748B)),
                _cText(DisplayFyMath.daySlashMonth(it.date)),
                _teamBadge(it.team),
                _pill(
                  it.kind == 'out' ? 'Out Flow' : 'In Proses',
                  it.kind == 'out' ? const Color(0xFFCFFAFE) : const Color(0xFFFEF3C7),
                  it.kind == 'out' ? const Color(0xFF0E7490) : const Color(0xFFB45309),
                ),
                _lText(it.process, bold: true),
                _lText(it.foundWhere, color: const Color(0xFFB45309)),
                _lText(it.problem),
                _cmCell(it.countermeasure, belum, 'Belum ada Kaizen'),
                _cText('${it.qty}', bold: true, size: 17, color: const Color(0xFFDC2626)),
                _pill(
                  it.hasKaizen ? 'Sudah' : 'Belum',
                  it.hasKaizen ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  it.hasKaizen ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                ),
                _lText(it.pic, size: 13),
              ];
            },
          ),
        ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              findings.isEmpty ? 'Belum ada temuan defect di bulan ini. Catat lewat Daily Quality Record.' : 'Tidak ada temuan yang sesuai filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// 4. PRODUCTIVITY MAIN — 1:1 `productivity-main.tsx`
// =============================================================================

class ProdFyMonthSide {
  const ProdFyMonthSide({
    required this.act,
    required this.delayMin,
    required this.eff,
  });

  final int act;
  final int delayMin;
  final double eff;
}

class ProdMainTemplate extends StatelessWidget {
  const ProdMainTemplate({
    super.key,
    required this.fy,
    required this.target,
    required this.redMonths, // 12
    required this.whiteMonths, // 12
  });

  final int fy;
  final double target;
  final List<ProdFyMonthSide?> redMonths;
  final List<ProdFyMonthSide?> whiteMonths;

  @override
  Widget build(BuildContext context) {
    final labels = DisplayFyMath.fyMonths(fy);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 18,
          child: Row(
            children: [
              Text('FY $fy – ${fy + 1} · Sumber: Monitoring Produksi', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(width: 18),
              const Text('Merah = di bawah target · ○ tercapai · ✕ belum', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildShiftBlock('RED SHIFT', 'red', redMonths, labels)),
        const SizedBox(height: 6),
        Expanded(child: _buildShiftBlock('WHITE SHIFT', 'white', whiteMonths, labels)),
      ],
    );
  }

  Widget _buildShiftBlock(String name, String team, List<ProdFyMonthSide?> sides, List<String> labels) {
    final isRed = team == 'red';
    final effs = List<double?>.generate(12, (i) => i < sides.length ? sides[i]?.eff : null);
    const border = BorderSide(color: Color(0xFFCBD5E1), width: 0.9);

    Widget rowLine(String label, List<Widget> cells, {Color? leftBg, Color? cellBg, double h = 25, bool head = false}) {
      return SizedBox(
        height: h,
        child: Row(
          children: [
            Container(
              width: 190,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: leftBg ?? const Color(0xFFF8FAFC),
                border: const Border(right: border, bottom: border),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: head ? FontWeight.w800 : FontWeight.w700,
                  color: head ? const Color(0xFF0F172A) : const Color(0xFF334155),
                ),
              ),
            ),
            for (final c in cells)
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cellBg ?? Colors.white,
                    border: const Border(right: border, bottom: border),
                  ),
                  child: c,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 460,
            height: 26,
            padding: const EdgeInsets.only(left: 12),
            color: isRed ? const Color(0xFFFDE047) : const Color(0xFF3F3B3B),
            alignment: Alignment.centerLeft,
            child: Text(
              name,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isRed ? const Color(0xFFDC2626) : Colors.white),
            ),
          ),
        ),
        Expanded(
          child: CustomPaint(
            painter: _ProdFyEffBarPainter(
              eff: effs,
              target: target,
              barColor: isRed ? const Color(0xFFF87171) : const Color(0xFF374151),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        Container(
          decoration: const BoxDecoration(border: Border(top: border, left: border)),
          child: Column(
            children: [
              rowLine(
                'MONTH',
                labels.map((l) => Text(l, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))).toList(),
                leftBg: const Color(0xFFE2E8F0),
                cellBg: const Color(0xFFE2E8F0),
                head: true,
              ),
              rowLine(
                'Produksi',
                List.generate(12, (i) {
                  final x = i < sides.length ? sides[i] : null;
                  return Text(x == null ? '' : DisplayFyMath.formatInt(x.act), style: const TextStyle(fontSize: 15));
                }),
              ),
              rowLine(
                'Line Stop (mnt)',
                List.generate(12, (i) {
                  final x = i < sides.length ? sides[i] : null;
                  return Text(x == null ? '' : DisplayFyMath.formatInt(x.delayMin), style: const TextStyle(fontSize: 15));
                }),
              ),
              rowLine(
                'Actual Efficiency',
                List.generate(12, (i) {
                  final x = i < sides.length ? sides[i] : null;
                  if (x == null) return const SizedBox.shrink();
                  return Text(
                    '${DisplayFyMath.fmtDec(x.eff, 1)}%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: x.eff >= target ? const Color(0xFF047857) : const Color(0xFFDC2626),
                    ),
                  );
                }),
              ),
              rowLine(
                'TARGET',
                List.generate(
                  12,
                  (_) => Text('${DisplayFyMath.fmtDec(target, 1)}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                ),
                cellBg: const Color(0xFFE2E8F0),
              ),
              rowLine(
                'EVA',
                List.generate(12, (i) {
                  final x = i < sides.length ? sides[i] : null;
                  return EvaMarkWidget(ok: x == null ? null : x.eff >= target, size: 20);
                }),
                cellBg: const Color(0xFFFEF3C7),
                h: 32,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProdFyEffBarPainter extends CustomPainter {
  const _ProdFyEffBarPainter({
    required this.eff,
    required this.target,
    required this.barColor,
  });

  final List<double?> eff;
  final double target;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 190.0;
    const top = 14.0;
    final ph = math.max(30.0, size.height - top - 10.0);
    final base = top + ph;
    final pw = math.max(100.0, size.width - left);
    final colW = pw / 12.0;
    final bw = math.min(64.0, colW * 0.5);

    final vals = eff.whereType<double>().toList();
    var minV = target;
    var maxV = target;
    for (final v in vals) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final lo = math.min(70.0, (minV / 5.0).floor() * 5.0);
    final hi = math.max(100.0, (maxV / 5.0).ceil() * 5.0);
    double yOf(double v) => top + ph * (1.0 - (v.clamp(lo, hi) - lo) / math.max(1.0, hi - lo));

    final rect = Rect.fromLTWH(left, top, pw, ph);
    canvas.drawRect(rect, Paint()..color = Colors.white);
    for (var i = 1; i < 12; i++) {
      canvas.drawLine(Offset(left + colW * i, top), Offset(left + colW * i, base), Paint()..color = const Color(0xFFF1F5F9));
    }
    canvas.drawRect(rect, Paint()..color = const Color(0xFFCBD5E1)..style = PaintingStyle.stroke);

    for (var t = lo; t <= hi + 0.01; t += 5) {
      final yy = yOf(t);
      canvas.drawLine(Offset(left, yy), Offset(size.width, yy), Paint()..color = const Color(0xFFE2E8F0));
      final tp = TextPainter(
        text: TextSpan(text: '${t.round()}%', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - 8 - tp.width, yy - tp.height / 2));
    }

    final yTp = TextPainter(
      text: const TextSpan(text: 'EFFICIENCY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFF475569))),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(22, top + ph / 2);
    canvas.rotate(-math.pi / 2);
    yTp.paint(canvas, Offset(-yTp.width / 2, -yTp.height / 2));
    canvas.restore();

    for (var i = 0; i < 12 && i < eff.length; i++) {
      final v = eff[i];
      if (v == null) continue;
      final cx = left + colW * (i + 0.5);
      final yy = yOf(v);
      final inside = (yy - top) < 20;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - bw / 2, yy, bw, math.max(1.0, base - yy)), const Radius.circular(2)),
        Paint()..color = barColor.withValues(alpha: 0.92),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${DisplayFyMath.fmtDec(v, 1)}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: inside ? Colors.white : (v < target ? const Color(0xFFB91C1C) : const Color(0xFF111827)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, inside ? yy + 4 : math.max(0, yy - tp.height - 2)));
    }

    final ty = yOf(target);
    drawDashedLine(canvas, Offset(left, ty), Offset(size.width, ty), const Color(0xFFB91C1C), 2.5, 9, 6);
    final tTp = TextPainter(
      text: TextSpan(
        text: 'TARGET ${DisplayFyMath.fmtDec(target, 1)}%',
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C), backgroundColor: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tTp.paint(canvas, Offset(size.width - 8 - tTp.width, math.max(0, ty - tTp.height - 3)));
  }

  @override
  bool shouldRepaint(covariant _ProdFyEffBarPainter oldDelegate) => true;
}

// =============================================================================
// 5. PRODUCTIVITY SUB — 1:1 `productivity-sub.tsx`
// =============================================================================

class ProdSubDayCell {
  const ProdSubDayCell({
    required this.act,
    required this.stopMin,
    required this.eff,
    required this.isSaved,
  });

  final int act;
  final int stopMin;
  final double eff;
  final bool isSaved;
}

class ProdSubMonthSlot {
  const ProdSubMonthSlot({
    this.redDays = const [],
    this.whiteDays = const [],
    this.weekend = const [],
    this.redSummary,
    this.whiteSummary,
  });

  final List<ProdSubDayCell?> redDays; // 31
  final List<ProdSubDayCell?> whiteDays; // 31
  final List<bool> weekend; // 31
  final ({int totalAct, int totalStop, double avgEff})? redSummary;
  final ({int totalAct, int totalStop, double avgEff})? whiteSummary;
}

class ProductivitySubTemplate extends StatelessWidget {
  const ProductivitySubTemplate({
    super.key,
    required this.ym,
    required this.threeMonths, // [-2, -1, 0]
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final String ym;
  final List<ProdSubMonthSlot> threeMonths;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  static const double _target = 98.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperMonthNav(ym: ym, onPrev: onPrevMonth, onNext: onNextMonth),
              const SizedBox(width: 20),
              const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  children: [
                    TextSpan(text: 'Target Eff '),
                    TextSpan(text: '98,0%', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                'O = memenuhi target, X = di bawah · Sumber: Monitoring Produksi',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildTeamBlock('UB Assy Red', 'red')),
        const SizedBox(height: 6),
        Expanded(child: _buildTeamBlock('UB Assy White', 'white')),
      ],
    );
  }

  Widget _buildTeamBlock(String name, String team) {
    final dim = DisplayFyMath.daysInMonth(ym);
    final labels = [-2, -1, 0].map((d) => DisplayFyMath.labelOfYm(DisplayFyMath.shiftYm(ym, d))).toList();
    final cur = threeMonths.length >= 3 ? threeMonths[2] : const ProdSubMonthSlot();
    final weekend = List<bool>.generate(
      31,
      (i) => i < cur.weekend.length ? cur.weekend[i] : DisplayFyMath.isWeekend(ym, i + 1),
    );

    final mActs = <int?>[];
    final mStops = <int?>[];
    final mEffs = <double?>[];
    for (var i = 0; i < 3; i++) {
      final s = i < threeMonths.length ? threeMonths[i] : const ProdSubMonthSlot();
      final sum = team == 'red' ? s.redSummary : s.whiteSummary;
      if (sum != null && sum.totalAct > 0) {
        mActs.add(sum.totalAct);
        mStops.add(sum.totalStop);
        mEffs.add(sum.avgEff);
      } else {
        mActs.add(null);
        mStops.add(null);
        mEffs.add(null);
      }
    }

    final days = team == 'red' ? cur.redDays : cur.whiteDays;
    final dActs = List<int?>.generate(31, (i) => i < dim && i < days.length && days[i]?.isSaved == true ? days[i]!.act : null);
    final dStops = List<int?>.generate(31, (i) => i < dim && i < days.length && days[i]?.isSaved == true ? days[i]!.stopMin : null);
    final dEffs = List<double?>.generate(31, (i) => i < dim && i < days.length && days[i]?.isSaved == true ? days[i]!.eff : null);

    Color? effColor(double? v) => v == null ? null : (v >= _target ? const Color(0xFF047857) : const Color(0xFFDC2626));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _teamTitleBadge(name, team),
        Expanded(
          child: Sub3MonthDailyChart(
            monthVals: mEffs,
            dayVals: dEffs,
            weekend: weekend,
            targets: const [_target, _target, _target],
            yLabel: '% EFF',
            isBar: true,
            barColor: team == 'red' ? const Color(0xFFF87171) : const Color(0xFF374151),
            lowerIsBetter: false,
            fixedMinY: 70,
            fixedMaxY: 100,
            fixedStep: 10,
          ),
        ),
        Sub3MonthDailyGrid(
          ym: ym,
          monthLabels: labels,
          weekend: weekend,
          cellHeight: 19,
          rows: [
            SubGridRowSpec(
              label: 'Produksi',
              monthCells: mActs.map(DisplayFyMath.formatInt).toList(),
              dayCells: dActs.map(DisplayFyMath.formatInt).toList(),
            ),
            SubGridRowSpec(
              label: 'L/Stop',
              monthCells: mStops.map(DisplayFyMath.formatInt).toList(),
              dayCells: dStops.map(DisplayFyMath.formatInt).toList(),
            ),
            SubGridRowSpec(
              label: 'Eff',
              monthCells: mEffs.map((v) => v == null ? '' : DisplayFyMath.fmtDec(v, v == v.roundToDouble() ? 0 : 1)).toList(),
              dayCells: dEffs.map((v) => v == null ? '' : DisplayFyMath.fmtDec(v, v == v.roundToDouble() ? 0 : 1)).toList(),
              monthColors: mEffs.map(effColor).toList(),
              dayColors: dEffs.map(effColor).toList(),
            ),
            SubGridRowSpec(
              label: 'Target',
              monthCells: const ['98', '98', '98'],
              dayCells: List.filled(31, '98'),
              rowBg: const Color(0xFFCBD5E1),
            ),
          ],
          monthEva: mEffs.map((v) => v == null ? null : v >= _target).toList(),
          dayEva: dEffs.map((v) => v == null ? null : v >= _target).toList(),
        ),
      ],
    );
  }
}

// =============================================================================
// 6. PRODUCTIVITY PROSES (TOP 10 CHOKOTEI INTERNAL) — 1:1 `productivity-chokotei.tsx`
// =============================================================================

class ProductivityProsesTemplate extends StatelessWidget {
  const ProductivityProsesTemplate({
    super.key,
    required this.ym,
    required this.issues,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final String ym;
  final List<ChokoteiIssue> issues;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final intOnly = issues.where((e) => e.category.toUpperCase() != 'EXT').toList();
    final openC = intOnly.where((e) => e.actionStatus == 'open').length;
    final progC = intOnly.where((e) => e.actionStatus == 'in_progress').length;
    final solvedC = intOnly.where((e) => e.actionStatus == 'solved').length;
    final lossTotal = intOnly.fold<int>(0, (s, e) => s + e.lossUnits);
    final stopTotal = intOnly.fold<int>(0, (s, e) => s + e.delayMin);

    int statusRank(String s) => s == 'open' ? 0 : (s == 'in_progress' ? 1 : 2);
    final sorted = [...intOnly]..sort((a, b) {
        final sr = statusRank(a.actionStatus).compareTo(statusRank(b.actionStatus));
        if (sr != 0) return sr;
        if (b.lossUnits != a.lossUnits) return b.lossUnits.compareTo(a.lossUnits);
        return b.delayMin.compareTo(a.delayMin);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperMonthNav(ym: ym, onPrev: onPrevMonth, onNext: onNextMonth),
              const SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  children: [
                    const TextSpan(text: 'Chokotei internal: '),
                    TextSpan(text: '${intOnly.length}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const TextSpan(text: ' kejadian · Loss '),
                    TextSpan(text: '$lossTotal', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                    const TextSpan(text: ' unit · Stop '),
                    TextSpan(text: '$stopTotal', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const TextSpan(text: ' mnt'),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              buildPaperChip('Belum', '$openC', const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
              const SizedBox(width: 6),
              buildPaperChip('Proses', '$progC', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
              const SizedBox(width: 6),
              buildPaperChip('Sudah', '$solvedC', const Color(0xFFD1FAE5), const Color(0xFF047857)),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Top 10: belum ditanggulangi dulu, lalu loss terbesar · Sumber: Checksheet + Chokotei Manual',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _TenRowProsesGrid(
            columns: const [
              (36, 'NO'),
              (78, 'TANGGAL'),
              (44, 'SHIFT'),
              (280, 'LINE / MESIN'),
              (360, 'PROBLEM'),
              (360, 'COUNTERMEASURE'),
              (66, 'LOSS (unit)'),
              (66, 'STOP (mnt)'),
              (112, 'STATUS'),
              (-10, 'PIC'),
            ],
            rowBuilder: (i) {
              final it = i < sorted.length ? sorted[i] : null;
              if (it == null) return List.filled(10, const SizedBox.shrink());
              final isOpen = it.actionStatus == 'open';
              final cmText = it.actionPlan.isNotEmpty ? it.actionPlan : it.countermeasure;
              final stLabel = it.actionStatus == 'solved'
                  ? 'Sudah → Kaizen'
                  : (it.actionStatus == 'in_progress' ? 'Proses' : 'Belum');
              final stBg = it.actionStatus == 'solved'
                  ? const Color(0xFFD1FAE5)
                  : (it.actionStatus == 'in_progress' ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2));
              final stFg = it.actionStatus == 'solved'
                  ? const Color(0xFF047857)
                  : (it.actionStatus == 'in_progress' ? const Color(0xFFB45309) : const Color(0xFFB91C1C));
              return [
                _cText('${i + 1}', bold: true, color: const Color(0xFF64748B)),
                _cText(DisplayFyMath.daySlashMonth(it.tanggal)),
                _teamBadge(it.shift.toLowerCase()),
                Row(
                  children: [
                    Flexible(child: _lText(it.machine, bold: true)),
                    if (it.isManual)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(3)),
                        child: const Text('MANUAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0369A1))),
                      ),
                  ],
                ),
                _lText(it.problem),
                _cmCell(cmText, isOpen, 'Belum ditanggulangi'),
                _cText('${it.lossUnits}', bold: true, size: 17, color: it.lossUnits > 0 ? const Color(0xFFDC2626) : const Color(0xFF0F172A)),
                _cText('${it.delayMin}', size: 16),
                _pill(stLabel, stBg, stFg),
                _lText(it.actionPic, size: 13),
              ];
            },
          ),
        ),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Belum ada chokotei internal di bulan ini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ),
      ],
    );
  }
}

// =============================================================================
// 7. COST MAIN — 1:1 `cost-main.tsx` (Mei - April Budget %)
// =============================================================================

class CostLiveReading {
  const CostLiveReading({required this.pct, required this.day});

  final double pct;
  final int day;
}

class CostMainData {
  const CostMainData({
    this.target = 80,
    required this.red, // 12 (May..Apr)
    required this.white, // 12
    this.liveRed = const [],
    this.liveWhite = const [],
    this.budgetNoRed = '',
    this.budgetNoWhite = '',
  });

  final double target;
  final List<double?> red;
  final List<double?> white;
  final List<CostLiveReading?> liveRed;
  final List<CostLiveReading?> liveWhite;
  final String budgetNoRed;
  final String budgetNoWhite;
}

class CostMainTemplate extends StatelessWidget {
  const CostMainTemplate({
    super.key,
    required this.costFy,
    required this.data,
  });

  final int costFy;
  final CostMainData data;

  ({CostLiveReading live, double projected, String level})? _liveAt(List<double?> act, List<CostLiveReading?> lives, int i) {
    if (i < act.length && act[i] != null) return null;
    if (i >= lives.length || lives[i] == null) return null;
    final lv = lives[i]!;
    final dim = DisplayFyMath.costMonthDays(costFy, i);
    final day = math.min(lv.day, dim);
    if (day < 1 || data.target <= 0) return null;
    final proj = (lv.pct / day) * dim;
    final ratio = proj / data.target;
    final level = (lv.pct > data.target || ratio > 1.1) ? 'bad' : (ratio > 1.0 ? 'warn' : 'ok');
    return (live: lv, projected: proj, level: level);
  }

  @override
  Widget build(BuildContext context) {
    final labels = DisplayFyMath.costMonths(costFy);
    final tgt = data.target > 0 ? data.target : 80.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 20,
          child: Row(
            children: [
              Text('FY $costFy – ${costFy + 1} (Mei – April) · Pemakaian Cost Budget (%)', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
              const SizedBox(width: 16),
              Text('Target: ${DisplayFyMath.fmtNum(tgt)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF0284C7), '≤ ${DisplayFyMath.fmtNum(tgt)}% (Biru)'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFEAB308), '${tgt.round() + 1}–100% (Kuning)'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFDC2626), '> 100% (Merah)'),
              const SizedBox(width: 16),
              Text('○ ≤ ${DisplayFyMath.fmtNum(tgt)}% · ✕ > ${DisplayFyMath.fmtNum(tgt)}%', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildBlock('PEMAKAIAN COST BUDGET · RED', 'red', data.red, data.liveRed, data.budgetNoRed, labels, tgt)),
        const SizedBox(height: 8),
        Expanded(child: _buildBlock('PEMAKAIAN COST BUDGET · WHITE', 'white', data.white, data.liveWhite, data.budgetNoWhite, labels, tgt)),
      ],
    );
  }

  Widget _legendDot(Color c, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
        ],
      );

  Widget _buildBlock(
    String name,
    String team,
    List<double?> actual,
    List<CostLiveReading?> livesRaw,
    String budgetNo,
    List<String> labels,
    double target,
  ) {
    final isRed = team == 'red';
    final lives = List.generate(12, (i) => _liveAt(actual, livesRaw, i));
    const border = BorderSide(color: Color(0xFFCBD5E1), width: 0.9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 460,
            height: 28,
            padding: const EdgeInsets.only(left: 12),
            color: isRed ? const Color(0xFFFDE047) : const Color(0xFF3F3B3B),
            child: Row(
              children: [
                Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isRed ? const Color(0xFFDC2626) : Colors.white)),
                if (budgetNo.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text('No. Budget $budgetNo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isRed ? const Color(0xFFB91C1C) : Colors.white70)),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: CustomPaint(
            painter: _CostBudgetBarPainter(actual: actual, target: target, lives: lives),
            child: const SizedBox.expand(),
          ),
        ),
        Container(
          decoration: const BoxDecoration(border: Border(top: border, left: border)),
          child: Column(
            children: [
              // Header row
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Container(
                      width: 190,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Color(0xFFE2E8F0), border: Border(right: border, bottom: border)),
                      child: const Text('FY (Mei – Apr)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ),
                    for (final l in labels)
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: Color(0xFFE2E8F0), border: Border(right: border, bottom: border)),
                          child: Text(l, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ),
                      ),
                  ],
                ),
              ),
              // TARGET (%)
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Container(
                      width: 190,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.centerLeft,
                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(right: border, bottom: border)),
                      child: const Text('TARGET (%)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                    ),
                    for (var i = 0; i < 12; i++)
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), border: Border(right: border, bottom: border)),
                          child: Text('${DisplayFyMath.fmtNum(target)}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        ),
                      ),
                  ],
                ),
              ),
              // ACTUAL (%)
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Container(
                      width: 190,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.centerLeft,
                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(right: border, bottom: border)),
                      child: const Text('ACTUAL (%)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                    ),
                    for (var i = 0; i < 12; i++)
                      Expanded(
                        child: Builder(
                          builder: (_) {
                            final v = i < actual.length ? actual[i] : null;
                            final lv = lives[i];
                            final bg = v == null
                                ? Colors.white
                                : (v > 100 ? const Color(0xFFFEF2F2) : (v > target ? const Color(0xFFFFFBEB) : Colors.white));
                            final fg = v == null
                                ? const Color(0xFF94A3B8)
                                : (v > 100 ? const Color(0xFFDC2626) : (v > target ? const Color(0xFFB45309) : const Color(0xFF0369A1)));
                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: bg, border: const Border(right: border, bottom: border)),
                              child: v != null
                                  ? Text('${DisplayFyMath.fmtNum(v)}%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg))
                                  : (lv != null
                                      ? Text(
                                          '${DisplayFyMath.fmtNum(lv.live.pct)}% tgl ${lv.live.day}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: lv.level == 'bad'
                                                ? const Color(0xFFDC2626)
                                                : (lv.level == 'warn' ? const Color(0xFFB45309) : const Color(0xFF0369A1)),
                                          ),
                                        )
                                      : const SizedBox.shrink()),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              // EVA
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Container(
                      width: 190,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.centerLeft,
                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(right: border, bottom: border)),
                      child: const Text('EVA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                    ),
                    for (var i = 0; i < 12; i++)
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: Color(0xFFFEF3C7), border: Border(right: border, bottom: border)),
                          child: (i < actual.length && actual[i] != null)
                              ? EvaMarkWidget(ok: actual[i]! <= target, size: 20)
                              : (lives[i] != null
                                  ? Text(
                                      lives[i]!.level == 'ok' ? 'on track' : (lives[i]!.level == 'warn' ? 'waspada' : 'over'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: lives[i]!.level == 'bad'
                                            ? const Color(0xFFDC2626)
                                            : (lives[i]!.level == 'warn' ? const Color(0xFFB45309) : const Color(0xFF0369A1)),
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CostBudgetBarPainter extends CustomPainter {
  const _CostBudgetBarPainter({
    required this.actual,
    required this.target,
    required this.lives,
  });

  final List<double?> actual;
  final double target;
  final List<({CostLiveReading live, double projected, String level})?> lives;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 190.0;
    const top = 18.0;
    final ph = math.max(30.0, size.height - top - 10.0);
    final base = top + ph;
    final pw = math.max(100.0, size.width - left);
    final colW = pw / 12.0;
    final bw = math.min(62.0, colW * 0.56);

    var maxVal = math.max(100.0, target);
    for (final v in actual.whereType<double>()) {
      if (v > maxVal) maxVal = v;
    }
    for (final l in lives) {
      if (l != null && l.projected > maxVal) maxVal = l.projected;
    }
    final step = maxVal <= 100 ? 20.0 : (maxVal <= 150 ? 25.0 : 50.0);
    final ymax = maxVal <= 100 ? 100.0 : (maxVal / step).ceil() * step;
    double yOf(double v) => base - (ph * v.clamp(0.0, ymax)) / ymax;
    double cxOf(int i) => left + colW * (i + 0.5);

    final rect = Rect.fromLTWH(left, top, pw, ph);
    canvas.drawRect(rect, Paint()..color = Colors.white);
    for (var i = 1; i < 12; i++) {
      canvas.drawLine(Offset(left + colW * i, top), Offset(left + colW * i, base), Paint()..color = const Color(0xFFF1F5F9));
    }
    canvas.drawRect(rect, Paint()..color = const Color(0xFFCBD5E1)..style = PaintingStyle.stroke);

    for (var t = 0.0; t <= ymax + 0.01; t += step) {
      final yy = yOf(t);
      canvas.drawLine(Offset(left, yy), Offset(size.width, yy), Paint()..color = const Color(0xFFE2E8F0));
      final tp = TextPainter(
        text: TextSpan(text: '${t.round()}%', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - 8 - tp.width, yy - tp.height / 2));
    }

    final yTp = TextPainter(
      text: const TextSpan(text: 'BUDGET (%)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFF475569))),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(22, top + ph / 2);
    canvas.rotate(-math.pi / 2);
    yTp.paint(canvas, Offset(-yTp.width / 2, -yTp.height / 2));
    canvas.restore();

    // Live TWIS projected bars
    for (var i = 0; i < 12 && i < lives.length; i++) {
      final l = lives[i];
      if (l == null) continue;
      final fill = l.level == 'bad'
          ? const Color(0xFFDC2626)
          : (l.level == 'warn' ? const Color(0xFFEAB308) : const Color(0xFF0284C7));
      final topY = yOf(l.projected);
      final nowY = yOf(l.live.pct);
      final projRect = RRect.fromRectAndRadius(Rect.fromLTWH(cxOf(i) - bw / 2, topY, bw, math.max(2, base - topY)), const Radius.circular(3));
      canvas.drawRRect(projRect, Paint()..color = fill.withValues(alpha: 0.22));
      canvas.drawRRect(projRect, Paint()..color = fill..style = PaintingStyle.stroke..strokeWidth = 1.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cxOf(i) - bw / 2, nowY, bw, math.max(2, base - nowY)), const Radius.circular(3)),
        Paint()..color = fill.withValues(alpha: 0.92),
      );
      final tp = TextPainter(
        text: TextSpan(text: 'Est. ${DisplayFyMath.fmtDec(l.projected, 1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fill)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cxOf(i) - tp.width / 2, math.max(2, topY - tp.height - 2)));
    }

    // Actual bars
    for (var i = 0; i < 12 && i < actual.length; i++) {
      final v = actual[i];
      if (v == null) continue;
      final barY = yOf(v);
      final fill = v > 100 ? const Color(0xFFDC2626) : (v > target ? const Color(0xFFEAB308) : const Color(0xFF0284C7));
      final txtFill = v > 100 ? const Color(0xFFB91C1C) : (v > target ? const Color(0xFFB45309) : const Color(0xFF111827));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cxOf(i) - bw / 2, barY, bw, math.max(2, base - barY)), const Radius.circular(3)),
        Paint()..color = fill.withValues(alpha: 0.92),
      );
      final tp = TextPainter(
        text: TextSpan(text: '${DisplayFyMath.fmtDec(v, v == v.roundToDouble() ? 0 : 1)}%', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: txtFill)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cxOf(i) - tp.width / 2, math.max(2, barY - tp.height - 2)));
    }

    final ty = yOf(target);
    drawDashedLine(canvas, Offset(left, ty), Offset(size.width, ty), const Color(0xFFB91C1C), 2.5, 9, 6);
    final tTp = TextPainter(
      text: TextSpan(
        text: 'TARGET ${DisplayFyMath.fmtNum(target)}%',
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C), backgroundColor: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tTp.paint(canvas, Offset(size.width - 8 - tTp.width, math.max(0, ty - tTp.height - 3)));
  }

  @override
  bool shouldRepaint(covariant _CostBudgetBarPainter oldDelegate) => true;
}

// =============================================================================
// 8. COST SUB (CONTROL COST DAILY RED & WHITE) — 1:1 `cost-sub.tsx`
// =============================================================================

class CostSubTemplate extends StatelessWidget {
  const CostSubTemplate({
    super.key,
    required this.ym,
    required this.monthData,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final String ym;
  final CostDailyMonth monthData;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  int _overCount(String team) {
    final dim = DisplayFyMath.daysInMonth(ym);
    var cnt = 0;
    for (final it in monthData.items) {
      final arr = monthData.valuesFor(team)[it.id] ?? const [];
      final m = CostPaceMath.computeItemMetrics(arr, dim, it.targetFor(team));
      if (m.pct != null && m.pct! > 100) cnt++;
    }
    return cnt;
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DisplayFyMath.todayYmd();
    final today = todayStr.startsWith(ym) ? (int.tryParse(todayStr.substring(8, 10)) ?? 0) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperMonthNav(ym: ym, onPrev: onPrevMonth, onNext: onNextMonth),
              const SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  children: [
                    const TextSpan(text: 'Item lewat target: '),
                    TextSpan(text: 'Red ${_overCount('red')}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                    const TextSpan(text: ' · '),
                    TextSpan(text: 'White ${_overCount('white')}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    TextSpan(text: ' dari ${monthData.items.length} item'),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              buildPaperChip('< 80%', '', const Color(0xFFD1FAE5), const Color(0xFF047857)),
              const SizedBox(width: 6),
              buildPaperChip('80–100%', '', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
              const SizedBox(width: 6),
              buildPaperChip('> 100%', '', const Color(0xFFFECACA), const Color(0xFFB91C1C)),
              const Spacer(),
              const Text('Sumber: Control Cost Daily', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildBlock('DATA CONTROL COST DAILY UB ASSY ( RED )', 'red', today)),
        const SizedBox(height: 6),
        Expanded(child: _buildBlock('DATA CONTROL COST DAILY UB ASSY ( WHITE )', 'white', today)),
      ],
    );
  }

  Widget _buildBlock(String title, String team, int today) {
    final dim = DisplayFyMath.daysInMonth(ym);
    final items = monthData.items;
    final n = math.max(1, items.length);
    final fs = n <= 14 ? 12.5 : (n <= 18 ? 11.5 : (n <= 24 ? 10.0 : 9.0));
    const thin = BorderSide(color: Color(0xFFCBD5E1), width: 0.8);
    const med = BorderSide(color: Color(0xFF94A3B8), width: 0.9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          color: team == 'red' ? const Color(0xFF8B1D1D) : const Color(0xFF3F3B3B),
          child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.4, color: Colors.white)),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: med, left: med)),
            child: Column(
              children: [
                // 2-row header (34px)
                SizedBox(
                  height: 34,
                  child: Row(
                    children: [
                      Container(
                        width: 250,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Color(0xFFE2E8F0), border: Border(right: med, bottom: med)),
                        child: const Text('ITEM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      ),
                      Container(
                        width: 66,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Color(0xFFE2E8F0), border: Border(right: med, bottom: med)),
                        child: const Text('Target\nBulanan', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, height: 1.1, color: Color(0xFF1E293B))),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 17,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: Color(0xFFE2E8F0), border: Border(right: med, bottom: med)),
                              child: Text(DisplayFyMath.longLabelOfYm(ym), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                            ),
                            SizedBox(
                              height: 17,
                              child: Row(
                                children: [
                                  for (var d = 1; d <= 31; d++)
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: d == today
                                              ? const Color(0xFF67E8F9)
                                              : (d <= dim && DisplayFyMath.isWeekend(ym, d) ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                                          border: const Border(right: med, bottom: med),
                                        ),
                                        child: Text(
                                          '$d',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: d > dim
                                                ? const Color(0xFF94A3B8)
                                                : (DisplayFyMath.isWeekend(ym, d) ? const Color(0xFFDC2626) : const Color(0xFF1E293B)),
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
                      Container(
                        width: 64,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Color(0xFFE2E8F0), border: Border(right: med, bottom: med)),
                        child: const Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      ),
                      Container(
                        width: 56,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Color(0xFFE2E8F0), border: Border(right: med, bottom: med)),
                        child: const Text('%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      ),
                    ],
                  ),
                ),
                // Item rows
                for (var r = 0; r < items.length; r++)
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        final it = items[r];
                        final arr = monthData.valuesFor(team)[it.id] ?? const [];
                        final tgt = it.targetFor(team);
                        final met = CostPaceMath.computeItemMetrics(arr, dim, tgt);
                        final pct = met.pct;
                        final pctBg = pct == null
                            ? null
                            : (pct > 100 ? const Color(0xFFFECACA) : (pct >= 80 ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5)));
                        final pctFg = pct == null
                            ? const Color(0xFF0F172A)
                            : (pct > 100 ? const Color(0xFFB91C1C) : (pct >= 80 ? const Color(0xFFB45309) : const Color(0xFF047857)));
                        final rowBg = r.isOdd ? const Color(0xFFF8FAFC) : Colors.white;

                        return Container(
                          color: rowBg,
                          child: Row(
                            children: [
                              Container(
                                width: 250,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                alignment: Alignment.centerLeft,
                                decoration: const BoxDecoration(border: Border(right: thin, bottom: thin)),
                                child: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: fs, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                              ),
                              Container(
                                width: 66,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(border: Border(right: thin, bottom: thin)),
                                child: Text(DisplayFyMath.fmtNum(tgt), style: TextStyle(fontSize: fs, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
                              ),
                              for (var i = 0; i < 31; i++)
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: (i + 1) > dim
                                          ? const Color(0xFFE2E8F0)
                                          : ((i + 1) == today
                                              ? const Color(0xFFCFFAFE)
                                              : (DisplayFyMath.isWeekend(ym, i + 1) ? const Color(0xFFF1F5F9) : null)),
                                      border: const Border(right: thin, bottom: thin),
                                    ),
                                    child: Text(
                                      (i + 1) <= dim && i < arr.length && arr[i] != null ? DisplayFyMath.fmtNum(arr[i]) : '',
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: TextStyle(fontSize: fs - 0.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                    ),
                                  ),
                                ),
                              Container(
                                width: 64,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(border: Border(right: thin, bottom: thin)),
                                child: Text(DisplayFyMath.fmtNum(met.total), style: TextStyle(fontSize: fs, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                              ),
                              Container(
                                width: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: pctBg, border: const Border(right: thin, bottom: thin)),
                                child: Text(pct == null ? '' : '${pct.round()}%', style: TextStyle(fontSize: fs, fontWeight: FontWeight.w800, color: pctFg)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 9. COST PROSES — 1:1 `cost-proses.tsx`
// =============================================================================

class CostProsesTemplate extends StatelessWidget {
  const CostProsesTemplate({
    super.key,
    required this.ym,
    required this.findings,
    required this.kindFilter,
    required this.teamFilter,
    required this.page,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onKindChanged,
    required this.onTeamChanged,
    required this.onPageChanged,
  });

  final String ym;
  final List<CostFinding> findings;
  final String kindFilter; // all | supply | consumable | other
  final String teamFilter; // all | red | white
  final int page;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String> onKindChanged;
  final ValueChanged<String> onTeamChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalLoss = findings.fold<int>(0, (s, f) => s + f.amount);
    final supplyN = findings.where((f) => f.kind == 'supply').length;
    final consN = findings.where((f) => f.kind == 'consumable').length;
    final otherN = findings.where((f) => f.kind == 'other').length;

    final filtered = findings.where((f) {
      if (kindFilter != 'all' && f.kind != kindFilter) return false;
      if (teamFilter != 'all' && f.team != teamFilter) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final pages = math.max(1, (filtered.length / 10).ceil());
    final cur = page.clamp(1, pages);
    final start = (cur - 1) * 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperMonthNav(ym: ym, onPrev: onPrevMonth, onNext: onNextMonth),
              const SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  children: [
                    const TextSpan(text: 'Temuan cost: '),
                    TextSpan(text: '${findings.length}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const TextSpan(text: ' · Potensi loss '),
                    TextSpan(text: formatRupiah(totalLoss), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              buildPaperChip('O. Supply', '$supplyN', const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
              const SizedBox(width: 6),
              buildPaperChip('Consumable Tools', '$consN', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
              const SizedBox(width: 6),
              buildPaperChip('Lainnya', '$otherN', const Color(0xFFE2E8F0), const Color(0xFF334155)),
              const Spacer(),
              PaperPager(page: cur, pages: pages, onPageChanged: onPageChanged),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperFilterSeg(
                label: 'JENIS',
                value: kindFilter,
                options: const [('all', 'Semua'), ('supply', 'O. Supply'), ('consumable', 'Consumable Tools'), ('other', 'Lainnya')],
                onChanged: onKindChanged,
              ),
              const SizedBox(width: 18),
              PaperFilterSeg(
                label: 'REGU',
                value: teamFilter,
                options: const [('all', 'Semua'), ('red', 'Red'), ('white', 'White')],
                onChanged: onTeamChanged,
              ),
              const SizedBox(width: 16),
              Text('${filtered.length} temuan · terbaru di atas · Sumber: Temuan Cost', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _TenRowProsesGrid(
            columns: const [
              (36, 'NO'),
              (78, 'TANGGAL'),
              (44, 'REGU'),
              (120, 'JENIS'),
              (190, 'LOKASI / ITEM'),
              (150, 'DITEMUKAN DI'),
              (-12, 'TEMUAN'),
              (-10, 'PENANGGULANGAN'),
              (110, 'LOSS (Rp)'),
              (120, 'PIC'),
            ],
            rowBuilder: (i) {
              final idx = start + i;
              final it = idx < filtered.length ? filtered[idx] : null;
              if (it == null) return List.filled(10, const SizedBox.shrink());
              final kBg = it.kind == 'supply'
                  ? const Color(0xFFE0F2FE)
                  : (it.kind == 'consumable' ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0));
              final kFg = it.kind == 'supply'
                  ? const Color(0xFF0369A1)
                  : (it.kind == 'consumable' ? const Color(0xFFB45309) : const Color(0xFF334155));
              return [
                _cText('${idx + 1}', bold: true, color: const Color(0xFF64748B)),
                _cText(DisplayFyMath.daySlashMonth(it.date)),
                _teamBadge(it.team),
                _pill(it.kindLabel, kBg, kFg),
                _lText(it.process, bold: true),
                _lText(it.foundWhere, color: const Color(0xFFB45309)),
                _lText(it.problem),
                _lText(it.countermeasure, color: const Color(0xFF334155)),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    it.amount > 0 ? DisplayFyMath.formatInt(it.amount) : '–',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: it.amount > 0 ? const Color(0xFFDC2626) : const Color(0xFF94A3B8)),
                  ),
                ),
                _lText(it.pic, size: 13),
              ];
            },
          ),
        ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              findings.isEmpty ? 'Belum ada temuan cost di bulan ini. Catat lewat halaman Temuan Cost.' : 'Tidak ada temuan yang sesuai filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// 10. HR-DEV MAIN — 1:1 `hr-dev-main.tsx`
// =============================================================================

class HrFyMonthSide {
  const HrFyMonthSide({this.idea, this.maker, this.mp});

  final int? idea;
  final int? maker;
  final int? mp;
}

class HrDevMainTemplate extends StatelessWidget {
  const HrDevMainTemplate({
    super.key,
    required this.fy,
    required this.redMonths, // 12
    required this.whiteMonths, // 12
    required this.targetIdea, // 12
    required this.targetPart, // 12
  });

  final int fy;
  final List<HrFyMonthSide> redMonths;
  final List<HrFyMonthSide> whiteMonths;
  final List<double> targetIdea;
  final List<double> targetPart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 22,
          child: Row(
            children: [
              Text('MONTHLY IDEA RECORD (RATIO & PARTICIPANT)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              SizedBox(width: 18),
              Text('Sumber: Monthly Idea Record HR-Dev', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildShift('RED SHIFT', 'red', redMonths)),
        const SizedBox(height: 6),
        Expanded(child: _buildShift('WHITE SHIFT', 'white', whiteMonths)),
      ],
    );
  }

  Widget _buildShift(String name, String team, List<HrFyMonthSide> sides) {
    final labels = DisplayFyMath.fyMonths(fy);
    final ipm = List<double?>.generate(12, (i) {
      final s = i < sides.length ? sides[i] : const HrFyMonthSide();
      return (s.idea != null && s.mp != null && s.mp! > 0) ? s.idea! / s.mp! : null;
    });
    final pp = List<double?>.generate(12, (i) {
      final s = i < sides.length ? sides[i] : const HrFyMonthSide();
      return (s.maker != null && s.mp != null && s.mp! > 0) ? (s.maker! / s.mp!) * 100.0 : null;
    });

    const border = BorderSide(color: Color(0xFF94A3B8), width: 0.8);
    Widget tRow(String label, List<Widget> cells, {bool shaded = false, bool head = false}) {
      return SizedBox(
        height: 21,
        child: Row(
          children: [
            Container(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), border: Border(right: border, bottom: border)),
              child: Text(label, style: TextStyle(fontSize: 12, fontWeight: head ? FontWeight.w800 : FontWeight.w700, color: const Color(0xFF0F172A))),
            ),
            for (final c in cells)
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: head ? const Color(0xFFF1F5F9) : (shaded ? const Color(0xFFE2E8F0) : Colors.white),
                    border: const Border(right: border, bottom: border),
                  ),
                  child: c,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 300,
            height: 24,
            padding: const EdgeInsets.only(left: 12),
            color: const Color(0xFF3F3B3B),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: team == 'red' ? const Color(0xFFEF4444) : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(border: Border(top: border, left: border)),
          child: Column(
            children: [
              tRow(name, labels.map((l) => Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))).toList(), head: true),
              tRow('Total Idea', List.generate(12, (i) => Text('${i < sides.length ? (sides[i].idea ?? '') : ''}', style: const TextStyle(fontSize: 12.5)))),
              tRow('Jumlah MP', List.generate(12, (i) => Text('${i < sides.length ? (sides[i].mp ?? '') : ''}', style: const TextStyle(fontSize: 12.5)))),
              tRow('Jumlah Pembuat', List.generate(12, (i) => Text('${i < sides.length ? (sides[i].maker ?? '') : ''}', style: const TextStyle(fontSize: 12.5)))),
              tRow('Target Idea/MP', List.generate(12, (i) => Text(DisplayFyMath.fmtNum(targetIdea[i]), style: const TextStyle(fontSize: 12.5))), shaded: true),
              tRow(
                'Idea / MP',
                List.generate(12, (i) {
                  final v = ipm[i];
                  if (v == null) return const SizedBox.shrink();
                  return Text(
                    DisplayFyMath.fmtDec(v, 1),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: v >= targetIdea[i] ? const Color(0xFF047857) : const Color(0xFFDC2626)),
                  );
                }),
              ),
              tRow('Tgt. Participant (%)', List.generate(12, (i) => Text(DisplayFyMath.fmtNum(targetPart[i]), style: const TextStyle(fontSize: 12.5))), shaded: true),
              tRow(
                'Act. Participant (%)',
                List.generate(12, (i) {
                  final v = pp[i];
                  if (v == null) return const SizedBox.shrink();
                  return Text(
                    DisplayFyMath.fmtDec(v, 0),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: v >= targetPart[i] ? const Color(0xFF047857) : const Color(0xFFDC2626)),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _HrMiniBarPainter(
                    title: '< Idea / MP >',
                    vals: ipm,
                    labels: labels,
                    tgts: targetIdea,
                    targetText: 'Target : ${DisplayFyMath.fmtNum(targetIdea.last)} Idea / MP',
                    fractional: true,
                    suffix: '',
                    decimals: 1,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomPaint(
                  painter: _HrMiniBarPainter(
                    title: '< Participant >',
                    vals: pp,
                    labels: labels,
                    tgts: targetPart,
                    targetText: 'Tgt Participant: ${DisplayFyMath.fmtNum(targetPart.last)}%',
                    fractional: false,
                    fixedMax: 100,
                    fixedStep: 25,
                    suffix: '%',
                    decimals: 0,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HrMiniBarPainter extends CustomPainter {
  const _HrMiniBarPainter({
    required this.title,
    required this.vals,
    required this.labels,
    required this.tgts,
    required this.targetText,
    required this.fractional,
    this.fixedMax,
    this.fixedStep,
    required this.suffix,
    required this.decimals,
  });

  final String title;
  final List<double?> vals;
  final List<String> labels;
  final List<double> tgts;
  final String targetText;
  final bool fractional;
  final double? fixedMax;
  final double? fixedStep;
  final String suffix;
  final int decimals;

  @override
  void paint(Canvas canvas, Size size) {
    const lPad = 42.0;
    const rPad = 10.0;
    const tPad = 24.0;
    const bPad = 20.0;
    final ph = math.max(24.0, size.height - tPad - bPad);
    final pw = math.max(80.0, size.width - lPad - rPad);
    final slot = pw / 12.0;
    final bw = slot * 0.5;

    var rawMax = 0.0;
    for (final t in tgts) {
      if (t > rawMax) rawMax = t;
    }
    for (final v in vals.whereType<double>()) {
      if (v > rawMax) rawMax = v;
    }
    double ymax;
    double step;
    if (fixedMax != null && fixedStep != null) {
      ymax = math.max(fixedMax!, (rawMax / fixedStep!).ceil() * fixedStep!);
      step = fixedStep!;
    } else {
      final ax = DisplayFyMath.chartAxis(math.max(rawMax, 1.0), fractional);
      ymax = ax.ymax;
      step = ax.step;
    }

    double yOf(double v) => tPad + ph * (1.0 - v.clamp(0.0, ymax) / ymax);
    double xOf(int i) => lPad + slot * (i + 0.5);

    final titleTp = TextPainter(
      text: TextSpan(text: title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset(size.width / 2 - titleTp.width / 2, 4));

    final rect = Rect.fromLTWH(lPad, tPad, pw, ph);
    canvas.drawRect(rect, Paint()..color = Colors.white);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF9CA3AF)..style = PaintingStyle.stroke);

    for (var t = 0.0; t <= ymax + 0.001; t += step) {
      final yy = yOf(t);
      canvas.drawLine(Offset(lPad, yy), Offset(size.width - rPad, yy), Paint()..color = const Color(0xFFE5E7EB));
      final tp = TextPainter(
        text: TextSpan(text: DisplayFyMath.fmtNum(t), style: const TextStyle(fontSize: 10.5, color: Color(0xFF374151))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lPad - 5 - tp.width, yy - tp.height / 2));
    }

    for (var i = 0; i < 12 && i < vals.length; i++) {
      final v = vals[i];
      if (v != null) {
        final yy = yOf(v);
        final ok = v >= tgts[i];
        final bRect = Rect.fromLTWH(xOf(i) - bw / 2, yy, bw, math.max(0.0, tPad + ph - yy));
        canvas.drawRect(bRect, Paint()..color = ok ? const Color(0xFFBBF7D0) : const Color(0xFFFCA5A5));
        canvas.drawRect(bRect, Paint()..color = const Color(0xFF111827)..style = PaintingStyle.stroke);
        final tp = TextPainter(
          text: TextSpan(text: '${DisplayFyMath.fmtDec(v, decimals)}$suffix', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(xOf(i) - tp.width / 2, math.max(tPad + 1, yy - tp.height - 2)));
      }
      final lTp = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(fontSize: 10.5, color: Color(0xFF374151))),
        textDirection: TextDirection.ltr,
      )..layout();
      lTp.paint(canvas, Offset(xOf(i) - lTp.width / 2, size.height - lTp.height - 1));
    }

    final ty = yOf(tgts.last);
    drawDashedLine(canvas, Offset(lPad, ty), Offset(size.width - rPad, ty), const Color(0xFFEF4444), 2.2, 10, 6);
    final tgtTp = TextPainter(
      text: TextSpan(text: targetText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFEF4444), backgroundColor: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    tgtTp.paint(canvas, Offset(size.width - rPad - 4 - tgtTp.width, math.max(tPad, ty - tgtTp.height - 2)));
  }

  @override
  bool shouldRepaint(covariant _HrMiniBarPainter oldDelegate) => true;
}

// =============================================================================
// 11. HR-DEV SUB — 1:1 `hr-dev-sub.tsx`
// =============================================================================

class HrDevSubTemplate extends StatelessWidget {
  const HrDevSubTemplate({
    super.key,
    required this.ym,
    required this.team,
    required this.threeMonths, // 3 HrIdeaMonth
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onTeamChanged,
  });

  final String ym;
  final String team;
  final List<HrIdeaMonth> threeMonths;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String> onTeamChanged;

  @override
  Widget build(BuildContext context) {
    final gIdea = List<double>.generate(3, (i) => i < threeMonths.length ? threeMonths[i].targetIdea : 2.0);
    final gPart = List<double>.generate(3, (i) => i < threeMonths.length ? threeMonths[i].targetPart : 90.0);
    final teamName = team == 'red' ? 'Red Shift' : 'White Shift';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperMonthNav(ym: ym, onPrev: onPrevMonth, onNext: onNextMonth),
              const SizedBox(width: 20),
              PaperTeamToggle(team: team, onChanged: onTeamChanged),
              const SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  children: [
                    const TextSpan(text: 'Target · Idea/MP '),
                    TextSpan(text: DisplayFyMath.fmtNum(gIdea[2]), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                    const TextSpan(text: ' · Participant '),
                    TextSpan(text: '${DisplayFyMath.fmtNum(gPart[2])}%', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'O = memenuhi target, X = di bawah · Sumber: Monthly Idea Record (/hr/idea)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildBlock(isIdea: true, name: 'IDEA / MP · $teamName', tgts: gIdea)),
        const SizedBox(height: 6),
        Expanded(child: _buildBlock(isIdea: false, name: 'PARTICIPANT · $teamName', tgts: gPart)),
      ],
    );
  }

  Widget _buildBlock({required bool isIdea, required String name, required List<double> tgts}) {
    final dim = DisplayFyMath.daysInMonth(ym);
    final labels = [-2, -1, 0].map((d) => DisplayFyMath.labelOfYm(DisplayFyMath.shiftYm(ym, d))).toList();

    final mCounts = <int?>[];
    final mMps = <int?>[];
    final mRatios = <double?>[];
    for (var i = 0; i < 3; i++) {
      final mYm = DisplayFyMath.shiftYm(ym, i - 2);
      final mDim = DisplayFyMath.daysInMonth(mYm);
      final rec = i < threeMonths.length ? threeMonths[i] : HrIdeaMonth.empty(mYm);
      final side = team == 'red' ? rec.red : rec.white;
      final met = HrIdeaMath.computeTeamMetrics(side, mDim);
      mCounts.add(isIdea ? met.totalIdea : met.totalMaker);
      mMps.add(side.mp);
      mRatios.add(isIdea ? met.ideaPerMp : met.partPct);
    }

    final curRec = threeMonths.length >= 3 ? threeMonths[2] : HrIdeaMonth.empty(ym);
    final curSide = team == 'red' ? curRec.red : curRec.white;
    final dailyRaw = isIdea ? curSide.dailyIdea : curSide.dailyMaker;
    final mp = curSide.mp;

    final dRatios = List<double?>.filled(31, null);
    var run = 0;
    var any = false;
    for (var i = 0; i < dim && i < 31; i++) {
      final v = i < dailyRaw.length ? dailyRaw[i] : null;
      if (v != null) {
        run += v;
        any = true;
      }
      if (any && mp != null && mp > 0) {
        dRatios[i] = isIdea ? (run / mp) : ((run / mp) * 100.0);
      }
    }

    String fmtRatio(double? v) => v == null ? '' : (isIdea ? DisplayFyMath.fmtDec(v, 2) : '${DisplayFyMath.fmtDec(v, 0)}%');
    Color? rColor(double? v, double t) => v == null ? null : (v >= t ? const Color(0xFF047857) : const Color(0xFFDC2626));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _teamTitleBadge(name, team),
        Expanded(
          child: Sub3MonthDailyChart(
            monthVals: mRatios,
            dayVals: dRatios,
            weekend: List.filled(31, false),
            targets: tgts,
            yLabel: isIdea ? 'IDEA / MP' : 'PARTICIPANT',
            lowerIsBetter: false,
            fractional: isIdea,
            fixedMaxY: isIdea ? null : 100,
            targetSuffix: isIdea ? '' : '%',
          ),
        ),
        Sub3MonthDailyGrid(
          ym: ym,
          monthLabels: labels,
          weekend: List.filled(31, false),
          dailyHeaderSuffix: ' (KUMULATIF)',
          cellHeight: 19,
          rows: [
            SubGridRowSpec(
              label: isIdea ? 'Idea' : 'Pembuat',
              monthCells: mCounts.map(DisplayFyMath.formatInt).toList(),
              dayCells: List.generate(31, (i) => i < dim && i < dailyRaw.length ? DisplayFyMath.formatInt(dailyRaw[i]) : ''),
            ),
            SubGridRowSpec(
              label: 'MP',
              monthCells: mMps.map(DisplayFyMath.formatInt).toList(),
              dayCells: List.generate(31, (i) => i < dim ? DisplayFyMath.formatInt(mp) : ''),
            ),
            SubGridRowSpec(
              label: isIdea ? 'Idea/MP' : 'Partisipan',
              monthCells: mRatios.map(fmtRatio).toList(),
              dayCells: dRatios.map(fmtRatio).toList(),
              monthColors: List.generate(3, (i) => rColor(mRatios[i], tgts[i])),
              dayColors: List.generate(31, (i) => rColor(dRatios[i], tgts[2])),
            ),
            SubGridRowSpec(
              label: 'Target',
              monthCells: tgts.map(fmtRatio).toList(),
              dayCells: List.filled(31, fmtRatio(tgts[2])),
              rowBg: const Color(0xFFCBD5E1),
            ),
          ],
          monthEva: List.generate(3, (i) => mRatios[i] == null ? null : mRatios[i]! >= tgts[i]),
          dayEva: List.generate(31, (i) => dRatios[i] == null ? null : dRatios[i]! >= tgts[2]),
        ),
      ],
    );
  }
}

// =============================================================================
// 12. HR-DEV PROSES — 1:1 `hr-dev-proses.tsx`
// =============================================================================

class HrDevProsesTemplate extends StatelessWidget {
  const HrDevProsesTemplate({
    super.key,
    required this.ym,
    required this.findings,
    required this.teamFilter,
    required this.kaizenFilter,
    required this.page,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onTeamChanged,
    required this.onKaizenChanged,
    required this.onPageChanged,
  });

  final String ym;
  final List<HrFindingItem> findings;
  final String teamFilter;
  final String kaizenFilter;
  final int page;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String> onTeamChanged;
  final ValueChanged<String> onKaizenChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final sumQty = findings.fold<int>(0, (s, f) => s + f.qty);
    final kzCount = findings.where((f) => f.hasKaizen).length;

    final filtered = findings.where((f) {
      if (teamFilter != 'all' && f.team != teamFilter) return false;
      if (kaizenFilter != 'all' && (kaizenFilter == 'yes') != f.hasKaizen) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final pages = math.max(1, (filtered.length / 10).ceil());
    final cur = page.clamp(1, pages);
    final start = (cur - 1) * 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperMonthNav(ym: ym, onPrev: onPrevMonth, onNext: onNextMonth),
              const SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  children: [
                    const TextSpan(text: 'Temuan HR-Dev: '),
                    TextSpan(text: '${findings.length}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const TextSpan(text: ' · Jumlah '),
                    TextSpan(text: '$sumQty', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              buildPaperChip('Kaizen', '$kzCount', const Color(0xFFD1FAE5), const Color(0xFF047857)),
              const Spacer(),
              PaperPager(page: cur, pages: pages, onPageChanged: onPageChanged),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperFilterSeg(
                label: 'REGU',
                value: teamFilter,
                options: const [('all', 'Semua'), ('red', 'Red'), ('white', 'White')],
                onChanged: onTeamChanged,
              ),
              const SizedBox(width: 18),
              PaperFilterSeg(
                label: 'KAIZEN',
                value: kaizenFilter,
                options: const [('all', 'Semua'), ('no', 'Belum'), ('yes', 'Sudah')],
                onChanged: onKaizenChanged,
              ),
              const SizedBox(width: 16),
              Text('${filtered.length} temuan · terbaru di atas · Sumber: Temuan HR-Dev (/hr/temuan)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _TenRowProsesGrid(
            columns: const [
              (36, 'NO'),
              (78, 'TANGGAL'),
              (44, 'REGU'),
              (170, 'LOKASI / PROSES'),
              (150, 'DITEMUKAN DI'),
              (-12, 'PROBLEM / TEMUAN'),
              (-10, 'COUNTERMEASURE'),
              (70, 'JUMLAH'),
              (90, 'KAIZEN'),
              (140, 'PIC'),
            ],
            rowBuilder: (i) {
              final idx = start + i;
              final it = idx < filtered.length ? filtered[idx] : null;
              if (it == null) return List.filled(10, const SizedBox.shrink());
              return [
                _cText('${idx + 1}', bold: true, color: const Color(0xFF64748B)),
                _cText(DisplayFyMath.daySlashMonth(it.date)),
                _teamBadge(it.team),
                _lText(it.process, bold: true),
                _lText(it.foundWhere, color: const Color(0xFFB45309)),
                _lText(it.problem),
                _cmCell(it.countermeasure, !it.hasKaizen, 'Belum ada Kaizen'),
                _cText('${it.qty}', bold: true, size: 17, color: const Color(0xFFDC2626)),
                _pill(
                  it.hasKaizen ? 'Sudah' : 'Belum',
                  it.hasKaizen ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  it.hasKaizen ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                ),
                _lText(it.pic, size: 13),
              ];
            },
          ),
        ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              findings.isEmpty ? 'Belum ada temuan di bulan ini. Catat lewat /hr/temuan.' : 'Tidak ada temuan yang sesuai filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// 13. ENV MAIN — 1:1 `env-main.tsx`
// =============================================================================

class EnvMainTemplate extends StatelessWidget {
  const EnvMainTemplate({
    super.key,
    required this.fy,
    required this.foundSeries,
    required this.openSeries,
  });

  final int fy;
  final FyShiftLineSeries foundSeries;
  final FyShiftLineSeries openSeries;

  @override
  Widget build(BuildContext context) {
    final months = DisplayFyMath.fyMonths(fy);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FyLineBlockWidget(
            title: foundSeries.title ?? 'DATA AIR LEAKAGE DITEMUKAN (TITIK) RED & WHITE',
            balloonLabel: foundSeries.label ?? 'DITEMUKAN',
            axisLabel: 'KASUS',
            months: months,
            series: foundSeries,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FyLineBlockWidget(
            title: openSeries.title ?? 'DATA AIR LEAKAGE BELUM DIPERBAIKI (TITIK) RED & WHITE',
            balloonLabel: openSeries.label ?? 'OPEN',
            axisLabel: 'KASUS',
            months: months,
            series: openSeries,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 14. ENV SUB — 1:1 `env-sub.tsx`
// =============================================================================

class EnvSubTemplate extends StatelessWidget {
  const EnvSubTemplate({
    super.key,
    required this.ym,
    required this.threeMonths, // 3 EnvEnergyMonth
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final String ym;
  final List<EnvEnergyMonth> threeMonths;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  double? _avg(List<double?> vals) {
    final nonNull = vals.whereType<double>().toList();
    if (nonNull.isEmpty) return null;
    return nonNull.fold<double>(0, (a, b) => a + b) / nonNull.length;
  }

  @override
  Widget build(BuildContext context) {
    final cur = threeMonths.length >= 3 ? threeMonths[2] : EnvEnergyMonth.empty(ym, target: 0);
    final target = cur.target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperMonthNav(ym: ym, onPrev: onPrevMonth, onNext: onNextMonth),
              const SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  children: [
                    const TextSpan(text: 'Target '),
                    TextSpan(
                      text: target > 0 ? '${DisplayFyMath.fmtNum(target)} kWh/hari' : 'belum diatur',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const Text('Merah = melebihi target · Energi listrik harian', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildBlock('UB Assy Red', 'red', target)),
        const SizedBox(height: 6),
        Expanded(child: _buildBlock('UB Assy White', 'white', target)),
      ],
    );
  }

  Widget _buildBlock(String name, String team, double target) {
    final dim = DisplayFyMath.daysInMonth(ym);
    final labels = [-2, -1, 0].map((d) => DisplayFyMath.labelOfYm(DisplayFyMath.shiftYm(ym, d))).toList();
    final weekend = List<bool>.generate(31, (i) => i < dim && DisplayFyMath.isWeekend(ym, i + 1));

    final ms = List<double?>.generate(3, (i) {
      if (i >= threeMonths.length) return null;
      final m = threeMonths[i];
      return _avg(team == 'red' ? m.red : m.white);
    });

    final cur = threeMonths.length >= 3 ? threeMonths[2] : EnvEnergyMonth.empty(ym, target: 0);
    final rawDays = team == 'red' ? cur.red : cur.white;
    final ds = List<double?>.generate(31, (i) => i < dim && i < rawDays.length ? rawDays[i] : null);

    bool? ok(double? v) => (v == null || target <= 0) ? null : v <= target;
    Color? kwhColor(double? v) {
      final o = ok(v);
      if (o == null) return null;
      return o ? const Color(0xFF047857) : const Color(0xFFDC2626);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _teamTitleBadge(name, team),
        Expanded(
          child: Sub3MonthDailyChart(
            monthVals: ms,
            dayVals: ds,
            weekend: weekend,
            targets: [target, target, target],
            yLabel: 'kWh',
            lowerIsBetter: true,
            fractional: true,
          ),
        ),
        Sub3MonthDailyGrid(
          ym: ym,
          monthLabels: labels,
          weekend: weekend,
          monthHeaderLabel: 'DATA 3 MONTH (rata² / hari)',
          cellHeight: 20,
          rows: [
            SubGridRowSpec(
              label: 'kWh',
              monthCells: ms.map(DisplayFyMath.formatInt).toList(),
              dayCells: ds.map(DisplayFyMath.formatInt).toList(),
              monthColors: ms.map(kwhColor).toList(),
              dayColors: ds.map(kwhColor).toList(),
            ),
            SubGridRowSpec(
              label: 'Target',
              monthCells: List.filled(3, target > 0 ? DisplayFyMath.formatInt(target) : ''),
              dayCells: List.filled(31, target > 0 ? DisplayFyMath.formatInt(target) : ''),
              rowBg: const Color(0xFFCBD5E1),
            ),
          ],
          monthEva: ms.map(ok).toList(),
          dayEva: ds.map(ok).toList(),
        ),
      ],
    );
  }
}

// =============================================================================
// 15. ENV PROSES — 1:1 `env-proses.tsx`
// =============================================================================

class EnvProsesTemplate extends StatelessWidget {
  const EnvProsesTemplate({
    super.key,
    required this.ym,
    required this.findings,
    required this.kindFilter,
    required this.teamFilter,
    required this.statusFilter,
    required this.kaizenFilter,
    required this.page,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onKindChanged,
    required this.onTeamChanged,
    required this.onStatusChanged,
    required this.onKaizenChanged,
    required this.onPageChanged,
  });

  final String ym;
  final List<EnvFindingItem> findings;
  final String kindFilter; // all | leak | energy | other
  final String teamFilter; // all | red | white
  final String statusFilter; // all | open | closed
  final String kaizenFilter; // all | no | yes
  final int page;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String> onKindChanged;
  final ValueChanged<String> onTeamChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onKaizenChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final openN = findings.where((f) => f.status == 'open').length;
    final closedN = findings.length - openN;
    final kzN = findings.where((f) => f.hasKaizen).length;
    final today = DisplayFyMath.todayYmd();

    final filtered = findings.where((f) {
      if (kindFilter != 'all' && f.kind != kindFilter) return false;
      if (teamFilter != 'all' && f.team != teamFilter) return false;
      if (statusFilter != 'all' && f.status != statusFilter) return false;
      if (kaizenFilter != 'all' && (kaizenFilter == 'yes') != f.hasKaizen) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final pages = math.max(1, (filtered.length / 10).ceil());
    final cur = page.clamp(1, pages);
    final start = (cur - 1) * 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperMonthNav(ym: ym, onPrev: onPrevMonth, onNext: onNextMonth),
              const SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  children: [
                    const TextSpan(text: 'Temuan lingkungan: '),
                    TextSpan(text: '${findings.length}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              buildPaperChip('Open', '$openN', const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
              const SizedBox(width: 6),
              buildPaperChip('Closed', '$closedN', const Color(0xFFD1FAE5), const Color(0xFF047857)),
              const SizedBox(width: 6),
              buildPaperChip('Kaizen', '$kzN', const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
              const Spacer(),
              PaperPager(page: cur, pages: pages, onPageChanged: onPageChanged),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: Row(
            children: [
              PaperFilterSeg(
                label: 'JENIS',
                value: kindFilter,
                options: const [('all', 'Semua'), ('leak', 'Air Leakage'), ('energy', 'Energi'), ('other', 'Lainnya')],
                onChanged: onKindChanged,
              ),
              const SizedBox(width: 14),
              PaperFilterSeg(
                label: 'REGU',
                value: teamFilter,
                options: const [('all', 'Semua'), ('red', 'Red'), ('white', 'White')],
                onChanged: onTeamChanged,
              ),
              const SizedBox(width: 14),
              PaperFilterSeg(
                label: 'STATUS',
                value: statusFilter,
                options: const [('all', 'Semua'), ('open', 'Open'), ('closed', 'Closed')],
                onChanged: onStatusChanged,
              ),
              const SizedBox(width: 14),
              PaperFilterSeg(
                label: 'KAIZEN',
                value: kaizenFilter,
                options: const [('all', 'Semua'), ('no', 'Belum'), ('yes', 'Sudah')],
                onChanged: onKaizenChanged,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${filtered.length} temuan · terbaru di atas · target merah = lewat tenggat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _TenRowProsesGrid(
            columns: const [
              (36, 'NO'),
              (78, 'TANGGAL'),
              (44, 'REGU'),
              (100, 'JENIS'),
              (150, 'LOKASI / MESIN'),
              (-13, 'TEMUAN'),
              (-11, 'COUNTERMEASURE'),
              (78, 'TARGET'),
              (80, 'STATUS'),
              (84, 'KAIZEN'),
              (130, 'PIC'),
            ],
            rowBuilder: (i) {
              final idx = start + i;
              final it = idx < filtered.length ? filtered[idx] : null;
              if (it == null) return List.filled(11, const SizedBox.shrink());
              final late = it.status == 'open' && it.due.isNotEmpty && it.due.compareTo(today) < 0;
              final belum = !it.hasKaizen || it.status == 'open';
              final kLabel = it.kind == 'leak' ? 'Air Leakage' : (it.kind == 'energy' ? 'Energi' : 'Lainnya');
              final kBg = it.kind == 'leak'
                  ? const Color(0xFFCFFAFE)
                  : (it.kind == 'energy' ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0));
              final kFg = it.kind == 'leak'
                  ? const Color(0xFF0E7490)
                  : (it.kind == 'energy' ? const Color(0xFFB45309) : const Color(0xFF334155));
              return [
                _cText('${idx + 1}', bold: true, color: const Color(0xFF64748B)),
                _cText(DisplayFyMath.daySlashMonth(it.date)),
                _teamBadge(it.team),
                _pill(kLabel, kBg, kFg),
                _lText(it.location, bold: true),
                _lText(it.problem),
                _cmCell(it.countermeasure, belum, 'Belum ada Kaizen'),
                _cText(DisplayFyMath.daySlashMonth(it.due), bold: late, color: late ? const Color(0xFFDC2626) : const Color(0xFF475569)),
                _pill(
                  it.status == 'closed' ? 'Closed' : 'Open',
                  it.status == 'closed' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  it.status == 'closed' ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                ),
                _pill(
                  it.hasKaizen ? 'Sudah' : 'Belum',
                  it.hasKaizen ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  it.hasKaizen ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                ),
                _lText(it.pic, size: 13),
              ];
            },
          ),
        ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              findings.isEmpty ? 'Belum ada temuan lingkungan di bulan ini. Catat lewat halaman /env/temuan.' : 'Tidak ada temuan yang sesuai filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// 16. KAIZEN REPORT ADAPTER FOR Q / P / C / HR / E — 1:1 `kaizen-report.tsx`
// =============================================================================

KaizenSheetEntry kaizenEntryFromMap(Map<String, dynamic> m) {
  final month = '${m['month'] ?? ''}'.trim();
  final pic = '${m['pic'] ?? ''}'.trim();
  final metric = '${m['metric'] ?? 'INDIKATOR'}'.trim();
  return KaizenSheetEntry(
    id: '${m['id'] ?? m['_id'] ?? ''}',
    theme: '${m['theme'] ?? m['title'] ?? ''}',
    pic: pic,
    line: '${m['line'] ?? 'UB Assy'}',
    process: '${m['process'] ?? m['line_process'] ?? ''}',
    bulanLabel: DisplayFyMath.bulanId(month),
    beforePhoto: '${m['beforePhoto'] ?? ''}',
    beforeCaption: '${m['beforeCaption'] ?? m['beforeText'] ?? m['root_cause'] ?? ''}',
    beforeSub: '${m['process'] ?? ''}',
    beforeBoxLabel: metric.isEmpty ? 'INDIKATOR' : metric,
    beforeBoxSub: '',
    beforeBoxValue: '${m['beforeValue'] ?? m['before_value'] ?? '-'}',
    afterPhoto: '${m['afterPhoto'] ?? ''}',
    afterCaption: '${m['afterCaption'] ?? m['afterText'] ?? m['countermeasure'] ?? ''}',
    afterSub: 'PIC: ${pic.isEmpty ? '-' : pic} · ${DisplayFyMath.bulanId(month)}',
    afterBoxLabel: metric.isEmpty ? 'INDIKATOR' : metric,
    afterBoxSub: '',
    afterBoxValue: '${m['afterValue'] ?? m['after_value'] ?? '-'}',
    result: '${m['result'] ?? m['countermeasure'] ?? ''}',
  );
}

bool isKaizenMapSudah(Map<String, dynamic> m) {
  final s = '${m['status'] ?? ''}'.toLowerCase().trim();
  if (s == 'belum' || s == 'open') return false;
  if (s == 'on progres' || s == 'on progress' || s == 'in_progress' || s == 'proses') return false;
  return true;
}

// =============================================================================
// SHARED 10-ROW PROSES GRID HELPERS
// =============================================================================

class _TenRowProsesGrid extends StatelessWidget {
  const _TenRowProsesGrid({
    required this.columns,
    required this.rowBuilder,
  });

  /// Positive width = fixed px; negative width = flex weight (e.g. -12 => flex 12).
  final List<(double, String)> columns;
  final List<Widget> Function(int rowIdx) rowBuilder;

  @override
  Widget build(BuildContext context) {
    const rBorder = Border(right: BorderSide(color: Color(0xFFCBD5E1)));

    Widget wrapCol(int cIdx, Widget child, {bool isHeader = false}) {
      final spec = columns[cIdx];
      final last = cIdx == columns.length - 1;
      final box = Container(
        padding: isHeader ? const EdgeInsets.symmetric(horizontal: 4) : const EdgeInsets.symmetric(horizontal: 6),
        alignment: isHeader ? Alignment.center : Alignment.centerLeft,
        decoration: BoxDecoration(
          border: last
              ? null
              : (isHeader ? const Border(right: BorderSide(color: Colors.white24)) : rBorder),
        ),
        child: child,
      );
      if (spec.$1 > 0) return SizedBox(width: spec.$1, child: box);
      return Expanded(flex: (-spec.$1).round(), child: box);
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF64748B), width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            color: const Color(0xFF3F3B3B),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columns.length; c++)
                  wrapCol(
                    c,
                    Text(
                      columns[c].$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, height: 1.1, color: Colors.white),
                    ),
                    isHeader: true,
                  ),
              ],
            ),
          ),
          for (var r = 0; r < 10; r++)
            Expanded(
              child: Builder(
                builder: (_) {
                  final cells = rowBuilder(r);
                  return Container(
                    decoration: BoxDecoration(
                      color: r.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
                      border: r < 9 ? const Border(bottom: BorderSide(color: Color(0xFFCBD5E1))) : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var c = 0; c < columns.length; c++)
                          wrapCol(c, c < cells.length ? cells[c] : const SizedBox.shrink()),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

Widget _cText(String t, {bool bold = false, double size = 13.5, Color color = const Color(0xFF0F172A)}) =>
    Center(
      child: Text(
        t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: color),
      ),
    );

Widget _lText(String t, {bool bold = false, double size = 13.5, Color color = const Color(0xFF0F172A)}) =>
    Text(
      t,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, height: 1.2, color: color),
    );

Widget _teamBadge(String team) {
  final isRed = team == 'red';
  return Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isRed ? const Color(0xFFEF4444) : const Color(0xFF334155),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(isRed ? 'R' : 'W', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
    ),
  );
}

Widget _pill(String text, Color bg, Color fg) => Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
      ),
    );

Widget _cmCell(String cm, bool isBelum, String emptyHint) {
  if (cm.trim().isNotEmpty) {
    return Text(
      cm,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: isBelum ? FontWeight.w600 : FontWeight.w500,
        height: 1.2,
        color: isBelum ? const Color(0xFF881337) : const Color(0xFF334155),
      ),
    );
  }
  if (!isBelum) return const SizedBox.shrink();
  return Text(
    emptyHint,
    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFF43F5E)),
  );
}
