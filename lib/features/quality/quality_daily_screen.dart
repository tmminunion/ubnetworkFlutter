import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';
import '../../models/quality_daily_models.dart';
import '../../services/quality_daily_store.dart';

class QualityDailyScreen extends StatefulWidget {
  const QualityDailyScreen({
    super.key,
    required this.kind, // 'out' | 'in'
  });

  final String kind;

  @override
  State<QualityDailyScreen> createState() => _QualityDailyScreenState();
}

class _QualityDailyScreenState extends State<QualityDailyScreen> {
  String _ym = QualityMath.wibYm();
  String _tab = 'record'; // record | list
  String _shiftTab = 'red'; // red | white | all
  String _search = '';
  bool _loading = true;

  late QualityMonthlyRecord _rec;
  MonthlyProdData? _prod;
  final TextEditingController _searchCtrl = TextEditingController();

  String get _kindName => widget.kind == 'in' ? 'In Proses' : 'Out Flow';
  String get _otherKind => widget.kind == 'in' ? 'out' : 'in';
  String get _otherLabel => widget.kind == 'in' ? 'Out Flow' : 'In Proses';

  @override
  void initState() {
    super.initState();
    _rec = QualityMonthlyRecord(ym: _ym, kind: widget.kind);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rec = await QualityDailyStore.instance.loadRecord(_ym, widget.kind);
    final prod = await QualityDailyStore.instance.fetchMonthlyProd(_ym);
    if (!mounted) return;
    setState(() {
      _rec = rec;
      _prod = prod;
      _loading = false;
    });
  }

  Future<void> _toggleZero(String team, int day) async {
    final set = _rec.zeroDaysFor(team);
    if (set.contains(day)) {
      set.remove(day);
    } else {
      set.add(day);
    }
    await QualityDailyStore.instance.saveZeroCell(_rec, team, day);
    if (mounted) setState(() {});
  }

