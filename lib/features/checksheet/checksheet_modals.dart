import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';

/// Seluruh Modal Interaktif Checksheet A3 (Slot/Chokotei, CBU, CKD, No Body, Overtime, Absensi, Header).
class ChecksheetModals {
  ChecksheetModals._();

  static Future<({HourlySlot slot, bool autoFillPrev, bool syncNow})?> showSlotModal(
    BuildContext context, {
    required HourlySlot initialSlot,
    required double taktTime,
    required int unfilledPrevCount,
  }) async {
    final slot = initialSlot.copy();
    var autoFillPrev = true;
    final planCtrl = TextEditingController(text: '${slot.plan}');
    final actCtrl = TextEditingController(text: slot.act == null ? '' : '${slot.act}');

    try {
      return await showModalBottomSheet<({HourlySlot slot, bool autoFillPrev, bool syncNow})>(
        context: context,
        isScrollControlled: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setM) {
            final actVal = int.tryParse(actCtrl.text.trim());
            final diff = actVal != null ? (actVal - slot.plan) : 0;
            final minus = (actVal != null && diff < 0) ? diff.abs() : 0;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SLOT #${slot.no} • ${slot.timeRange}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: UbColors.cyan),
                            ),
                            const Text('Input Aktual Output & Chokotei', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                    const Divider(color: UbColors.card),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          slot.isBlocked ? '⏹️ Slot Non-Aktif' : '🟢 Slot Aktif',
                          style: TextStyle(fontWeight: FontWeight.w800, color: slot.isBlocked ? UbColors.textMuted : UbColors.emerald),
                        ),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Aktif')),
                            ButtonSegment(value: true, label: Text('Off')),
                          ],
                          selected: {slot.isBlocked},
                          onSelectionChanged: (s) {
                            setM(() {
                              slot.isBlocked = s.first;
                              if (slot.isBlocked) {
                                slot.plan = 0;
                                slot.act = null;
                                slot.problems.clear();
                                planCtrl.text = '0';
                                actCtrl.text = '';
                              } else if (slot.plan <= 0) {
                                slot.plan = (60 / taktTime).round();
                                planCtrl.text = '${slot.plan}';
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!slot.isBlocked) ...[
                      Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: planCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(labelText: 'Plan', border: OutlineInputBorder(), isDense: true),
                              onChanged: (v) => setM(() => slot.plan = int.tryParse(v) ?? 0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: actCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w900),
                              decoration: const InputDecoration(labelText: 'Aktual Output (Unit)', border: OutlineInputBorder(), isDense: true),
                              onChanged: (v) => setM(() => slot.act = v.trim().isEmpty ? null : int.tryParse(v.trim())),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () {
                              setM(() {
                                slot.act = slot.plan;
                                actCtrl.text = '${slot.plan}';
                              });
                            },
                            child: const Text('⭐ OK'),
                          ),
                        ],
                      ),
                      if (unfilledPrevCount > 0) ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          value: autoFillPrev,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('Auto-isi $unfilledPrevCount slot sebelumnya sesuai Plan (⭐)', style: const TextStyle(fontSize: 12)),
                          onChanged: (v) => setM(() => autoFillPrev = v ?? true),
                        ),
                      ],
                      if (minus > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: UbColors.amber.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: UbColors.amber.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '⚠️ Defisit $minus Unit (${(minus * taktTime).toStringAsFixed(1)}m delay)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: UbColors.amber),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rincian Chokotei (${slot.problems.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                          TextButton.icon(
                            onPressed: () {
                              setM(() {
                                final lu = minus > 0 ? minus : 1;
                                slot.problems.add(ChokoteiProblem(
                                  id: 'p-${DateTime.now().millisecondsSinceEpoch}',
                                  lossUnits: lu,
                                  delayMin: double.parse((lu * taktTime).toStringAsFixed(1)),
                                  category: 'EXT',
                                ));
                              });
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Tambah Kendala'),
                          ),
                        ],
                      ),
                      for (var i = 0; i < slot.problems.length; i++)
                        _ProblemEditorCard(
                          key: ValueKey(slot.problems[i].id),
                          index: i,
                          problem: slot.problems[i],
                          taktTime: taktTime,
                          onDelete: () => setM(() => slot.problems.removeAt(i)),
                          onChanged: () => setM(() {}),
                        ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, (slot: slot, autoFillPrev: autoFillPrev, syncNow: false)),
                            child: const Text('Simpan Lokal'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                            onPressed: () => Navigator.pop(ctx, (slot: slot, autoFillPrev: autoFillPrev, syncNow: true)),
                            child: const Text('Simpan & Sync', style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      planCtrl.dispose();
      actCtrl.dispose();
    }
  }

  static Future<({List<CbuModelItem> models, String source})?> showCbuModal(
    BuildContext context, {
    required List<CbuModelItem> initialModels,
    required String initialSource,
    required int totalAct,
    required int totalPlan,
  }) async {
    var models = initialModels.map((m) => m.copy()).toList();
    var source = initialSource;
    return showModalBottomSheet<({List<CbuModelItem> models, String source})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          final tot = models.fold<int>(0, (a, m) => a + m.qty);
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('🚗 Update Capaian Model CBU', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => setM(() {
                            source = 'ratio';
                            models = UbMasterData.calculateCbuByRatio(totalAct, models);
                          }),
                          child: Text('✨ Dari Aktual (${totalAct}u)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setM(() {
                            source = 'ratio';
                            models = UbMasterData.calculateCbuByRatio(totalPlan > 0 ? totalPlan : 212, models);
                          }),
                          child: Text('Dari Plan (${totalPlan}u)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...models.map((m) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        subtitle: Text('Rasio ${m.ratio}x', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => setM(() {
                                if (m.qty > 0) m.qty--;
                                source = 'manual';
                              }),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            SizedBox(
                              width: 44,
                              child: Text('${m.qty}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                            ),
                            IconButton(
                              onPressed: () => setM(() {
                                m.qty++;
                                source = 'manual';
                              }),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      )),
                  const Divider(color: UbColors.card),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL PRODUKSI CBU', style: TextStyle(fontWeight: FontWeight.w800)),
                      Text('$tot Unit', style: const TextStyle(fontFamily: 'monospace', fontSize: 17, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                    onPressed: () => Navigator.pop(ctx, (models: models, source: source)),
                    child: const Text('Simpan Capaian CBU', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<List<CkdPartItem>?> showCkdModal(
    BuildContext context, {
    required List<CkdPartItem> initialParts,
  }) async {
    final parts = initialParts.map((p) => p.copy()).toList();
    final ctrls = parts.map((p) => TextEditingController(text: '${p.qty}')).toList();
    try {
      return await showModalBottomSheet<List<CkdPartItem>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('📦 Update Part CKD Export', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                for (var i = 0; i < parts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(parts[i].partNo, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, color: UbColors.cyan, fontSize: 12.5)),
                              Text(parts[i].partName, style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 82,
                          child: TextField(
                            controller: ctrls[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, suffixText: 'u'),
                            onChanged: (v) => parts[i].qty = int.tryParse(v) ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                  onPressed: () => Navigator.pop(ctx, parts),
                  child: const Text('Simpan Data Part CKD', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      for (final c in ctrls) {
        c.dispose();
      }
    }
  }

  static Future<({String start, String finish, String jamStop})?> showNoBodyModal(
    BuildContext context, {
    required String start,
    required String finish,
    required String jamStop,
    required String sysTime,
    required int effectiveCcr,
    required int totalAct,
    ({String finish, String label})? prevCarry,
  }) async {
    final sCtrl = TextEditingController(text: start);
    final fCtrl = TextEditingController(text: finish);
    final jCtrl = TextEditingController(text: jamStop);
    var finManual = finish.isNotEmpty;

    try {
      return await showModalBottomSheet<({String start, String finish, String jamStop})>(
        context: context,
        isScrollControlled: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setM) {
            final sn = int.tryParse(sCtrl.text.replaceAll(RegExp(r'\D'), ''));
            final fn = int.tryParse(fCtrl.text.replaceAll(RegExp(r'\D'), ''));
            final run = (sn != null && fn != null && fn >= sn) ? (fn - sn + 1) : totalAct;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('📋 Update No Body & Jam Stop', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: UbColors.purple),
                          onPressed: () => Navigator.pop(ctx, (start: sCtrl.text.trim(), finish: fCtrl.text.trim(), jamStop: jCtrl.text.trim())),
                          child: const Text('Simpan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sCtrl,
                            decoration: const InputDecoration(labelText: 'No Body Start', prefixText: '#', border: OutlineInputBorder(), isDense: true),
                            onChanged: (v) {
                              if (!finManual && effectiveCcr > 0) {
                                final af = UbMasterData.addNumberPreservePad(v, effectiveCcr - 1);
                                if (af.isNotEmpty) fCtrl.text = af;
                              }
                              setM(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: fCtrl,
                            decoration: const InputDecoration(labelText: 'No Body Finish', prefixText: '#', border: OutlineInputBorder(), isDense: true),
                            onChanged: (_) => setM(() => finManual = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (prevCarry != null)
                          ActionChip(
                            label: Text('Shift sblm #${prevCarry.finish} → +1', style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              final ns = UbMasterData.addNumberPreservePad(prevCarry.finish, 1);
                              sCtrl.text = ns;
                              if (effectiveCcr > 0) {
                                fCtrl.text = UbMasterData.addNumberPreservePad(ns, effectiveCcr - 1);
                                finManual = false;
                              }
                              setM(() {});
                            },
                          ),
                        if (effectiveCcr > 0)
                          ActionChip(
                            label: Text('Auto Finish (CCR $effectiveCcr)', style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              finManual = false;
                              final af = UbMasterData.addNumberPreservePad(sCtrl.text, effectiveCcr - 1);
                              if (af.isNotEmpty) fCtrl.text = af;
                              setM(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Total Body Run: $run Unit · Actual: $totalAct Unit', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: UbColors.cyan)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: UbColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: UbColors.cyan.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('🕒 Waktu Sistem: $sysTime WIB', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, color: UbColors.cyan)),
                          TextButton(
                            onPressed: () {
                              if (sysTime != '-') jCtrl.text = sysTime;
                            },
                            child: const Text('Salin ↓'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: jCtrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w900, color: UbColors.rose),
                      decoration: const InputDecoration(
                        labelText: 'Jam Stop Manual',
                        hintText: '18:15',
                        suffixText: 'WIB',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      sCtrl.dispose();
      fCtrl.dispose();
      jCtrl.dispose();
    }
  }

  static Future<({int ccrPlan, double otHours})?> showOvertimeModal(
    BuildContext context, {
    required int ccrPlan,
    required double otHours,
  }) async {
    final ccrCtrl = TextEditingController(text: '$ccrPlan');
    final otCtrl = TextEditingController(text: '$otHours');
    try {
      return await showModalBottomSheet<({int ccrPlan, double otHours})>(
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
                const Text('⏱️ Target CCR & Overtime (OT)', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                  controller: ccrCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target CCR Plan (Unit)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: otCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Jam Overtime (OT)', suffixText: 'Jam', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0].map((h) {
                    return ChoiceChip(
                      label: Text('${h}h'),
                      selected: (double.tryParse(otCtrl.text) ?? -1) == h,
                      onSelected: (_) => setM(() => otCtrl.text = '$h'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: UbColors.amber, foregroundColor: UbColors.bg),
                  onPressed: () => Navigator.pop(ctx, (
                    ccrPlan: int.tryParse(ccrCtrl.text) ?? ccrPlan,
                    otHours: double.tryParse(otCtrl.text) ?? 0,
                  )),
                  child: const Text('Simpan Overtime', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      ccrCtrl.dispose();
      otCtrl.dispose();
    }
  }

  static Future<List<MemberAbsen>?> showAbsenModal(
    BuildContext context, {
    required String shift,
    required List<MemberAbsen> initialMembers,
  }) async {
    final mems = initialMembers.map((m) => m.copy()).toList();
    return showModalBottomSheet<List<MemberAbsen>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          final hadir = mems.where((m) => m.status == 'Hadir').length;
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.82,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('👥 Absensi Regu $shift ($hadir/${mems.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      TextButton(
                        onPressed: () => setM(() {
                          for (final m in mems) {
                            m.status = 'Hadir';
                          }
                        }),
                        child: const Text('Semua Hadir'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: mems.length,
                      itemBuilder: (_, idx) {
                        final m = mems[idx];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          subtitle: Text('${m.noreg} • ${m.note}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                          trailing: DropdownButton<String>(
                            value: m.status,
                            underline: const SizedBox.shrink(),
                            items: const ['Hadir', 'Sakit', 'Izin', 'Cuti', 'Dinas', 'Alpa']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setM(() => m.status = v);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg),
                      onPressed: () => Navigator.pop(ctx, mems),
                      child: const Text('Simpan Data Absensi', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<Map<String, dynamic>?> showHeaderModal(
    BuildContext context, {
    required ChecksheetReport report,
  }) async {
    var shift = report.shift;
    var session = report.session;
    var workMode = report.workMode;
    var templateCode = report.templateCode;
    var otHours = report.overtimeHours;
    var otAwal = report.otAwal;
    final lineCtrl = TextEditingController(text: report.lineName);
    final taktCtrl = TextEditingController(text: '${report.taktTime}');
    final picCtrl = TextEditingController(text: report.picName);
    final spvCtrl = TextEditingController(text: report.spvName);

    try {
      return await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setM) {
            final tpls = UbMasterData.masterTemplates.where((t) => t.category == workMode).toList();
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('⚙️ Pengaturan Shift & Jadwal Kerja', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'RED', label: Text('🔴 RED')),
                              ButtonSegment(value: 'WHITE', label: Text('⚪ WHITE')),
                            ],
                            selected: {shift},
                            onSelectionChanged: (s) => setM(() => shift = s.first),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'day', label: Text('☀️ DAY')),
                              ButtonSegment(value: 'night', label: Text('🌙 NIGHT')),
                            ],
                            selected: {session},
                            onSelectionChanged: (s) => setM(() {
                              session = s.first;
                              templateCode = session == 'night'
                                  ? (workMode == 'puasa' ? 'malam_puasa' : 'malam_normal')
                                  : (workMode == 'puasa' ? 'pagi_puasa' : 'pagi_normal');
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'normal', label: Text('☀️ Normal')),
                        ButtonSegment(value: 'puasa', label: Text('🌙 Bulan Puasa')),
                      ],
                      selected: {workMode},
                      onSelectionChanged: (s) => setM(() {
                        workMode = s.first;
                        templateCode = session == 'night'
                            ? (workMode == 'puasa' ? 'malam_puasa' : 'malam_normal')
                            : (workMode == 'puasa' ? 'pagi_puasa' : 'pagi_normal');
                      }),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tpls.map((t) => ChoiceChip(
                            label: Text(t.name, style: const TextStyle(fontSize: 11.5)),
                            selected: templateCode == t.code,
                            onSelected: (_) => setM(() {
                              templateCode = t.code;
                              session = t.timeSession;
                            }),
                          )).toList(),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [0, 1, 2, 3].map((ot) => ChoiceChip(
                            label: Text(ot == 0 ? 'Tanpa OT' : 'OT ${ot}j'),
                            selected: otHours == ot,
                            onSelected: (_) => setM(() => otHours = ot),
                          )).toList(),
                    ),
                    if (session == 'night') ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [('none', 'Normal 21:00'), ('30m', 'OT Awal 30m'), ('1h', 'OT Awal 1j')].map((p) => ChoiceChip(
                              label: Text(p.$2, style: const TextStyle(fontSize: 11)),
                              selected: otAwal == p.$1,
                              onSelected: (_) => setM(() => otAwal = p.$1),
                            )).toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: lineCtrl, decoration: const InputDecoration(labelText: 'Line', border: OutlineInputBorder(), isDense: true))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: taktCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Takt Time (m)', border: OutlineInputBorder(), isDense: true))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: picCtrl, decoration: const InputDecoration(labelText: 'PIC (GL)', border: OutlineInputBorder(), isDense: true))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: spvCtrl, decoration: const InputDecoration(labelText: 'TL / SPV', border: OutlineInputBorder(), isDense: true))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                      onPressed: () => Navigator.pop(ctx, {
                        'shift': shift,
                        'session': session,
                        'workMode': workMode,
                        'templateCode': templateCode,
                        'overtimeHours': otHours,
                        'otAwal': otAwal,
                        'lineName': lineCtrl.text.trim(),
                        'taktTime': double.tryParse(taktCtrl.text.trim()) ?? report.taktTime,
                        'picName': picCtrl.text.trim(),
                        'spvName': spvCtrl.text.trim(),
                      }),
                      child: const Text('Terapkan Perubahan', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      lineCtrl.dispose();
      taktCtrl.dispose();
      picCtrl.dispose();
      spvCtrl.dispose();
    }
  }
}

class _ProblemEditorCard extends StatefulWidget {
  const _ProblemEditorCard({
    super.key,
    required this.index,
    required this.problem,
    required this.taktTime,
    required this.onDelete,
    required this.onChanged,
  });

  final int index;
  final ChokoteiProblem problem;
  final double taktTime;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  @override
  State<_ProblemEditorCard> createState() => _ProblemEditorCardState();
}

class _ProblemEditorCardState extends State<_ProblemEditorCard> {
  late final TextEditingController _stCtrl;
  late final TextEditingController _luCtrl;
  late final TextEditingController _dmCtrl;
  late final TextEditingController _prCtrl;
  late final TextEditingController _cmCtrl;

  @override
  void initState() {
    super.initState();
    _stCtrl = TextEditingController(text: widget.problem.lineStation);
    _luCtrl = TextEditingController(text: '${widget.problem.lossUnits}');
    _dmCtrl = TextEditingController(text: '${widget.problem.delayMin}');
    _prCtrl = TextEditingController(text: widget.problem.problem);
    _cmCtrl = TextEditingController(text: widget.problem.countermeasure);
  }

  @override
  void dispose() {
    _stCtrl.dispose();
    _luCtrl.dispose();
    _dmCtrl.dispose();
    _prCtrl.dispose();
    _cmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.problem;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: UbColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UbColors.card),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('#${widget.index + 1}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('INT', style: TextStyle(fontSize: 10.5)),
                selected: p.category == 'INT',
                onSelected: (_) {
                  p.category = 'INT';
                  widget.onChanged();
                },
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('EXT', style: TextStyle(fontSize: 10.5)),
                selected: p.category == 'EXT',
                onSelected: (_) {
                  p.category = 'EXT';
                  widget.onChanged();
                },
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: UbColors.rose, size: 18),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _stCtrl,
                  decoration: const InputDecoration(labelText: 'Line/ST', border: OutlineInputBorder(), isDense: true),
                  onChanged: (v) => p.lineStation = v,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _luCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Loss U', border: OutlineInputBorder(), isDense: true),
                  onChanged: (v) {
                    final u = int.tryParse(v) ?? 0;
                    p.lossUnits = u;
                    p.delayMin = double.parse((u * widget.taktTime).toStringAsFixed(1));
                    _dmCtrl.text = '${p.delayMin}';
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _dmCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Delay m', border: OutlineInputBorder(), isDense: true),
                  onChanged: (v) => p.delayMin = double.tryParse(v) ?? 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _prCtrl,
            decoration: const InputDecoration(labelText: 'Uraian Problem', border: OutlineInputBorder(), isDense: true),
            onChanged: (v) => p.problem = v,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _cmCtrl,
            decoration: const InputDecoration(labelText: 'Countermeasure', border: OutlineInputBorder(), isDense: true),
            onChanged: (v) => p.countermeasure = v,
          ),
        ],
      ),
    );
  }
}
