import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/prod_monitoring_models.dart';
import '../../services/prod_monitoring_store.dart';
import '../checksheet/checksheet_screen.dart';

class ProdMonitoringScreen extends StatefulWidget {
  const ProdMonitoringScreen({super.key});

  @override
  State<ProdMonitoringScreen> createState() => _ProdMonitoringScreenState();
}

class _ProdMonitoringScreenState extends State<ProdMonitoringScreen> {
  late int _year;
  late int _month;
  String _shift = 'WHITE'; // WHITE | RED
  bool _showChart = true;
  bool _loading = true;
  bool _fromServer = false;
  double _taktTime = 2.4;
  List<DayMonitoringRow> _days = const [];

  @override
  void initState() {
    super.initState();
    final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
    _year = wib.year;
    _month = wib.month;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ProdMonitoringStore.instance.fetchMonthly(_year, _month);
    if (!mounted) return;
    setState(() {
      _days = res.days;
      _taktTime = res.taktTime;
      _fromServer = res.fromServer;
      _loading = false;
    });
  }

  void _stepMonth(int delta) {
    final dt = DateTime(_year, _month + delta, 1);
    setState(() {
      _year = dt.year;
      _month = dt.month;
    });
    _load();
  }

  Future<void> _openChecksheet(String date) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChecksheetScreen(initialDate: date, initialShift: _shift),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final kpi = ProdMonitoringMath.computeKpi(_days, _shift);
    final uph = _taktTime > 0 ? (60 / _taktTime).round() : 25;
    final monthLabel = '${ProdMonitoringMath.monthNames[_month - 1]} $_year';

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. COMPACT STICKY TOPBAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: UbColors.surface,
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 17, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Monitoring 1–31', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (_fromServer ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _fromServer ? 'LIVE' : 'LOKAL',
                                style: TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w900, color: _fromServer ? UbColors.emerald : UbColors.amber),
                              ),
                            ),
                          ],
                        ),
                        Text('TT ${_taktTime}m ($uph U/h) · $monthLabel', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  // Shift Switcher (WHITE | RED)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: UbColors.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        _shiftPill('WHITE', Colors.white, UbColors.bg),
                        const SizedBox(width: 4),
                        _shiftPill('RED', UbColors.rose, Colors.white),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: UbColors.cyan),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                        children: [
                          // Month Nav + Chart Toggle
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: UbColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _stepMonth(-1),
                                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                    ),
                                    Text(monthLabel, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900)),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _stepMonth(1),
                                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              FilterChip(
                                label: const Text('Grafik', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                selected: _showChart,
                                selectedColor: UbColors.cyan.withValues(alpha: 0.25),
                                onSelected: (v) => setState(() => _showChart = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 6 KPI CARDS
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: MediaQuery.of(context).size.width >= 760 ? 3 : 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.0,
                            children: [
                              _kpiCard(
                                'Output Produksi',
                                '${kpi.totalAct} / ${kpi.totalPlan} U',
                                'Diff: ${kpi.totalDiff >= 0 ? "+${kpi.totalDiff}" : kpi.totalDiff} U',
                                Colors.white,
                              ),
                              _kpiCard(
                                'Efisiensi INT',
                                '${kpi.avgEff}%',
                                'EXT ${kpi.avgEffExt}% · TOT ${kpi.avgEffTotal}%',
                                kpi.avgEff >= 98 ? UbColors.emerald : UbColors.amber,
                              ),
                              _kpiCard(
                                'Total Lembur (OT)',
                                '${kpi.totalActOtHours} / ${kpi.totalOtHours}h',
                                'Plan ${kpi.totalOtHours}h',
                                UbColors.amber,
                              ),
                              _kpiCard(
                                'Minus Output',
                                kpi.totalMinusUnits > 0 ? '-${kpi.totalMinusUnits} U' : '0 U',
                                'Loss ${(kpi.totalMinusUnits * _taktTime).toStringAsFixed(1)}m',
                                kpi.totalMinusUnits > 0 ? UbColors.rose : UbColors.emerald,
                              ),
                              _kpiCard(
                                'Delay Line Stop',
                                '${kpi.totalDelayMin}m',
                                'INT ${kpi.totalIntDelay}m · EXT ${kpi.totalExtDelay}m',
                                UbColors.amber,
                              ),
                              _kpiCard(
                                'Absensi MP',
                                '${kpi.avgAttendanceRate}%',
                                kpi.avgAttendanceRate >= 98 ? 'OPTIMAL' : 'PERLU ATENSI',
                                kpi.avgAttendanceRate >= 98 ? UbColors.emerald : UbColors.amber,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // COLLAPSIBLE EFFICIENCY BAR CHART (1-31)
                          if (_showChart) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: UbColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Grafik Tren Efisiensi Regu $_shift', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white)),
                                      const Text('Target 98%', style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w800, color: UbColors.rose)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 140,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: _days.map((d) {
                                          final t = d.forShift(_shift);
                                          final hasAct = t.act > 0;
                                          final isOk = t.efficiency >= 98;
                                          final barH = hasAct ? ((t.efficiency.clamp(0, 115) / 115) * 90).clamp(10.0, 90.0) : 6.0;
                                          final barColor = !hasAct
                                              ? Colors.white12
                                              : (!isOk
                                                  ? UbColors.rose
                                                  : (t.session == 'night' ? UbColors.cyan : UbColors.amber));
                                          return InkWell(
                                            onTap: () => _openChecksheet(d.date),
                                            child: Container(
                                              width: 28,
                                              margin: const EdgeInsets.only(right: 4),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  if (hasAct)
                                                    Text(
                                                      '${t.efficiency.round()}%',
                                                      style: TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: FontWeight.w800, color: isOk ? UbColors.emerald : UbColors.rose),
                                                    ),
                                                  const SizedBox(height: 2),
                                                  Container(
                                                    width: 18,
                                                    height: barH,
                                                    decoration: BoxDecoration(
                                                      color: barColor,
                                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${d.dayNumber}',
                                                    style: TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: d.isSunday ? UbColors.rose : (d.isSaturday ? UbColors.emerald : UbColors.textMuted),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // 1-31 TABLE
                          Container(
                            decoration: BoxDecoration(
                              color: UbColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowHeight: 36,
                                dataRowMinHeight: 42,
                                dataRowMaxHeight: 46,
                                columnSpacing: 14,
                                horizontalMargin: 10,
                                headingRowColor: WidgetStateProperty.all(UbColors.bg),
                                columns: const [
                                  DataColumn(label: Text('Tgl', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900))),
                                  DataColumn(label: Text('Sesi', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900))),
                                  DataColumn(label: Text('Plan', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.cyan))),
                                  DataColumn(label: Text('Act', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.emerald))),
                                  DataColumn(label: Text('Diff', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900))),
                                  DataColumn(label: Text('Eff%', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900))),
                                  DataColumn(label: Text('Delay', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.amber))),
                                  DataColumn(label: Text('Aksi', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900))),
                                ],
                                rows: [
                                  ..._days.map((d) {
                                    final t = d.forShift(_shift);
                                    final isOff = t.session == 'off';
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            '${d.dayNumber} ${d.dayName}',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: d.isSunday ? UbColors.rose : (d.isSaturday ? UbColors.emerald : Colors.white),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            t.session.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isOff ? UbColors.textMuted : (t.session == 'night' ? UbColors.cyan : UbColors.amber),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${t.plan}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: UbColors.cyan))),
                                        DataCell(Text(t.act > 0 ? '${t.act}' : '–', style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900))),
                                        DataCell(
                                          Text(
                                            t.act == 0 ? '–' : (t.diff >= 0 ? '+${t.diff}' : '${t.diff}'),
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: t.act == 0 ? UbColors.textMuted : (t.diff >= 0 ? UbColors.emerald : UbColors.rose),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            t.act > 0 ? '${t.efficiency}%' : '–',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: t.act == 0 ? UbColors.textMuted : (t.efficiency >= 98 ? UbColors.emerald : UbColors.rose),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${t.delayMin}m', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: t.delayMin > 0 ? UbColors.amber : UbColors.textMuted))),
                                        DataCell(
                                          InkWell(
                                            onTap: () => _openChecksheet(d.date),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: (t.isSaved ? UbColors.emerald : UbColors.cyan).withValues(alpha: 0.18),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                t.isSaved ? 'Lihat' : 'Buka',
                                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: t.isSaved ? UbColors.emerald : UbColors.cyan),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                  // Total Row
                                  DataRow(
                                    color: WidgetStateProperty.all(UbColors.bg),
                                    cells: [
                                      const DataCell(Text('TOTAL', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.cyan))),
                                      DataCell(Text('${kpi.daySessions}D/${kpi.nightSessions}N', style: const TextStyle(fontFamily: 'monospace', fontSize: 10))),
                                      DataCell(Text('${kpi.totalPlan}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900, color: UbColors.cyan))),
                                      DataCell(Text('${kpi.totalAct}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900, color: UbColors.emerald))),
                                      DataCell(Text('${kpi.totalDiff >= 0 ? "+${kpi.totalDiff}" : kpi.totalDiff}', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: kpi.totalDiff >= 0 ? UbColors.emerald : UbColors.rose))),
                                      DataCell(Text('${kpi.avgEff}%', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: kpi.avgEff >= 98 ? UbColors.emerald : UbColors.amber))),
                                      DataCell(Text('${kpi.totalDelayMin}m', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.amber))),
                                      const DataCell(Text('SUM', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: UbColors.textMuted))),
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
    );
  }

  Widget _shiftPill(String val, Color activeBg, Color activeFg) {
    final active = _shift == val;
    return InkWell(
      onTap: () => setState(() => _shift = val),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: active ? activeBg : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w900, color: active ? activeFg : UbColors.textMuted)),
      ),
    );
  }

  Widget _kpiCard(String label, String val, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: UbColors.textMuted)),
          const SizedBox(height: 2),
          Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'monospace', fontSize: 15.5, fontWeight: FontWeight.w900, color: color)),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: UbColors.textMuted)),
        ],
      ),
    );
  }
}