  Future<void> _editTargetDu() async {
    final ctrl = TextEditingController(text: QualityMath.fmtDu(_rec.targetDu));
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: UbColors.surface,
          title: const Text('Target D/U Bulanan'),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target D/U (mis. 0.025)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
      if (ok == true) {
        final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
        if (v != null && v > 0 && v <= 1) {
          _rec.targetDu = v;
          await QualityDailyStore.instance.saveTargetDu(_rec);
          if (mounted) setState(() {});
        }
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _openFindingModal({QualityFinding? existing, String? team, int? day}) async {
    final today = UbMasterData.wibToday();
    final defaultDay = day ?? (today.startsWith(_ym) ? (int.tryParse(today.substring(8, 10)) ?? 1) : 1);
    var selTeam = existing?.team ?? team ?? (_shiftTab == 'white' ? 'white' : 'red');
    final dateCtrl = TextEditingController(
      text: existing?.date ?? '$_ym-${defaultDay.toString().padLeft(2, '0')}',
    );
    final qtyCtrl = TextEditingController(text: '${existing?.qty ?? 1}');
    final probCtrl = TextEditingController(text: existing?.problem ?? '');
    final procCtrl = TextEditingController(text: existing?.process ?? '');
    final whereCtrl = TextEditingController(text: existing?.foundWhere ?? '');
    final picCtrl = TextEditingController(text: existing?.pic ?? '');
    final cmCtrl = TextEditingController(text: existing?.countermeasure ?? '');

    try {
      final action = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                        child: Text(
                          existing != null ? 'Edit Temuan ${existing.id}' : 'Insert Temuan · Defect $_kindName',
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: UbColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateCtrl,
                          decoration: const InputDecoration(labelText: 'Tanggal (YYYY-MM-DD)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty (pcs)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('🔴 UB Assy Red')),
                          selected: selTeam == 'red',
                          selectedColor: UbColors.rose.withValues(alpha: 0.3),
                          onSelected: (_) => setM(() => selTeam = 'red'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('⚪ UB Assy White')),
                          selected: selTeam == 'white',
                          selectedColor: Colors.white24,
                          onSelected: (_) => setM(() => selTeam = 'white'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: probCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Problem / Temuan (Wajib)',
                      hintText: 'mis. Porosity weld bead di joint rear floor',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: procCtrl,
                          decoration: const InputDecoration(labelText: 'Lokasi / Proses', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: whereCtrl,
                          decoration: const InputDecoration(labelText: 'Ditemukan di', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: picCtrl,
                    decoration: const InputDecoration(labelText: 'PIC', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cmCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Penanggulangan Sementara', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (existing != null)
                        IconButton(
                          onPressed: () => Navigator.pop(ctx, 'delete'),
                          icon: const Icon(Icons.delete_outline_rounded, color: UbColors.rose),
                        ),
                      const Spacer(),
                      OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                        onPressed: () {
                          if (probCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Problem / temuan wajib diisi.')),
                            );
                            return;
                          }
                          Navigator.pop(ctx, 'save');
                        },
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text('Simpan Temuan', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (action == 'delete' && existing != null) {
        await QualityDailyStore.instance.deleteFinding(_rec, existing.id);
        if (mounted) setState(() {});
      } else if (action == 'save') {
        final qty = math.max(1, int.tryParse(qtyCtrl.text.trim()) ?? 1);
        final item = QualityFinding(
          id: existing?.id ?? 'Q${widget.kind == "in" ? "I" : "O"}-${DateTime.now().millisecondsSinceEpoch}',
          date: dateCtrl.text.trim(),
          team: selTeam,
          kind: widget.kind,
          problem: probCtrl.text.trim(),
          process: procCtrl.text.trim(),
          foundWhere: whereCtrl.text.trim(),
          qty: qty,
          pic: picCtrl.text.trim(),
          countermeasure: cmCtrl.text.trim(),
          hasKaizen: existing?.hasKaizen ?? false,
        );
        await QualityDailyStore.instance.upsertFinding(_rec, item);
        if (mounted) setState(() {});
      }
    } finally {
      dateCtrl.dispose();
      qtyCtrl.dispose();
      probCtrl.dispose();
      procCtrl.dispose();
      whereCtrl.dispose();
      picCtrl.dispose();
      cmCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = QualityMath.daysInMonth(_ym);
    final redSum = QualityMath.teamSummary(_rec, 'red', dim, _prod?.red);
    final whiteSum = QualityMath.teamSummary(_rec, 'white', dim, _prod?.white);

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
                        Text('Defect $_kindName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Daily Quality · ${QualityMath.formatYmLabel(_ym)}', style: const TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UbColors.cyan,
                      side: BorderSide(color: UbColors.cyan.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(builder: (_) => QualityDailyScreen(kind: _otherKind)),
                      );
                    },
                    child: Text(_otherLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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
                          // Month Nav + Target D/U Pill
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
                                      onPressed: () {
                                        setState(() => _ym = QualityMath.shiftYm(_ym, -1));
                                        _load();
                                      },
                                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                    ),
                                    Text(
                                      QualityMath.formatYmLabel(_ym),
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
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
                              InkWell(
                                onTap: _editTargetDu,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: UbColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: UbColors.amber.withValues(alpha: 0.45)),
                                  ),
                                  child: Text(
                                    'Target D/U: ${QualityMath.fmtDu(_rec.targetDu)}',
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900, color: UbColors.amber),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Tab Record Harian vs List Temuan
                          Row(
                            children: [
                              Expanded(
                                child: _tabBtn('record', Icons.calendar_month_rounded, 'Record Harian'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tabBtn('list', Icons.list_alt_rounded, 'List Temuan (${_rec.findings.length})'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_tab == 'record') ...[
                            // Shift Switcher (Red | White | Atas-Bawah)
                            Row(
                              children: [
                                _shiftBtn('red', '🔴 Shift Red', UbColors.rose, Colors.white),
                                const SizedBox(width: 6),
                                _shiftBtn('white', '⚪ Shift White', Colors.white, UbColors.bg),
                                const SizedBox(width: 6),
                                _shiftBtn('all', 'Atas-Bawah', UbColors.cyan, UbColors.bg),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_shiftTab == 'red' || _shiftTab == 'all')
                              _buildShiftBlock('red', 'UB Assy Red', redSum, _prod?.red, dim),
                            if (_shiftTab == 'all') const SizedBox(height: 16),
                            if (_shiftTab == 'white' || _shiftTab == 'all')
                              _buildShiftBlock('white', 'UB Assy White', whiteSum, _prod?.white, dim),
                          ] else
                            _buildFindingsList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.cyan,
        foregroundColor: UbColors.bg,
        onPressed: () => _openFindingModal(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Temuan', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _tabBtn(String key, IconData icon, String label) {
    final active = _tab == key;
    return InkWell(
      onTap: () => setState(() => _tab = key),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : UbColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? Colors.white : Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: active ? UbColors.bg : UbColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: active ? UbColors.bg : Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _shiftBtn(String key, String label, Color bg, Color fg) {
    final active = _shiftTab == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _shiftTab = key),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? bg : UbColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: active ? bg : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: active ? fg : UbColors.textMuted)),
        ),
      ),
    );
  }

  Widget _buildShiftBlock(
    String team,
    String title,
    QualityTeamSummary sum,
    List<int?>? prodDays,
    int dim,
  ) {
    final isRed = team == 'red';
    final accent = isRed ? UbColors.rose : Colors.white;
    final duColor = sum.du == null ? UbColors.textMuted : (sum.du! <= _rec.targetDu ? UbColors.emerald : UbColors.rose);
    final duSeries = List<double?>.generate(dim, (i) {
      final act = (prodDays != null && i < prodDays.length) ? prodDays[i] : null;
      final df = QualityMath.dayDefect(_rec, team, i + 1);
      return QualityMath.defectPerUnit(df, act);
    });

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isRed ? const Color(0xFFFCA5A5) : Colors.white)),
                    Text('Defect $_kindName · Target ${QualityMath.fmtDu(_rec.targetDu)}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                  ],
                ),
              ),
              _miniKpi('Prod', sum.totalProd > 0 ? '${sum.totalProd}' : '–', Colors.white),
              const SizedBox(width: 8),
              _miniKpi('Def', sum.totalDefect == null ? '–' : '${sum.totalDefect}', accent),
              const SizedBox(width: 8),
              _miniKpi('D/U', QualityMath.fmtDu(sum.du), duColor),
            ],
          ),
          const SizedBox(height: 12),

          // Daily D/U Trend Chart
          Container(
            height: 125,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: UbColors.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: CustomPaint(
              painter: _DuChartPainter(
                du: duSeries,
                target: _rec.targetDu,
                lineColor: isRed ? const Color(0xFFF87171) : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 1-31 Daily Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 34,
              dataRowMinHeight: 42,
              dataRowMaxHeight: 48,
              columnSpacing: 14,
              horizontalMargin: 8,
              headingRowColor: WidgetStateProperty.all(UbColors.bg),
              columns: const [
                DataColumn(label: Text('Tgl', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text('Prod', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text('Def', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text('D/U', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text('Temuan & Aksi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
              ],
              rows: List.generate(dim, (i) {
                final day = i + 1;
                final act = (prodDays != null && i < prodDays.length) ? prodDays[i] : null;
                final df = QualityMath.dayDefect(_rec, team, day);
                final du = QualityMath.defectPerUnit(df, act);
                final dayFinds = _rec.findings.where((f) => f.team == team && f.dayNumber == day).toList();
                final isZero = dayFinds.isEmpty && df == 0;

                return DataRow(
                  cells: [
                    DataCell(Text('$day', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800))),
                    DataCell(Text(act == null ? '–' : '$act', style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: UbColors.textMuted))),
                    DataCell(Text(df == null ? '–' : '$df', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, color: (df ?? 0) > 0 ? UbColors.rose : UbColors.textMuted))),
                    DataCell(Text(QualityMath.fmtDu(du), style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, color: du == null ? UbColors.textMuted : (du <= _rec.targetDu ? UbColors.emerald : UbColors.rose)))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dayFinds.isEmpty)
                            InkWell(
                              onTap: () => _toggleZero(team, day),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isZero ? UbColors.emerald.withValues(alpha: 0.22) : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isZero ? '✓ Zero' : 'Zero',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: isZero ? UbColors.emerald : UbColors.textMuted),
                                ),
                              ),
                            )
                          else
                            ...dayFinds.map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: InkWell(
                                  onTap: () => _openFindingModal(existing: f),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: UbColors.amber.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${f.qty} pcs', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: UbColors.amber)),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _openFindingModal(team: team, day: day),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isRed ? UbColors.rose : UbColors.cyan).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+ Temuan',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: isRed ? const Color(0xFFFCA5A5) : UbColors.cyan),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniKpi(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: UbColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: UbColors.textMuted)),
          Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildFindingsList() {
    final q = _search.trim().toLowerCase();
    final items = _rec.findings.where((f) {
      if (q.isEmpty) return true;
      return '${f.id} ${f.problem} ${f.process} ${f.foundWhere} ${f.pic} ${f.countermeasure}'.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _search = v),
          style: const TextStyle(fontSize: 12.5),
          decoration: InputDecoration(
            hintText: 'Cari problem, lokasi, ditemukan di, PIC...',
            hintStyle: const TextStyle(fontSize: 12, color: UbColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, size: 17),
            isDense: true,
            filled: true,
            fillColor: UbColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: UbColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              'Belum ada temuan di bulan ini. Tap tombol + Temuan untuk mencatat defect baru.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: UbColors.textMuted),
            ),
          )
        else
          ...items.map((f) {
            final isRed = f.team == 'red';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: UbColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: (isRed ? UbColors.rose : Colors.white24).withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(f.id, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                      const SizedBox(width: 8),
                      Text(f.date, style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: UbColors.rose.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${f.qty} pcs', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: UbColors.rose)),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _openFindingModal(existing: f),
                        icon: const Icon(Icons.edit_rounded, size: 17, color: UbColors.cyan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(f.problem, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    '${isRed ? "UB Assy Red" : "UB Assy White"}${f.process.isNotEmpty ? " · ${f.process}" : ""}${f.foundWhere.isNotEmpty ? " · Di: ${f.foundWhere}" : ""}${f.pic.isNotEmpty ? " · PIC: ${f.pic}" : ""}',
                    style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted),
                  ),
                  if (f.countermeasure.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('CM: ${f.countermeasure}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF6EE7B7))),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _DuChartPainter extends CustomPainter {
  _DuChartPainter({
    required this.du,
    required this.target,
    required this.lineColor,
  });

  final List<double?> du;
  final double target;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = du.length;
    if (dim == 0) return;

    final nonNull = du.whereType<double>().toList();
    final maxVal = nonNull.isEmpty ? target * 1.6 : math.max(target * 1.6, nonNull.reduce(math.max));
    final ymax = maxVal * 1.15;

    const padL = 8.0;
    const padR = 8.0;
    const padT = 10.0;
    const padB = 12.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;

    double xOf(int i) => padL + chartW * (i + 0.5) / dim;
    double yOf(double v) => padT + chartH * (1 - (v.clamp(0, ymax) / ymax));

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = yOf(ymax * frac);
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);
    }

    // Target dashed line
    final targetY = yOf(target);
    final targetPaint = Paint()
      ..color = UbColors.amber
      ..strokeWidth = 1.5;
    for (double x = padL; x < size.width - padR; x += 10) {
      canvas.drawLine(Offset(x, targetY), Offset(math.min(x + 6, size.width - padR), targetY), targetPaint);
    }

    // Polyline segments
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    Path? seg;
    for (var i = 0; i < dim; i++) {
      final v = du[i];
      if (v == null) {
        if (seg != null) {
          canvas.drawPath(seg, linePaint);
          seg = null;
        }
      } else {
        final pt = Offset(xOf(i), yOf(v));
        if (seg == null) {
          seg = Path()..moveTo(pt.dx, pt.dy);
        } else {
          seg.lineTo(pt.dx, pt.dy);
        }
      }
    }
    if (seg != null) canvas.drawPath(seg, linePaint);

    // Points
    for (var i = 0; i < dim; i++) {
      final v = du[i];
      if (v == null) continue;
      final pt = Offset(xOf(i), yOf(v));
      final over = v > target;
      canvas.drawCircle(
        pt,
        over ? 4.2 : 3.0,
        Paint()..color = over ? UbColors.rose : lineColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DuChartPainter oldDelegate) => true;
}
