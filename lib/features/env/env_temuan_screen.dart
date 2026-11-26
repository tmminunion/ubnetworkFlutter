import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/cost_env_models.dart';
import '../../services/cost_env_store.dart';

class EnvTemuanScreen extends StatefulWidget {
  const EnvTemuanScreen({super.key});

  @override
  State<EnvTemuanScreen> createState() => _EnvTemuanScreenState();
}

class _EnvTemuanScreenState extends State<EnvTemuanScreen> {
  String _ym = costEnvTodayYmd().substring(0, 7);
  String _teamFilter = 'all';
  String _kindFilter = 'all';
  String _search = '';
  List<EnvFindingItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await CostEnvStore.instance.loadEnvFindings(_ym);
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

  Future<void> _toggleStatus(EnvFindingItem f) async {
    final next = _items
        .map((e) => e.id == f.id ? e.copyWith(status: e.status == 'open' ? 'closed' : 'open') : e)
        .toList();
    await CostEnvStore.instance.saveEnvFindings(_ym, next);
    if (mounted) setState(() => _items = next);
  }

  Future<void> _openForm([EnvFindingItem? existing]) async {
    final today = costEnvTodayYmd();
    final dateCtrl = TextEditingController(text: existing?.date ?? (today.startsWith(_ym) ? today : '$_ym-01'));
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final picCtrl = TextEditingController(text: existing?.pic ?? '');
    final probCtrl = TextEditingController(text: existing?.problem ?? '');
    final cmCtrl = TextEditingController(text: existing?.countermeasure ?? '');
    final dueCtrl = TextEditingController(text: existing?.due ?? '');
    var team = existing?.team ?? 'red';
    var kind = existing?.kind ?? 'leak';
    var status = existing?.status ?? 'open';
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
                  Text(existing == null ? 'Temuan Lingkungan Baru' : 'Edit Temuan ${existing.id}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: kind,
                          decoration: const InputDecoration(labelText: 'Jenis', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'leak', child: Text('Air Leakage')),
                            DropdownMenuItem(value: 'energy', child: Text('Energi Listrik')),
                            DropdownMenuItem(value: 'other', child: Text('Lainnya / 3R')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => kind = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'open', child: Text('Open')),
                            DropdownMenuItem(value: 'closed', child: Text('Closed')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => status = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Lokasi / Mesin', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: picCtrl, decoration: const InputDecoration(labelText: 'PIC', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: probCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Problem Lingkungan *', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: cmCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Countermeasure', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: dueCtrl, decoration: const InputDecoration(labelText: 'Target Selesai (YYYY-MM-DD)', border: OutlineInputBorder(), isDense: true)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: hasKaizen,
                    title: const Text('Sudah dibuatkan Kaizen Report (Area E)', style: TextStyle(fontSize: 13)),
                    onChanged: (v) => setM(() => hasKaizen = v),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg),
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
        final next = List<EnvFindingItem>.from(_items);
        final item = EnvFindingItem(
          id: existing?.id ?? 'E${(next.length + 1).toString().padLeft(2, '0')}',
          date: dateCtrl.text.trim(),
          team: team,
          kind: kind,
          location: locCtrl.text.trim(),
          problem: probCtrl.text.trim(),
          countermeasure: cmCtrl.text.trim(),
          pic: picCtrl.text.trim(),
          due: dueCtrl.text.trim(),
          status: status,
          hasKaizen: hasKaizen,
        );
        if (existing != null) {
          final idx = next.indexWhere((e) => e.id == existing.id);
          if (idx >= 0) next[idx] = item;
        } else {
          next.insert(0, item);
        }
        await CostEnvStore.instance.saveEnvFindings(_ym, next);
        if (mounted) setState(() => _items = next);
      }
    } finally {
      dateCtrl.dispose();
      locCtrl.dispose();
      picCtrl.dispose();
      probCtrl.dispose();
      cmCtrl.dispose();
      dueCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = costEnvTodayYmd();
    final shown = _items.where((f) {
      if (_teamFilter != 'all' && f.team != _teamFilter) return false;
      if (_kindFilter != 'all' && f.kind != _kindFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return f.problem.toLowerCase().contains(q) || f.location.toLowerCase().contains(q) || f.pic.toLowerCase().contains(q);
      }
      return true;
    }).toList();
    final openCount = _items.where((e) => e.status == 'open').length;
    final kzCount = _items.where((e) => e.hasKaizen).length;

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temuan Lingkungan & Kaizen', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('Air Leakage, Energi Listrik & 3R Area E', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.emerald,
        foregroundColor: UbColors.bg,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Temuan Baru', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 84),
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
                          Text(_ym, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900)),
                          IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
                          const Spacer(),
                          Text('$openCount Open · $kzCount Kaizen', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: UbColors.emerald)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        onChanged: (v) => setState(() => _search = v.trim()),
                        decoration: InputDecoration(
                          hintText: 'Cari problem, lokasi, PIC...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 17),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                            for (final k in [('all', 'Semua Jenis'), ('leak', 'Air Leak'), ('energy', 'Energi'), ('other', '3R/Lain')])
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
                    child: Center(child: Text('Belum ada temuan lingkungan di bulan ini.', style: TextStyle(color: UbColors.textMuted))),
                  )
                else
                  ...shown.map((f) {
                    final closed = f.status == 'closed';
                    final late = !closed && f.due.isNotEmpty && f.due.compareTo(today) < 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(f.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: UbColors.emerald)),
                                const SizedBox(width: 6),
                                Text(f.date, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted)),
                                const SizedBox(width: 6),
                                Chip(label: Text(f.kindLabel, style: const TextStyle(fontSize: 9.5)), visualDensity: VisualDensity.compact),
                                const Spacer(),
                                InkWell(
                                  onTap: () => _toggleStatus(f),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (closed ? UbColors.emerald : UbColors.rose).withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      closed ? 'CLOSED' : 'OPEN',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: closed ? UbColors.emerald : UbColors.rose),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(f.problem, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                            Text('${f.team.toUpperCase()} · ${f.location.isEmpty ? 'UB Assy' : f.location} · PIC: ${f.pic.isEmpty ? '-' : f.pic}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                            if (f.countermeasure.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('CM: ${f.countermeasure}', style: const TextStyle(fontSize: 11.5, color: UbColors.emerald)),
                              ),
                            Row(
                              children: [
                                if (late)
                                  const Text('⚠️ Terlambat', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.rose)),
                                if (f.hasKaizen) ...[
                                  if (late) const SizedBox(width: 8),
                                  const Text('✨ Kaizen E', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                                ],
                                const Spacer(),
                                IconButton(icon: const Icon(Icons.edit_rounded, size: 17, color: UbColors.cyan), onPressed: () => _openForm(f)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: UbColors.rose),
                                  onPressed: () async {
                                    final next = _items.where((e) => e.id != f.id).toList();
                                    await CostEnvStore.instance.saveEnvFindings(_ym, next);
                                    if (mounted) setState(() => _items = next);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
