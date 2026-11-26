import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/cost_env_models.dart';
import '../../services/cost_env_store.dart';

class CostTemuanScreen extends StatefulWidget {
  const CostTemuanScreen({super.key});

  @override
  State<CostTemuanScreen> createState() => _CostTemuanScreenState();
}

class _CostTemuanScreenState extends State<CostTemuanScreen> {
  String _ym = costEnvTodayYmd().substring(0, 7);
  String _teamFilter = 'all';
  String _kindFilter = 'all';
  List<CostFinding> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await CostEnvStore.instance.loadCostFindings(_ym);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    final p = _ym.split('-');
    final d = DateTime(int.parse(p[0]), int.parse(p[1]) + delta, 1);
    setState(() => _ym = '${d.year}-${d.month.toString().padLeft(2, '0')}');
    _load();
  }

  Future<void> _openForm([CostFinding? existing]) async {
    final today = costEnvTodayYmd();
    final dateCtrl = TextEditingController(text: existing?.date ?? (today.startsWith(_ym) ? today : '$_ym-01'));
    final procCtrl = TextEditingController(text: existing?.process ?? '');
    final whereCtrl = TextEditingController(text: existing?.foundWhere ?? '');
    final probCtrl = TextEditingController(text: existing?.problem ?? '');
    final amtCtrl = TextEditingController(text: existing != null && existing.amount > 0 ? '${existing.amount}' : '');
    final cmCtrl = TextEditingController(text: existing?.countermeasure ?? '');
    final picCtrl = TextEditingController(text: existing?.pic ?? '');
    var team = existing?.team ?? 'red';
    var kind = existing?.kind ?? 'consumable';

    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setM) => Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(existing == null ? 'Tambah Temuan Cost' : 'Edit Temuan ${existing.id}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Tanggal (YYYY-MM-DD)', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: team,
                          decoration: const InputDecoration(labelText: 'Regu', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'red', child: Text('Red')),
                            DropdownMenuItem(value: 'white', child: Text('White')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => team = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: kind,
                    decoration: const InputDecoration(labelText: 'Jenis Pemborosan', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'supply', child: Text('O. Supply')),
                      DropdownMenuItem(value: 'consumable', child: Text('Consumable Tools')),
                      DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                    ],
                    onChanged: (v) {
                      if (v != null) setM(() => kind = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: procCtrl, decoration: const InputDecoration(labelText: 'Lokasi / Item', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: whereCtrl, decoration: const InputDecoration(labelText: 'Ditemukan di', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: probCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Temuan Pemborosan *', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Potensi Loss (Rp)', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: picCtrl, decoration: const InputDecoration(labelText: 'PIC', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: cmCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Penanggulangan', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.rose, foregroundColor: Colors.white),
                    onPressed: () {
                      if (probCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Simpan Temuan', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (ok == true) {
        final next = List<CostFinding>.from(_items);
        final nextNum = next.length + 1;
        final item = CostFinding(
          id: existing?.id ?? 'C${nextNum.toString().padLeft(2, '0')}',
          date: dateCtrl.text.trim(),
          team: team,
          kind: kind,
          process: procCtrl.text.trim(),
          foundWhere: whereCtrl.text.trim(),
          problem: probCtrl.text.trim(),
          amount: int.tryParse(amtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          countermeasure: cmCtrl.text.trim(),
          pic: picCtrl.text.trim(),
        );
        if (existing != null) {
          final idx = next.indexWhere((e) => e.id == existing.id);
          if (idx >= 0) next[idx] = item;
        } else {
          next.insert(0, item);
        }
        await CostEnvStore.instance.saveCostFindings(_ym, next);
        await CostEnvStore.instance.syncUpsertCostFinding(item, isEdit: existing != null);
        if (mounted) setState(() => _items = next);
      }
    } finally {
      dateCtrl.dispose();
      procCtrl.dispose();
      whereCtrl.dispose();
      probCtrl.dispose();
      amtCtrl.dispose();
      cmCtrl.dispose();
      picCtrl.dispose();
    }
  }

  Future<void> _delete(CostFinding f) async {
    final next = _items.where((e) => e.id != f.id).toList();
    await CostEnvStore.instance.saveCostFindings(_ym, next);
    if (mounted) setState(() => _items = next);
    await CostEnvStore.instance.syncDeleteCostFinding(f.id);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _items
        .where((f) => (_teamFilter == 'all' || f.team == _teamFilter) && (_kindFilter == 'all' || f.kind == _kindFilter))
        .toList();
    final totalLoss = shown.fold<int>(0, (acc, e) => acc + e.amount);

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temuan Cost (List Up Problem)', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('Pencatatan Pemborosan & Potensi Loss (Rp)', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.rose,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Temuan', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 84),
              children: [
                // Month + Total Loss Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UbColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
                          Text(_ym, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900)),
                          IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${shown.length} Temuan', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                              Text(formatRupiah(totalLoss), style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w900, color: UbColors.rose)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final t in [('all', 'Semua Regu'), ('red', 'Red'), ('white', 'White')])
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(t.$2, style: const TextStyle(fontSize: 11)),
                                  selected: _teamFilter == t.$1,
                                  onSelected: (_) => setState(() => _teamFilter = t.$1),
                                ),
                              ),
                            for (final k in [('all', 'Semua Jenis'), ('supply', 'O. Supply'), ('consumable', 'Consumable'), ('other', 'Lainnya')])
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(k.$2, style: const TextStyle(fontSize: 11)),
                                  selected: _kindFilter == k.$1,
                                  onSelected: (_) => setState(() => _kindFilter = k.$1),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: Text('Belum ada temuan cost di bulan ini.', style: TextStyle(color: UbColors.textMuted))),
                  )
                else
                  ...shown.map(
                    (f) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(f.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: UbColors.amber)),
                                const SizedBox(width: 6),
                                Text(f.date, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted)),
                                const SizedBox(width: 6),
                                Chip(label: Text(f.team.toUpperCase(), style: const TextStyle(fontSize: 9.5)), visualDensity: VisualDensity.compact),
                                const SizedBox(width: 4),
                                Chip(label: Text(f.kindLabel, style: const TextStyle(fontSize: 9.5)), visualDensity: VisualDensity.compact),
                                const Spacer(),
                                if (f.amount > 0)
                                  Text(formatRupiah(f.amount), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: UbColors.rose, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(f.problem, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                            if (f.process.isNotEmpty || f.foundWhere.isNotEmpty)
                              Text('${f.process}${f.foundWhere.isNotEmpty ? ' · ${f.foundWhere}' : ''}', style: const TextStyle(fontSize: 11.5, color: UbColors.amber)),
                            if (f.countermeasure.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('CM: ${f.countermeasure}', style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
                              ),
                            Row(
                              children: [
                                Text('PIC: ${f.pic.isEmpty ? '-' : f.pic}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                                const Spacer(),
                                IconButton(icon: const Icon(Icons.edit_rounded, size: 17, color: UbColors.cyan), onPressed: () => _openForm(f)),
                                IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 17, color: UbColors.rose), onPressed: () => _delete(f)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
