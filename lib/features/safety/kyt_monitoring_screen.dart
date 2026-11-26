import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/kyt_models.dart';
import '../../services/kyt_store.dart';

class KytMonitoringScreen extends StatefulWidget {
  const KytMonitoringScreen({super.key});

  @override
  State<KytMonitoringScreen> createState() => _KytMonitoringScreenState();
}

class _KytMonitoringScreenState extends State<KytMonitoringScreen> {
  List<SgaMonitoringRow> _rows = const [];
  String _activeShiftTab = 'WHITE'; // WHITE | RED | SPLIT
  int _selectedYear = DateTime.now().year.clamp(2024, 2028);
  String _search = '';
  bool _loading = true;
  bool _fromServer = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await KytStore.instance.fetchMonitoring(_selectedYear);
    if (!mounted) return;
    setState(() {
      _rows = res.rows;
      _fromServer = res.fromServer;
      _loading = false;
    });
  }

  bool _matches(SgaGroup g) {
    if (_search.trim().isEmpty) return true;
    final q = _search.trim().toLowerCase();
    return g.name.toLowerCase().contains(q) ||
        g.code.toLowerCase().contains(q) ||
        g.tlName.toLowerCase().contains(q) ||
        g.posArea.toLowerCase().contains(q);
  }

  Future<void> _openCellModal(SgaMonitoringRow row, MonthlyKytStatus month) async {
    var status = month.status;
    final defaultDate = month.tanggal.isNotEmpty
        ? month.tanggal
        : '$_selectedYear-${month.monthNumber.toString().padLeft(2, '0')}-15';
    final tanggalCtrl = TextEditingController(text: defaultDate);
    final picCtrl = TextEditingController(text: month.createdBy.isNotEmpty ? month.createdBy : row.group.tlName);
    final temaCtrl = TextEditingController(text: month.tema);
    final t1Ctrl = TextEditingController(text: month.tahap1);
    final t2Ctrl = TextEditingController(text: month.tahap2);
    final t3Ctrl = TextEditingController(text: month.tahap3);
    final t4Ctrl = TextEditingController(text: month.tahap4);
    final ikrarCtrl = TextEditingController(text: month.ikrar.isNotEmpty ? month.ikrar : 'Zero Accident, Yoshi!');

    try {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setM) => Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(ctx).viewInsets.bottom + 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KYT BULAN ${KytMaster.monthNames[month.monthIdx].toUpperCase()} $_selectedYear',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.amber),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${row.group.name} (${row.group.shift} SHIFT)',
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        icon: const Icon(Icons.close_rounded, color: UbColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: UbColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      'TL: ${row.group.tlName} · Area: ${row.group.posArea}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.cyan),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Status Pelaksanaan KYT', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statusBtn('done', '✓ Selesai', UbColors.emerald, status == 'done', () => setM(() => status = 'done')),
                      const SizedBox(width: 6),
                      _statusBtn('pending', '● Pending', UbColors.amber, status == 'pending', () => setM(() => status = 'pending')),
                      const SizedBox(width: 6),
                      _statusBtn('empty', '- Belum', UbColors.textMuted, status == 'empty', () => setM(() => status = 'empty')),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tanggalCtrl,
                          decoration: const InputDecoration(labelText: 'Tanggal (YYYY-MM-DD)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: picCtrl,
                          decoration: const InputDecoration(labelText: 'Dicatat Oleh (PIC/TL)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: temaCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Tema Bahaya KYT Bulan Ini',
                      hintText: 'Uraikan fokus prediksi bahaya yang diangkat...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: UbColors.bg.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DETAIL 4 TAHAP TOYOTA KYT (OPSIONAL)', style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                        const SizedBox(height: 8),
                        TextField(controller: t1Ctrl, decoration: const InputDecoration(labelText: 'Tahap 1: Fakta / Temuan bahaya', border: OutlineInputBorder(), isDense: true)),
                        const SizedBox(height: 6),
                        TextField(controller: t2Ctrl, decoration: const InputDecoration(labelText: 'Tahap 2: Inti bahaya & penyebab', border: OutlineInputBorder(), isDense: true)),
                        const SizedBox(height: 6),
                        TextField(controller: t3Ctrl, decoration: const InputDecoration(labelText: 'Tahap 3: Tindakan penanggulangan', border: OutlineInputBorder(), isDense: true)),
                        const SizedBox(height: 6),
                        TextField(controller: t4Ctrl, decoration: const InputDecoration(labelText: 'Tahap 4: Target tindakan bersama', border: OutlineInputBorder(), isDense: true)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: ikrarCtrl,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, color: UbColors.amber),
                    decoration: const InputDecoration(
                      labelText: 'Rumusan Ikrar Tunjuk Sebut (Yubisashi Kosho)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg),
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.check_rounded, size: 17),
                          label: const Text('Simpan ke Database', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (saved == true) {
        final updated = month.copyWith(
          status: status,
          tanggal: tanggalCtrl.text.trim(),
          createdBy: picCtrl.text.trim(),
          tema: temaCtrl.text.trim(),
          tahap1: t1Ctrl.text.trim(),
          tahap2: t2Ctrl.text.trim(),
          tahap3: t3Ctrl.text.trim(),
          tahap4: t4Ctrl.text.trim(),
          ikrar: ikrarCtrl.text.trim(),
        );
        final res = await KytStore.instance.saveKytCell(
          year: _selectedYear,
          row: row,
          updatedMonth: updated,
        );
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: res.synced ? UbColors.emerald : UbColors.surface,
          ),
        );
      }
    } finally {
      tanggalCtrl.dispose();
      picCtrl.dispose();
      temaCtrl.dispose();
      t1Ctrl.dispose();
      t2Ctrl.dispose();
      t3Ctrl.dispose();
      t4Ctrl.dispose();
      ikrarCtrl.dispose();
    }
  }

  Widget _statusBtn(String val, String label, Color color, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.22) : UbColors.bg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: active ? color : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: active ? Colors.white : UbColors.textMuted),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final whiteRows = _rows.where((r) => r.group.shift == 'WHITE' && _matches(r.group)).toList();
    final redRows = _rows.where((r) => r.group.shift == 'RED' && _matches(r.group)).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('KYT Monitoring 12 Bulan', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (_fromServer ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _fromServer ? 'LIVE' : 'LOKAL',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: _fromServer ? UbColors.emerald : UbColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Text('Target 1 Bulan 1 KYT per Group SGA', style: TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  // Year Switcher
                  Container(
                    decoration: BoxDecoration(
                      color: UbColors.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (_selectedYear > 2024) {
                              setState(() => _selectedYear -= 1);
                              _load();
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.chevron_left_rounded, size: 16, color: UbColors.textMuted),
                          ),
                        ),
                        Text(
                          '$_selectedYear',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: UbColors.amber),
                        ),
                        InkWell(
                          onTap: () {
                            if (_selectedYear < 2028) {
                              setState(() => _selectedYear += 1);
                              _load();
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.chevron_right_rounded, size: 16, color: UbColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded, size: 19, color: UbColors.cyan),
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
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                        children: [
                          // Shift Tabs (WHITE | RED | SPLIT)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: UbColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _shiftTabBtn('WHITE', 'WHITE (${whiteRows.length})', Colors.white, UbColors.bg),
                                    const SizedBox(width: 6),
                                    _shiftTabBtn('RED', 'RED (${redRows.length})', UbColors.rose, Colors.white),
                                    const SizedBox(width: 6),
                                    _shiftTabBtn('SPLIT', 'Terpisah', UbColors.cyan, UbColors.bg),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) => setState(() => _search = v),
                                  style: const TextStyle(fontSize: 12.5),
                                  decoration: InputDecoration(
                                    hintText: 'Cari group, TL, pos area...',
                                    hintStyle: const TextStyle(fontSize: 12, color: UbColors.textMuted),
                                    prefixIcon: const Icon(Icons.search_rounded, size: 17),
                                    isDense: true,
                                    filled: true,
                                    fillColor: UbColors.bg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Legend
                          const Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _LegendItem(symbol: '✓', label: 'Selesai', color: UbColors.emerald),
                              _LegendItem(symbol: '●', label: 'Pending', color: UbColors.amber),
                              _LegendItem(symbol: '-', label: 'Belum', color: UbColors.textMuted),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_activeShiftTab == 'WHITE' || _activeShiftTab == 'SPLIT')
                            _buildShiftMatrix('WHITE', whiteRows),
                          if (_activeShiftTab == 'SPLIT') const SizedBox(height: 16),
                          if (_activeShiftTab == 'RED' || _activeShiftTab == 'SPLIT')
                            _buildShiftMatrix('RED', redRows),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shiftTabBtn(String key, String label, Color activeBg, Color activeFg) {
    final active = _activeShiftTab == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeShiftTab = key),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? activeBg : UbColors.bg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: active ? activeBg : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: active ? activeFg : UbColors.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftMatrix(String shift, List<SgaMonitoringRow> rows) {
    final isWhite = shift == 'WHITE';
    final stats = KytMaster.computeShiftStats(rows);
    final accent = isWhite ? Colors.white70 : UbColors.rose;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shift Header + Mini KPI
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWhite ? 'WHITE SHIFT (SHIFT PUTIH)' : 'RED SHIFT (SHIFT MERAH)',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: accent),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Matriks 12 Bulan KYT — ${isWhite ? "White" : "Red"}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: UbColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _miniStat('YTD', '${stats.completedYtd}/${stats.targetYear}', UbColors.emerald),
                    const SizedBox(width: 10),
                    _miniStat('Kepatuhan', '${stats.compliancePercent}%', stats.compliancePercent >= 80 ? UbColors.cyan : UbColors.amber),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Belum ada Group SGA untuk shift ini.', style: TextStyle(fontSize: 12, color: UbColors.textMuted)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 54,
                dataRowMaxHeight: 60,
                columnSpacing: 10,
                horizontalMargin: 8,
                headingRowColor: WidgetStateProperty.all(UbColors.bg),
                columns: [
                  const DataColumn(label: Text('Group SGA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                  const DataColumn(label: Text('TL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                  ...KytMaster.monthNames.map(
                    (m) => DataColumn(
                      label: SizedBox(
                        width: 34,
                        child: Text(m, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const DataColumn(label: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.amber))),
                ],
                rows: rows.map((row) {
                  final done = row.completedCount;
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 145,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${row.group.code} · ${row.group.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                              Text(row.group.posArea, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: UbColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 98,
                          child: Text(row.group.tlName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      ...row.months.map((m) {
                        final isDone = m.status == 'done';
                        final isPending = m.status == 'pending';
                        final cellColor = isDone ? UbColors.emerald : (isPending ? UbColors.amber : UbColors.textMuted);
                        return DataCell(
                          InkWell(
                            onTap: () => _openCellModal(row, m),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isDone || isPending ? cellColor.withValues(alpha: 0.2) : UbColors.bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDone || isPending ? cellColor.withValues(alpha: 0.6) : Colors.white12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isDone ? '✓' : (isPending ? '●' : '-'),
                                style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w900, color: cellColor),
                              ),
                            ),
                          ),
                        );
                      }),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (done >= 12 ? UbColors.emerald : (done > 0 ? UbColors.amber : UbColors.bg)).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$done/12',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: done >= 12 ? UbColors.emerald : (done > 0 ? UbColors.amber : UbColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: UbColors.textMuted)),
        Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.symbol, required this.label, required this.color});

  final String symbol;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(symbol, style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: color)),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
      ],
    );
  }
}
