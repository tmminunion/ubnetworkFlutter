// 1:1 Dart port of Next.js templates:
// hoshin-main, hoshin-sub, hoshin-proses, hoshin-kaizen,
// safety-main, safety-sub, safety-proses, safety-kaizen.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/safety_finding_models.dart';
import 'display_paper_defaults.dart';
import 'display_shared_widgets.dart';

// =============================================================================
// 1. HOSHIN MAIN — 1:1 `hoshin-main.tsx`
// =============================================================================

class HoshinMainTemplate extends StatelessWidget {
  const HoshinMainTemplate({super.key, this.hoshinData});

  final Map<String, dynamic>? hoshinData;

  @override
  Widget build(BuildContext context) {
    final h = <String, dynamic>{...kHoshinMainDefault, ...?hoshinData};
    final reflections = (h['reflection'] is List ? h['reflection'] as List : kHoshinMainDefault['reflection'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final strategies = (h['strategy'] is List ? h['strategy'] as List : kHoshinMainDefault['strategy'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final kpis = (h['kpi'] is List ? h['kpi'] as List : kHoshinMainDefault['kpi'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final boxBorder = Border.all(color: const Color(0xFF64748B));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pillar + Title Banner
        SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 190,
                color: const Color(0xFF1F4E8C),
                alignment: Alignment.center,
                child: Text(
                  '${h['pillar'] ?? 'Pillar 0'}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFFF1F5F9)]),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${h['pillarTitle'] ?? 'Basic Foundation'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Text(
                        '${h['page'] ?? '1/8'}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Coy Hoshin
        SizedBox(
          height: 52,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 170,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: boxBorder),
                alignment: Alignment.center,
                child: const Text('Coy Hoshin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, border: boxBorder),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${h['coy'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.15, color: Color(0xFF0F172A)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Dir Hoshin + KPI Tgt
        SizedBox(
          height: 68,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 170,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: boxBorder),
                alignment: Alignment.center,
                child: const Text('Dir Hoshin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, border: boxBorder),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${h['dir'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, height: 1.15, color: Color(0xFF0F172A)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 480,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, border: boxBorder),
                alignment: Alignment.centerLeft,
                child: Text(
                  'KPI Tgt : ${h['kpiTarget'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600, height: 1.15, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Three Columns: 31fr : 45fr : 24fr
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FY25 Reflection
              Expanded(
                flex: 31,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, border: boxBorder),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: const Color(0xFFCBD5E1),
                        alignment: Alignment.center,
                        child: const Text('FY25 Reflection', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final g in reflections)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                      color: const Color(0xFFBEF264),
                                      child: Text(
                                        '[${g['title'] ?? ''}] :',
                                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    for (final ln in (g['lines'] is List ? g['lines'] as List : const []))
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('- ', style: TextStyle(fontSize: 20, color: Color(0xFF334155))),
                                            Expanded(
                                              child: Text(
                                                '$ln',
                                                style: const TextStyle(fontSize: 20, height: 1.25, color: Color(0xFF334155)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // FY26 Strategy & Key Activity <include BEB>
              Expanded(
                flex: 45,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, border: boxBorder),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: const Color(0xFF1F4E8C),
                        alignment: Alignment.center,
                        child: const Text(
                          'FY26 Strategy & Key Activity <include BEB>',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final g in strategies)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${g['heading'] ?? ''}',
                                      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, height: 1.18, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 8),
                                    for (var j = 0; j < (g['items'] is List ? (g['items'] as List).length : 0); j++)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 7),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (g['lettered'] == true)
                                              SizedBox(
                                                width: 28,
                                                child: Text(
                                                  '${String.fromCharCode(65 + j)}.',
                                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                '${(g['items'] as List)[j]}',
                                                style: const TextStyle(fontSize: 20, height: 1.24, color: Color(0xFF1E293B)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // KPI
              Expanded(
                flex: 24,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, border: boxBorder),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: const Color(0xFF1F4E8C),
                        alignment: Alignment.center,
                        child: const Text('KPI', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (final g in kpis)
                                Column(
                                  children: [
                                    Container(
                                      padding: g['hl'] == true ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2) : EdgeInsets.zero,
                                      color: g['hl'] == true ? const Color(0xFFBEF264) : Colors.transparent,
                                      child: Text(
                                        '${g['label'] ?? ''}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, height: 1.15, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    for (final ln in (g['lines'] is List ? g['lines'] as List : const []))
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(
                                          '$ln',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 20, height: 1.2, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                  ],
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
    );
  }
}

// =============================================================================
// 2. HOSHIN SUB (DEPARTMENT ACTION PLAN) — 1:1 `hoshin-sub.tsx`
// =============================================================================

class HoshinSubTemplate extends StatelessWidget {
  const HoshinSubTemplate({super.key, this.actionPlanData});

  final Map<String, dynamic>? actionPlanData;

  List<String> _codes(String raw) =>
      raw.split(RegExp(r'[\s,]+')).where((e) => e.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final hasCustom = actionPlanData != null &&
        actionPlanData!['rows'] is List &&
        (actionPlanData!['rows'] as List).isNotEmpty;
    final p = hasCustom ? actionPlanData! : kActionPlanDefault;
    final pics = _codes('${p['pics'] ?? 'FS AS RL W MY S A B ALL'}');
    final sups = _codes('${p['sups'] ?? 'SHE WES TIIN MTN'}');
    final rows = (p['rows'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    int estLines(List<String> items, double w, double fs) {
      final cpl = math.max(4, ((w - 8) / (fs * 0.52)).floor());
      var sum = 0;
      for (final t in items) {
        for (final l in t.split('\n')) {
          sum += math.max(1, (l.length / cpl).ceil());
        }
      }
      return sum;
    }

    int rowWeight(Map<String, dynamic> r, double fs) {
      final impr = (r['improvement'] is List ? (r['improvement'] as List).map((e) => '$e').toList() : const <String>[]);
      final act = (r['activity'] is List ? (r['activity'] as List).map((e) => '$e').toList() : const <String>[]);
      return [
        estLines(['${r['kra'] ?? ''}'], 85, fs),
        estLines(['${r['output'] ?? ''}'], 85, fs),
        estLines(['${r['kpiName'] ?? ''}'], 105, fs),
        estLines(['${r['target'] ?? ''}'], 95, fs),
        estLines(['${r['current'] ?? ''}'], 95, fs),
        estLines(impr, 260, fs),
        estLines(act, 237, fs),
        2,
      ].reduce(math.max);
    }

    double fs = 9.0;
    for (var f = 13.0; f >= 9.0; f -= 1.0) {
      final tot = rows.fold<int>(0, (a, r) => a + rowWeight(r, f));
      if (tot * f * 1.15 + rows.length * 4 <= 600) {
        fs = f;
        break;
      }
    }
    final weights = rows.map((r) => rowWeight(r, fs).toDouble()).toList();
    final weightSum = weights.fold<double>(0, (a, b) => a + b);

    List<({int start, int count, String text, String no})> computeSpans(String key) {
      final out = <({int start, int count, String text, String no})>[];
      for (var i = 0; i < rows.length; i++) {
        final txt = '${rows[i][key] ?? ''}'.trim();
        if (txt.isNotEmpty) {
          out.add((start: i, count: 1, text: txt, no: '${rows[i]['no'] ?? ''}'));
        } else if (out.isNotEmpty) {
          final last = out.removeLast();
          out.add((start: last.start, count: last.count + 1, text: last.text, no: last.no));
        }
      }
      return out;
    }

    final kraSpans = computeSpans('kra');
    final outSpans = computeSpans('output');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top title + DIV/DEPT HEAD signature boxes
        SizedBox(
          height: 38,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${p['title'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${p['subtitle'] ?? ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              for (final sig in [('DIV. HEAD', '${p['divHead'] ?? ''}'), ('DEPT. HEAD', '${p['deptHead'] ?? ''}')])
                Container(
                  width: 130,
                  height: 34,
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF475569))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sig.$1, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      Text(sig.$2, style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Main Matrix Grid via LayoutBuilder for exact merged spans & Gantt bars
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              final totalH = constraints.maxHeight;
              const headerH = 60.0; // 3 rows of 20px
              final bodyH = math.max(100.0, totalH - headerH);

              const noW = 26.0;
              const refW = 56.0;
              const schedW = 12 * 18.0; // 216
              final picW = pics.length * 20.0;
              final supW = sups.length * 26.0;
              final fixedW = noW + refW + schedW + picW + supW;
              final flexAvail = math.max(200.0, totalW - fixedW);
              // Flex proportions: 85 + 85 + 105 + 95 + 95 + 260 + 237 = 962
              double fw(double fr) => flexAvail * (fr / 962.0);
              final kraW = fw(85);
              final outW = fw(85);
              final kpiW = fw(105);
              final tgtW = fw(95);
              final curW = fw(95);
              final impW = fw(260);
              final actW = fw(237);

              final colX = <double>[
                0,
                noW,
                noW + kraW,
                noW + kraW + outW,
                noW + kraW + outW + kpiW,
                noW + kraW + outW + kpiW + refW,
                noW + kraW + outW + kpiW + refW + tgtW,
                noW + kraW + outW + kpiW + refW + tgtW + curW,
                noW + kraW + outW + kpiW + refW + tgtW + curW + impW,
                noW + kraW + outW + kpiW + refW + tgtW + curW + impW + actW,
              ];
              final schedX = colX[9];
              final picX = schedX + schedW;
              final supX = picX + picW;

              final rowY = <double>[headerH];
              final rowH = <double>[];
              for (final w in weights) {
                final h = weightSum > 0 ? bodyH * (w / weightSum) : bodyH / rows.length;
                rowH.add(h);
                rowY.add(rowY.last + h);
              }

              const bSide = BorderSide(color: Color(0xFF475569), width: 0.9);
              Widget cellBox({
                required double left,
                required double top,
                required double width,
                required double height,
                required Widget child,
                Color bg = Colors.white,
                Alignment align = Alignment.center,
                EdgeInsetsGeometry pad = const EdgeInsets.all(2),
              }) {
                return Positioned(
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  child: Container(
                    padding: pad,
                    alignment: align,
                    decoration: BoxDecoration(
                      color: bg,
                      border: const Border(right: bSide, bottom: bSide),
                    ),
                    child: child,
                  ),
                );
              }

              Widget hText(String t, [double? size]) => Text(
                    t,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size ?? fs,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: const Color(0xFF0F172A),
                    ),
                  );

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: bSide, left: bSide),
                ),
                child: Stack(
                  children: [
                    // Headers
                    cellBox(left: colX[0], top: 0, width: noW, height: 60, bg: const Color(0xFFE2E8F0), child: hText('NO')),
                    cellBox(left: colX[1], top: 0, width: kraW, height: 60, bg: const Color(0xFFE2E8F0), child: hText('KEY RESULT AREA')),
                    cellBox(left: colX[2], top: 0, width: outW, height: 60, bg: const Color(0xFFE2E8F0), child: hText('DEPARTMENT OUTPUT')),
                    cellBox(left: colX[3], top: 0, width: kpiW + refW + tgtW + curW, height: 20, bg: const Color(0xFFE2E8F0), child: hText('DEPARTEMENT KPI')),
                    cellBox(left: colX[3], top: 20, width: kpiW, height: 40, bg: const Color(0xFFE2E8F0), child: hText('KPI Name')),
                    cellBox(left: colX[4], top: 20, width: refW, height: 40, bg: const Color(0xFFE2E8F0), child: hText('Ref. No')),
                    cellBox(left: colX[5], top: 20, width: tgtW, height: 40, bg: const Color(0xFFE2E8F0), child: hText('Target')),
                    cellBox(left: colX[6], top: 20, width: curW, height: 40, bg: const Color(0xFFE2E8F0), child: hText('Current')),
                    cellBox(left: colX[7], top: 0, width: impW, height: 60, bg: const Color(0xFFE2E8F0), child: hText('MAIN IMPROVEMENT\n( to achieve the target )')),
                    cellBox(left: colX[8], top: 0, width: actW, height: 60, bg: const Color(0xFFE2E8F0), child: hText('ACTIVITY TARGET\n( for Dept or Supporting Div. )')),
                    cellBox(left: schedX, top: 0, width: schedW, height: 20, bg: const Color(0xFFE2E8F0), child: hText('ACTIVITY SCHEDULE')),
                    cellBox(left: schedX, top: 20, width: 9 * 18.0, height: 20, bg: const Color(0xFFE2E8F0), child: hText('2026')),
                    cellBox(left: schedX + 9 * 18.0, top: 20, width: 3 * 18.0, height: 20, bg: const Color(0xFFE2E8F0), child: hText('2027')),
                    for (var m = 0; m < 12; m++)
                      cellBox(left: schedX + m * 18.0, top: 40, width: 18.0, height: 20, bg: const Color(0xFFE2E8F0), pad: EdgeInsets.zero, child: hText(kIndoMonths[m], fs - 2)),
                    cellBox(left: picX, top: 0, width: picW, height: 40, bg: const Color(0xFFE2E8F0), child: hText('PIC')),
                    for (var i = 0; i < pics.length; i++)
                      cellBox(left: picX + i * 20.0, top: 40, width: 20.0, height: 20, bg: const Color(0xFFE2E8F0), pad: EdgeInsets.zero, child: hText(pics[i], fs - 1.5)),
                    cellBox(left: supX, top: 0, width: supW, height: 40, bg: const Color(0xFFE2E8F0), child: hText('SUPORTING DEPARTMENT', fs - 1.5)),
                    for (var i = 0; i < sups.length; i++)
                      cellBox(left: supX + i * 26.0, top: 40, width: 26.0, height: 20, bg: const Color(0xFFE2E8F0), pad: EdgeInsets.zero, child: hText(sups[i], fs - 2)),

                    // Merged NO & KRA spans
                    for (final sp in kraSpans) ...[
                      cellBox(
                        left: colX[0],
                        top: rowY[sp.start],
                        width: noW,
                        height: rowY[sp.start + sp.count] - rowY[sp.start],
                        align: Alignment.topCenter,
                        child: Text(sp.no, style: TextStyle(fontSize: fs, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      ),
                      cellBox(
                        left: colX[1],
                        top: rowY[sp.start],
                        width: kraW,
                        height: rowY[sp.start + sp.count] - rowY[sp.start],
                        align: Alignment.topLeft,
                        pad: const EdgeInsets.all(3),
                        child: Text(sp.text, style: TextStyle(fontSize: fs, fontWeight: FontWeight.w800, height: 1.15, color: const Color(0xFF0F172A))),
                      ),
                    ],

                    // Merged Output spans
                    for (final sp in outSpans)
                      cellBox(
                        left: colX[2],
                        top: rowY[sp.start],
                        width: outW,
                        height: rowY[sp.start + sp.count] - rowY[sp.start],
                        align: Alignment.topLeft,
                        pad: const EdgeInsets.all(3),
                        child: Text(sp.text, style: TextStyle(fontSize: fs, height: 1.15, color: const Color(0xFF0F172A))),
                      ),

                    // Per-row cells + Gantt + PIC/Sup dots
                    for (var i = 0; i < rows.length; i++) ...[
                      cellBox(
                        left: colX[3],
                        top: rowY[i],
                        width: kpiW,
                        height: rowH[i],
                        align: Alignment.topLeft,
                        pad: const EdgeInsets.all(3),
                        child: Text('${rows[i]['kpiName'] ?? ''}', style: TextStyle(fontSize: fs, height: 1.12, color: const Color(0xFF0F172A))),
                      ),
                      cellBox(
                        left: colX[4],
                        top: rowY[i],
                        width: refW,
                        height: rowH[i],
                        align: Alignment.topCenter,
                        child: Text('${rows[i]['ref'] ?? ''}', textAlign: TextAlign.center, style: TextStyle(fontSize: fs - 0.5, height: 1.12, color: const Color(0xFF0F172A))),
                      ),
                      cellBox(
                        left: colX[5],
                        top: rowY[i],
                        width: tgtW,
                        height: rowH[i],
                        align: Alignment.topLeft,
                        pad: const EdgeInsets.all(3),
                        child: Text('${rows[i]['target'] ?? ''}', style: TextStyle(fontSize: fs, height: 1.12, color: const Color(0xFF0F172A))),
                      ),
                      cellBox(
                        left: colX[6],
                        top: rowY[i],
                        width: curW,
                        height: rowH[i],
                        align: Alignment.topLeft,
                        pad: const EdgeInsets.all(3),
                        child: Text('${rows[i]['current'] ?? ''}', style: TextStyle(fontSize: fs, height: 1.12, color: const Color(0xFF0F172A))),
                      ),
                      cellBox(
                        left: colX[7],
                        top: rowY[i],
                        width: impW,
                        height: rowH[i],
                        align: Alignment.topLeft,
                        pad: const EdgeInsets.all(3),
                        child: Text(
                          (rows[i]['improvement'] is List ? rows[i]['improvement'] as List : const [])
                              .asMap()
                              .entries
                              .map((e) => '${e.key + 1}. ${e.value}')
                              .join('\n'),
                          style: TextStyle(fontSize: fs, height: 1.14, color: const Color(0xFF0F172A)),
                        ),
                      ),
                      cellBox(
                        left: colX[8],
                        top: rowY[i],
                        width: actW,
                        height: rowH[i],
                        align: Alignment.topLeft,
                        pad: const EdgeInsets.all(3),
                        child: Text(
                          (rows[i]['activity'] is List ? rows[i]['activity'] as List : const [])
                              .map((e) => '- $e')
                              .join('\n'),
                          style: TextStyle(fontSize: fs, height: 1.14, color: const Color(0xFF0F172A)),
                        ),
                      ),
                      // Gantt schedule cell
                      Positioned(
                        left: schedX,
                        top: rowY[i],
                        width: schedW,
                        height: rowH[i],
                        child: _buildGanttCell(rows[i], schedW, rowH[i], fs),
                      ),
                      // PIC & Supporting dots
                      ..._buildPicSupDots(rows[i], pics, sups, picX, supX, rowY[i], rowH[i]),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        // Legend bar
        SizedBox(
          height: 22,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${p['legend'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 9, height: 9, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0F172A))),
                const Text(' = MAIN IN CHARGE   ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF334155))),
                ),
                const Text(' = SUPPORTING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGanttCell(Map<String, dynamic> row, double width, double height, double fs) {
    final schedLines = (row['schedule'] is List ? row['schedule'] as List : const []).map((e) => '$e').toList();
    final parsed = parseActionPlanBars(schedLines);
    final laneH = height / parsed.lanes;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFF475569), width: 0.9),
          bottom: BorderSide(color: Color(0xFF475569), width: 0.9),
        ),
      ),
      child: Stack(
        children: [
          // 12 vertical month gridlines
          for (var m = 1; m < 12; m++)
            Positioned(
              left: (width / 12.0) * m,
              top: 0,
              bottom: 0,
              child: Container(width: 0.8, color: const Color(0xFFCBD5E1)),
            ),
          for (final b in parsed.bars)
            Positioned(
              left: (b.start / 12.0) * width + 1,
              width: math.max(8, ((b.end - b.start + 1) / 12.0) * width - 2),
              top: b.lane * laneH + 1,
              height: math.min(14.0, math.max(6.0, laneH - 2)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  b.label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(fontSize: math.max(7.0, fs - 3), fontWeight: FontWeight.w700, height: 1.0, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPicSupDots(
    Map<String, dynamic> row,
    List<String> pics,
    List<String> sups,
    double picX,
    double supX,
    double top,
    double height,
  ) {
    final mainSet = _codes('${row['main'] ?? ''}').toSet();
    final supSet = _codes('${row['sup'] ?? ''}').toSet();
    final widgets = <Widget>[];
    const bSide = BorderSide(color: Color(0xFF475569), width: 0.9);

    for (var i = 0; i < pics.length; i++) {
      final c = pics[i];
      widgets.add(
        Positioned(
          left: picX + i * 20.0,
          top: top,
          width: 20.0,
          height: height,
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(border: Border(right: bSide, bottom: bSide)),
            child: mainSet.contains(c)
                ? Container(width: 8.5, height: 8.5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0F172A)))
                : (supSet.contains(c)
                    ? Container(width: 8.5, height: 8.5, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF334155))))
                    : null),
          ),
        ),
      );
    }

    for (var i = 0; i < sups.length; i++) {
      final c = sups[i];
      widgets.add(
        Positioned(
          left: supX + i * 26.0,
          top: top,
          width: 26.0,
          height: height,
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(border: Border(right: bSide, bottom: bSide)),
            child: mainSet.contains(c)
                ? Container(width: 8.5, height: 8.5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0F172A)))
                : (supSet.contains(c)
                    ? Container(width: 8.5, height: 8.5, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF334155))))
                    : null),
          ),
        ),
      );
    }
    return widgets;
  }
}

// =============================================================================
// 3. HOSHIN PROSES (KPI TREE) — 1:1 `hoshin-proses.tsx`
// =============================================================================

class HoshinProsesTemplate extends StatelessWidget {
  const HoshinProsesTemplate({super.key, this.kpiTreeData});

  final Map<String, dynamic>? kpiTreeData;

  int _linesOf(Map<String, dynamic> r) {
    final sub = r['sub'] is List ? (r['sub'] as List).length : 0;
    final subHead = '${r['subHead'] ?? ''}'.trim().isNotEmpty ? 1 : 0;
    final proc = r['process'] is List ? (r['process'] as List).length : 0;
    final mainL = '${r['main'] ?? ''}'.split('\n').length;
    return [sub + subHead, proc, mainL, 2].reduce(math.max);
  }

  @override
  Widget build(BuildContext context) {
    final rawRows = (kpiTreeData != null && kpiTreeData!['rows'] is List && (kpiTreeData!['rows'] as List).isNotEmpty)
        ? kpiTreeData!['rows'] as List
        : kKpiTreeDefault['rows'] as List;
    final rows = rawRows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    final total = rows.fold<int>(0, (a, r) => a + _linesOf(r));
    final fs = total <= 26 ? 19.0 : (total <= 30 ? 17.0 : (total <= 36 ? 15.0 : 13.0));
    const bSide = BorderSide(color: Color(0xFF475569), width: 1.0);

    Widget hCell(String t) => Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE2E8F0),
            border: Border(right: bSide, bottom: bSide),
          ),
          child: Text(t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: bSide, left: bSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 170, child: hCell('Pillar')),
                SizedBox(width: 330, child: hCell('Main KPI')),
                SizedBox(width: 440, child: hCell('Sub KPI')),
                Expanded(child: hCell('Process KPI')),
              ],
            ),
          ),
          for (final r in rows)
            Expanded(
              flex: _linesOf(r) + 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 170,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(border: Border(right: bSide, bottom: bSide)),
                    child: Text(
                      '${r['pillar'] ?? ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: fs + 6, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                  ),
                  Container(
                    width: 330,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(border: Border(right: bSide, bottom: bSide)),
                    child: Text(
                      '${r['main'] ?? ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: fs + 5, fontWeight: FontWeight.w800, height: 1.18, color: const Color(0xFF0F172A)),
                    ),
                  ),
                  Container(
                    width: 440,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: const BoxDecoration(border: Border(right: bSide, bottom: bSide)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if ('${r['subHead'] ?? ''}'.trim().isNotEmpty)
                          Text('${r['subHead']}', style: TextStyle(fontSize: fs, height: 1.18, color: const Color(0xFF0F172A))),
                        for (final s in (r['sub'] is List ? r['sub'] as List : const []))
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('→  ', style: TextStyle(fontSize: fs, height: 1.18, color: const Color(0xFF0F172A))),
                              Expanded(child: Text('$s', style: TextStyle(fontSize: fs, height: 1.18, color: const Color(0xFF0F172A)))),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: const BoxDecoration(border: Border(right: bSide, bottom: bSide)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final rawS in (r['process'] is List ? r['process'] as List : const []))
                            Builder(
                              builder: (_) {
                                final s = '$rawS';
                                final nested = RegExp(r'^-\s+').hasMatch(s);
                                final clean = s.replaceFirst(RegExp(r'^-\s+'), '');
                                return Padding(
                                  padding: EdgeInsets.only(left: nested ? 44 : 0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nested ? '✓  ' : '•  ', style: TextStyle(fontSize: fs, height: 1.18, color: const Color(0xFF0F172A))),
                                      Expanded(child: Text(clean, style: TextStyle(fontSize: fs, height: 1.18, color: const Color(0xFF0F172A)))),
                                    ],
                                  ),
                                );
                              },
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
    );
  }
}

// =============================================================================
// 4. HOSHIN KAIZEN (STRATEGY) — 1:1 `hoshin-kaizen.tsx`
// =============================================================================

class HoshinKaizenTemplate extends StatelessWidget {
  const HoshinKaizenTemplate({super.key, this.strategyData});

  final Map<String, dynamic>? strategyData;

  List<InlineSpan> _parseMarked(String line, double fs) {
    final spans = <InlineSpan>[];
    final reg = RegExp(r'\[\[(.+?)\]\]');
    var last = 0;
    for (final m in reg.allMatches(line)) {
      if (m.start > last) {
        spans.add(TextSpan(text: line.substring(last, m.start)));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: const Color(0xFFBEF264),
            child: Text(
              m.group(1) ?? '',
              style: TextStyle(fontSize: fs, fontWeight: FontWeight.w600, height: 1.25, color: const Color(0xFF334155)),
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

  @override
  Widget build(BuildContext context) {
    final hasCustom = strategyData != null &&
        strategyData!['groups'] is List &&
        (strategyData!['groups'] as List).isNotEmpty;
    final b = hasCustom ? strategyData! : kStrategyBoardDefault;
    final groups = (b['groups'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    final total = groups.fold<int>(0, (a, g) => a + math.max(1, g['lines'] is List ? (g['lines'] as List).length : 1));
    final fs = total <= 12 ? 40.0 : (total <= 15 ? 34.0 : (total <= 19 ? 28.0 : 23.0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${b['title'] ?? 'STRATEGY'}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 74, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: 1.2, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final g in groups)
                  Expanded(
                    flex: math.max(1, g['lines'] is List ? (g['lines'] as List).length : 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: fs * 3.6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${g['letter'] ?? ''}',
                                style: TextStyle(fontSize: fs * 1.65, fontWeight: FontWeight.w800, height: 1.0, color: const Color(0xFF475569)),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                ':',
                                style: TextStyle(fontSize: fs * 1.3, fontWeight: FontWeight.w800, height: 1.05, color: const Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: fs * 0.08),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final ln in (g['lines'] is List ? g['lines'] as List : const []))
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('~  ', style: TextStyle(fontSize: fs, height: 1.28, color: const Color(0xFF334155))),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            style: TextStyle(fontSize: fs, height: 1.28, color: const Color(0xFF334155)),
                                            children: _parseMarked('$ln', fs),
                                          ),
                                        ),
                                      ),
                                    ],
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
        ),
      ],
    );
  }
}

// =============================================================================
// 5. SAFETY MAIN — 1:1 `safety-main.tsx`
// =============================================================================

class SafetyMainTemplate extends StatelessWidget {
  const SafetyMainTemplate({
    super.key,
    required this.fy,
    required this.accident,
    required this.incident,
  });

  final int fy;
  final FyShiftLineSeries accident;
  final FyShiftLineSeries incident;

  @override
  Widget build(BuildContext context) {
    final months = DisplayFyMath.fyMonths(fy);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FyLineBlockWidget(
            title: accident.title ?? 'DATA ACCIDENT RED & WHITE',
            balloonLabel: accident.label ?? 'ACCIDENT',
            axisLabel: 'KASUS',
            months: months,
            series: accident,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FyLineBlockWidget(
            title: incident.title ?? 'DATA INCIDENT RED & WHITE',
            balloonLabel: incident.label ?? 'INCIDENT',
            axisLabel: 'KASUS',
            months: months,
            series: incident,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 6. SAFETY SUB (KYT + PATROL SAFETY 24-SLOT PAIRED BARS) — 1:1 `safety-sub.tsx`
// =============================================================================

class SafetySubData {
  const SafetySubData({
    required this.kytTarget,
    required this.kytRedGroups, // 3 x 12
    required this.kytWhiteGroups, // 3 x 12
    required this.patrolTarget,
    required this.patrolProblemRed, // 12
    required this.patrolProblemWhite, // 12
    required this.patrolImproveRed, // 12
    required this.patrolImproveWhite, // 12
  });

  final double kytTarget;
  final List<List<double?>> kytRedGroups;
  final List<List<double?>> kytWhiteGroups;
  final double patrolTarget;
  final List<double?> patrolProblemRed;
  final List<double?> patrolProblemWhite;
  final List<double?> patrolImproveRed;
  final List<double?> patrolImproveWhite;
}

class SafetySubTemplate extends StatelessWidget {
  const SafetySubTemplate({
    super.key,
    required this.fy,
    required this.data,
  });

  final int fy;
  final SafetySubData data;

  List<double?> _sumGroups(List<List<double?>> groups) {
    return List<double?>.generate(12, (m) {
      final vals = groups.map((g) => m < g.length ? g[m] : null).whereType<double>().toList();
      if (vals.isEmpty) return null;
      return vals.fold<double>(0, (a, b) => a + b);
    });
  }

  List<double?> _patrolPct(List<double?> prob, List<double?> imp) {
    return List<double?>.generate(12, (m) {
      final p = m < prob.length ? prob[m] : null;
      final im = m < imp.length ? imp[m] : null;
      if (p == null || im == null) return null;
      return p == 0 ? 100.0 : ((im / p) * 100.0).roundToDouble();
    });
  }

  List<double?> _interleave(List<double?> r, List<double?> w) {
    final out = <double?>[];
    for (var i = 0; i < 12; i++) {
      out.add(i < r.length ? r[i] : null);
      out.add(i < w.length ? w[i] : null);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final months = DisplayFyMath.fyMonths(fy);
    final kytTotRed = _sumGroups(data.kytRedGroups);
    final kytTotWhite = _sumGroups(data.kytWhiteGroups);
    final kytCells = _interleave(kytTotRed, kytTotWhite);
    var kytMax = math.max(5.0, data.kytTarget);
    for (final v in kytCells.whereType<double>()) {
      if (v > kytMax) kytMax = v;
    }

    final pr = _patrolPct(data.patrolProblemRed, data.patrolImproveRed);
    final pw = _patrolPct(data.patrolProblemWhite, data.patrolImproveWhite);
    final pctCells = _interleave(pr, pw);
    var pctMax = math.max(100.0, data.patrolTarget);
    for (final v in pctCells.whereType<double>()) {
      if (v > pctMax) pctMax = v;
    }
    final pctTop = (pctMax / 25.0).ceil() * 25.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SECTION 1: KYT RED & WHITE
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader('KYT RED & WHITE'),
              Expanded(
                child: CustomPaint(
                  painter: _SafetyPairChartPainter(
                    interleaved: kytCells,
                    ymax: kytMax.ceilToDouble(),
                    step: 1,
                    target: data.kytTarget,
                    balloon: 'TARGET ${DisplayFyMath.fmtNum(data.kytTarget)} TEMA KYT/BLN',
                    yLabel: 'TEMA KYT',
                    suffix: '',
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              _build24SlotTable(
                months: months,
                rows: [
                  for (var g = 0; g < 3; g++)
                    (
                      label: 'GROUP${g + 1}',
                      cells: _interleave(
                        g < data.kytRedGroups.length ? data.kytRedGroups[g] : const [],
                        g < data.kytWhiteGroups.length ? data.kytWhiteGroups[g] : const [],
                      ).map((v) => v == null ? '' : DisplayFyMath.fmtNum(v)).toList(),
                      bg: null,
                      bold: false,
                    ),
                  (
                    label: 'TOTAL',
                    cells: kytCells.map((v) => v == null ? '' : DisplayFyMath.fmtNum(v)).toList(),
                    bg: const Color(0xFFFEF9C3),
                    bold: true,
                  ),
                  (
                    label: 'TARGET KYT',
                    cells: List.filled(24, DisplayFyMath.fmtNum(data.kytTarget)),
                    bg: const Color(0xFFE2E8F0),
                    bold: false,
                  ),
                ],
                eva: kytCells.map((v) => v == null ? null : v >= data.kytTarget).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // SECTION 2: PATROL SAFETY RED & WHITE
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionHeader('PATROL SAFETY RED & WHITE'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF34D399)),
                        SizedBox(width: 6),
                        Text(
                          'Auto-sync dari Temuan & Kaizen Proses KPI',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: CustomPaint(
                  painter: _SafetyPairChartPainter(
                    interleaved: pctCells,
                    ymax: pctTop,
                    step: 25,
                    target: data.patrolTarget,
                    balloon: 'TARGET ${DisplayFyMath.fmtNum(data.patrolTarget)}% PENANGGULANGAN',
                    yLabel: 'TEMUAN',
                    suffix: '%',
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              _build24SlotTable(
                months: months,
                rows: [
                  (
                    label: 'PROBLEM',
                    cells: _interleave(data.patrolProblemRed, data.patrolProblemWhite)
                        .map((v) => v == null ? '' : DisplayFyMath.fmtNum(v))
                        .toList(),
                    bg: null,
                    bold: false,
                  ),
                  (
                    label: 'IMPROVE',
                    cells: _interleave(data.patrolImproveRed, data.patrolImproveWhite)
                        .map((v) => v == null ? '' : DisplayFyMath.fmtNum(v))
                        .toList(),
                    bg: null,
                    bold: false,
                  ),
                  (
                    label: '%',
                    cells: pctCells.map((v) => v == null ? '' : '${DisplayFyMath.fmtNum(v)}%').toList(),
                    bg: const Color(0xFFFEF9C3),
                    bold: true,
                  ),
                  (
                    label: 'TARGET',
                    cells: List.filled(24, '${DisplayFyMath.fmtNum(data.patrolTarget)}%'),
                    bg: const Color(0xFFE2E8F0),
                    bold: false,
                  ),
                ],
                eva: pctCells.map((v) => v == null ? null : v >= data.patrolTarget).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 460,
        height: 26,
        padding: const EdgeInsets.only(left: 12),
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(
          color: Color(0xFF3F3B3B),
          border: Border(left: BorderSide(color: Color(0xFF34D399), width: 6)),
        ),
        child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }

  Widget _build24SlotTable({
    required List<String> months,
    required List<({String label, List<String> cells, Color? bg, bool bold})> rows,
    required List<bool?> eva,
  }) {
    const thin = BorderSide(color: Color(0xFFCBD5E1), width: 0.8);
    const grpLeft = BorderSide(color: Color(0xFF64748B), width: 1.0);

    return Container(
      decoration: const BoxDecoration(border: Border(top: grpLeft, left: grpLeft)),
      child: Column(
        children: [
          // Month row (12 x col-span-2)
          SizedBox(
            height: 22,
            child: Row(
              children: [
                Container(
                  width: 190,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    border: Border(right: grpLeft, bottom: thin),
                  ),
                  child: const Text('MONTH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ),
                for (var m = 0; m < 12; m++)
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        border: Border(right: grpLeft, bottom: thin),
                      ),
                      child: Text(months[m], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ),
                  ),
              ],
            ),
          ),
          // R | W row
          SizedBox(
            height: 20,
            child: Row(
              children: [
                Container(
                  width: 190,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(right: grpLeft, bottom: thin),
                  ),
                ),
                for (var i = 0; i < 24; i++)
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        border: Border(right: i.isOdd ? grpLeft : thin, bottom: thin),
                      ),
                      child: Text(
                        i.isEven ? 'R' : 'W',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: i.isEven ? const Color(0xFFEF4444) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Data rows
          for (final r in rows)
            SizedBox(
              height: 21,
              child: Row(
                children: [
                  Container(
                    width: 190,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: r.bg ?? const Color(0xFFF8FAFC),
                      border: const Border(right: grpLeft, bottom: thin),
                    ),
                    child: Text(
                      r.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: r.bold ? FontWeight.w800 : FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  for (var i = 0; i < 24; i++)
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: r.bg ?? Colors.white,
                          border: Border(right: i.isOdd ? grpLeft : thin, bottom: thin),
                        ),
                        child: Text(
                          i < r.cells.length ? r.cells[i] : '',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: r.bold ? FontWeight.w800 : FontWeight.w500,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // EVA row
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Container(
                  width: 190,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(right: grpLeft, bottom: grpLeft),
                  ),
                  child: const Text('EVA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                ),
                for (var i = 0; i < 24; i++)
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        border: Border(right: i.isOdd ? grpLeft : thin, bottom: grpLeft),
                      ),
                      child: EvaMarkWidget(ok: i < eva.length ? eva[i] : null, size: 17),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyPairChartPainter extends CustomPainter {
  const _SafetyPairChartPainter({
    required this.interleaved,
    required this.ymax,
    required this.step,
    required this.target,
    required this.balloon,
    required this.yLabel,
    required this.suffix,
  });

  final List<double?> interleaved;
  final double ymax;
  final double step;
  final double target;
  final String balloon;
  final String yLabel;
  final String suffix;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 190.0;
    const top = 36.0;
    final ph = math.max(30.0, size.height - top - 6.0);
    final base = top + ph;
    final pw = math.max(100.0, size.width - left);
    final slotW = pw / 24.0;
    final safeMax = math.max(1.0, ymax);
    double yOf(double v) => base - (math.min(v, safeMax) / safeMax) * ph;

    final rect = Rect.fromLTWH(left, top, pw, ph);
    canvas.drawRect(rect, Paint()..color = Colors.white);
    for (var m = 0; m < 12; m++) {
      if (m.isOdd) {
        canvas.drawRect(Rect.fromLTWH(left + slotW * 2 * m, top, slotW * 2, ph), Paint()..color = const Color(0xFFF8FAFC));
      }
    }
    canvas.drawRect(rect, Paint()..color = const Color(0xFFCBD5E1)..style = PaintingStyle.stroke);

    // Ticks
    for (var t = 0.0; t <= safeMax + 0.01; t += step) {
      final yy = yOf(t);
      canvas.drawLine(Offset(left, yy), Offset(size.width, yy), Paint()..color = const Color(0xFFE2E8F0));
      final tp = TextPainter(
        text: TextSpan(
          text: '${DisplayFyMath.fmtNum(t)}$suffix',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - 8 - tp.width, yy - tp.height / 2));
    }

    // Y-axis rotated
    final yTp = TextPainter(
      text: TextSpan(text: yLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFF475569))),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(22, top + ph / 2);
    canvas.rotate(-math.pi / 2);
    yTp.paint(canvas, Offset(-yTp.width / 2, -yTp.height / 2));
    canvas.restore();

    // Legend
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(46, 8, 16, 14), const Radius.circular(3)), Paint()..color = const Color(0xFFF87171));
    (TextPainter(text: const TextSpan(text: 'Red', style: TextStyle(fontSize: 13, color: Color(0xFF475569))), textDirection: TextDirection.ltr)..layout()).paint(canvas, const Offset(68, 7));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(108, 8, 16, 14), const Radius.circular(3)), Paint()..color = const Color(0xFF374151));
    (TextPainter(text: const TextSpan(text: 'White', style: TextStyle(fontSize: 13, color: Color(0xFF475569))), textDirection: TextDirection.ltr)..layout()).paint(canvas, const Offset(130, 7));

    // Bars
    for (var i = 0; i < 24 && i < interleaved.length; i++) {
      final v = interleaved[i];
      if (v == null) continue;
      final yy = yOf(v);
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(left + slotW * i + slotW * 0.14, yy, slotW * 0.72, math.max(1.0, base - yy)),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        r,
        Paint()..color = (i.isEven ? const Color(0xFFF87171) : const Color(0xFF374151)).withValues(alpha: 0.92),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${DisplayFyMath.fmtNum(v)}$suffix',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left + slotW * (i + 0.5) - tp.width / 2, math.max(2.0, yy - tp.height - 2)));
    }

    // Target line + top-right pill
    final ty = yOf(target);
    drawDashedLine(canvas, Offset(left, ty), Offset(size.width, ty), const Color(0xFFB91C1C), 2.5, 10, 6);

    final pillTp = TextPainter(
      text: TextSpan(text: balloon, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C))),
      textDirection: TextDirection.ltr,
    )..layout();
    final bw = pillTp.width + 26;
    final pillRect = RRect.fromRectAndRadius(Rect.fromLTWH(size.width - bw - 8, 5, bw, 25), const Radius.circular(13));
    canvas.drawRRect(pillRect, Paint()..color = Colors.white);
    canvas.drawRRect(pillRect, Paint()..color = const Color(0xFFB91C1C)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    pillTp.paint(canvas, Offset(size.width - bw / 2 - 8 - pillTp.width / 2, 17.5 - pillTp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _SafetyPairChartPainter oldDelegate) => true;
}

// =============================================================================
// 7. SAFETY PROSES (OFFICIAL 8-COL LIST UP PROBLEM SHEET) — 1:1 `safety-proses.tsx`
// =============================================================================

class SafetyProsesTemplate extends StatelessWidget {
  const SafetyProsesTemplate({
    super.key,
    required this.findings,
    required this.filter,
    required this.page,
    required this.onFilterChanged,
    required this.onPageChanged,
    this.onPrintPdf,
    this.onSharePdf,
  });

  final List<SafetyFinding> findings;
  final String filter; // 'all' | 'open' | 'closed'
  final int page;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onPrintPdf;
  final VoidCallback? onSharePdf;

  static const int _perPage = 4;

  static const List<List<String>> _sourceGroups = [
    ['Yokoten Accident', 'TOP Management Patrol', 'Safety Close Up'],
    ['Work Risk Assessment', 'Safety Patrol Internal', 'Safety Patrol SHE'],
    ['KYT', 'Hyarihatto', 'Voice Member'],
    ['Changing Point / Henkaten', 'Machine Safety Audit', 'Safety Device Check'],
  ];

  @override
  Widget build(BuildContext context) {
    final allCount = findings.length;
    final closedCount = findings.where((f) => f.status == 'closed').length;
    final openCount = allCount - closedCount;

    final filtered = findings.where((f) {
      if (filter == 'closed') return f.status == 'closed';
      if (filter == 'open') return f.status != 'closed';
      return true;
    }).toList();

    final pages = math.max(1, (filtered.length / _perPage).ceil());
    final cur = page.clamp(1, pages);
    final start = (cur - 1) * _perPage;
    final slots = List<SafetyFinding?>.generate(
      _perPage,
      (i) => (start + i) < filtered.length ? filtered[start + i] : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top info & filter bar
        SizedBox(
          height: 28,
          child: Row(
            children: [
              _infoSpan('Division', 'PWPD'),
              const SizedBox(width: 28),
              _infoSpan('Shop', 'WELDING BODY #1'),
              const SizedBox(width: 28),
              _infoSpan('Line', 'UB Assy'),
              const Spacer(),
              if (onPrintPdf != null) ...[
                GestureDetector(
                  onTap: onPrintPdf,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      children: [
                        Icon(Icons.print_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Cetak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (onSharePdf != null) ...[
                GestureDetector(
                  onTap: onSharePdf,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      children: [
                        Icon(Icons.share_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Kirim PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 8), color: const Color(0xFFCBD5E1)),
              ],
              PaperFilterSeg(
                label: '',
                value: filter,
                options: [
                  ('all', 'Semua $allCount'),
                  ('open', 'Belum $openCount'),
                  ('closed', 'Sudah $closedCount'),
                ],
                onChanged: onFilterChanged,
              ),
              Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 8), color: const Color(0xFFCBD5E1)),
              PaperPager(page: cur, pages: pages, onPageChanged: onPageChanged),
            ],
          ),
        ),
        const SizedBox(height: 5),

        // 8-column bordered sheet
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF64748B), width: 2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  height: 36,
                  color: const Color(0xFF3F3B3B),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _headCell(32, ['NO']),
                      _headCell(186, ['PROBLEM']),
                      _headCell(100, ['HAZARD', 'CONDITION']),
                      _headCell(200, ['SOURCE']),
                      _headCell(290, ['RISK BEFORE COUNTERMEASURE', '(Type, Level)']),
                      _headCell(190, ['RECOMMENDATION', '( Standard )']),
                      _headCell(260, ['COUNTERMEASURE', 'PIC · DATE']),
                      Expanded(child: _headCell(null, ['RISK AFTER COUNTERMEASURE', '(Type, Level)'], last: true)),
                    ],
                  ),
                ),
                // 4 Finding Rows
                for (var i = 0; i < _perPage; i++)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: i < _perPage - 1
                            ? const Border(bottom: BorderSide(color: Color(0xFF64748B), width: 2))
                            : null,
                      ),
                      child: _buildFindingRow(slots[i], slots[i] != null ? '${start + i + 1}' : ''),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoSpan(String l, String v) => Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          children: [
            TextSpan(text: '$l: ', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
            TextSpan(text: v),
          ],
        ),
      );

  Widget _headCell(double? w, List<String> lines, {bool last = false}) {
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: last ? null : const Border(right: BorderSide(color: Colors.white24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < lines.length; i++)
            Text(
              lines[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w500,
                color: i == 0 ? Colors.white : Colors.white70,
                height: 1.15,
              ),
            ),
        ],
      ),
    );
    return w != null ? SizedBox(width: w, child: box) : box;
  }

  Widget _buildFindingRow(SafetyFinding? rawFinding, String no) {
    final isEmpty = rawFinding == null;
    final f = rawFinding ?? SafetyFinding(id: '');
    final isClosed = !isEmpty && f.status == 'closed';
    final hasPhotoAfter = !isEmpty && f.photoAfter.trim().isNotEmpty;
    final isBelum = !isEmpty && (f.status == 'open' || (!isClosed && f.cm.trim().isEmpty && !hasPhotoAfter));
    const rBorder = Border(right: BorderSide(color: Color(0xFF94A3B8)));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. NO
        Container(
          width: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(border: rBorder),
          child: Text(no, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        ),

        // 2. PROBLEM (Location + Status + Photo + Caption)
        Container(
          width: 186,
          decoration: const BoxDecoration(border: rBorder),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 3, 6, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 10, color: Color(0xFF0F172A)),
                          children: [
                            const TextSpan(text: 'Location : ', style: TextStyle(color: Color(0xFF64748B))),
                            TextSpan(text: isEmpty ? '' : f.location, style: const TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isEmpty && f.caption.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isClosed
                              ? const Color(0xFFD1FAE5)
                              : (f.status == 'progress' ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          SafetyRiskMaster.statusLabels[f.status] ?? 'Belum',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isClosed
                                ? const Color(0xFF047857)
                                : (f.status == 'progress' ? const Color(0xFFB45309) : const Color(0xFFB91C1C)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: buildPaperPhotoBox(isEmpty ? null : f.photo, placeholder: 'FOTO', fit: BoxFit.cover),
                ),
              ),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                child: Text(
                  isEmpty ? '' : f.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        ),

        // 3. HAZARD CONDITION
        Container(
          width: 100,
          decoration: const BoxDecoration(border: rBorder),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var hi = 0; hi < SafetyRiskMaster.hazards.length; hi++)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: (!isEmpty && f.hazard == hi) ? const Color(0xFFCBD5E1) : const Color(0xFFF1F5F9),
                      border: hi < 3 ? const Border(bottom: BorderSide(color: Color(0xFFCBD5E1))) : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            SafetyRiskMaster.hazards[hi],
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: (!isEmpty && f.hazard == hi) ? FontWeight.w800 : FontWeight.w500,
                              height: 1.1,
                              color: (!isEmpty && f.hazard == hi) ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        if (!isEmpty && f.hazard == hi)
                          const Text('✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 4. SOURCE (12 items in 4 groups)
        Container(
          width: 200,
          decoration: const BoxDecoration(border: rBorder),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var gi = 0; gi < _sourceGroups.length; gi++)
                Expanded(
                  child: Container(
                    decoration: gi < 3 ? const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF94A3B8)))) : null,
                    child: Column(
                      children: [
                        for (var si = 0; si < _sourceGroups[gi].length; si++)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: si < 2 ? const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))) : null,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _sourceGroups[gi][si],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 9, color: Color(0xFF1E293B)),
                                    ),
                                  ),
                                  if (!isEmpty && f.sources.contains(gi * 3 + si))
                                    const Text('✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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

        // 5. RISK BEFORE
        Container(
          width: 290,
          decoration: const BoxDecoration(border: rBorder),
          child: _buildRiskBox(f.before),
        ),

        // 6. RECOMMENDATION (Standard)
        Container(
          width: 190,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: const BoxDecoration(border: rBorder),
          child: Text(
            isEmpty ? '' : f.standard,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, height: 1.25, color: Color(0xFF0F172A)),
          ),
        ),

        // 7. COUNTERMEASURE (PIC · DATE + Body)
        Container(
          width: 260,
          decoration: BoxDecoration(
            color: isBelum ? const Color(0xFFFFF1F2) : Colors.white,
            border: rBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: isBelum ? const Color(0xFFFFE4E6) : const Color(0xFFF1F5F9),
                  border: Border(bottom: BorderSide(color: isBelum ? const Color(0xFFFDA4AF) : const Color(0xFF94A3B8))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'PIC: ${isEmpty || f.pic.isEmpty ? '-' : f.pic}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                              ),
                            ),
                            if (!isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isClosed
                                      ? const Color(0xFFD1FAE5)
                                      : (isBelum ? const Color(0xFFFECDD3) : const Color(0xFFFEF3C7)),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  isClosed ? 'Selesai' : (isBelum ? 'Belum' : 'Proses'),
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: isClosed
                                        ? const Color(0xFF047857)
                                        : (isBelum ? const Color(0xFF9F1239) : const Color(0xFF92400E)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 70,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF94A3B8)))),
                      child: Text(
                        isEmpty || f.date.isEmpty ? '-' : f.date,
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isEmpty
                    ? const SizedBox.shrink()
                    : hasPhotoAfter
                        ? Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: buildPaperPhotoBox(f.photoAfter, placeholder: 'FOTO AFTER', fit: BoxFit.cover),
                                ),
                              ),
                              Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                alignment: Alignment.center,
                                child: Text(
                                  f.cm.isNotEmpty ? f.cm : (f.standard.isNotEmpty ? f.standard : 'Telah ditanggulangi'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                ),
                              ),
                            ],
                          )
                        : isBelum
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFE4E6),
                                          border: Border.all(color: const Color(0xFFFDA4AF)),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: const Text(
                                          'Belum Ada Countermeasure',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFBE123C)),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        f.cm.isNotEmpty ? f.cm : 'Menunggu perbaikan Kaizen',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFF9F1239)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : isClosed
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD1FAE5),
                                              border: Border.all(color: const Color(0xFF6EE7B7)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Kaizen Selesai',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            f.cm.isNotEmpty ? f.cm : (f.standard.isNotEmpty ? f.standard : 'Telah ditanggulangi'),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF334155)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    color: const Color(0xFFFFFBEB),
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Rencana Penanggulangan:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                                        const SizedBox(height: 2),
                                        Text(
                                          f.cm.isNotEmpty ? f.cm : 'Sedang proses penanggulangan',
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF334155)),
                                        ),
                                      ],
                                    ),
                                  ),
              ),
            ],
          ),
        ),

        // 8. RISK AFTER
        Expanded(
          child: _buildRiskBox(f.after, beforeRank: isEmpty ? null : f.before.effectiveRank),
        ),
      ],
    );
  }

  Widget _buildRiskBox(SafetyRisk r, {String? beforeRank}) {
    final tot = r.totalPoints;
    final dispRank = r.effectiveRank;
    final upper = dispRank.toUpperCase();
    final isA = upper.startsWith('A');
    final isB = upper.startsWith('B');
    final isC = upper.startsWith('C');
    final rankDown = beforeRank != null && SafetyRiskMaster.isRankDown(beforeRank, dispRank);

    final parts = [
      ('Injury', r.injury),
      ('Frequency', r.frequency),
      ('Counterm.', r.countermeasure),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top header
        Container(
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: Color(0xFF94A3B8))),
          ),
          child: Row(
            children: [
              const Expanded(child: Center(child: Text('Kind of accident', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)))),
              Container(
                width: 74,
                alignment: Alignment.center,
                decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF94A3B8)))),
                child: const Text('STOP 6 Type', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        // Accident & STOP 6 Code
        Expanded(
          flex: 11,
          child: Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF94A3B8)))),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      r.accident,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, height: 1.15, color: Color(0xFF0F172A)),
                    ),
                  ),
                ),
                Container(
                  width: 74,
                  decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF94A3B8)))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r.code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.0, color: Color(0xFF0F172A))),
                      if (r.typeName.isNotEmpty)
                        Text(
                          r.typeName.split('(').first.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Risk Level | Point subheader
        Container(
          height: 14,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: Color(0xFF94A3B8))),
          ),
          child: Row(
            children: [
              const Expanded(child: Center(child: Text('Risk Level', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)))),
              Container(
                width: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF94A3B8)))),
                child: const Text('Point', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        // 3 Part rows
        for (final p in parts)
          Container(
            height: 16.5,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1)))),
            child: Row(
              children: [
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  color: const Color(0xFFF1F5F9),
                  alignment: Alignment.centerLeft,
                  child: Text(p.$1, style: const TextStyle(fontSize: 9, color: Color(0xFF475569))),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      p.$2.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9.5, color: Color(0xFF0F172A)),
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFCBD5E1)))),
                  child: Text(
                    p.$2.point == null ? '' : '${p.$2.point}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),
        // Total Point
        Container(
          height: 16.5,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: Color(0xFF94A3B8))),
          ),
          child: Row(
            children: [
              const Expanded(child: Center(child: Text('Total Point', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)))),
              SizedBox(
                width: 34,
                child: Center(
                  child: Text(tot == null ? '' : '$tot', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        // Rank
        Expanded(
          flex: 10,
          child: Row(
            children: [
              Container(
                width: 58,
                color: const Color(0xFFF1F5F9),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Rank', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    if (rankDown)
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                        decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(2)),
                        child: const Text('▼ Down', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    dispRank,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      color: isA
                          ? const Color(0xFFBE123C)
                          : (isB ? const Color(0xFFB45309) : (isC ? const Color(0xFF047857) : const Color(0xFF0F172A))),
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
}

// =============================================================================
// 8. SAFETY KAIZEN — 1:1 `safety-kaizen.tsx`
// =============================================================================

class SafetyKaizenTemplate extends StatelessWidget {
  const SafetyKaizenTemplate({
    super.key,
    required this.closedFindings,
    required this.page,
    required this.onPageChanged,
  });

  final List<SafetyFinding> closedFindings;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final entries = closedFindings.map((f) {
      final srcText = f.sources
          .where((idx) => idx >= 0 && idx < SafetyRiskMaster.flatSources.length)
          .map((idx) => SafetyRiskMaster.flatSources[idx])
          .join(', ');
      final hazText = f.hazard >= 0 && f.hazard < SafetyRiskMaster.hazards.length
          ? SafetyRiskMaster.hazards[f.hazard]
          : '';
      return KaizenSheetEntry(
        id: f.no.isNotEmpty ? f.no : f.id,
        theme: f.theme.isNotEmpty ? f.theme : f.caption,
        pic: f.pic,
        line: f.location,
        process: f.process,
        bulanLabel: DisplayFyMath.bulanId(f.foundAt),
        beforePhoto: f.photo,
        beforeCaption: f.caption,
        beforeSub: 'Ditemukan ${f.foundAt} · $hazText${srcText.isNotEmpty ? ' · $srcText' : ''}',
        beforeBoxLabel: 'RISK RANK',
        beforeBoxSub: 'Total ${f.before.totalPoints ?? '-'} pt',
        beforeBoxValue: f.before.effectiveRank.isEmpty ? '-' : f.before.effectiveRank,
        afterPhoto: f.photoAfter,
        afterCaption: f.cm.isNotEmpty ? f.cm : f.standard,
        afterSub: 'PIC: ${f.pic.isEmpty ? '-' : f.pic} · ${f.date.isEmpty ? '-' : f.date}',
        afterBoxLabel: 'RISK RANK',
        afterBoxSub: 'Total ${f.after.totalPoints ?? '-'} pt',
        afterBoxValue: f.after.effectiveRank.isEmpty ? '-' : f.after.effectiveRank,
        result: f.result.isNotEmpty ? f.result : f.cm,
      );
    }).toList();

    return KaizenReportSheetWidget(
      chip: 'S',
      pillarName: 'Safety',
      entries: entries,
      page: page,
      onPageChanged: onPageChanged,
      badgePrefix: 'Selesai',
      emptyTitle: 'Belum ada temuan yang selesai ditanggulangi',
      emptyHint: 'Tutup temuan di modul Temuan Safety (/safety/temuan) agar otomatis tampil di sini',
    );
  }
}
