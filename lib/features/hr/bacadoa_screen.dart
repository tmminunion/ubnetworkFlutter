import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/hr_morale_models.dart';
import '../../services/hr_morale_store.dart';

class BacaDoaScreen extends StatefulWidget {
  const BacaDoaScreen({super.key});

  @override
  State<BacaDoaScreen> createState() => _BacaDoaScreenState();
}

class _BacaDoaScreenState extends State<BacaDoaScreen> {
  String _ym = hrTodayYmd().substring(0, 7);
  String _shift = 'RED';
  List<BacaDoaOperator> _operators = const [];
  Map<int, BacaDoaAssignment> _records = const {};
  bool _loading = true;

  static const _dayNames = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ops = HrMoraleStore.instance.operatorsForShift(_shift);
    final recs = await HrMoraleStore.instance.loadBacaDoa(_ym, _shift);
    if (!mounted) return;
    setState(() {
      _operators = ops;
      _records = recs;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    final p = _ym.split('-');
    final d = DateTime(int.parse(p[0]), int.parse(p[1]) + delta, 1);
    setState(() => _ym = '${d.year}-${d.month.toString().padLeft(2, '0')}');
    _load();
  }

  Future<void> _autoSchedule() async {
    final generated = BacaDoaEngine.generateTueToFriRotation(ym: _ym, operators: _operators);
    await HrMoraleStore.instance.saveBacaDoa(_ym, _shift, generated);
    if (!mounted) return;
    setState(() => _records = generated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rotasi otomatis Selasa–Jumat dibuat untuk ${generated.length} hari (Senin Briefing Masal & Weekend off)!')),
    );
  }

  Future<void> _toggleDoneQuick(int day) async {
    final cur = _records[day];
    if (cur == null) return;
    final next = Map<int, BacaDoaAssignment>.from(_records);
    next[day] = cur.copyWith(status: cur.status == 'done' ? 'scheduled' : 'done');
    await HrMoraleStore.instance.saveBacaDoa(_ym, _shift, next);
    if (mounted) setState(() => _records = next);
  }

  Future<void> _openDayModal(int day) async {
    final existing = _records[day];
    var selectedMemberId = existing?.memberId ?? (_operators.isNotEmpty ? _operators.first.id : 0);
    var status = existing?.status ?? 'scheduled';
    final subCtrl = TextEditingController(text: existing?.substituteName ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final isMon = BacaDoaEngine.isMonday(_ym, day);

    try {
      final action = await showModalBottomSheet<String>(
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
                  Text('Petugas Doa · $_ym-${day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                  if (isMon)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: UbColors.amber.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
                      child: const Text('Hari Senin: BRIEFING MASAL Shopfloor (secara standar off giliran doa perorangan).', style: TextStyle(fontSize: 11.5, color: UbColors.amber)),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedMemberId,
                    decoration: const InputDecoration(labelText: 'Pilih Operator (TM)', border: OutlineInputBorder(), isDense: true),
                    items: _operators.map((op) => DropdownMenuItem(value: op.id, child: Text('${op.name} (${op.pos})'))).toList(),
                    onChanged: (v) {
                      if (v != null) setM(() => selectedMemberId = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status Pelaksanaan', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'scheduled', child: Text('○ Terjadwal (Rencana)')),
                      DropdownMenuItem(value: 'done', child: Text('● Selesai Sesuai (Aktual TL)')),
                      DropdownMenuItem(value: 'replaced', child: Text('Digantikan (Substituted)')),
                      DropdownMenuItem(value: 'off', child: Text('Off / Libur')),
                    ],
                    onChanged: (v) {
                      if (v != null) setM(() => status = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Pengganti (opsional)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Catatan Briefing Asare', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (existing != null)
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, 'delete'),
                          child: const Text('Hapus', style: TextStyle(color: UbColors.rose)),
                        ),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg),
                        onPressed: () => Navigator.pop(ctx, 'save'),
                        child: const Text('Simpan Jadwal', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (action == 'delete') {
        final next = Map<int, BacaDoaAssignment>.from(_records)..remove(day);
        await HrMoraleStore.instance.saveBacaDoa(_ym, _shift, next);
        if (mounted) setState(() => _records = next);
      } else if (action == 'save') {
        final op = _operators.firstWhere((e) => e.id == selectedMemberId, orElse: () => _operators.first);
        final next = Map<int, BacaDoaAssignment>.from(_records);
        next[day] = BacaDoaAssignment(
          day: day,
          memberId: op.id,
          memberName: op.name,
          noreg: op.noreg,
          pos: op.pos,
          status: status,
          substituteName: subCtrl.text.trim(),
          note: noteCtrl.text.trim(),
        );
        await HrMoraleStore.instance.saveBacaDoa(_ym, _shift, next);
        if (mounted) setState(() => _records = next);
      }
    } finally {
      subCtrl.dispose();
      noteCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = hrDaysInMonth(_ym);
    var effectiveDays = 0;
    for (var d = 1; d <= dim; d++) {
      if (!BacaDoaEngine.isWeekend(_ym, d) && !BacaDoaEngine.isMonday(_ym, d)) effectiveDays++;
    }
    final assigned = _records.length;
    final done = _records.values.where((r) => r.status == 'done').length;

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Matrik Baca Doa Asare', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('Rotasi Selasa–Jumat (Senin Briefing Masal)', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
        actions: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'RED', label: Text('RED', style: TextStyle(fontSize: 11))),
              ButtonSegment(value: 'WHITE', label: Text('WHITE', style: TextStyle(fontSize: 11))),
            ],
            selected: {_shift},
            onSelectionChanged: (s) {
              setState(() => _shift = s.first);
              _load();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
              children: [
                // Month + Auto-Schedule
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
                          Text(_ym, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14)),
                          IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
                          const Spacer(),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                            onPressed: _autoSchedule,
                            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                            label: const Text('Rotasi Sel–Jum', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('TM: ${_operators.length}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                          Text('Efektif: $effectiveDays hr', style: const TextStyle(fontSize: 11, color: UbColors.cyan, fontWeight: FontWeight.w800)),
                          Text('Terjadwal: $assigned', style: const TextStyle(fontSize: 11, color: UbColors.amber, fontWeight: FontWeight.w800)),
                          Text('Aktual ●: $done', style: const TextStyle(fontSize: 11, color: UbColors.emerald, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                ...List.generate(dim, (i) {
                  final day = i + 1;
                  final wd = BacaDoaEngine.weekdayOf(_ym, day);
                  final isMon = wd == DateTime.monday;
                  final isWk = wd == DateTime.saturday || wd == DateTime.sunday;
                  final rec = _records[day];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    color: isMon
                        ? UbColors.amber.withValues(alpha: 0.08)
                        : isWk
                            ? Colors.white.withValues(alpha: 0.02)
                            : null,
                    child: ListTile(
                      dense: true,
                      onTap: () => _openDayModal(day),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isMon
                            ? UbColors.amber.withValues(alpha: 0.25)
                            : isWk
                                ? UbColors.rose.withValues(alpha: 0.2)
                                : UbColors.emerald.withValues(alpha: 0.18),
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: isMon ? UbColors.amber : (isWk ? UbColors.rose : UbColors.emerald),
                          ),
                        ),
                      ),
                      title: Text(
                        isMon
                            ? 'BRIEFING MASAL (OFF DOA)'
                            : isWk
                                ? 'WEEKEND / LIBUR'
                                : (rec?.memberName ?? 'Belum ditugaskan — tap untuk pilih'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isMon ? UbColors.amber : (isWk ? UbColors.textMuted : Colors.white),
                        ),
                      ),
                      subtitle: Text(
                        '${_dayNames[wd]}${rec != null ? ' · ${rec.pos}${rec.note.isNotEmpty ? ' · ${rec.note}' : ''}' : ''}',
                        style: const TextStyle(fontSize: 11, color: UbColors.textMuted),
                      ),
                      trailing: rec != null
                          ? InkWell(
                              onTap: () => _toggleDoneQuick(day),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (rec.status == 'done' ? UbColors.emerald : UbColors.cyan).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  rec.status == 'done' ? '● OK' : '○ PLAN',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: rec.status == 'done' ? UbColors.emerald : UbColors.cyan,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
