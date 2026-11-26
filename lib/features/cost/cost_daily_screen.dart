import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/cost_env_models.dart';
import '../../services/cost_env_store.dart';

class CostDailyScreen extends StatefulWidget {
  const CostDailyScreen({super.key});

  @override
  State<CostDailyScreen> createState() => _CostDailyScreenState();
}

class _CostDailyScreenState extends State<CostDailyScreen> {
  String _ym = costEnvTodayYmd().substring(0, 7);
  String _team = 'red'; // red | white
  CostDailyMonth? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await CostEnvStore.instance.loadCostDaily(_ym);
    if (!mounted) return;
    setState(() {
      _data = d;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    final p = _ym.split('-');
    final d = DateTime(int.parse(p[0]), int.parse(p[1]) + delta, 1);
    setState(() => _ym = '${d.year}-${d.month.toString().padLeft(2, '0')}');
    _load();
  }

  Future<void> _editDayDialog(CostItem item, int day) async {
    final d = _data;
    if (d == null) return;
    final arr = d.valuesFor(_team)[item.id] ?? List<double?>.filled(31, null);
    final cur = arr[day - 1];
    final ctrl = TextEditingController(text: cur == null ? '' : '$cur');

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: UbColors.surface,
          title: Text('${item.name} · Tgl $day', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Pemakaian (kosong = belum diisi)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: UbColors.amber, foregroundColor: UbColors.bg),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );

      if (ok == true) {
        final raw = ctrl.text.trim().replaceAll(',', '.');
        final val = raw.isEmpty ? null : double.tryParse(raw);
        final nextArr = List<double?>.from(arr);
        nextArr[day - 1] = val;
        final nextMap = Map<String, List<double?>>.from(d.valuesFor(_team));
        nextMap[item.id] = nextArr;
        final updated = _team == 'red' ? d.copyWith(red: nextMap) : d.copyWith(white: nextMap);
        await CostEnvStore.instance.saveCostDaily(updated);
        await CostEnvStore.instance.patchCostCell(ym: _ym, team: _team, itemId: item.id, day: day, value: val);
        if (mounted) setState(() => _data = updated);
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _openItemManager([CostItem? existing]) async {
    final d = _data;
    if (d == null) return;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final tRedCtrl = TextEditingController(text: existing?.targetRed == null ? '' : '${existing!.targetRed}');
    final tWhiteCtrl = TextEditingController(text: existing?.targetWhite == null ? '' : '${existing!.targetWhite}');

    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Tambah Item Cost' : 'Edit Item Cost', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Item (O. Supply / Consumable)', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: tRedCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target Red', border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: tWhiteCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target White', border: OutlineInputBorder(), isDense: true))),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: UbColors.amber, foregroundColor: UbColors.bg),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Simpan Item', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      );

      if (ok == true) {
        final tRed = double.tryParse(tRedCtrl.text.trim().replaceAll(',', '.'));
        final tWhite = double.tryParse(tWhiteCtrl.text.trim().replaceAll(',', '.'));
        final items = List<CostItem>.from(d.items);
        final red = Map<String, List<double?>>.from(d.red);
        final white = Map<String, List<double?>>.from(d.white);

        if (existing != null) {
          final idx = items.indexWhere((e) => e.id == existing.id);
          if (idx >= 0) {
            items[idx] = CostItem(id: existing.id, name: nameCtrl.text.trim(), targetRed: tRed, targetWhite: tWhite);
          }
        } else {
          final id = 'ci_${DateTime.now().millisecondsSinceEpoch}';
          items.add(CostItem(id: id, name: nameCtrl.text.trim(), targetRed: tRed, targetWhite: tWhite));
          red[id] = List<double?>.filled(31, null);
          white[id] = List<double?>.filled(31, null);
        }

        final updated = d.copyWith(items: items, red: red, white: white);
        await CostEnvStore.instance.saveCostDaily(updated);
        if (mounted) setState(() => _data = updated);
      }
    } finally {
      nameCtrl.dispose();
      tRedCtrl.dispose();
      tWhiteCtrl.dispose();
    }
  }

  Future<void> _deleteItem(CostItem item) async {
    final d = _data;
    if (d == null) return;
    final items = d.items.where((e) => e.id != item.id).toList();
    final red = Map<String, List<double?>>.from(d.red)..remove(item.id);
    final white = Map<String, List<double?>>.from(d.white)..remove(item.id);
    final updated = d.copyWith(items: items, red: red, white: white);
    await CostEnvStore.instance.saveCostDaily(updated);
    if (mounted) setState(() => _data = updated);
  }

  Color _paceColor(String? level) {
    if (level == 'bad') return UbColors.rose;
    if (level == 'warn') return UbColors.amber;
    if (level == 'ok') return UbColors.emerald;
    return UbColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final dim = daysInMonthYm(_ym);
    var overCount = 0;
    if (d != null) {
      for (final it in d.items) {
        final m = CostPaceMath.computeItemMetrics(d.valuesFor(_team)[it.id] ?? const [], dim, it.targetFor(_team));
        if (m.pct != null && m.pct! > 100) overCount++;
      }
    }

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Control Cost Daily (UB Assy)', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('Pemakaian O. Supply & Consumable 1–31', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
        actions: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'red', label: Text('RED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
              ButtonSegment(value: 'white', label: Text('WHITE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
            ],
            selected: {_team},
            onSelectionChanged: (s) => setState(() => _team = s.first),
          ),
          const SizedBox(width: 10),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.amber,
        foregroundColor: UbColors.bg,
        onPressed: () => _openItemManager(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Item', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading || d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 84),
              children: [
                // Month Nav + Summary Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: UbColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
                      Text(_ym, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14)),
                      IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (overCount > 0 ? UbColors.rose : UbColors.emerald).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$overCount / ${d.items.length} Over Target',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: overCount > 0 ? UbColors.rose : UbColors.emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                ...d.items.map((it) {
                  final vals = d.valuesFor(_team)[it.id] ?? List<double?>.filled(31, null);
                  final tgt = it.targetFor(_team);
                  final m = CostPaceMath.computeItemMetrics(vals, dim, tgt);
                  final pc = _paceColor(m.paceLevel);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: UbColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: pc.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: pc)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5))),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_rounded, size: 17, color: UbColors.cyan),
                              onPressed: () => _openItemManager(it),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline_rounded, size: 17, color: UbColors.rose),
                              onPressed: () => _deleteItem(it),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Target: ${tgt ?? '-'}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.amber)),
                            const SizedBox(width: 12),
                            Text('Total: ${m.total ?? '-'}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 12),
                            Text(
                              m.pct == null ? '-%' : '${m.pct!.round()}%',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: pc),
                            ),
                            const Spacer(),
                            Text(
                              'Est: ${m.projection == null ? '-' : m.projection!.round()}',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: pc),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(dim, (i) {
                              final day = i + 1;
                              final v = vals[i];
                              return Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: InkWell(
                                  onTap: () => _editDayDialog(it, day),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 40,
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    decoration: BoxDecoration(
                                      color: v != null ? pc.withValues(alpha: 0.16) : UbColors.bg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: v != null ? pc.withValues(alpha: 0.5) : Colors.white12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text('$day', style: const TextStyle(fontSize: 9, color: UbColors.textMuted)),
                                        Text(
                                          v == null ? '-' : (v == v.roundToDouble() ? '${v.toInt()}' : '$v'),
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
