import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';
import '../../models/chokotei_models.dart';
import '../../models/quality_daily_models.dart';
import '../../services/chokotei_store.dart';

class ChokoteiManualScreen extends StatefulWidget {
  const ChokoteiManualScreen({super.key});

  @override
  State<ChokoteiManualScreen> createState() => _ChokoteiManualScreenState();
}

class _ChokoteiManualScreenState extends State<ChokoteiManualScreen> {
  String _ym = QualityMath.wibYm();
  String _statusFilter = 'ALL'; // ALL | open | in_progress | solved
  List<ChokoteiIssue> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ChokoteiStore.instance.fetchManual(_ym);
    if (!mounted) return;
    setState(() {
      _items = res.items;
      _loading = false;
    });
  }

  Future<void> _openForm({ChokoteiIssue? existing}) async {
    var shift = existing?.shift ?? 'RED';
    var status = existing?.actionStatus ?? 'open';
    final tglCtrl = TextEditingController(text: existing?.tanggal ?? UbMasterData.wibToday());
    final machCtrl = TextEditingController(text: existing?.machine ?? '');
    final probCtrl = TextEditingController(text: existing?.problem ?? '');
    final cmCtrl = TextEditingController(text: existing?.countermeasure ?? '');
    final picCtrl = TextEditingController(text: existing?.actionPic ?? '');
    final lossCtrl = TextEditingController(text: '${existing?.lossUnits ?? 0}');
    final delayCtrl = TextEditingController(text: '${existing?.delayMin ?? 0}');

    try {
      final act = await showModalBottomSheet<String>(
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
                  Text(existing != null ? 'Edit Chokotei ${existing.id}' : 'Chokotei Manual Baru', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: tglCtrl, decoration: const InputDecoration(labelText: 'Tanggal', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: shift,
                          decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'RED', child: Text('RED')),
                            DropdownMenuItem(value: 'WHITE', child: Text('WHITE')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => shift = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: machCtrl, decoration: const InputDecoration(labelText: 'Mesin / Line', hintText: 'mis. AUTO SPOT SOB 560', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: probCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Problem (Wajib)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: lossCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Loss (unit)', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: delayCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stop (menit)', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: cmCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Penanggulangan', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: picCtrl, decoration: const InputDecoration(labelText: 'PIC', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'open', child: Text('Belum')),
                            DropdownMenuItem(value: 'in_progress', child: Text('Proses')),
                            DropdownMenuItem(value: 'solved', child: Text('Sudah')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => status = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (existing != null)
                        IconButton(onPressed: () => Navigator.pop(ctx, 'delete'), icon: const Icon(Icons.delete_outline_rounded, color: UbColors.rose)),
                      const Spacer(),
                      OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                        onPressed: () {
                          if (probCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx, 'save');
                        },
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (act == 'delete' && existing != null) {
        await ChokoteiStore.instance.deleteManual(_ym, existing.id);
        await _load();
      } else if (act == 'save') {
        final item = ChokoteiIssue(
          id: existing?.id ?? 'CM-${DateTime.now().millisecondsSinceEpoch}',
          tanggal: tglCtrl.text.trim(),
          shift: shift,
          machine: machCtrl.text.trim().isEmpty ? 'UB ASSY' : machCtrl.text.trim(),
          problem: probCtrl.text.trim(),
          countermeasure: cmCtrl.text.trim(),
          lossUnits: int.tryParse(lossCtrl.text.trim()) ?? 0,
          delayMin: int.tryParse(delayCtrl.text.trim()) ?? 0,
          actionPic: picCtrl.text.trim(),
          actionStatus: status,
          isManual: true,
        );
        await ChokoteiStore.instance.upsertManual(_ym, item);
        await _load();
      }
    } finally {
      tglCtrl.dispose();
      machCtrl.dispose();
      probCtrl.dispose();
      cmCtrl.dispose();
      picCtrl.dispose();
      lossCtrl.dispose();
      delayCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cOpen = _items.where((i) => i.actionStatus == 'open').length;
    final cProg = _items.where((i) => i.actionStatus == 'in_progress').length;
    final cSolved = _items.where((i) => i.actionStatus == 'solved').length;
    final shown = _statusFilter == 'ALL' ? _items : _items.where((i) => i.actionStatus == _statusFilter).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
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
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chokotei Manual', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Problem tanpa line stop · ${QualityMath.formatYmLabel(_ym)}', style: const TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Tambah', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                      children: [
                        // Month Nav + 3 Summary KPIs
                        Row(
                          children: [
                            Expanded(child: _kpiTile('Belum', '$cOpen', UbColors.rose)),
                            const SizedBox(width: 8),
                            Expanded(child: _kpiTile('Proses', '$cProg', UbColors.amber)),
                            const SizedBox(width: 8),
                            Expanded(child: _kpiTile('Sudah', '$cSolved', UbColors.emerald)),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                            DropdownButton<String>(
                              value: _statusFilter,
                              dropdownColor: UbColors.surface,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: 'ALL', child: Text('Semua')),
                                DropdownMenuItem(value: 'open', child: Text('Belum')),
                                DropdownMenuItem(value: 'in_progress', child: Text('Proses')),
                                DropdownMenuItem(value: 'solved', child: Text('Sudah')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _statusFilter = v);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (shown.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                            child: const Center(child: Text('Belum ada chokotei manual di bulan ini.', style: TextStyle(fontSize: 12.5, color: UbColors.textMuted))),
                          )
                        else
                          ...shown.map((it) {
                            final stColor = it.actionStatus == 'solved' ? UbColors.emerald : (it.actionStatus == 'in_progress' ? UbColors.amber : UbColors.rose);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(it.id, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                                      const SizedBox(width: 6),
                                      Text('${it.tanggal} · ${it.shift}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: UbColors.textMuted)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(color: stColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
                                        child: Text(it.actionStatus == 'solved' ? 'Sudah' : (it.actionStatus == 'in_progress' ? 'Proses' : 'Belum'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: stColor)),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _openForm(existing: it),
                                        icon: const Icon(Icons.edit_rounded, size: 17, color: UbColors.cyan),
                                      ),
                                    ],
                                  ),
                                  Text('${it.machine} · ${it.problem}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text('Loss ${it.lossUnits} U · Stop ${it.delayMin}m · PIC: ${it.actionPic.isEmpty ? "-" : it.actionPic}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
                                  if (it.countermeasure.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('CM: ${it.countermeasure}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF6EE7B7))),
                                  ],
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: UbColors.textMuted)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
