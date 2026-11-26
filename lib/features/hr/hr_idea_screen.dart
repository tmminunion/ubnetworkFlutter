import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/hr_morale_models.dart';
import '../../services/hr_morale_store.dart';

class HrIdeaScreen extends StatefulWidget {
  const HrIdeaScreen({super.key});

  @override
  State<HrIdeaScreen> createState() => _HrIdeaScreenState();
}

class _HrIdeaScreenState extends State<HrIdeaScreen> {
  String _ym = hrTodayYmd().substring(0, 7);
  HrIdeaMonth? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await HrMoraleStore.instance.loadHrIdea(_ym);
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

  Future<void> _editTeamMp(String team) async {
    final d = _data;
    if (d == null) return;
    final t = team == 'red' ? d.red : d.white;
    final mpCtrl = TextEditingController(text: '${t.mp ?? 20}');
    final manIdeaCtrl = TextEditingController(text: t.totalIdeaManual == null ? '' : '${t.totalIdeaManual}');
    final manMakerCtrl = TextEditingController(text: t.totalMakerManual == null ? '' : '${t.totalMakerManual}');

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: UbColors.surface,
          title: Text('Atur MP & Manual · UB Assy ${team.toUpperCase()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: mpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah MP', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: manIdeaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Idea Manual (opsional)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: manMakerCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Pembuat Manual (opsional)', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: UbColors.purple, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );
      if (ok == true) {
        final nextTeam = t.copyWith(
          mp: int.tryParse(mpCtrl.text.trim()) ?? t.mp,
          totalIdeaManual: int.tryParse(manIdeaCtrl.text.trim()),
          totalMakerManual: int.tryParse(manMakerCtrl.text.trim()),
        );
        final updated = team == 'red' ? d.copyWith(red: nextTeam) : d.copyWith(white: nextTeam);
        await HrMoraleStore.instance.saveHrIdea(updated);
        if (mounted) setState(() => _data = updated);
      }
    } finally {
      mpCtrl.dispose();
      manIdeaCtrl.dispose();
      manMakerCtrl.dispose();
    }
  }

  Future<void> _editDay(int day) async {
    final d = _data;
    if (d == null) return;
    final riCtrl = TextEditingController(text: d.red.dailyIdea[day - 1]?.toString() ?? '');
    final rmCtrl = TextEditingController(text: d.red.dailyMaker[day - 1]?.toString() ?? '');
    final wiCtrl = TextEditingController(text: d.white.dailyIdea[day - 1]?.toString() ?? '');
    final wmCtrl = TextEditingController(text: d.white.dailyMaker[day - 1]?.toString() ?? '');

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: UbColors.surface,
          title: Text('Idea Harian · Tgl $day', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: riCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Red Idea', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: rmCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Red Pembuat', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: wiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'White Idea', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: wmCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'White Pembuat', border: OutlineInputBorder()))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: UbColors.purple, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );

      if (ok == true) {
        int? pi(TextEditingController c) => c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());
        final rIdea = List<int?>.from(d.red.dailyIdea)..[day - 1] = pi(riCtrl);
        final rMaker = List<int?>.from(d.red.dailyMaker)..[day - 1] = pi(rmCtrl);
        final wIdea = List<int?>.from(d.white.dailyIdea)..[day - 1] = pi(wiCtrl);
        final wMaker = List<int?>.from(d.white.dailyMaker)..[day - 1] = pi(wmCtrl);
        final updated = d.copyWith(
          red: d.red.copyWith(dailyIdea: rIdea, dailyMaker: rMaker),
          white: d.white.copyWith(dailyIdea: wIdea, dailyMaker: wMaker),
        );
        await HrMoraleStore.instance.saveHrIdea(updated);
        if (mounted) setState(() => _data = updated);
      }
    } finally {
      riCtrl.dispose();
      rmCtrl.dispose();
      wiCtrl.dispose();
      wmCtrl.dispose();
    }
  }

  Widget _teamCard(String teamKey, String title, Color dotColor, HrIdeaTeamData t, int dim, HrIdeaMonth d) {
    final m = HrIdeaMath.computeTeamMetrics(t, dim);
    final ipmOk = m.ideaPerMp != null && m.ideaPerMp! >= d.targetIdea;
    final ppOk = m.partPct != null && m.partPct! >= d.targetPart;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _editTeamMp(teamKey),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: Text('MP: ${t.mp ?? '-'}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat('IDEA', '${m.totalIdea ?? '-'}', Colors.white),
              _MiniStat('PEMBUAT', '${m.totalMaker ?? '-'}', Colors.white),
              _MiniStat('IDEA/MP', m.ideaPerMp == null ? '-' : m.ideaPerMp!.toStringAsFixed(2), ipmOk ? UbColors.emerald : UbColors.rose),
              _MiniStat('PART %', m.partPct == null ? '-' : '${m.partPct!.round()}%', ppOk ? UbColors.emerald : UbColors.rose),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final dim = hrDaysInMonth(_ym);

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Idea Record', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('Ratio Idea/MP & Participant % Red & White', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
      ),
      body: _loading || d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
                    Text(_ym, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14)),
                    IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
                    const Spacer(),
                    Text('Target: ${d.targetIdea} Idea/MP · ${d.targetPart.round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: UbColors.amber)),
                  ],
                ),
                const SizedBox(height: 8),
                _teamCard('red', 'UB Assy Red', UbColors.rose, d.red, dim, d),
                _teamCard('white', 'UB Assy White', Colors.white, d.white, dim, d),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('Input Harian (Tanggal 1–31 · Tap baris untuk edit)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: UbColors.textMuted)),
                ),
                ...List.generate(dim, (i) {
                  final day = i + 1;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: ListTile(
                      dense: true,
                      onTap: () => _editDay(day),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: UbColors.purple.withValues(alpha: 0.2),
                        child: Text('$day', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFC084FC))),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'RED: ${d.red.dailyIdea[i] ?? '-'} idea / ${d.red.dailyMaker[i] ?? '-'} org',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: UbColors.rose),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'WHT: ${d.white.dailyIdea[i] ?? '-'} idea / ${d.white.dailyMaker[i] ?? '-'} org',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.edit_rounded, size: 15, color: UbColors.textMuted),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.val, this.color);

  final String label;
  final String val;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: UbColors.textMuted)),
        Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
