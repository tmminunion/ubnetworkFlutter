import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/cbu_ckd_models.dart';
import '../../models/checksheet_models.dart';
import '../../models/quality_daily_models.dart';
import '../../services/cbu_ckd_store.dart';
import '../checksheet/checksheet_screen.dart';
import 'cbu_monitoring_screen.dart';

class CkdMonitoringScreen extends StatefulWidget {
  const CkdMonitoringScreen({super.key});

  @override
  State<CkdMonitoringScreen> createState() => _CkdMonitoringScreenState();
}

class _CkdMonitoringScreenState extends State<CkdMonitoringScreen> {
  String _ym = QualityMath.wibYm();
  String _shiftFilter = 'ALL'; // ALL | WHITE | RED
  bool _loading = true;
  bool _fromServer = false;
  List<CkdPartItem> _parts = UbMasterData.defaultCkdParts();
  List<Map<String, dynamic>> _rawReports = const [];

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
      _parts = res.ckdParts;
      _rawReports = res.reports;
      _fromServer = res.fromServer;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = CbuCkdMath.aggregateCkd(
      ym: _ym,
      shiftFilter: _shiftFilter,
      partsConfig: _parts,
      rawReports: _rawReports,
    );
    final sum = CbuCkdMath.summarizeCkd(days, _parts);

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
                            const Text('Part CKD 1–31', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: (_fromServer ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                              child: Text(_fromServer ? 'LIVE' : 'LOKAL', style: TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w900, color: _fromServer ? UbColors.emerald : UbColors.amber)),
                            ),
                          ],
                        ),
                        Text('Export Sub-Assy · ${QualityMath.formatYmLabel(_ym)}', style: const TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UbColors.purple,
                      side: BorderSide(color: UbColors.purple.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(builder: (_) => const CbuMonitoringScreen()),
                    ),
                    child: const Text('Model CBU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: UbColors.emerald),
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
                                    selectedColor: UbColors.emerald.withValues(alpha: 0.3),
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
                              _kpiCard('Total Volume CKD', '${sum.grandTotal} U', '${sum.workDays} hari aktif', UbColors.emerald),
                              _kpiCard('Part Terdaftar', '${_parts.length} Part', 'Master Settings', UbColors.cyan),
                              _kpiCard('Rata-Rata Harian', '${sum.avgDaily} U', 'Per hari aktif', UbColors.purple),
                              _kpiCard('Top Volume Part', sum.topPartNo, '${sum.topPartQty} U (${sum.topPartPercent}%)', UbColors.amber),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 1-31 Matrix Table
                          Container(
                            decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowHeight: 38,
                                dataRowMinHeight: 40,
                                dataRowMaxHeight: 44,
                                columnSpacing: 14,
                                horizontalMargin: 10,
                                headingRowColor: WidgetStateProperty.all(UbColors.bg),
                                columns: [
                                  const DataColumn(label: Text('Tgl', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900))),
                                  const DataColumn(label: Text('Total CKD', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.emerald))),
                                  ..._parts.map((p) => DataColumn(label: Text(p.partNo, style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w800)))),
                                  const DataColumn(label: Text('Aksi', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800))),
                                ],
                                rows: [
                                  ...days.map((d) => DataRow(
                                        cells: [
                                          DataCell(Text('${d.dayNumber} ${d.dayName}', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: d.isWeekend ? UbColors.rose : Colors.white))),
                                          DataCell(Text(d.totalCkd > 0 ? '${d.totalCkd} U' : '–', style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900, color: d.totalCkd > 0 ? UbColors.emerald : UbColors.textMuted))),
                                          ..._parts.map((p) {
                                            final q = d.parts[p.partNo] ?? 0;
                                            return DataCell(Text(q > 0 ? '$q' : '–', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: q > 0 ? Colors.white : UbColors.textMuted)));
                                          }),
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
                                      const DataCell(Text('TOTAL', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.emerald))),
                                      DataCell(Text('${sum.grandTotal} U', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: UbColors.emerald))),
                                      ..._parts.map((p) => DataCell(Text('${sum.partTotals[p.partNo] ?? 0}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900, color: UbColors.cyan)))),
                                      DataCell(Text('${sum.workDays} hari', style: const TextStyle(fontSize: 10, color: UbColors.textMuted))),
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
