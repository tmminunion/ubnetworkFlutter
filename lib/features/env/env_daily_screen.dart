import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/cost_env_models.dart';
import '../../services/cost_env_store.dart';

class EnvDailyScreen extends StatefulWidget {
  const EnvDailyScreen({super.key});

  @override
  State<EnvDailyScreen> createState() => _EnvDailyScreenState();
}

class _EnvDailyScreenState extends State<EnvDailyScreen> {
  String _ym = costEnvTodayYmd().substring(0, 7);
  String _tab = 'all'; // all | red | white
  EnvEnergyMonth? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await CostEnvStore.instance.loadEnvEnergy(_ym);
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

  Future<void> _editTarget() async {
    final d = _data;
    if (d == null) return;
    final ctrl = TextEditingController(text: '${d.target}');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: UbColors.surface,
          title: const Text('Target Harian Energi (kWh)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target kWh / shift', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );
      if (ok == true) {
        final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? d.target;
        final updated = d.copyWith(target: v);
        await CostEnvStore.instance.saveEnvEnergy(updated);
        if (mounted) setState(() => _data = updated);
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _editDay(int day) async {
    final d = _data;
    if (d == null) return;
    final rCtrl = TextEditingController(text: d.red[day - 1] == null ? '' : '${d.red[day - 1]}');
    final wCtrl = TextEditingController(text: d.white[day - 1] == null ? '' : '${d.white[day - 1]}');

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: UbColors.surface,
          title: Text('Input kWh · $_ym-${day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: rCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'kWh Shift RED', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: wCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'kWh Shift WHITE', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );
      if (ok == true) {
        final nr = List<double?>.from(d.red);
        final nw = List<double?>.from(d.white);
        nr[day - 1] = rCtrl.text.trim().isEmpty ? null : double.tryParse(rCtrl.text.trim().replaceAll(',', '.'));
        nw[day - 1] = wCtrl.text.trim().isEmpty ? null : double.tryParse(wCtrl.text.trim().replaceAll(',', '.'));
        final updated = d.copyWith(red: nr, white: nw);
        await CostEnvStore.instance.saveEnvEnergy(updated);
        if (mounted) setState(() => _data = updated);
      }
    } finally {
      rCtrl.dispose();
      wCtrl.dispose();
    }
  }

  Widget _evaBadge(double? val, double target) {
    if (val == null || target <= 0) return const Text('-', style: TextStyle(color: UbColors.textMuted));
    final ok = val <= target;
    final c = ok ? UbColors.emerald : UbColors.rose;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.2), border: Border.all(color: c)),
      child: Text(ok ? 'O' : 'X', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final dim = daysInMonthYm(_ym);
    final sum = d == null ? null : EnvEnergyMath.computeSummary(d);

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Control Energi Harian (kWh)', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('Monitoring Listrik Red & White + Evaluasi EVA', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _editTarget,
            icon: const Icon(Icons.flag_rounded, size: 16, color: UbColors.emerald),
            label: Text(
              d == null ? 'Target' : '${d.target.round()} kWh',
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: UbColors.emerald),
            ),
          ),
        ],
      ),
      body: _loading || d == null || sum == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
              children: [
                // Month + Filter
                Row(
                  children: [
                    IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
                    Text(_ym, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14)),
                    IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
                    const Spacer(),
                    for (final t in [('all', 'Semua'), ('red', 'Red'), ('white', 'White')])
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ChoiceChip(
                          label: Text(t.$2, style: const TextStyle(fontSize: 11)),
                          selected: _tab == t.$1,
                          onSelected: (_) => setState(() => _tab = t.$1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Summary Cards
                Row(
                  children: [
                    _EnergyKpi(label: 'TOTAL PLANT', value: '${sum.totalCombined} kWh', sub: 'Red + White', color: UbColors.cyan),
                    const SizedBox(width: 6),
                    _EnergyKpi(label: 'RED (${sum.rateRed}%)', value: '${sum.totalRed}', sub: 'Avg ${sum.avgRed}/h', color: UbColors.rose),
                    const SizedBox(width: 6),
                    _EnergyKpi(label: 'WHITE (${sum.rateWhite}%)', value: '${sum.totalWhite}', sub: 'Avg ${sum.avgWhite}/h', color: UbColors.emerald),
                  ],
                ),
                const SizedBox(height: 10),

                // Daily Rows 1..dim
                ...List.generate(dim, (i) {
                  final day = i + 1;
                  final r = d.red[i];
                  final w = d.white[i];
                  final tot = (r ?? 0) + (w ?? 0);
                  final hasAny = r != null || w != null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      onTap: () => _editDay(day),
                      leading: CircleAvatar(
                        radius: 15,
                        backgroundColor: UbColors.emerald.withValues(alpha: 0.16),
                        child: Text('$day', style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900, color: UbColors.emerald)),
                      ),
                      title: Row(
                        children: [
                          if (_tab == 'all' || _tab == 'red') ...[
                            Expanded(
                              child: Row(
                                children: [
                                  Text('R: ${r ?? '-'}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w800, color: UbColors.rose)),
                                  const SizedBox(width: 6),
                                  _evaBadge(r, d.target),
                                ],
                              ),
                            ),
                          ],
                          if (_tab == 'all' || _tab == 'white') ...[
                            Expanded(
                              child: Row(
                                children: [
                                  Text('W: ${w ?? '-'}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w800)),
                                  const SizedBox(width: 6),
                                  _evaBadge(w, d.target),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: _tab == 'all'
                          ? Text(
                              hasAny ? '${tot.toStringAsFixed(1)} kWh' : '-',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w900, color: UbColors.cyan),
                            )
                          : const Icon(Icons.edit_rounded, size: 16, color: UbColors.textMuted),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _EnergyKpi extends StatelessWidget {
  const _EnergyKpi({required this.label, required this.value, required this.sub, required this.color});

  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: UbColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: UbColors.textMuted)),
            const SizedBox(height: 2),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: color)),
            Text(sub, style: const TextStyle(fontSize: 9.5, color: UbColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
