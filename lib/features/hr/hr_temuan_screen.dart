import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/hr_morale_models.dart';
import '../../services/hr_morale_store.dart';

class HrTemuanScreen extends StatefulWidget {
  const HrTemuanScreen({super.key});

  @override
  State<HrTemuanScreen> createState() => _HrTemuanScreenState();
}

class _HrTemuanScreenState extends State<HrTemuanScreen> {
  String _ym = hrTodayYmd().substring(0, 7);
  String _teamFilter = 'all';
  String _search = '';
  List<HrFindingItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await HrMoraleStore.instance.loadHrFindings(_ym);
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

  Future<void> _openForm([HrFindingItem? existing]) async {
    final today = hrTodayYmd();
    final dateCtrl = TextEditingController(text: existing?.date ?? (today.startsWith(_ym) ? today : '$_ym-01'));
    final qtyCtrl = TextEditingController(text: '${existing?.qty ?? 1}');
    final probCtrl = TextEditingController(text: existing?.problem ?? '');
    final procCtrl = TextEditingController(text: existing?.process ?? '');
    final whereCtrl = TextEditingController(text: existing?.foundWhere ?? '');
    final picCtrl = TextEditingController(text: existing?.pic ?? '');
    final cmCtrl = TextEditingController(text: existing?.countermeasure ?? '');
    var team = existing?.team ?? 'red';
    var hasKaizen = existing?.hasKaizen ?? false;

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
                  Text(existing == null ? 'Temuan HR-Dev Baru' : 'Edit Temuan ${existing.id}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Tanggal', border: OutlineInputBorder(), isDense: true))),
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
                      const SizedBox(width: 8),
                      SizedBox(width: 72, child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: probCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Problem / Temuan HR-Dev *', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: procCtrl, decoration: const InputDecoration(labelText: 'Lokasi / Proses', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: whereCtrl, decoration: const InputDecoration(labelText: 'Ditemukan di', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: picCtrl, decoration: const InputDecoration(labelText: 'PIC', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: cmCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Countermeasure', border: OutlineInputBorder(), isDense: true)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: hasKaizen,
                    title: const Text('Sudah dibuatkan Kaizen HR-Dev', style: TextStyle(fontSize: 13)),
                    onChanged: (v) => setM(() => hasKaizen = v),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.purple, foregroundColor: Colors.white),
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
        final next = List<HrFindingItem>.from(_items);
        final item = HrFindingItem(
          id: existing?.id ?? 'H${(next.length + 1).toString().padLeft(2, '0')}',
          date: dateCtrl.text.trim(),
          team: team,
          qty: int.tryParse(qtyCtrl.text.trim()) ?? 1,
          problem: probCtrl.text.trim(),
          process: procCtrl.text.trim(),
          foundWhere: whereCtrl.text.trim(),
          countermeasure: cmCtrl.text.trim(),
          pic: picCtrl.text.trim(),
          hasKaizen: hasKaizen,
        );
        if (existing != null) {
          final idx = next.indexWhere((e) => e.id == existing.id);
          if (idx >= 0) next[idx] = item;
        } else {
          next.insert(0, item);
        }
        await HrMoraleStore.instance.saveHrFindings(_ym, next);
        await HrMoraleStore.instance.syncUpsertHrFinding(item, isEdit: existing != null);
        if (mounted) setState(() => _items = next);
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
    final shown = _items.where((f) {
      if (_teamFilter != 'all' && f.team != _teamFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return f.problem.toLowerCase().contains(q) || f.process.toLowerCase().contains(q) || f.pic.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temuan & Kaizen HR-Dev', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('List Up Problem SDM & Morale Area H', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.purple,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Temuan Baru', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 84),
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
                    Text(_ym, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
                    const Spacer(),
                    for (final t in [('all', 'Semua'), ('red', 'Red'), ('white', 'White')])
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ChoiceChip(
                          label: Text(t.$2, style: const TextStyle(fontSize: 11)),
                          selected: _teamFilter == t.$1,
                          onSelected: (_) => setState(() => _teamFilter = t.$1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => setState(() => _search = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari problem, lokasi, PIC...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 17),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: Text('Belum ada temuan HR-Dev di bulan ini.', style: TextStyle(color: UbColors.textMuted))),
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
                                Text(f.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: Color(0xFFC084FC))),
                                const SizedBox(width: 6),
                                Text(f.date, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted)),
                                const SizedBox(width: 6),
                                Chip(label: Text('${f.team.toUpperCase()} · Qty ${f.qty}', style: const TextStyle(fontSize: 9.5)), visualDensity: VisualDensity.compact),
                                const Spacer(),
                                if (f.hasKaizen)
                                  const Text('✨ Kaizen H', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.emerald)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(f.problem, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                            if (f.process.isNotEmpty || f.foundWhere.isNotEmpty)
                              Text('${f.process}${f.foundWhere.isNotEmpty ? ' · ${f.foundWhere}' : ''}', style: const TextStyle(fontSize: 11, color: UbColors.amber)),
                            if (f.countermeasure.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('CM: ${f.countermeasure}', style: const TextStyle(fontSize: 11.5, color: UbColors.emerald)),
                              ),
                            Row(
                              children: [
                                Text('PIC: ${f.pic.isEmpty ? '-' : f.pic}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                                const Spacer(),
                                IconButton(icon: const Icon(Icons.edit_rounded, size: 17, color: UbColors.cyan), onPressed: () => _openForm(f)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: UbColors.rose),
                                  onPressed: () async {
                                    final next = _items.where((e) => e.id != f.id).toList();
                                    await HrMoraleStore.instance.saveHrFindings(_ym, next);
                                    if (mounted) setState(() => _items = next);
                                    await HrMoraleStore.instance.syncDeleteHrFinding(f.id);
                                  },
                                ),
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
