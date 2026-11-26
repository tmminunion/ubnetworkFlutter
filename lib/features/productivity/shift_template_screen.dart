import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/productivity_ops_models.dart';
import '../../services/productivity_ops_store.dart';

class ShiftTemplateScreen extends StatefulWidget {
  const ShiftTemplateScreen({super.key});

  @override
  State<ShiftTemplateScreen> createState() => _ShiftTemplateScreenState();
}

class _ShiftTemplateScreenState extends State<ShiftTemplateScreen> {
  List<ShiftTemplateModel> _templates = const [];
  int _selectedIdx = 0;
  double _masterTaktTime = 2.4;
  double _simTaktTime = 2.4;
  bool _loading = true;
  bool _fromServer = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ProductivityOpsStore.instance.fetchTemplates(_simTaktTime);
    if (!mounted) return;
    setState(() {
      _templates = res.templates;
      _masterTaktTime = res.masterTaktTime;
      _simTaktTime = res.masterTaktTime;
      _fromServer = res.fromServer;
      if (_selectedIdx >= _templates.length) _selectedIdx = 0;
      _loading = false;
    });
  }

  ShiftTemplateModel? get _active => _templates.isEmpty ? null : _templates[_selectedIdx];

  Future<void> _saveActiveTemplate() async {
    final tpl = _active;
    if (tpl == null) return;
    final res = await ProductivityOpsStore.instance.saveTemplate(tpl);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
  }

  void _updateActiveSlots(List<ShiftTemplateSlot> newSlots) {
    final tpl = _active;
    if (tpl == null) return;
    final renumbered = newSlots.asMap().entries.map((e) => e.value.copyWith(slotNo: e.key + 1)).toList();
    final updatedList = List<ShiftTemplateModel>.from(_templates);
    updatedList[_selectedIdx] = tpl.copyWith(slots: renumbered);
    setState(() => _templates = updatedList);
  }

  Future<void> _openSlotForm([int? editIdx]) async {
    final tpl = _active;
    if (tpl == null) return;
    final existing = editIdx != null ? tpl.slots[editIdx] : null;
    final startCtrl = TextEditingController(text: existing?.startTime ?? '18:15');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '19:15');
    final durCtrl = TextEditingController(text: '${existing?.durationMin ?? 60}');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var isOt = existing?.isOvertime ?? true;
    var isActive = existing?.isActive ?? true;

    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setM) => Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(existing == null ? 'Tambah Slot Jam Kerja' : 'Edit Slot #${existing.slotNo}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Mulai (HH:MM)', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'Selesai (HH:MM)', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: durCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Durasi (mnt)', border: OutlineInputBorder(), isDense: true))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Catatan (Break/OT)', border: OutlineInputBorder(), isDense: true)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isOt,
                  title: const Text('Tandai sebagai Overtime (OT)', style: TextStyle(fontSize: 13)),
                  onChanged: (v) => setM(() => isOt = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isActive,
                  title: const Text('Slot Aktif', style: TextStyle(fontSize: 13)),
                  onChanged: (v) => setM(() => isActive = v),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Terapkan Slot', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      );

      if (ok == true) {
        final slot = ShiftTemplateSlot(
          slotNo: existing?.slotNo ?? (tpl.slots.length + 1),
          startTime: startCtrl.text.trim(),
          endTime: endCtrl.text.trim(),
          durationMin: int.tryParse(durCtrl.text.trim()) ?? 60,
          isOvertime: isOt,
          isActive: isActive,
          note: noteCtrl.text.trim(),
        );
        final slots = List<ShiftTemplateSlot>.from(tpl.slots);
        if (editIdx != null) {
          slots[editIdx] = slot;
        } else {
          slots.add(slot);
        }
        _updateActiveSlots(slots);
      }
    } finally {
      startCtrl.dispose();
      endCtrl.dispose();
      durCtrl.dispose();
      noteCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tpl = _active;
    final summary = tpl == null
        ? (planRegular: 0, planFullOt: 0, totalHours: 0.0, activeSlots: 0)
        : ShiftTemplateMath.computeSummary(tpl.slots, _simTaktTime);

    final taktPills = <double>{_masterTaktTime, 1.9, 1.6}.toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Master Jam Kerja & Shift', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text(
              _fromServer ? 'Live Sync MySQL · Simulasi Takt Time' : 'Offline-First Lokal · Simulasi Takt Time',
              style: const TextStyle(fontSize: 11, color: UbColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _saveActiveTemplate,
            icon: const Icon(Icons.save_rounded, color: UbColors.emerald),
            tooltip: 'Simpan Template',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.cyan,
        foregroundColor: UbColors.bg,
        onPressed: () => _openSlotForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Slot', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading || tpl == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
              children: [
                // Template Selector Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _templates.asMap().entries.map((e) {
                      final sel = e.key == _selectedIdx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.value.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          selected: sel,
                          onSelected: (_) => setState(() => _selectedIdx = e.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Takt Time Simulation Pills
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UbColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Simulasi Takt Time (otomatis hitung Plan = Durasi ÷ TT)', style: TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: taktPills.map((tt) {
                          final sel = (_simTaktTime - tt).abs() < 0.01;
                          return ChoiceChip(
                            label: Text('TT ${tt.toStringAsFixed(1)} mnt (${(60 / tt).round()} UPH)'),
                            selected: sel,
                            onSelected: (_) => setState(() => _simTaktTime = tt),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3 Summary Cards
                Row(
                  children: [
                    _TplKpi(label: 'PLAN REGULER', value: '${summary.planRegular} U', color: UbColors.cyan),
                    const SizedBox(width: 8),
                    _TplKpi(label: 'PLAN FULL (OT)', value: '${summary.planFullOt} U', color: UbColors.emerald),
                    const SizedBox(width: 8),
                    _TplKpi(label: 'TOTAL KERJA', value: '${summary.totalHours} Jam', color: UbColors.amber),
                  ],
                ),
                const SizedBox(height: 12),

                // Slots List
                ...tpl.slots.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final plan = s.dynamicPlan(_simTaktTime);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (s.isOvertime ? UbColors.amber : UbColors.cyan).withValues(alpha: 0.18),
                        child: Text(
                          '${s.slotNo}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: s.isOvertime ? UbColors.amber : UbColors.cyan,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(s.timeRange, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 13)),
                          const SizedBox(width: 8),
                          if (s.isOvertime)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: UbColors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('OT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: UbColors.amber)),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${s.durationMin} mnt → Plan $plan Unit${s.note.isNotEmpty ? ' · ${s.note}' : ''}',
                        style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: s.isActive,
                            onChanged: (v) {
                              final next = List<ShiftTemplateSlot>.from(tpl.slots);
                              next[idx] = s.copyWith(isActive: v);
                              _updateActiveSlots(next);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18, color: UbColors.cyan),
                            onPressed: () => _openSlotForm(idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: UbColors.rose),
                            onPressed: () {
                              final next = List<ShiftTemplateSlot>.from(tpl.slots)..removeAt(idx);
                              _updateActiveSlots(next);
                            },
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

class _TplKpi extends StatelessWidget {
  const _TplKpi({required this.label, required this.value, required this.color});

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
            Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: UbColors.textMuted)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}
