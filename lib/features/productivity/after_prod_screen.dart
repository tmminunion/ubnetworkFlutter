import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../models/productivity_ops_models.dart';
import '../../services/productivity_ops_store.dart';

class _MemberDragData {
  const _MemberDragData({
    required this.jobIdx,
    required this.memberIdx,
    required this.name,
  });

  final int jobIdx;
  final int memberIdx;
  final String name;
}

class AfterProdScreen extends StatefulWidget {
  const AfterProdScreen({super.key});

  @override
  State<AfterProdScreen> createState() => _AfterProdScreenState();
}

class _AfterProdScreenState extends State<AfterProdScreen> {
  int _tabIndex = 0; // 0: Generate, 1: List Anggota, 2: List Pekerjaan, 3: History
  String _shift = 'WHITE';
  String _jamPulang = '18.15';
  bool _loading = true;
  bool _fromServer = false;

  List<AfterProdMember> _members = const [];
  List<AfterProdJob> _jobs = const [];
  List<AfterProdAssignment> _assignments = const [];
  List<AfterProdHistoryRecord> _history = const [];

  _MemberDragData? _selectedForMove;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _selectedForMove = null;
    });

    final results = await Future.wait([
      ProductivityOpsStore.instance.fetchAfterMembers(_shift),
      ProductivityOpsStore.instance.fetchAfterJobs(_shift),
      ProductivityOpsStore.instance.fetchAfterTasks(_shift),
      ProductivityOpsStore.instance.loadAfterHistory(_shift),
    ]);

    if (!mounted) return;

    final memRes = results[0] as ({List<AfterProdMember> members, bool fromServer});
    final jobRes = results[1] as ({List<AfterProdJob> jobs, bool fromServer});
    final taskRes = results[2]
        as ({List<AfterProdAssignment> tasks, String? jamPulang, String? date, bool fromServer});
    final hist = results[3] as List<AfterProdHistoryRecord>;

    final eligibleMembers = memRes.members.where((m) => m.isEligibleFor5S).toList();
    final sortedJobs = List<AfterProdJob>.from(jobRes.jobs)
      ..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        return a.id.compareTo(b.id);
      });

    List<AfterProdAssignment> initialTasks = const [];
    var loadedJam = _jamPulang;

    if (taskRes.tasks.isNotEmpty) {
      initialTasks = taskRes.tasks;
      if (taskRes.jamPulang != null && taskRes.jamPulang!.isNotEmpty) {
        loadedJam = taskRes.jamPulang!;
      }
    } else if (hist.isNotEmpty && hist.first.date == ubTodayYmd()) {
      initialTasks = hist.first.assignments;
      loadedJam = hist.first.jamPulang;
    } else if (eligibleMembers.any((m) => m.present) && sortedJobs.any((j) => j.isActive)) {
      initialTasks = AfterProdEngine.generateAssignments(
        members: eligibleMembers,
        jobs: sortedJobs,
        shift: _shift,
      );
    }

    setState(() {
      _members = eligibleMembers;
      _jobs = sortedJobs;
      _history = hist;
      _assignments = initialTasks;
      _jamPulang = loadedJam;
      _fromServer = memRes.fromServer || jobRes.fromServer || taskRes.fromServer;
      _loading = false;
    });
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _persistSilently(List<AfterProdAssignment> next) async {
    final rec = AfterProdHistoryRecord(
      date: ubTodayYmd(),
      shift: _shift,
      jamPulang: _jamPulang,
      presentCount: _presentCount,
      requiredCount: _requiredCount,
      assignments: next,
    );
    await ProductivityOpsStore.instance.saveAfterHistory(rec);
    final hist = await ProductivityOpsStore.instance.loadAfterHistory(_shift);
    if (mounted) {
      setState(() => _history = hist);
    }
  }

  void _generate() {
    if (_activeJobCount == 0) {
      _showToast('Belum ada pekerjaan aktif. Tambahkan di List Pekerjaan.');
      setState(() => _tabIndex = 2);
      return;
    }
    if (_presentCount == 0) {
      _showToast('Pilih minimal 1 anggota yang hadir.');
      return;
    }
    final res = AfterProdEngine.generateAssignments(
      members: _members,
      jobs: _jobs,
      shift: _shift,
    );
    setState(() {
      _assignments = res;
      _selectedForMove = null;
    });
    _persistSilently(res);
    _showToast('✨ Penugasan After Produksi berhasil di-generate ulang!');
  }

  Future<void> _saveCurrentAssignments() async {
    if (_assignments.isEmpty) return;
    final rec = AfterProdHistoryRecord(
      date: ubTodayYmd(),
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
    _showToast(res.message);
  }

  void _copyWhatsapp() {
    if (_assignments.isEmpty) return;
    final text = AfterProdEngine.buildWhatsappText(
      date: ubTodayYmd(),
      shift: _shift,
      jamPulang: _jamPulang,
      assignments: _assignments,
    );
    Clipboard.setData(ClipboardData(text: text));
    _showToast('Format WA distribusi 5S disalin ke clipboard!');
  }

  void _handleMoveMember(_MemberDragData dragged, int targetJobIdx) {
    if (dragged.jobIdx == targetJobIdx) return;
    final targetJobName = _assignments[targetJobIdx].jobName;
    final next = AfterProdEngine.moveMember(
      assignments: _assignments,
      fromJobIdx: dragged.jobIdx,
      memberName: dragged.name,
      toJobIdx: targetJobIdx,
    );
    setState(() {
      _assignments = next;
      _selectedForMove = null;
    });
    _persistSilently(next);
    _showToast('✅ ${dragged.name} dipindahkan ke $targetJobName');
  }

  void _handleSwapMembers(_MemberDragData a, _MemberDragData b) {
    if (a.jobIdx == b.jobIdx && a.memberIdx == b.memberIdx) return;
    final next = AfterProdEngine.swapMembers(
      assignments: _assignments,
      aJobIdx: a.jobIdx,
      aMemberIdx: a.memberIdx,
      bJobIdx: b.jobIdx,
      bMemberIdx: b.memberIdx,
    );
    setState(() {
      _assignments = next;
      _selectedForMove = null;
    });
    _persistSilently(next);
    _showToast('🔄 ${a.name} ↔ ${b.name} berhasil ditukar!');
  }

  void _handleTapMember(int jobIdx, int memberIdx, String name) {
    final tapped = _MemberDragData(jobIdx: jobIdx, memberIdx: memberIdx, name: name);
    final sel = _selectedForMove;
    if (sel == null) {
      setState(() => _selectedForMove = tapped);
      return;
    }
    if (sel.jobIdx == jobIdx && sel.memberIdx == memberIdx) {
      setState(() => _selectedForMove = null);
      return;
    }
    _handleSwapMembers(sel, tapped);
  }

  Future<void> _openJobForm([AfterProdJob? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emojiCtrl = TextEditingController(text: existing?.emoji ?? '🛠️');
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
                            DropdownMenuItem(value: 'COMMON', child: Text('COMMON (R & W)')),
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
                          initialValue: req.clamp(1, 5),
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
                    style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
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
        final name = nameCtrl.text.trim();
        final emoji = emojiCtrl.text.trim().isEmpty ? AfterProdEngine.jobEmoji(name) : emojiCtrl.text.trim();
        final job = AfterProdJob(
          id: existing?.id ?? 0,
          name: name,
          emoji: emoji,
          scope: scope,
          requiredPeople: req,
          allowedStatuses: allowed.toList(),
          preferredLine: lineCtrl.text.trim(),
          isActive: active,
        );
        final res = await ProductivityOpsStore.instance.saveAfterJob(_shift, job);
        await _load();
        _showToast(res.message);
      }
    } finally {
      nameCtrl.dispose();
      emojiCtrl.dispose();
      lineCtrl.dispose();
    }
  }

  int get _presentCount => _members.where((m) => m.isEligibleFor5S && m.present).length;

  int get _activeJobCount => _jobs
      .where((j) => j.isActive && (j.scope == 'COMMON' || j.scope == _shift))
      .length;

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
    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildCompactHeader(),
            _buildNavGrid(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: UbColors.cyan))
                  : _buildActiveTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: UbColors.surface,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'UBAI',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: UbColors.cyan,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          // Compact RED | WHITE pill switcher matching web 1:1
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: UbColors.bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShiftPill(
                  label: 'RED',
                  active: _shift == 'RED',
                  activeColor: const Color(0xFFDC2626),
                  onTap: () {
                    if (_shift != 'RED') {
                      setState(() => _shift = 'RED');
                      _load();
                    }
                  },
                ),
                const SizedBox(width: 2),
                _ShiftPill(
                  label: 'WHITE',
                  active: _shift == 'WHITE',
                  activeColor: const Color(0xFF2563EB),
                  onTap: () {
                    if (_shift != 'WHITE') {
                      setState(() => _shift = 'WHITE');
                      _load();
                    }
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          Tooltip(
            message: _fromServer ? 'Tersambung Server' : 'Mode Offline Cache',
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _fromServer ? UbColors.emerald : UbColors.amber,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _load,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.refresh_rounded, size: 18, color: UbColors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _NavCard(
                  icon: Icons.shuffle_rounded,
                  title: 'GENERATE',
                  subtitle: 'Buat penugasan hari ini',
                  active: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NavCard(
                  icon: Icons.groups_rounded,
                  title: 'LIST ANGGOTA',
                  subtitle: '$_presentCount/${_members.length} hadir',
                  active: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NavCard(
                  icon: Icons.tune_rounded,
                  title: 'LIST PEKERJAAN',
                  subtitle: '$_activeJobCount job aktif',
                  active: _tabIndex == 2,
                  onTap: () => setState(() => _tabIndex = 2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NavCard(
                  icon: Icons.history_rounded,
                  title: 'HISTORY',
                  subtitle: 'Riwayat per hari',
                  active: _tabIndex == 3,
                  onTap: () => setState(() => _tabIndex = 3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_tabIndex) {
      case 0:
        return _buildGenerateTab();
      case 1:
        return _buildMembersTab();
      case 2:
        return _buildJobsTab();
      case 3:
        return _buildHistoryTab();
      default:
        return _buildGenerateTab();
    }
  }

  Widget _buildGenerateTab() {
    final sel = _selectedForMove;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
      children: [
        // Compact Control Bar
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: UbColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Pulang:',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: UbColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    for (final jp in const ['16.00', '17.15', '18.15', '19.15'])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          selectedColor: UbColors.cyan,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _jamPulang == jp ? UbColors.bg : Colors.white70,
                          ),
                          label: Text('$jp WIB'),
                          selected: _jamPulang == jp,
                          onSelected: (_) => setState(() => _jamPulang = jp),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: UbColors.cyan,
                        foregroundColor: UbColors.bg,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _generate,
                      icon: const Icon(Icons.shuffle_rounded, size: 16),
                      label: const Text('GENERATE ULANG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      onPressed: _assignments.isEmpty ? null : _copyWhatsapp,
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('WA', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _assignments.isEmpty ? null : _saveCurrentAssignments,
                      icon: const Icon(Icons.save_rounded, size: 15),
                      label: const Text('Simpan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Instruction / Active Swap Banner (1:1 with web screenshot)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: sel != null ? UbColors.cyan.withValues(alpha: 0.14) : UbColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel != null ? UbColors.cyan.withValues(alpha: 0.7) : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Icon(
                sel != null ? Icons.swap_horiz_rounded : Icons.drag_indicator_rounded,
                size: 16,
                color: UbColors.cyan,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: sel != null
                    ? Text(
                        'Memindahkan ${sel.name} — tap nama lain untuk tukar, atau tap baris job untuk pindah.',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                      )
                    : const Text(
                        'Tahan & geser nama ke job lain untuk pindah, atau jatuhkan di atas nama lain untuk tukar posisi. Di HP, cukup tap nama lalu tap tujuan.',
                        style: TextStyle(fontSize: 11, color: UbColors.textMuted, height: 1.35),
                      ),
              ),
              if (sel != null)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: UbColors.rose,
                  ),
                  onPressed: () => setState(() => _selectedForMove = null),
                  child: const Text('Batal', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3-Column Table: NO | PEKERJAAN | ANGGOTA PETUGAS (1:1 with web)
        if (_assignments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Tekan tombol GENERATE ULANG untuk membagi tugas 5S akhir shift.',
                textAlign: TextAlign.center,
                style: TextStyle(color: UbColors.textMuted, fontSize: 12.5),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: UbColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    border: const Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text(
                          'NO',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: UbColors.textMuted, letterSpacing: 0.6),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          'PEKERJAAN',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: UbColors.textMuted, letterSpacing: 0.6),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: Text(
                          'ANGGOTA PETUGAS',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: UbColors.textMuted, letterSpacing: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows
                for (var idx = 0; idx < _assignments.length; idx++)
                  _buildAssignmentRow(idx, _assignments[idx]),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentRow(int jobIdx, AfterProdAssignment a) {
    final isStandby = a.jobId == -1 || a.status == 'Sisa MP';
    final isOff = a.status == 'Off (Kekurangan MP)' && a.members.isEmpty;
    final canTapMoveHere = _selectedForMove != null && _selectedForMove!.jobIdx != jobIdx;

    return DragTarget<_MemberDragData>(
      onWillAcceptWithDetails: (details) => details.data.jobIdx != jobIdx,
      onAcceptWithDetails: (details) => _handleMoveMember(details.data, jobIdx),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return InkWell(
          onTap: canTapMoveHere ? () => _handleMoveMember(_selectedForMove!, jobIdx) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: isHovered
                  ? UbColors.cyan.withValues(alpha: 0.16)
                  : (canTapMoveHere ? UbColors.cyan.withValues(alpha: 0.05) : Colors.transparent),
              border: Border(
                bottom: BorderSide(
                  color: isHovered ? UbColors.cyan : Colors.white10,
                  width: isHovered ? 1.5 : 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    isStandby ? '★' : '${jobIdx + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isStandby ? UbColors.amber : UbColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(a.emoji, style: const TextStyle(fontSize: 17)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.jobName,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            color: isStandby ? UbColors.amber : UbColors.cyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: isOff
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: UbColors.rose.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: UbColors.rose.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            canTapMoveHere ? '+ Tap pindah ke sini' : 'Off (Kurang MP)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: canTapMoveHere ? UbColors.cyan : UbColors.rose,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var mIdx = 0; mIdx < a.members.length; mIdx++)
                              Padding(
                                padding: EdgeInsets.only(bottom: mIdx == a.members.length - 1 ? 0 : 6),
                                child: _buildMemberChip(jobIdx, mIdx, a.members[mIdx]),
                              ),
                            if (canTapMoveHere)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '+ Tap baris untuk pindah',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: UbColors.cyan.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberChip(int jobIdx, int memberIdx, String memberName) {
    final payload = _MemberDragData(jobIdx: jobIdx, memberIdx: memberIdx, name: memberName);
    final isSelected = _selectedForMove?.jobIdx == jobIdx && _selectedForMove?.memberIdx == memberIdx;

    Widget buildChipBody({required bool highlighted, required bool dragging}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: dragging
              ? UbColors.cyan
              : (highlighted ? UbColors.cyan.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: highlighted || dragging ? UbColors.cyan : Colors.white24,
            width: highlighted || dragging ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              size: 13,
              color: dragging ? UbColors.bg : (highlighted ? UbColors.cyan : UbColors.textMuted),
            ),
            const SizedBox(width: 4),
            Text(
              '${memberIdx + 1}. ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: dragging ? UbColors.bg : UbColors.textMuted,
              ),
            ),
            Expanded(
              child: Text(
                memberName,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: dragging ? UbColors.bg : Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DragTarget<_MemberDragData>(
      onWillAcceptWithDetails: (details) =>
          !(details.data.jobIdx == jobIdx && details.data.memberIdx == memberIdx),
      onAcceptWithDetails: (details) => _handleSwapMembers(details.data, payload),
      builder: (context, candidateData, rejectedData) {
        final isSwapTarget = candidateData.isNotEmpty;
        return LongPressDraggable<_MemberDragData>(
          data: payload,
          delay: const Duration(milliseconds: 180),
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 155,
              child: buildChipBody(highlighted: true, dragging: true),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: buildChipBody(highlighted: false, dragging: false),
          ),
          child: InkWell(
            onTap: () => _handleTapMember(jobIdx, memberIdx, memberName),
            borderRadius: BorderRadius.circular(9),
            child: buildChipBody(highlighted: isSelected || isSwapTarget, dragging: false),
          ),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Operator TM Shift $_shift · $_presentCount/${_members.length} hadir (GL & TL dikecualikan)',
                  style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () {
                  setState(() {
                    _members = _members.map((m) => m.copyWith(present: true)).toList();
                  });
                },
                child: const Text('Hadir Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: UbColors.rose),
                onPressed: () {
                  setState(() {
                    _members = _members.map((m) => m.copyWith(present: false)).toList();
                  });
                },
                child: const Text('Off Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
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
          ),
        ),
      ],
    );
  }

  Widget _jobPill({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteJob(AfterProdJob j) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UbColors.surface,
        title: const Text('Hapus Pekerjaan?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        content: Text(
          'Hapus "${j.name}" dari daftar pekerjaan $_shift?',
          style: const TextStyle(color: UbColors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: UbColors.rose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ProductivityOpsStore.instance.deleteAfterJob(_shift, j.id);
      await _load();
    }
  }

  Widget _buildJobsTab() {
    final activeJobs = _jobs.where((j) => j.isActive).toList();
    final inactiveCount = _jobs.length - activeJobs.length;
    final totalMpNeeded = activeJobs.fold<int>(0, (sum, j) => sum + j.requiredPeople);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.cyan,
        foregroundColor: UbColors.bg,
        elevation: 4,
        onPressed: () => _openJobForm(),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Tambah Job', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
      ),
      body: _jobs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.work_outline_rounded, size: 40, color: UbColors.textMuted),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada daftar pekerjaan',
                    style: TextStyle(color: UbColors.textMuted, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 92),
              itemCount: _jobs.length + 1,
              itemBuilder: (_, index) {
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: UbColors.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: UbColors.border.withValues(alpha: 0.7)),
                    ),
                    child: Row(
                      children: [
                        _jobPill(
                          label: '${activeJobs.length} Aktif',
                          color: UbColors.emerald,
                          icon: Icons.check_circle_rounded,
                        ),
                        const SizedBox(width: 6),
                        if (inactiveCount > 0) ...[
                          _jobPill(
                            label: '$inactiveCount Off',
                            color: UbColors.textMuted,
                            icon: Icons.pause_circle_outline_rounded,
                          ),
                          const SizedBox(width: 6),
                        ],
                        const Spacer(),
                        _jobPill(
                          label: 'Total $totalMpNeeded MP',
                          color: UbColors.cyan,
                          icon: Icons.groups_rounded,
                        ),
                      ],
                    ),
                  );
                }

                final j = _jobs[index - 1];
                final scopeUpper = j.scope.toUpperCase();
                final scopeColor = scopeUpper == 'COMMON'
                    ? UbColors.amber
                    : (scopeUpper == 'RED' ? UbColors.rose : UbColors.primaryBlue);
                final statusLabel = j.allowedStatuses.length >= 3
                    ? 'Semua Status'
                    : j.allowedStatuses.join(', ');

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: j.isActive
                        ? UbColors.surface
                        : UbColors.surface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: j.isActive
                          ? UbColors.cyan.withValues(alpha: 0.28)
                          : UbColors.border.withValues(alpha: 0.55),
                      width: 1,
                    ),
                    boxShadow: j.isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 3.5,
                            color: j.isActive
                                ? UbColors.cyan
                                : UbColors.border.withValues(alpha: 0.6),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 11, 10, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: (j.isActive ? UbColors.cyan : UbColors.textMuted)
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: (j.isActive ? UbColors.cyan : UbColors.border)
                                                .withValues(alpha: 0.28),
                                          ),
                                        ),
                                        child: Text(
                                          j.emoji,
                                          style: const TextStyle(fontSize: 19),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          j.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            height: 1.25,
                                            color: j.isActive ? UbColors.textPrimary : UbColors.textMuted,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Transform.scale(
                                        scale: 0.8,
                                        alignment: Alignment.centerRight,
                                        child: Switch(
                                          value: j.isActive,
                                          activeThumbColor: UbColors.bg,
                                          activeTrackColor: UbColors.cyan,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          onChanged: (v) async {
                                            await ProductivityOpsStore.instance
                                                .saveAfterJob(_shift, j.copyWith(isActive: v));
                                            await _load();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 9),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 5,
                                          children: [
                                            _jobPill(label: scopeUpper, color: scopeColor),
                                            _jobPill(
                                              label: '${j.requiredPeople} MP',
                                              color: UbColors.cyan,
                                              icon: Icons.person_outline_rounded,
                                            ),
                                            _jobPill(
                                              label: statusLabel,
                                              color: UbColors.purple,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _openJobForm(j),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: UbColors.cyan.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: UbColors.cyan.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit_rounded,
                                            size: 16,
                                            color: UbColors.cyan,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _confirmDeleteJob(j),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: UbColors.rose.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: UbColors.rose.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 16,
                                            color: UbColors.rose,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: _history.length,
      itemBuilder: (_, idx) {
        final h = _history[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text('${h.date} · Shift ${h.shift}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            subtitle: Text(
              '${h.assignments.length} pos · Pulang ${h.jamPulang} WIB',
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

class _ShiftPill extends StatelessWidget {
  const _ShiftPill({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Colors.white : UbColors.textMuted,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: active ? Colors.white : UbColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF06B6D4) : UbColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFF22D3EE) : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: active ? UbColors.bg : UbColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: active ? UbColors.bg : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? UbColors.bg.withValues(alpha: 0.78) : UbColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
