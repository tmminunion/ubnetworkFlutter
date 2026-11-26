import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';
import '../../models/productivity_ops_models.dart';
import '../../services/local_store.dart';
import '../../services/productivity_ops_store.dart';

class _SolvedChokoteiCandidate {
  const _SolvedChokoteiCandidate({
    required this.key,
    required this.date,
    required this.shift,
    required this.machine,
    required this.problem,
    required this.durationMin,
  });

  final String key;
  final String date;
  final String shift;
  final String machine;
  final String problem;
  final int durationMin;
}

class ProdKaizenScreen extends StatefulWidget {
  const ProdKaizenScreen({super.key});

  @override
  State<ProdKaizenScreen> createState() => _ProdKaizenScreenState();
}

class _ProdKaizenScreenState extends State<ProdKaizenScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<ProdKaizenItem> _items = const [];
  List<_SolvedChokoteiCandidate> _solvedChokotei = const [];
  bool _loading = true;
  String _selectedMonth = UbMasterData.todayYmd().substring(0, 7);
  bool _allMonths = false;
  String _statusFilter = 'ALL'; // ALL | SUDAH | ON PROGRES | BELUM

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ProductivityOpsStore.instance.loadKaizenItems();
    final reports = await LocalStore.instance.listReports();
    final solved = <_SolvedChokoteiCandidate>[];
    for (final r in reports) {
      for (final d in r.delays) {
        if (d.problem.trim().isEmpty) continue;
        solved.add(
          _SolvedChokoteiCandidate(
            key: '${r.tanggal}_${r.shift}_${d.machine}_${d.problem.hashCode}',
            date: r.tanggal,
            shift: r.shift,
            machine: d.machine.isEmpty ? 'UB Assy' : d.machine,
            problem: d.problem,
            durationMin: d.duration.round(),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _solvedChokotei = solved;
      _loading = false;
    });
  }

  List<ProdKaizenItem> get _filteredItems {
    return _items.where((k) {
      if (!_allMonths && k.month != _selectedMonth) return false;
      if (_statusFilter != 'ALL' && k.status != _statusFilter) return false;
      return true;
    }).toList();
  }

  void _shiftMonth(int delta) {
    final parts = _selectedMonth.split('-');
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = int.tryParse(parts[1]) ?? 1;
    final d = DateTime(y, m + delta, 1);
    setState(() {
      _selectedMonth = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      _allMonths = false;
    });
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUDAH':
        return UbColors.emerald;
      case 'ON PROGRES':
        return UbColors.amber;
      default:
        return UbColors.rose;
    }
  }

  Future<void> _openKaizenForm({ProdKaizenItem? existing, _SolvedChokoteiCandidate? fromChokotei}) async {
    final themeCtrl = TextEditingController(
      text: existing?.theme ??
          (fromChokotei != null ? 'Kaizen Penanggulangan ${fromChokotei.machine}: ${fromChokotei.problem}' : ''),
    );
    final lineCtrl = TextEditingController(text: existing?.lineProcess ?? fromChokotei?.machine ?? 'UB Assy');
    final picCtrl = TextEditingController(text: existing?.pic ?? '');
    final beforeCtrl = TextEditingController(
      text: existing?.beforeValue ?? (fromChokotei != null ? '${fromChokotei.durationMin} mnt delay' : ''),
    );
    final afterCtrl = TextEditingController(text: existing?.afterValue ?? '0 mnt delay');
    final rootCtrl = TextEditingController(text: existing?.rootCause ?? '');
    final cmCtrl = TextEditingController(text: existing?.countermeasure ?? '');
    var tag = existing?.tag ?? 'CHOKOTEI';
    var status = existing?.status ?? 'ON PROGRES';

    try {
      final saved = await showModalBottomSheet<bool>(
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
                  Text(existing == null ? 'Buat Kaizen Report Productivity' : 'Edit Kaizen Report', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  TextField(controller: themeCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Tema Kaizen', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: tag,
                          decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'CHOKOTEI', child: Text('CHOKOTEI')),
                            DropdownMenuItem(value: 'CYCLE TIME', child: Text('CYCLE TIME')),
                            DropdownMenuItem(value: 'PRODUCTIVITY', child: Text('PRODUCTIVITY')),
                            DropdownMenuItem(value: '5S', child: Text('5S')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => tag = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'SUDAH', child: Text('SUDAH')),
                            DropdownMenuItem(value: 'ON PROGRES', child: Text('ON PROGRES')),
                            DropdownMenuItem(value: 'BELUM', child: Text('BELUM')),
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
                      Expanded(child: TextField(controller: lineCtrl, decoration: const InputDecoration(labelText: 'Line / Proses', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: picCtrl, decoration: const InputDecoration(labelText: 'PIC', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: beforeCtrl, decoration: const InputDecoration(labelText: 'BEFORE', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: afterCtrl, decoration: const InputDecoration(labelText: 'AFTER', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: rootCtrl, decoration: const InputDecoration(labelText: 'Akar Masalah (Root Cause)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: cmCtrl, decoration: const InputDecoration(labelText: 'Penanggulangan (Countermeasure)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.purple, foregroundColor: Colors.white),
                    onPressed: () {
                      if (themeCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Simpan Kaizen Report', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (saved == true) {
        final next = List<ProdKaizenItem>.from(_items);
        final item = ProdKaizenItem(
          id: existing?.id ?? 'kz_${DateTime.now().millisecondsSinceEpoch}',
          tag: tag,
          month: existing?.month ?? _selectedMonth,
          theme: themeCtrl.text.trim(),
          lineProcess: lineCtrl.text.trim(),
          pic: picCtrl.text.trim().isEmpty ? 'Tim UB Assy' : picCtrl.text.trim(),
          beforeValue: beforeCtrl.text.trim(),
          afterValue: afterCtrl.text.trim(),
          status: status,
          rootCause: rootCtrl.text.trim(),
          countermeasure: cmCtrl.text.trim(),
          sourceChokoteiKey: existing?.sourceChokoteiKey ?? fromChokotei?.key ?? '',
        );
        if (existing != null) {
          final idx = next.indexWhere((e) => e.id == existing.id);
          if (idx >= 0) next[idx] = item;
        } else {
          next.insert(0, item);
        }
        await ProductivityOpsStore.instance.saveKaizenItems(next);
        if (mounted) setState(() => _items = next);
      }
    } finally {
      themeCtrl.dispose();
      lineCtrl.dispose();
      picCtrl.dispose();
      beforeCtrl.dispose();
      afterCtrl.dispose();
      rootCtrl.dispose();
      cmCtrl.dispose();
    }
  }

  Future<void> _deleteItem(ProdKaizenItem item) async {
    final next = _items.where((e) => e.id != item.id).toList();
    await ProductivityOpsStore.instance.saveKaizenItems(next);
    if (mounted) setState(() => _items = next);
  }

  @override
  Widget build(BuildContext context) {
    final linkedKeys = _items.map((e) => e.sourceChokoteiKey).where((e) => e.isNotEmpty).toSet();
    final unlinkedChokotei = _solvedChokotei.where((c) => !linkedKeys.contains(c.key)).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kaizen Report Productivity', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('Rekap Before-After & Follow-Up Chokotei', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: UbColors.purple,
          labelColor: const Color(0xFFC084FC),
          unselectedLabelColor: UbColors.textMuted,
          tabs: [
            Tab(text: 'Kaizen Report (${_filteredItems.length})'),
            Tab(text: 'Chokotei Sudah (${_solvedChokotei.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.purple,
        foregroundColor: Colors.white,
        onPressed: () => _openKaizenForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kaizen Baru', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 3 Summary Cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      _KzKpi(label: 'KAIZEN REPORT', value: '${_items.length}', color: const Color(0xFFC084FC)),
                      const SizedBox(width: 8),
                      _KzKpi(label: 'CHOKOTEI SUDAH', value: '${_solvedChokotei.length}', color: UbColors.cyan),
                      const SizedBox(width: 8),
                      _KzKpi(label: 'BELUM DI-KAIZEN', value: '${unlinkedChokotei.length}', color: UbColors.amber),
                    ],
                  ),
                ),

                // Month & Status filter bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left_rounded, size: 20)),
                        Text(_allMonths ? 'Semua Bulan' : _selectedMonth, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 12)),
                        IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right_rounded, size: 20)),
                        FilterChip(
                          label: const Text('Semua', style: TextStyle(fontSize: 11)),
                          selected: _allMonths,
                          onSelected: (v) => setState(() => _allMonths = v),
                        ),
                        const SizedBox(width: 6),
                        for (final st in ['ALL', 'SUDAH', 'ON PROGRES', 'BELUM'])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(st, style: const TextStyle(fontSize: 10.5)),
                              selected: _statusFilter == st,
                              onSelected: (_) => setState(() => _statusFilter = st),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildKaizenList(),
                      _buildChokoteiTab(linkedKeys),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildKaizenList() {
    final list = _filteredItems;
    if (list.isEmpty) {
      return const Center(
        child: Text('Belum ada Kaizen Report pada filter ini.', style: TextStyle(color: UbColors.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 84),
      itemCount: list.length,
      itemBuilder: (_, idx) {
        final k = list[idx];
        final sc = _statusColor(k.status);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: UbColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sc.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: UbColors.purple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text(k.tag, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFC084FC))),
                  ),
                  const SizedBox(width: 6),
                  Text(k.month, style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: sc.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
                    child: Text(k.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: sc)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(k.theme, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              Text('${k.lineProcess} · PIC: ${k.pic}', style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: UbColors.bg, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('BEFORE: ${k.beforeValue}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: UbColors.rose)),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 15, color: UbColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('AFTER: ${k.afterValue}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: UbColors.emerald)),
                    ),
                  ],
                ),
              ),
              if (k.countermeasure.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('CM: ${k.countermeasure}', style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _openKaizenForm(existing: k),
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteItem(k),
                    icon: const Icon(Icons.delete_outline_rounded, size: 15, color: UbColors.rose),
                    label: const Text('Hapus', style: TextStyle(fontSize: 11.5, color: UbColors.rose)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChokoteiTab(Set<String> linkedKeys) {
    if (_solvedChokotei.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada data chokotei lokal dari Checksheet A3 yang siap dibuatkan Kaizen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: UbColors.textMuted),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 84),
      itemCount: _solvedChokotei.length,
      itemBuilder: (_, idx) {
        final c = _solvedChokotei[idx];
        final done = linkedKeys.contains(c.key);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${c.machine} · ${c.problem}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            subtitle: Text('${c.date} · Shift ${c.shift} · Delay ${c.durationMin} mnt', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
            trailing: done
                ? const Chip(label: Text('Sudah Kaizen', style: TextStyle(fontSize: 10)))
                : FilledButton.tonal(
                    onPressed: () => _openKaizenForm(fromChokotei: c),
                    child: const Text('Buat Kaizen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
          ),
        );
      },
    );
  }
}

class _KzKpi extends StatelessWidget {
  const _KzKpi({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: UbColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: UbColors.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}
