import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/kyt_models.dart';
import '../../services/sga_group_store.dart';
import 'kyt_monitoring_screen.dart';

class SgaGroupScreen extends StatefulWidget {
  const SgaGroupScreen({super.key});

  @override
  State<SgaGroupScreen> createState() => _SgaGroupScreenState();
}

class _SgaGroupScreenState extends State<SgaGroupScreen> {
  List<SgaGroup> _groups = const [];
  List<LineMemberOption> _lineMembers = const [];
  String _activeShiftTab = 'WHITE'; // WHITE | RED | SPLIT
  String _search = '';
  bool _loading = true;
  bool _fromServer = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await SgaGroupStore.instance.fetchGroups();
    final members = await SgaGroupStore.instance.fetchLineMembers();
    if (!mounted) return;
    setState(() {
      _groups = res.groups;
      _fromServer = res.fromServer;
      _lineMembers = members;
      _loading = false;
    });
  }

  bool _matches(SgaGroup g) {
    if (_search.trim().isEmpty) return true;
    final q = _search.trim().toLowerCase();
    return g.name.toLowerCase().contains(q) ||
        g.code.toLowerCase().contains(q) ||
        g.tlName.toLowerCase().contains(q) ||
        g.posArea.toLowerCase().contains(q) ||
        g.circleTema.toLowerCase().contains(q) ||
        g.members.any((m) => m.name.toLowerCase().contains(q) || m.noreg.contains(q));
  }

  Future<void> _openGroupModal({SgaGroup? existing, String? forcedShift}) async {
    var shift = existing?.shift ?? forcedShift ?? (_activeShiftTab == 'RED' ? 'RED' : 'WHITE');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final posCtrl = TextEditingController(text: existing?.posArea ?? '');
    final tlNameCtrl = TextEditingController(text: existing?.tlName ?? '');
    final tlNoregCtrl = TextEditingController(text: existing?.tlNoreg ?? '');
    final temaCtrl = TextEditingController(text: existing?.circleTema ?? '');
    final addNameCtrl = TextEditingController();
    final addRoleCtrl = TextEditingController(text: 'TM Member');
    final members = List<SgaMemberItem>.from(existing?.members ?? const []);

    try {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: UbColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setM) {
            final shiftCandidates = _lineMembers.where((m) => m.shift == shift).toList();
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(ctx).viewInsets.bottom + 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            existing != null ? 'Edit Group SGA' : 'Daftarkan Group SGA Baru',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: const Icon(Icons.close_rounded, color: UbColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            decoration: InputDecoration(
                              labelText: 'Kode Group',
                              hintText: shift == 'WHITE' ? 'SGA-W01' : 'SGA-R01',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: shift,
                            decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), isDense: true),
                            items: const [
                              DropdownMenuItem(value: 'WHITE', child: Text('WHITE SHIFT')),
                              DropdownMenuItem(value: 'RED', child: Text('RED SHIFT')),
                            ],
                            onChanged: (v) {
                              if (v != null && v != shift) {
                                setM(() {
                                  shift = v;
                                  members.clear();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kelompok (SGA Circle Name)',
                        hintText: 'Contoh: SGA Underbody Main',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: posCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pos Area Kerja',
                        hintText: 'Contoh: Pos 1 Underbody Main Floor',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: tlNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Team Leader ($shift)',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: tlNoregCtrl,
                            decoration: const InputDecoration(
                              labelText: 'NOREG',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: temaCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Tema Circle / Fokus Kaizen K3',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Roster Builder
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: UbColors.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anggota Circle Shift $shift (${members.length} Orang)',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: UbColors.cyan),
                          ),
                          const SizedBox(height: 8),
                          if (shiftCandidates.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Pilih dari Master $shift',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: shiftCandidates
                                  .map(
                                    (m) => DropdownMenuItem<int>(
                                      value: m.id,
                                      child: Text('${m.name} (${m.noreg})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) {
                                if (id == null) return;
                                final found = shiftCandidates.firstWhere((e) => e.id == id);
                                if (!members.any((m) => m.name == found.name)) {
                                  setM(() {
                                    members.add(
                                      SgaMemberItem(
                                        memberId: found.id,
                                        name: found.name,
                                        noreg: found.noreg,
                                        role: found.role.isNotEmpty ? found.role : 'TM Member',
                                      ),
                                    );
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: addNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Tambah Nama Manual',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: addRoleCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Role',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filled(
                                style: IconButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                                onPressed: () {
                                  final n = addNameCtrl.text.trim();
                                  if (n.isEmpty) return;
                                  setM(() {
                                    members.add(SgaMemberItem(name: n, role: addRoleCtrl.text.trim().isEmpty ? 'TM Member' : addRoleCtrl.text.trim()));
                                    addNameCtrl.clear();
                                  });
                                },
                                icon: const Icon(Icons.add_rounded, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (members.isEmpty)
                            const Text('Belum ada anggota ditambahkan.', style: TextStyle(fontSize: 11, color: UbColors.textMuted))
                          else
                            ...members.asMap().entries.map((entry) {
                              final i = entry.key;
                              final m = entry.value;
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(m.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                subtitle: Text('${m.role}${m.noreg.isNotEmpty ? " · ${m.noreg}" : ""}', style: const TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: UbColors.rose),
                                  onPressed: () => setM(() => members.removeAt(i)),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty || tlNameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Nama group dan Team Leader wajib diisi.')),
                                );
                                return;
                              }
                              Navigator.pop(ctx, true);
                            },
                            icon: const Icon(Icons.check_rounded, size: 17),
                            label: Text('Simpan Group ($shift)', style: const TextStyle(fontWeight: FontWeight.w900)),
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

      if (saved == true) {
        final code = codeCtrl.text.trim().isNotEmpty
            ? codeCtrl.text.trim()
            : 'SGA-${shift == "RED" ? "R" : "W"}${(_groups.length + 1).toString().padLeft(2, "0")}';
        final grp = SgaGroup(
          id: existing?.id ?? 'sga_${DateTime.now().microsecondsSinceEpoch}',
          code: code,
          name: nameCtrl.text.trim(),
          shift: shift,
          posArea: posCtrl.text.trim().isEmpty ? 'Lini Underbody' : posCtrl.text.trim(),
          circleTema: temaCtrl.text.trim().isEmpty ? 'Pencegahan Bahaya Kerja & Kaizen 5S' : temaCtrl.text.trim(),
          tlName: tlNameCtrl.text.trim(),
          tlNoreg: tlNoregCtrl.text.trim(),
          members: members.isNotEmpty
              ? members
              : [SgaMemberItem(name: tlNameCtrl.text.trim(), noreg: tlNoregCtrl.text.trim(), role: 'TL & Inisiator')],
        );
        final res = await SgaGroupStore.instance.saveGroup(grp);
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      }
    } finally {
      codeCtrl.dispose();
      nameCtrl.dispose();
      posCtrl.dispose();
      tlNameCtrl.dispose();
      tlNoregCtrl.dispose();
      temaCtrl.dispose();
      addNameCtrl.dispose();
      addRoleCtrl.dispose();
    }
  }

  Future<void> _confirmDelete(SgaGroup g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UbColors.surface,
        title: Text('Hapus ${g.name}?'),
        content: Text('Group SGA "${g.name}" (${g.code}) shift ${g.shift} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: UbColors.rose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final res = await SgaGroupStore.instance.deleteGroup(g);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final whiteGroups = _groups.where((g) => g.shift == 'WHITE' && _matches(g)).toList();
    final redGroups = _groups.where((g) => g.shift == 'RED' && _matches(g)).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Group SGA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (_fromServer ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _fromServer ? 'LIVE' : 'LOKAL',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: _fromServer ? UbColors.emerald : UbColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Text('Small Group Activity · Red & White Terpisah', style: TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UbColors.amber,
                      side: BorderSide(color: UbColors.amber.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const KytMonitoringScreen()),
                    ),
                    child: const Text('KYT', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: UbColors.cyan,
                      foregroundColor: UbColors.bg,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: () => _openGroupModal(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Group', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                        children: [
                          // Shift Tabs & Search
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: UbColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _tabBtn('WHITE', 'WHITE (${whiteGroups.length})', Colors.white, UbColors.bg),
                                    const SizedBox(width: 6),
                                    _tabBtn('RED', 'RED (${redGroups.length})', UbColors.rose, Colors.white),
                                    const SizedBox(width: 6),
                                    _tabBtn('SPLIT', 'Terpisah', UbColors.cyan, UbColors.bg),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) => setState(() => _search = v),
                                  style: const TextStyle(fontSize: 12.5),
                                  decoration: InputDecoration(
                                    hintText: 'Cari group, TL, nama member...',
                                    hintStyle: const TextStyle(fontSize: 12, color: UbColors.textMuted),
                                    prefixIcon: const Icon(Icons.search_rounded, size: 17),
                                    isDense: true,
                                    filled: true,
                                    fillColor: UbColors.bg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (_activeShiftTab == 'WHITE' || _activeShiftTab == 'SPLIT')
                            _buildShiftSection('WHITE', whiteGroups),
                          if (_activeShiftTab == 'SPLIT') const SizedBox(height: 16),
                          if (_activeShiftTab == 'RED' || _activeShiftTab == 'SPLIT')
                            _buildShiftSection('RED', redGroups),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String key, String label, Color activeBg, Color activeFg) {
    final active = _activeShiftTab == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeShiftTab = key),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? activeBg : UbColors.bg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: active ? activeBg : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: active ? activeFg : UbColors.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftSection(String shift, List<SgaGroup> list) {
    final isWhite = shift == 'WHITE';
    final accent = isWhite ? Colors.white70 : UbColors.rose;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWhite ? 'WHITE SHIFT (SHIFT PUTIH)' : 'RED SHIFT (SHIFT MERAH)',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: accent),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${list.length} Kelompok SGA Terdaftar',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _openGroupModal(forcedShift: shift),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text('+ $shift', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Belum ada Group SGA untuk shift ini.', style: TextStyle(fontSize: 12, color: UbColors.textMuted)),
              ),
            )
          else
            ...list.map((g) => _buildGroupCard(g, accent)),
        ],
      ),
    );
  }

  Widget _buildGroupCard(SgaGroup g, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: UbColors.bg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: UbColors.cyan.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(g.code, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('${g.shift} SHIFT', style: TextStyle(fontFamily: 'monospace', fontSize: 9.5, fontWeight: FontWeight.w800, color: accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(g.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text(g.posArea, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _openGroupModal(existing: g),
                  icon: const Icon(Icons.edit_rounded, size: 17, color: UbColors.cyan),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDelete(g),
                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: UbColors.rose),
                ),
              ],
            ),
          ),

          // Tema Circle
          if (g.circleTema.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: UbColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                '"${g.circleTema}"',
                style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: UbColors.textPrimary),
              ),
            ),

          // TL Badge
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: UbColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: UbColors.amber.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 13,
                  backgroundColor: UbColors.amber,
                  child: Text('TL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: UbColors.bg)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(g.tlName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                if (g.tlNoreg.isNotEmpty)
                  Text(g.tlNoreg, style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.amber)),
              ],
            ),
          ),

          // Roster Members
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anggota Circle (${g.members.length})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: UbColors.textMuted),
                ),
                const SizedBox(height: 6),
                if (g.members.isEmpty)
                  const Text('Belum ada anggota terdaftar.', style: TextStyle(fontSize: 11, color: UbColors.textMuted))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: g.members
                        .map(
                          (m) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: UbColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Text(
                              '${m.name}${m.role.isNotEmpty ? " · ${m.role}" : ""}',
                              style: const TextStyle(fontSize: 10.5, color: UbColors.textPrimary),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),

          // Footer link to Matriks KYT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: UbColors.surface.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Target KYT: ${g.kytTargetPerYear} Sesi / Tahun', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const KytMonitoringScreen()),
                  ),
                  child: const Row(
                    children: [
                      Text('Matriks KYT', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: UbColors.cyan)),
                      Icon(Icons.chevron_right_rounded, size: 16, color: UbColors.cyan),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
