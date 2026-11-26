import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/cbu_ckd_models.dart';
import '../../models/checksheet_models.dart';
import '../../models/quality_daily_models.dart';
import '../../services/cbu_ckd_store.dart';
import '../checksheet/checksheet_screen.dart';
import 'ckd_monitoring_screen.dart';

class CbuMonitoringScreen extends StatefulWidget {
  const CbuMonitoringScreen({super.key});

  @override
  State<CbuMonitoringScreen> createState() => _CbuMonitoringScreenState();
}

class _CbuMonitoringScreenState extends State<CbuMonitoringScreen> {
  String _ym = QualityMath.wibYm();
  String _shiftFilter = 'ALL'; // ALL | WHITE | RED
  bool _loading = true;
  bool _fromServer = false;
  List<CbuModelItem> _models = UbMasterData.defaultCbuModels();
  List<Map<String, dynamic>> _rawReports = const [];

  static const _palette = [
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
    Color(0xFFF59E0B),
    Color(0xFFF43F5E),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await CbuCkdStore.instance.fetchMonthlyBundle(_ym);
    if (!mounted) return;
    setState(() {
      _models = res.models;
      _rawReports = res.reports;
      _fromServer = res.fromServer;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = CbuCkdMath.aggregateCbu(
      ym: _ym,
      shiftFilter: _shiftFilter,
      modelsConfig: _models,
      rawReports: _rawReports,
    );
    final sum = CbuCkdMath.summarizeCbu(days, _models);
    final totalRatio = _models.fold<double>(0, (acc, m) => acc + (m.ratio > 0 ? m.ratio : 1.0));

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
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
                            const Text('Model CBU 1–31', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: (_fromServer ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                              child: Text(_fromServer ? 'LIVE' : 'LOKAL', style: TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w900, color: _fromServer ? UbColors.emerald : UbColors.amber)),
                            ),
                          ],
                        ),
                        Text('Rekap & Rasio · ${QualityMath.formatYmLabel(_ym)}', style: const TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UbColors.amber,
                      side: BorderSide(color: UbColors.amber.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(builder: (_) => const CkdMonitoringScreen()),
                    ),
                    child: const Text('Part CKD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: UbColors.purple),
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
                          // Month Nav + Shift Filter
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                                child: Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        setState(() => _ym = QualityMath.shiftYm(_ym, -1));
                                        _load();
                                      },
                                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                    ),
                                    Text(QualityMath.formatYmLabel(_ym), style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900)),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        setState(() => _ym = QualityMath.shiftYm(_ym, 1));
                                        _load();
                                      },
                                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              ...['ALL', 'WHITE', 'RED'].map((s) {
                                final active = _shiftFilter == s;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: ChoiceChip(
                                    label: Text(s == 'ALL' ? 'Semua' : s, style: const TextStyle(fontSize: 10.5)),
                                    selected: active,
                                    selectedColor: UbColors.purple.withValues(alpha: 0.35),
                                    onSelected: (_) => setState(() => _shiftFilter = s),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 4 KPI Cards
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.05,
                            children: [
                              _kpiCard('Total CBU Bulan Ini', '${sum.grandTotal} U', '${sum.activeDays} hari aktif', Colors.white),
                              _kpiCard('Model Terbanyak', sum.topModelName, '${sum.topModelQty} U (${sum.topModelShare}%)', UbColors.emerald),
                              _kpiCard('Rata-Rata / Hari', '${sum.avgPerDay} U', 'Kapasitas ~420 U', UbColors.cyan),
                              _kpiCard('Metode Input', '⚡ ${sum.ratioDays} · ✏️ ${sum.manualDays}', 'Rasio vs Manual', UbColors.amber),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Komparasi Rasio Setting vs Realisasi
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Komparasi Rasio Setting vs Realisasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                                const SizedBox(height: 10),
                                ..._models.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final m = entry.value;
                                  final col = _palette[idx % _palette.length];
                                  final theoPct = totalRatio > 0 ? ((m.ratio / totalRatio) * 100) : 0.0;
                                  final actQty = sum.modelTotals[m.code] ?? 0;
                                  final actPct = sum.grandTotal > 0 ? ((actQty / sum.grandTotal) * 100) : 0.0;
                                  final dev = actPct - theoPct;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: col)),
                                            const SizedBox(width: 6),
                                            Text(m.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                            const Spacer(),
                                            Text(
                                              '$actQty U · ${actPct.toStringAsFixed(1)}% (Target ${theoPct.toStringAsFixed(1)}% · ${dev >= 0 ? "+${dev.toStringAsFixed(1)}" : dev.toStringAsFixed(1)}%)',
                                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: UbColors.textMuted),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(99),
                                          child: LinearProgressIndicator(
                                            value: (actPct / 100).clamp(0.02, 1.0),
                                            minHeight: 7,
                                            backgroundColor: UbColors.bg,
                                            valueColor: AlwaysStoppedAnimation<Color>(col),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 1-31 Table
                          Container(
                            decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowHeight: 36,
                                dataRowMinHeight: 40,
                                dataRowMaxHeight: 44,
                                columnSpacing: 14,
                                horizontalMargin: 10,
                                headingRowColor: WidgetStateProperty.all(UbColors.bg),
                                columns: [
                                  const DataColumn(label: Text('Tgl', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900))),
                                  ..._models.map((m) => DataColumn(label: Text(m.name, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)))),
                                  const DataColumn(label: Text('Total', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.purple))),
                                  const DataColumn(label: Text('Aksi', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800))),
                                ],
                                rows: [
                                  ...days.map((d) => DataRow(
                                        cells: [
                                          DataCell(Text('${d.dayNumber} ${d.dayName}', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: d.isWeekend ? UbColors.rose : Colors.white))),
                                          ..._models.map((m) {
                                            final q = d.models[m.code] ?? 0;
                                            return DataCell(Text(q > 0 ? '$q' : '–', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: q > 0 ? Colors.white : UbColors.textMuted)));
                                          }),
                                          DataCell(Text(d.totalCbu > 0 ? '${d.totalCbu}' : '–', style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900, color: UbColors.purple))),
                                          DataCell(
                                            InkWell(
                                              onTap: () => Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => ChecksheetScreen(
                                                    initialDate: d.date,
                                                    initialShift: _shiftFilter == 'RED' ? 'RED' : 'WHITE',
                                                  ),
                                                ),
                                              ),
                                              child: const Text('Checksheet ↗', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: UbColors.cyan)),
                                            ),
                                          ),
                                        ],
                                      )),
                                  DataRow(
                                    color: WidgetStateProperty.all(UbColors.bg),
                                    cells: [
                                      const DataCell(Text('TOTAL', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.purple))),
                                      ..._models.map((m) => DataCell(Text('${sum.modelTotals[m.code] ?? 0}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900)))),
                                      DataCell(Text('${sum.grandTotal}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: UbColors.purple))),
                                      const DataCell(Text('100%', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: UbColors.textMuted))),
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

  Widget _kpiCard(String label, String val, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
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
