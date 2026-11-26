import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/roster_attendance_models.dart';
import '../../services/roster_attendance_store.dart';
import 'attendance_screen.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  String _shift = 'RED'; // RED | WHITE
  String _roleFilter = 'ALL'; // ALL | GL | TL | TM
  String _statusFilter = 'ALL'; // ALL | PERMANEN | KONTRAK | VOKASI
  String _search = '';
  bool _loading = true;
  bool _fromServer = false;
  List<RosterMember> _members = const [];
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
    final res = await RosterAttendanceStore.instance.fetchRoster(_shift);
    if (!mounted) return;
    setState(() {
      _members = res.members;
      _fromServer = res.fromServer;
      _loading = false;
    });
  }

  Future<void> _openMemberModal({RosterMember? existing}) async {
    var role = existing?.role ?? 'TM';
    var empStatus = existing?.statusKaryawan ?? 'PERMANEN';
    var isActive = existing?.isActive ?? true;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final noregCtrl = TextEditingController(text: existing?.noreg ?? '');
    final posCtrl = TextEditingController(text: existing?.defaultPos ?? 'Pos 1');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final rfidCtrl = TextEditingController(text: existing?.rfidCode ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

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
                  Text(
                    existing != null ? 'Edit Data Anggota Tim' : 'Tambah Anggota Tim ($_shift)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text('Status Karyawan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['PERMANEN', 'KONTRAK', 'VOKASI'].map((st) {
                      final active = empStatus == st;
                      final col = st == 'PERMANEN' ? UbColors.amber : (st == 'KONTRAK' ? UbColors.emerald : UbColors.rose);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Center(child: Text(st, style: const TextStyle(fontSize: 10.5))),
                            selected: active,
                            selectedColor: col.withValues(alpha: 0.3),
                            onSelected: (_) => setM(() => empStatus = st),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text('Jabatan Struktural', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['GL', 'TL', 'TM'].map((r) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Center(child: Text(r, style: const TextStyle(fontSize: 11))),
                            selected: role == r,
                            selectedColor: UbColors.cyan.withValues(alpha: 0.3),
                            onSelected: (_) => setM(() => role = r),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap Anggota (Wajib)', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: noregCtrl, decoration: const InputDecoration(labelText: 'NOREG', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Pos Stasiun', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No. HP', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: rfidCtrl, decoration: const InputDecoration(labelText: 'Kode RFID', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Keterangan / Tugas', border: OutlineInputBorder(), isDense: true)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    title: const Text('Status Anggota Aktif', style: TextStyle(fontSize: 12.5)),
                    onChanged: (v) => setM(() => isActive = v),
                  ),
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
                          if (nameCtrl.text.trim().isEmpty) return;
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
        final res = await RosterAttendanceStore.instance.deleteMember(existing);
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      } else if (act == 'save') {
        final m = RosterMember(
          id: existing?.id ?? 0,
          name: nameCtrl.text.trim().toUpperCase(),
          noreg: noregCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          rfidCode: rfidCtrl.text.trim().toUpperCase(),
          role: role,
          shift: _shift,
          defaultPos: posCtrl.text.trim().isEmpty ? 'Pos 1' : posCtrl.text.trim(),
          statusKaryawan: empStatus,
          isActive: isActive,
          notes: notesCtrl.text.trim(),
        );
        final res = await RosterAttendanceStore.instance.saveMember(m);
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      }
    } finally {
      nameCtrl.dispose();
      noregCtrl.dispose();
      posCtrl.dispose();
      phoneCtrl.dispose();
      rfidCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = RosterAttendanceMath.computeRosterStats(_members);
    final q = _search.trim().toLowerCase();
    final filtered = _members.where((m) {
      if (_roleFilter != 'ALL' && m.role != _roleFilter) return false;
      if (_statusFilter != 'ALL' && m.statusKaryawan != _statusFilter) return false;
      if (q.isEmpty) return true;
      return '${m.name} ${m.noreg} ${m.defaultPos} ${m.statusKaryawan} ${m.notes}'.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_rounded, size: 17, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Roster Anggota', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: (_fromServer ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                              child: Text(_fromServer ? 'LIVE' : 'LOKAL', style: TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w900, color: _fromServer ? UbColors.emerald : UbColors.amber)),
                            ),
                          ],
                        ),
                        Text('Shift $_shift · ${stats.total} Personel', style: const TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UbColors.emerald,
                      side: BorderSide(color: UbColors.emerald.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AttendanceScreen()),
                    ),
                    child: const Text('Absensi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7)),
                    onPressed: () => _openMemberModal(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('MP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
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
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                        children: [
                          // Shift Switcher
                          Row(
                            children: [
                              Expanded(child: _shiftBtn('RED', '🔴 Shift Merah (RED)', UbColors.rose, Colors.white)),
                              const SizedBox(width: 8),
                              Expanded(child: _shiftBtn('WHITE', '⚪ Shift Putih (WHITE)', Colors.white, UbColors.bg)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 6 Stat Cards
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            childAspectRatio: 1.85,
                            children: [
                              _statBox('GL', '${stats.gl}', UbColors.purple),
                              _statBox('TL', '${stats.tl}', UbColors.cyan),
                              _statBox('TM', '${stats.tm}', UbColors.emerald),
                              _statBox('Permanen', '${stats.permanen}', UbColors.amber),
                              _statBox('Kontrak', '${stats.kontrak}', UbColors.emerald),
                              _statBox('Vokasi', '${stats.vokasi}', UbColors.rose),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Search & Filter
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _search = v),
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Cari nama, noreg, pos kerja, status...',
                              hintStyle: const TextStyle(fontSize: 12, color: UbColors.textMuted),
                              prefixIcon: const Icon(Icons.search_rounded, size: 17),
                              isDense: true,
                              filled: true,
                              fillColor: UbColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...['ALL', 'PERMANEN', 'KONTRAK', 'VOKASI'].map((st) => Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: ChoiceChip(
                                        label: Text(st == 'ALL' ? 'Semua Status' : st, style: const TextStyle(fontSize: 10)),
                                        selected: _statusFilter == st,
                                        onSelected: (_) => setState(() => _statusFilter = st),
                                      ),
                                    )),
                                ...['ALL', 'GL', 'TL', 'TM'].map((r) => Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: ChoiceChip(
                                        label: Text(r == 'ALL' ? 'Semua Role' : r, style: const TextStyle(fontSize: 10)),
                                        selected: _roleFilter == r,
                                        onSelected: (_) => setState(() => _roleFilter = r),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (filtered.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                              child: const Center(child: Text('Tidak ada anggota yang cocok.', style: TextStyle(fontSize: 12.5, color: UbColors.textMuted))),
                            )
                          else
                            ...filtered.map(_buildMemberCard),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shiftBtn(String val, String label, Color bg, Color fg) {
    final active = _shift == val;
    return InkWell(
      onTap: () {
        if (_shift != val) {
          setState(() => _shift = val);
          _load();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? bg : UbColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? bg : Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: active ? fg : UbColors.textMuted)),
      ),
    );
  }

  Widget _statBox(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
          Text(val, style: const TextStyle(fontFamily: 'monospace', fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(RosterMember m) {
    final roleColor = m.role == 'GL' ? UbColors.purple : (m.role == 'TL' ? UbColors.cyan : UbColors.emerald);
    final empColor = m.statusKaryawan == 'PERMANEN'
        ? UbColors.amber
        : (m.statusKaryawan == 'KONTRAK' ? UbColors.emerald : UbColors.rose);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(11), border: Border.all(color: roleColor.withValues(alpha: 0.4))),
            alignment: Alignment.center,
            child: Text(m.role, style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: roleColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(color: empColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                      child: Text(m.statusKaryawan, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: empColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.noreg.isEmpty ? "-" : m.noreg} · ${m.defaultPos}${m.phone.isNotEmpty ? " · ${m.phone}" : ""}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _openMemberModal(existing: m),
            icon: const Icon(Icons.edit_rounded, size: 17, color: UbColors.cyan),
          ),
        ],
      ),
    );
  }
}
