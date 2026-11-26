import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';
import '../../models/productivity_ops_models.dart';
import '../../services/productivity_ops_store.dart';

class AfterProdScreen extends StatefulWidget {
  const AfterProdScreen({super.key});

  @override
  State<AfterProdScreen> createState() => _AfterProdScreenState();
}

class _AfterProdScreenState extends State<AfterProdScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _shift = 'RED';
  String _jamPulang = '18.15';
  bool _loading = true;
  bool _fromServer = false;

  List<AfterProdMember> _members = const [];
  List<AfterProdJob> _jobs = const [];
  List<AfterProdAssignment> _assignments = const [];
  List<AfterProdHistoryRecord> _history = const [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final memRes = await ProductivityOpsStore.instance.fetchAfterMembers(_shift);
    final jobRes = await ProductivityOpsStore.instance.fetchAfterJobs(_shift);
    final hist = await ProductivityOpsStore.instance.loadAfterHistory(_shift);
    if (!mounted) return;
    setState(() {
      _members = memRes.members;
      _jobs = jobRes.jobs;
      _history = hist;
      _fromServer = memRes.fromServer || jobRes.fromServer;
      _assignments = hist.isNotEmpty && hist.first.date == UbMasterData.todayYmd()
          ? hist.first.assignments
          : const [];
      _loading = false;
    });
  }

  void _generate() {
    final res = AfterProdEngine.generateAssignments(
      members: _members,
      jobs: _jobs,
      shift: _shift,
    );
    setState(() => _assignments = res);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Penugasan 5S After Produksi berhasil di-generate!')),
    );
  }

  Future<void> _saveCurrentAssignments() async {
    if (_assignments.isEmpty) return;
    final rec = AfterProdHistoryRecord(
      date: UbMasterData.todayYmd(),
      shift: _shift,
      jamPulang: _jamPulang,
      presentCount: _presentCount,
      requiredCount: _requiredCount,
      assignments: _assignments,
    );
    final res = await ProductivityOpsStore.instance.saveAfterHistory(rec);
    final hist = await ProductivityOpsStore.instance.loadAfterHistory(_shift);
    if (!mounted) return;
    setState(() => _history = hist);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
  }

  void _copyWhatsapp() {
    if (_assignments.isEmpty) return;
    final text = AfterProdEngine.buildWhatsappText(
      date: UbMasterData.todayYmd(),
      shift: _shift,
      jamPulang: _jamPulang,
      assignments: _assignments,
    );
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Format WA distribusi 5S disalin ke clipboard!')),
    );
  }

  void _openMoveMemberSheet(int fromIndex, String memberName) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pindahkan $memberName ke Area Lain', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _assignments.length,
                itemBuilder: (_, idx) {
                  if (idx == fromIndex) return const SizedBox.shrink();
                  final target = _assignments[idx];
                  return ListTile(
                    dense: true,
                    leading: Text(target.emoji, style: const TextStyle(fontSize: 18)),
                    title: Text(target.jobName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('${target.members.length} petugas', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                    trailing: const Icon(Icons.swap_horiz_rounded, color: UbColors.cyan),
                    onTap: () {
                      final updated = List<AfterProdAssignment>.from(_assignments);
                      final srcList = List<String>.from(updated[fromIndex].members)..remove(memberName);
                      final dstList = List<String>.from(updated[idx].members)..add(memberName);
                      updated[fromIndex] = updated[fromIndex].copyWith(
                        members: srcList,
                        status: srcList.isEmpty && updated[fromIndex].jobId != -1 ? 'Off (Kekurangan MP)' : updated[fromIndex].status,
                      );
                      updated[idx] = updated[idx].copyWith(
                        members: dstList,
                        status: updated[idx].jobId == -1 ? 'Sisa MP' : 'Terisi',
                      );
                      setState(() => _assignments = updated);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openJobForm([AfterProdJob? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emojiCtrl = TextEditingController(text: existing?.emoji ?? '🧹');
    final lineCtrl = TextEditingController(text: existing?.preferredLine ?? '');
    var req = existing?.requiredPeople ?? 1;
    var scope = existing?.scope ?? 'COMMON';
    final allowed = Set<String>.from(existing?.allowedStatuses ?? const ['Tetap', 'Kontrak', 'Vokasi']);
    var active = existing?.isActive ?? true;

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
                  Text(
                    existing == null ? 'Tambah Pekerjaan 5S' : 'Edit Pekerjaan 5S',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 68,
                        child: TextField(
                          controller: emojiCtrl,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(labelText: 'Ikon', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Pekerjaan 5S', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: scope,
                          decoration: const InputDecoration(labelText: 'Scope Shift', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'COMMON', child: Text('COMMON (Semua)')),
                            DropdownMenuItem(value: 'RED', child: Text('RED')),
                            DropdownMenuItem(value: 'WHITE', child: Text('WHITE')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => scope = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: req,
                          decoration: const InputDecoration(labelText: 'Butuh MP', border: OutlineInputBorder(), isDense: true),
                          items: [1, 2, 3, 4, 5].map((n) => DropdownMenuItem(value: n, child: Text('$n Orang'))).toList(),
                          onChanged: (v) {
                            if (v != null) setM(() => req = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: lineCtrl,
                    decoration: const InputDecoration(labelText: 'Prioritas Pos / Line (opsional)', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  const Text('Status Karyawan Diizinkan', style: TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Tetap', 'Kontrak', 'Vokasi'].map((st) {
                      final sel = allowed.contains(st);
                      return FilterChip(
                        label: Text(st),
                        selected: sel,
                        onSelected: (v) => setM(() {
                          if (v) {
                            allowed.add(st);
                          } else if (allowed.length > 1) {
                            allowed.remove(st);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    title: const Text('Aktif saat Generate', style: TextStyle(fontSize: 13)),
                    onChanged: (v) => setM(() => active = v),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Simpan Pekerjaan', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (saved == true) {
        final job = AfterProdJob(
          id: existing?.id ?? 0,
          name: nameCtrl.text.trim(),
          emoji: emojiCtrl.text.trim().isEmpty ? '🧹' : emojiCtrl.text.trim(),
          scope: scope,
          requiredPeople: req,
          allowedStatuses: allowed.toList(),
          preferredLine: lineCtrl.text.trim(),
          isActive: active,
        );
        final res = await ProductivityOpsStore.instance.saveAfterJob(_shift, job);
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
        }
      }
    } finally {
      nameCtrl.dispose();
      emojiCtrl.dispose();
      lineCtrl.dispose();
    }
  }

  int get _presentCount => _members.where((m) => m.isEligibleFor5S && m.present).length;

  int get _requiredCount => _jobs
      .where((j) => j.isActive && (j.scope == 'COMMON' || j.scope == _shift))
      .fold<int>(0, (acc, j) => acc + j.requiredPeople);

  Color _statusDotColor(String st) {
    final s = st.toLowerCase();
    if (s.contains('vokasi')) return UbColors.rose;
    if (s.contains('kontrak')) return UbColors.emerald;
    return UbColors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final diff = _presentCount - _requiredCount;
    final balLabel = diff == 0 ? 'PAS' : (diff > 0 ? 'SURPLUS +$diff' : 'KURANG $diff');
    final balColor = diff >= 0 ? UbColors.emerald : UbColors.rose;

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UBAI After-Prod 5S', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text(
              _fromServer ? 'Live Sync MySQL · Shift $_shift' : 'Offline-First Lokal · Shift $_shift',
              style: const TextStyle(fontSize: 11, color: UbColors.textMuted),
            ),
          ],
        ),
        actions: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'RED', label: Text('RED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
              ButtonSegment(value: 'WHITE', label: Text('WHITE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
            ],
            selected: {_shift},
            onSelectionChanged: (s) {
              setState(() => _shift = s.first);
              _load();
            },
          ),
          const SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: UbColors.emerald,
          labelColor: UbColors.emerald,
          unselectedLabelColor: UbColors.textMuted,
          tabs: const [
            Tab(text: 'Generate'),
            Tab(text: 'List Anggota'),
            Tab(text: 'List Pekerjaan'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 4 TOP KPI STAT CARDS
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: Row(
                    children: [
                      _MiniKpi(label: 'HADIR ($_shift)', value: '$_presentCount', color: UbColors.cyan),
                      const SizedBox(width: 8),
                      _MiniKpi(label: 'BUTUH', value: '$_requiredCount', color: UbColors.amber),
                      const SizedBox(width: 8),
                      _MiniKpi(label: 'BAL', value: balLabel, color: balColor),
                      const SizedBox(width: 8),
                      _MiniKpi(
                        label: 'DISTRIBUSI',
                        value: _assignments.isEmpty ? '-' : '${_assignments.length} Pos',
                        color: UbColors.purple,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildGenerateTab(),
                      _buildMembersTab(),
                      _buildJobsTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGenerateTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: UbColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Target Pulang:', style: TextStyle(fontSize: 12, color: UbColors.textMuted)),
                  const SizedBox(width: 8),
                  for (final jp in ['16.00', '17.15', '18.15', '19.15'])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('$jp WIB', style: const TextStyle(fontSize: 11)),
                        selected: _jamPulang == jp,
                        onSelected: (_) => setState(() => _jamPulang = jp),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: UbColors.emerald,
                  foregroundColor: UbColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _generate,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('GENERATE TUGAS AFTER PRODUKSI', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              if (_assignments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyWhatsapp,
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Salin Format WA', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _saveCurrentAssignments,
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Simpan History', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_assignments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Tekan tombol GENERATE untuk membagi tugas 5S akhir shift secara otomatis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: UbColors.textMuted, fontSize: 12.5),
              ),
            ),
          )
        else
          ..._assignments.asMap().entries.map((entry) {
            final idx = entry.key;
            final a = entry.value;
            final isOff = a.status == 'Off (Kekurangan MP)';
            final isStandby = a.status == 'Sisa MP';
            final badgeColor = isOff ? UbColors.rose : (isStandby ? UbColors.amber : UbColors.emerald);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: UbColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(a.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(a.jobName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          a.status,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  if (a.members.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: a.members
                          .map(
                            (m) => ActionChip(
                              avatar: const Icon(Icons.swap_horiz_rounded, size: 14, color: UbColors.cyan),
                              label: Text(m, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                              onPressed: () => _openMoveMemberSheet(idx, m),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMembersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _members.length,
      itemBuilder: (_, idx) {
        final m = _members[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: SwitchListTile(
            value: m.present,
            activeThumbColor: UbColors.emerald,
            secondary: CircleAvatar(
              radius: 14,
              backgroundColor: _statusDotColor(m.statusKaryawan).withValues(alpha: 0.2),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _statusDotColor(m.statusKaryawan)),
              ),
            ),
            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            subtitle: Text(
              '${m.statusKaryawan} · ${m.line}${m.noreg.isNotEmpty ? ' · ${m.noreg}' : ''}',
              style: const TextStyle(fontSize: 11, color: UbColors.textMuted),
            ),
            onChanged: (v) {
              final next = List<AfterProdMember>.from(_members);
              next[idx] = m.copyWith(present: v);
              setState(() => _members = next);
            },
          ),
        );
      },
    );
  }

  Widget _buildJobsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.emerald,
        foregroundColor: UbColors.bg,
        onPressed: () => _openJobForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Job', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
        itemCount: _jobs.length,
        itemBuilder: (_, idx) {
          final j = _jobs[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Text(j.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(j.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              subtitle: Text(
                '${j.scope} · Butuh ${j.requiredPeople} MP · ${j.allowedStatuses.join(', ')}',
                style: const TextStyle(fontSize: 11, color: UbColors.textMuted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: j.isActive,
                    onChanged: (v) async {
                      await ProductivityOpsStore.instance.saveAfterJob(_shift, j.copyWith(isActive: v));
                      await _load();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: UbColors.cyan),
                    onPressed: () => _openJobForm(j),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: UbColors.rose),
                    onPressed: () async {
                      await ProductivityOpsStore.instance.deleteAfterJob(_shift, j.id);
                      await _load();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return const Center(
        child: Text('Belum ada riwayat penugasan 5S tersimpan.', style: TextStyle(color: UbColors.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _history.length,
      itemBuilder: (_, idx) {
        final h = _history[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text('${h.date} · Shift ${h.shift}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            subtitle: Text(
              'Hadir ${h.presentCount} / Butuh ${h.requiredCount} · Pulang ${h.jamPulang} WIB',
              style: const TextStyle(fontSize: 11, color: UbColors.textMuted),
            ),
            children: h.assignments
                .map(
                  (a) => ListTile(
                    dense: true,
                    leading: Text(a.emoji),
                    title: Text(a.jobName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      a.members.isEmpty ? a.status : a.members.join(', '),
                      style: const TextStyle(fontSize: 11, color: UbColors.textMuted),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}
