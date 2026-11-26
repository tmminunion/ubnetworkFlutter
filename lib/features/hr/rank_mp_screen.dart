import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/hr_morale_models.dart';
import '../../services/hr_morale_store.dart';

class RankMpScreen extends StatefulWidget {
  const RankMpScreen({super.key});

  @override
  State<RankMpScreen> createState() => _RankMpScreenState();
}

class _RankMpScreenState extends State<RankMpScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final String _ym = hrTodayYmd().substring(0, 7);
  String _shift = 'RED';
  String _search = '';
  String _tierFilter = 'ALL';
  List<MemberRankRow> _rows = const [];
  Map<int, RankMpCustomEval> _evals = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ops = HrMoraleStore.instance.operatorsForShift(_shift);
    final baca = await HrMoraleStore.instance.loadBacaDoa(_ym, _shift);
    final evals = await HrMoraleStore.instance.loadRankEvals(_ym, _shift);
    final ranked = RankMpEngine.computeRankings(
      shift: _shift,
      operators: ops,
      bacaDoaRecords: baca,
      customEvals: evals,
    );
    if (!mounted) return;
    setState(() {
      _evals = evals;
      _rows = ranked;
      _loading = false;
    });
  }

  Future<void> _editHrEval(MemberRankRow row) async {
    final ptsCtrl = TextEditingController(text: '${row.customHrPoints}');
    final noteCtrl = TextEditingController(text: row.hrNotes);

    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Evaluasi HR · ${row.name}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(controller: ptsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Poin Penyesuaian HR (+/-)', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: noteCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Catatan Apresiasi / Evaluasi', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Simpan Penilaian', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      );
      if (ok == true) {
        final next = Map<int, RankMpCustomEval>.from(_evals);
        next[row.memberId] = RankMpCustomEval(
          customPoints: int.tryParse(ptsCtrl.text.trim()) ?? 0,
          notes: noteCtrl.text.trim(),
        );
        await HrMoraleStore.instance.saveRankEvals(_ym, _shift, next);
        await _load();
      }
    } finally {
      ptsCtrl.dispose();
      noteCtrl.dispose();
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'S':
        return UbColors.amber;
      case 'A':
        return UbColors.cyan;
      case 'B':
        return UbColors.emerald;
      default:
        return UbColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _rows.where((r) {
      if (_tierFilter != 'ALL' && r.tier != _tierFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return r.name.toLowerCase().contains(q) || r.noreg.toLowerCase().contains(q) || r.pos.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rank MP (Poin & Podium)', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('$_ym · Shift $_shift · Terhubung Matrik Doa', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
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
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: UbColors.cyan,
          labelColor: UbColors.cyan,
          unselectedLabelColor: UbColors.textMuted,
          tabs: const [
            Tab(text: 'List Rank MP'),
            Tab(text: 'Podium & MVP'),
            Tab(text: 'Kriteria Poin'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // TAB 1: LIST
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      children: [
                        for (final t in ['ALL', 'S', 'A', 'B', 'C'])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(t == 'ALL' ? 'Semua' : 'Tier $t', style: const TextStyle(fontSize: 11)),
                              selected: _tierFilter == t,
                              onSelected: (_) => setState(() => _tierFilter = t),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => setState(() => _search = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, noreg, pos...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 17),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...filtered.map((r) {
                      final tc = _tierColor(r.tier);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 7),
                        child: ListTile(
                          onTap: () => _editHrEval(r),
                          leading: CircleAvatar(
                            backgroundColor: tc.withValues(alpha: 0.2),
                            child: Text('#${r.rank}', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 12, color: tc)),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: tc.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                                child: Text('Tier ${r.tier}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: tc)),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Doa ● ${r.doaDone}x (+${r.doaPoints}) · Disiplin +${r.disciplinePoints}${r.isMultiDuty ? ' · Multi-Duty +15' : ''}${r.customHrPoints != 0 ? ' · HR ${r.customHrPoints > 0 ? '+' : ''}${r.customHrPoints}' : ''}',
                            style: const TextStyle(fontSize: 11, color: UbColors.textMuted),
                          ),
                          trailing: Text('${r.totalPoints} pt', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14, color: UbColors.cyan)),
                        ),
                      );
                    }),
                  ],
                ),

                // TAB 2: PODIUM & MVP
                ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    const Text('TOP MANPOWER OF THE MONTH', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: UbColors.amber)),
                    const SizedBox(height: 12),
                    if (_rows.isNotEmpty)
                      ..._rows.take(3).toList().asMap().entries.map((e) {
                        final medals = ['👑 Juara 1 (MVP)', '🥈 Juara 2', '🥉 Juara 3'];
                        final colors = [UbColors.amber, UbColors.cyan, UbColors.emerald];
                        final r = e.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: UbColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors[e.key].withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(medals[e.key], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colors[e.key])),
                                    const SizedBox(height: 2),
                                    Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                    Text('${r.pos} · Doa Aktual ${r.doaDone}x', style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${r.totalPoints} Pts', style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, color: colors[e.key])),
                                  Text('Tier ${r.tier}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),

                // TAB 3: KRITERIA POIN
                ListView(
                  padding: const EdgeInsets.all(14),
                  children: const [
                    _CriteriaCard(title: 'Aktual Pimpin Doa & Senam (●)', pts: '+15 Pt / kali', desc: 'Operator TM yang menjalankan tugas pimpin doa briefing pagi sesuai verifikasi TL.'),
                    _CriteriaCard(title: 'Terjadwal Doa (○)', pts: '+5 Pt / kali', desc: 'Poin komitmen dasar saat terdaftar di Matrik Baca Doa bulan berjalan.'),
                    _CriteriaCard(title: 'Bonus Multi-Duty (≥ 2x)', pts: '+15 Pt', desc: 'Apresiasi tambahan bagi operator yang memimpin doa minimal 2 kali dalam sebulan.'),
                    _CriteriaCard(title: 'Disiplin Kehadiran Dasar', pts: '+10 Pt', desc: 'Poin dasar kepatuhan kehadiran & standar kerja shopfloor.'),
                    _CriteriaCard(title: 'Penyesuaian Khusus HR / GL', pts: '+/- Custom', desc: 'Poin bonus inisiatif Kaizen, bantu rekan, atau catatan evaluasi langsung GL/TL.'),
                    _CriteriaCard(title: 'Ambang Batas Tier', pts: 'S ≥ 50 · A ≥ 35 · B ≥ 20', desc: 'Tier otomatis dihitung dari total akumulasi poin bulanan.'),
                  ],
                ),
              ],
            ),
    );
  }
}

class _CriteriaCard extends StatelessWidget {
  const _CriteriaCard({required this.title, required this.pts, required this.desc});

  final String title;
  final String pts;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
            Text(pts, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 11.5, color: UbColors.cyan)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(desc, style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
        ),
      ),
    );
  }
}
