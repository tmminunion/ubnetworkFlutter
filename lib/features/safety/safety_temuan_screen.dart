import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';
import '../../models/safety_finding_models.dart';
import '../../services/safety_findings_store.dart';
import 'safety_kaizen_paper_screen.dart';
import 'safety_temuan_form_modal.dart';

class SafetyTemuanScreen extends StatefulWidget {
  const SafetyTemuanScreen({super.key});

  @override
  State<SafetyTemuanScreen> createState() => _SafetyTemuanScreenState();
}

class _SafetyTemuanScreenState extends State<SafetyTemuanScreen> {
  List<SafetyFinding> _all = const [];
  bool _loading = true;
  bool _busy = false;
  String _source = 'atlas'; // atlas | default | local
  String? _syncError;

  String _tab = 'temuan'; // temuan | kaizen
  bool _kaizenVertical = false; // false = Horizontal (Kiri-Kanan), true = Vertikal (Atas-Bawah)

  bool _allMonths = true;
  String _selectedYm = ''; // YYYY-MM

  String _statusFilter = 'all'; // all | open_combined | open | progress | closed
  String _shiftFilter = 'all'; // all | red | white
  int? _hazardFilter; // null or 0..3
  String _sortMode = 'open'; // open | new | old | risk | no_desc
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedYm = UbMasterData.wibToday().substring(0, 7);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = _all.isEmpty);
    final res = await SafetyFindingsStore.instance.fetchFindings();
    if (!mounted) return;
    setState(() {
      _all = res.items;
      _source = res.source;
      _syncError = res.error;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    final parts = _selectedYm.split('-');
    final y = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? DateTime.now().year;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? DateTime.now().month;
    final next = DateTime(y, m + delta, 1);
    setState(() {
      _selectedYm = '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _openCreate() async {
    final blank = SafetyFinding(
      id: 'sf_${DateTime.now().microsecondsSinceEpoch}',
      foundAt: UbMasterData.wibToday(),
      shift: _shiftFilter == 'red' ? 'red' : 'white',
      status: 'open',
    );
    final res = await showSafetyTemuanModal(context, initial: blank);
    if (res != null) {
      setState(() => _busy = true);
      final saved = await SafetyFindingsStore.instance.upsertFinding(res);
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(saved.syncStatus == 'synced' ? 'Temuan #${saved.no} tersimpan ke Server' : 'Temuan disimpan di perangkat');
      await _load();
    }
  }

  Future<SafetyFinding?> _openEditAndReturn(SafetyFinding item, {bool kaizenMode = false}) async {
    final res = await showSafetyTemuanModal(context, initial: item, kaizenMode: kaizenMode);
    if (res == null) return null;
    setState(() => _busy = true);
    final saved = await SafetyFindingsStore.instance.upsertFinding(res);
    if (mounted) {
      setState(() => _busy = false);
      _toast(
        saved.syncStatus == 'synced'
            ? '${kaizenMode ? "Kaizen" : "Temuan"} #${saved.no} tersinkron ke Server'
            : 'Perubahan disimpan lokal',
      );
      await _load();
    }
    return saved;
  }

  void _openKaizenPaper(SafetyFinding target, List<SafetyFinding> currentList) {
    final navItems = currentList.isNotEmpty ? currentList : <SafetyFinding>[target];
    final idx = navItems.indexWhere((x) => x.id == target.id || (target.no.isNotEmpty && x.no == target.no));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SafetyKaizenPaperScreen(
          items: navItems,
          initialIndex: idx >= 0 ? idx : 0,
          initialVertical: _kaizenVertical,
          onEdit: (f) => _openEditAndReturn(f, kaizenMode: true),
        ),
      ),
    );
  }

  Future<void> _quickStatus(SafetyFinding item, String nextStatus) async {
    if (_busy) return;
    setState(() => _busy = true);
    final updated = item.copyWith(status: nextStatus);
    final saved = await SafetyFindingsStore.instance.upsertFinding(updated);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(
      nextStatus == 'closed'
          ? 'Temuan #${saved.no} ditandai Selesai (Tampil di Display Kaizen)'
          : 'Status Temuan #${saved.no} diperbarui',
    );
    await _load();
  }

  Future<void> _confirmDelete(SafetyFinding item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UbColors.surface,
        title: Text('Hapus Temuan #${item.no}?'),
        content: Text('Temuan "${item.caption}" beserta Kaizen Report akan dihapus permanen.'),
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
      setState(() => _busy = true);
      await SafetyFindingsStore.instance.deleteFinding(item.id, no: item.no);
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('Temuan #${item.no} dihapus');
      await _load();
    }
  }

  void _toast(String msg, {bool isErr = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isErr ? UbColors.rose : UbColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetFilters() {
    _searchCtrl.clear();
    setState(() {
      _allMonths = true;
      _statusFilter = 'all';
      _shiftFilter = 'all';
      _hazardFilter = null;
      _sortMode = 'open';
      _search = '';
    });
  }

  List<SafetyFinding> get _baseMonthFiltered {
    if (_allMonths) return _all;
    return _all.where((f) => f.foundAt.startsWith(_selectedYm)).toList();
  }

  List<SafetyFinding> get _filtered {
    final q = _search.trim().toLowerCase();
    final list = _baseMonthFiltered.where((f) {
      if (_shiftFilter != 'all' && f.shift != _shiftFilter) return false;
      if (_hazardFilter != null && f.hazard != _hazardFilter) return false;
      if (_statusFilter == 'open_combined' && f.status == 'closed') return false;
      if (_statusFilter == 'open' && f.status != 'open') return false;
      if (_statusFilter == 'progress' && f.status != 'progress') return false;
      if (_statusFilter == 'closed' && f.status != 'closed') return false;
      if (q.isNotEmpty) {
        final hay =
            '${f.no} ${f.caption} ${f.location} ${f.process} ${f.pic} ${f.standard} ${f.cm} ${f.theme} ${f.result}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    int statusRank(String s) => s == 'open' ? 0 : (s == 'progress' ? 1 : 2);
    list.sort((a, b) {
      if (_sortMode == 'open') {
        final d = statusRank(a.status).compareTo(statusRank(b.status));
        if (d != 0) return d;
      } else if (_sortMode == 'old') {
        final c = a.foundAt.compareTo(b.foundAt);
        if (c != 0) return c;
        return (int.tryParse(a.no) ?? 0).compareTo(int.tryParse(b.no) ?? 0);
      } else if (_sortMode == 'risk') {
        final ra = a.before.totalPoints ?? -1;
        final rb = b.before.totalPoints ?? -1;
        if (rb != ra) return rb.compareTo(ra);
      } else if (_sortMode == 'no_desc') {
        final na = int.tryParse(a.no) ?? 0;
        final nb = int.tryParse(b.no) ?? 0;
        if (nb != na) return nb.compareTo(na);
      }
      final dateCmp = b.foundAt.compareTo(a.foundAt);
      if (dateCmp != 0) return dateCmp;
      return (int.tryParse(b.no) ?? 0).compareTo(int.tryParse(a.no) ?? 0);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final monthPool = _baseMonthFiltered;
    final cAll = monthPool.length;
    final cOnlyOpen = monthPool.where((e) => e.status == 'open').length;
    final cProgress = monthPool.where((e) => e.status == 'progress').length;
    final cOpenCombined = cOnlyOpen + cProgress;
    final cClosed = monthPool.where((e) => e.status == 'closed').length;
    final items = _filtered;

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: UbColors.bg,
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
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFDC2626)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_rounded, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Temuan & Kaizen Safety',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (_source == 'atlas' ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: (_source == 'atlas' ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.45),
                                ),
                              ),
                              child: Text(
                                _source == 'atlas' ? 'LIVE ATLAS' : 'CACHE LOKAL',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: _source == 'atlas' ? const Color(0xFF6EE7B7) : UbColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'List Up Problem & Before–After Kaizen Report',
                          style: TextStyle(fontSize: 10.5, color: UbColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.sync_rounded, size: 19, color: UbColors.cyan),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Muat Ulang dari Server',
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: UbColors.cyan,
                      foregroundColor: UbColors.bg,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _busy ? null : _openCreate,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Temuan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
            ),

            if (_busy) const LinearProgressIndicator(minHeight: 2, color: UbColors.cyan),

            Expanded(
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: UbColors.cyan),
                          SizedBox(height: 12),
                          Text('Memuat Temuan & Kaizen Safety dari Server...', style: TextStyle(fontSize: 12.5, color: UbColors.textMuted)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                        children: [
                          if (_syncError != null && _source == 'local') ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: UbColors.amber.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: UbColors.amber.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.cloud_off_rounded, size: 16, color: UbColors.amber),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Menampilkan cache lokal — tarik ke bawah atau ketuk ikon Sync untuk sambung ulang.',
                                      style: TextStyle(fontSize: 11, color: Colors.white70),
                                    ),
                                  ),
                                  TextButton(onPressed: _load, child: const Text('Coba Lagi', style: TextStyle(fontSize: 11))),
                                ],
                              ),
                            ),
                          ],

                          // 4 KPI Summary Cards (1:1 Next.js)
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: MediaQuery.of(context).size.width >= 680 ? 4 : 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.1,
                            children: [
                              _kpiCard('Total Temuan', '$cAll', Colors.white, _tab == 'temuan' && _statusFilter == 'all', () {
                                setState(() {
                                  _tab = 'temuan';
                                  _statusFilter = 'all';
                                });
                              }),
                              _kpiCard('Belum & Progres', '$cOpenCombined', UbColors.rose, _statusFilter == 'open_combined', () {
                                setState(() {
                                  _statusFilter = 'open_combined';
                                });
                              }),
                              _kpiCard('On Progres', '$cProgress', UbColors.amber, _statusFilter == 'progress', () {
                                setState(() {
                                  _statusFilter = 'progress';
                                });
                              }),
                              _kpiCard('Selesai / Display', '$cClosed', UbColors.emerald, _tab == 'kaizen' && _statusFilter == 'closed', () {
                                setState(() {
                                  _tab = 'kaizen';
                                  _statusFilter = 'closed';
                                });
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Tab Switcher (Daftar Temuan vs Kaizen Report)
                          Row(
                            children: [
                              Expanded(
                                child: _tabPill(
                                  active: _tab == 'temuan',
                                  icon: Icons.fact_check_rounded,
                                  label: 'Daftar Temuan ($cAll)',
                                  onTap: () => setState(() => _tab = 'temuan'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tabPill(
                                  active: _tab == 'kaizen',
                                  icon: Icons.auto_awesome_rounded,
                                  label: 'Kaizen Report ($cClosed Selesai)',
                                  onTap: () => setState(() => _tab = 'kaizen'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Month Filter + Kaizen Orientation Switcher (Horizontal vs Vertikal)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Month Switcher (`Semua Bulan` / `Per Bulan`)
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: UbColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _miniToggleBtn('Semua Bulan', _allMonths, () => setState(() => _allMonths = true)),
                                    _miniToggleBtn(
                                      'Per Bulan (${SafetyRiskMaster.formatBulanId(_selectedYm)})',
                                      !_allMonths,
                                      () => setState(() => _allMonths = false),
                                    ),
                                    if (!_allMonths) ...[
                                      InkWell(
                                        onTap: () => _shiftMonth(-1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 5),
                                          child: Icon(Icons.chevron_left_rounded, size: 18, color: UbColors.cyan),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _shiftMonth(1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 5),
                                          child: Icon(Icons.chevron_right_rounded, size: 18, color: UbColors.cyan),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Before–After Orientation Switcher (`Horizontal` vs `Vertikal`)
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: UbColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: UbColors.emerald.withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _miniToggleBtn(
                                      '↔ Horizontal',
                                      !_kaizenVertical,
                                      () => setState(() => _kaizenVertical = false),
                                      activeColor: UbColors.emerald,
                                    ),
                                    _miniToggleBtn(
                                      '↕ Vertikal',
                                      _kaizenVertical,
                                      () => setState(() => _kaizenVertical = true),
                                      activeColor: UbColors.emerald,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Filter, Status, Hazard, Shift & Sort Panel (1:1 Next.js)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: UbColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status filter chips
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _filterChip('Semua ($cAll)', _statusFilter == 'all', () => setState(() => _statusFilter = 'all')),
                                      const SizedBox(width: 6),
                                      _filterChip(
                                        'Belum & Progres ($cOpenCombined)',
                                        _statusFilter == 'open_combined',
                                        () => setState(() => _statusFilter = 'open_combined'),
                                        color: UbColors.rose,
                                      ),
                                      const SizedBox(width: 6),
                                      _filterChip(
                                        'Belum ($cOnlyOpen)',
                                        _statusFilter == 'open',
                                        () => setState(() => _statusFilter = 'open'),
                                        color: UbColors.rose,
                                      ),
                                      const SizedBox(width: 6),
                                      _filterChip(
                                        'On Progres ($cProgress)',
                                        _statusFilter == 'progress',
                                        () => setState(() => _statusFilter = 'progress'),
                                        color: UbColors.amber,
                                      ),
                                      const SizedBox(width: 6),
                                      _filterChip(
                                        'Selesai / Display ($cClosed)',
                                        _statusFilter == 'closed',
                                        () => setState(() => _statusFilter = 'closed'),
                                        color: UbColors.emerald,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) => setState(() => _search = v),
                                  style: const TextStyle(fontSize: 12.5),
                                  decoration: InputDecoration(
                                    hintText: 'Cari #no, temuan, thema, lokasi, PIC, proses, rekomendasi...',
                                    hintStyle: const TextStyle(fontSize: 12, color: UbColors.textMuted),
                                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                    suffixIcon: _search.isNotEmpty
                                        ? IconButton(
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              setState(() => _search = '');
                                            },
                                            icon: const Icon(Icons.close_rounded, size: 16),
                                          )
                                        : null,
                                    isDense: true,
                                    filled: true,
                                    fillColor: UbColors.bg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _filterChip('Semua Shift', _shiftFilter == 'all', () => setState(() => _shiftFilter = 'all')),
                                      const SizedBox(width: 6),
                                      _filterChip(
                                        'Shift Red',
                                        _shiftFilter == 'red',
                                        () => setState(() => _shiftFilter = 'red'),
                                        color: UbColors.rose,
                                      ),
                                      const SizedBox(width: 6),
                                      _filterChip(
                                        'Shift White',
                                        _shiftFilter == 'white',
                                        () => setState(() => _shiftFilter = 'white'),
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      // Sort Cycle Chip
                                      _filterChip(
                                        _sortLabel(_sortMode),
                                        _sortMode != 'open',
                                        () {
                                          const modes = ['open', 'new', 'risk', 'no_desc', 'old'];
                                          final next = modes[(modes.indexOf(_sortMode) + 1) % modes.length];
                                          setState(() => _sortMode = next);
                                        },
                                        color: UbColors.amber,
                                      ),
                                      const SizedBox(width: 8),
                                      // Hazard Cycle Chip
                                      _filterChip(
                                        _hazardFilter == null
                                            ? 'Semua Hazard'
                                            : 'Hazard: ${SafetyRiskMaster.hazards[_hazardFilter!]}',
                                        _hazardFilter != null,
                                        () {
                                          setState(() {
                                            if (_hazardFilter == null) {
                                              _hazardFilter = 0;
                                            } else if (_hazardFilter! < 3) {
                                              _hazardFilter = _hazardFilter! + 1;
                                            } else {
                                              _hazardFilter = null;
                                            }
                                          });
                                        },
                                        color: UbColors.amber,
                                      ),
                                      const SizedBox(width: 6),
                                      TextButton.icon(
                                        onPressed: _resetFilters,
                                        icon: const Icon(Icons.restart_alt_rounded, size: 15),
                                        label: const Text('Reset', style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_tab == 'kaizen')
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: UbColors.emerald.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: UbColors.emerald.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF6EE7B7)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Mode Kaizen ${_kaizenVertical ? "Vertikal (Atas–Bawah)" : "Horizontal (Kiri–Kanan)"} · Ketuk "Lihat Kertas Kaizen" untuk kanvas A4 penuh.',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6EE7B7)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Items List
                          if (items.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: UbColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.assignment_outlined, size: 34, color: UbColors.textMuted),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tidak ada data yang sesuai dengan filter ini.',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: _resetFilters,
                                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                                    label: const Text('Tampilkan Semua Bulan & Reset Filter'),
                                  ),
                                ],
                              ),
                            )
                          else if (_tab == 'temuan')
                            ...items.map((f) => _buildTemuanDetailCard(f, items))
                          else
                            ...items.map((f) => _buildKaizenBeforeAfterCard(f, items)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel(String mode) {
    switch (mode) {
      case 'new':
        return 'Urut: Terbaru';
      case 'old':
        return 'Urut: Terlama';
      case 'risk':
        return 'Urut: Risiko Tertinggi';
      case 'no_desc':
        return 'Urut: #No Terbesar';
      default:
        return 'Urut: Belum Selesai';
    }
  }

  Widget _miniToggleBtn(String label, bool active, VoidCallback onTap, {Color activeColor = UbColors.cyan}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: active ? UbColors.bg : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? UbColors.cyan.withValues(alpha: 0.12) : UbColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? UbColors.cyan.withValues(alpha: 0.5) : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: UbColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabPill({
    required bool active,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : UbColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? Colors.white : Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: active ? UbColors.bg : UbColors.textMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: active ? UbColors.bg : Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap, {Color color = UbColors.cyan}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.22) : UbColors.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? color.withValues(alpha: 0.7) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? Colors.white : UbColors.textMuted),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: DAFTAR TEMUAN PROBLEM CARD (1:1 Next.js + BEFORE & AFTER PHOTOS)
  // ===========================================================================
  Widget _buildTemuanDetailCard(SafetyFinding f, List<SafetyFinding> currentList) {
    final statusColor = f.status == 'closed' ? UbColors.emerald : (f.status == 'progress' ? UbColors.amber : UbColors.rose);
    final statusText = SafetyRiskMaster.statusLabels[f.status] ?? f.status;
    final delta = f.riskDelta;
    final rankDown = SafetyRiskMaster.isRankDown(f.before.effectiveRank, f.after.effectiveRank);

    final beforePhotoTile = _buildPhotoCardTile(
      photoUrl: f.resolvedPhoto,
      badge: 'BEFORE',
      caption: f.caption,
      findingNo: f.no,
      isAfter: false,
      onEmptyTap: () => _openEditAndReturn(f),
      emptyLabel: '+ Foto Before',
    );
    final afterPhotoTile = _buildPhotoCardTile(
      photoUrl: f.resolvedPhotoAfter,
      badge: 'AFTER',
      caption: f.cm.isNotEmpty ? f.cm : f.theme,
      findingNo: f.no,
      isAfter: true,
      onEmptyTap: () => _openEditAndReturn(f, kaizenMode: true),
      emptyLabel: '+ Foto After / Kaizen',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Metadata Badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _badge('#${f.no}', UbColors.cyan),
              if (f.foundAt.isNotEmpty) _badge(f.foundAt, Colors.white70),
              _badge(
                f.shift == 'red' ? 'Shift Red' : 'Shift White',
                f.shift == 'red' ? UbColors.rose : Colors.white,
              ),
              _badge(statusText, statusColor),
              _badge(
                '${f.location}${f.process.isNotEmpty ? " · ${f.process}" : ""}',
                UbColors.cyan,
              ),
              _badge('PIC: ${f.pic.isEmpty ? "-" : f.pic}', UbColors.amber),
              if (f.hasKaizenReport) _badge('✓ Kaizen Siap', UbColors.emerald),
            ],
          ),
          const SizedBox(height: 10),

          // Problem Title
          const Text(
            'PROBLEM (TEMUAN BAHAYA):',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: UbColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            f.caption.isEmpty ? '(Tanpa judul temuan)' : f.caption,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3),
          ),
          const SizedBox(height: 10),

          // BEFORE & AFTER Photo Comparison (Horizontal or Vertical)
          _kaizenVertical
              ? Column(
                  children: [
                    beforePhotoTile,
                    const SizedBox(height: 8),
                    afterPhotoTile,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: beforePhotoTile),
                    const SizedBox(width: 8),
                    Expanded(child: afterPhotoTile),
                  ],
                ),
          const SizedBox(height: 10),

          // Hazard Condition (4 Categories + Sources)
          _buildHazardConditionBox(f),
          const SizedBox(height: 10),

          // Risk Assessment BEFORE vs AFTER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDetailedRiskBox('RISK BEFORE', f.before, UbColors.rose)),
              const SizedBox(width: 8),
              Expanded(child: _buildDetailedRiskBox('RISK AFTER', f.after, UbColors.emerald)),
            ],
          ),

          if (delta != null && (rankDown || delta.diff > 0)) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: UbColors.emerald.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: UbColors.emerald.withValues(alpha: 0.35)),
              ),
              child: Text(
                rankDown
                    ? '▼ RANK DOWN: ${f.before.effectiveRank} (${delta.beforePt}pt) ➔ ${f.after.effectiveRank} (${delta.afterPt}pt)'
                    : '▼ Risiko turun ${delta.diff} pt (${delta.pct}%)',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7)),
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Recommendation & Countermeasure (1:1 Next.js)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: UbColors.bg.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RECOMMENDATION (STANDAR K3)',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: UbColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.standard.isEmpty ? 'Belum ada standar ditentukan' : f.standard,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: f.standard.isEmpty ? UbColors.textMuted : Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: UbColors.emerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: UbColors.emerald.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'COUNTERMEASURE (AFTER)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF6EE7B7)),
                            ),
                          ),
                          if (f.date.isNotEmpty)
                            Text(
                              f.date,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF6EE7B7)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.cm.isEmpty ? 'Belum ada tindakan tercatat' : f.cm,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: f.cm.isEmpty ? UbColors.textMuted : Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Action Row
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _actionBtn(
                Icons.description_rounded,
                'Lihat Kertas Kaizen',
                UbColors.cyan,
                () => _openKaizenPaper(f, currentList),
              ),
              _actionBtn(
                Icons.auto_awesome_rounded,
                f.hasKaizenReport ? 'Edit Kaizen' : 'Buat Kaizen',
                UbColors.emerald,
                () => _openEditAndReturn(f, kaizenMode: true),
              ),
              _actionBtn(
                Icons.edit_rounded,
                'Edit Temuan',
                Colors.white70,
                () => _openEditAndReturn(f),
              ),
              if (f.status != 'progress' && f.status != 'closed')
                _actionBtn(
                  Icons.play_arrow_rounded,
                  'On Progres',
                  UbColors.amber,
                  () => _quickStatus(f, 'progress'),
                ),
              if (f.status != 'closed')
                _actionBtn(
                  Icons.check_circle_rounded,
                  'Selesai',
                  UbColors.emerald,
                  () => _quickStatus(f, 'closed'),
                ),
              _actionBtn(
                Icons.delete_outline_rounded,
                'Hapus',
                UbColors.rose,
                () => _confirmDelete(f),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: KAIZEN REPORT BEFORE–AFTER CARD (SUPPORTS HORIZONTAL & VERTICAL!)
  // ===========================================================================
  Widget _buildKaizenBeforeAfterCard(SafetyFinding f, List<SafetyFinding> currentList) {
    final isClosed = f.status == 'closed';
    final isProgress = f.status == 'progress';
    final statusColor = isClosed ? UbColors.emerald : (isProgress ? UbColors.amber : UbColors.rose);
    final statusLabel = SafetyRiskMaster.statusLabels[f.status] ?? f.status;
    final tag = SafetyRiskMaster.kaizenTag(f.no, 'S');
    final delta = f.riskDelta;
    final rankDown = SafetyRiskMaster.isRankDown(f.before.effectiveRank, f.after.effectiveRank);

    final beforeBlock = _buildKaizenHalfPanel(
      label: 'BEFORE (SEBELUM)',
      photoUrl: f.resolvedPhoto,
      description: f.caption.isEmpty ? '(Uraian temuan kosong)' : f.caption,
      meta: 'Ditemukan: ${f.foundAt.isEmpty ? "-" : f.foundAt} · ${SafetyRiskMaster.hazards[f.hazard]}',
      risk: f.before,
      isAfter: false,
      findingNo: f.no,
      onEmptyPhotoTap: () => _openEditAndReturn(f, kaizenMode: true),
    );

    final afterBlock = _buildKaizenHalfPanel(
      label: 'AFTER (SESUDAH KAIZEN)',
      photoUrl: f.resolvedPhotoAfter,
      description: f.cm.isNotEmpty
          ? f.cm
          : (f.standard.isNotEmpty ? f.standard : '(Belum ada uraian penanggulangan / foto After)'),
      meta: 'PIC: ${f.pic.isEmpty ? "-" : f.pic}${f.closedAt.isNotEmpty ? " · Selesai ${f.closedAt}" : (f.date.isNotEmpty ? " · ${f.date}" : "")}',
      risk: f.after,
      isAfter: true,
      findingNo: f.no,
      onEmptyPhotoTap: () => _openEditAndReturn(f, kaizenMode: true),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isClosed ? UbColors.emerald.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Kaizen Tag, Status, Display Indicator
          Row(
            children: [
              _badge(tag.isNotEmpty ? tag : '#${f.no}', UbColors.cyan),
              const SizedBox(width: 6),
              _badge(statusLabel, statusColor),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isClosed ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: (isClosed ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isClosed ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 12,
                      color: isClosed ? const Color(0xFF6EE7B7) : UbColors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isClosed ? 'Tampil di Display' : 'Draft (Perlu Selesai)',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isClosed ? const Color(0xFF6EE7B7) : UbColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // THEMA KAIZEN
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: UbColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THEMA : ${(f.theme.trim().isNotEmpty ? f.theme : f.caption).toUpperCase()}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white, height: 1.25),
                ),
                const SizedBox(height: 3),
                Text(
                  '${f.location}${f.process.isNotEmpty ? " · ${f.process}" : ""} · Bulan: ${SafetyRiskMaster.formatBulanId(f.closedAt.isNotEmpty ? f.closedAt : f.foundAt)} · PIC: ${f.pic.isEmpty ? "-" : f.pic}',
                  style: const TextStyle(fontSize: 10.5, color: UbColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // BEFORE vs AFTER COMPARISON (Horizontal Side-by-Side OR Vertical Top-Bottom!)
          if (_kaizenVertical)
            Column(
              children: [
                beforeBlock,
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_downward_rounded, size: 16, color: UbColors.emerald),
                      const SizedBox(width: 6),
                      Text(
                        delta != null
                            ? 'IMPROVEMENT: ${f.before.effectiveRank} (${delta.beforePt}pt) ➔ ${f.after.effectiveRank} (${delta.afterPt}pt)'
                            : 'PERBAIKAN KAIZEN (BEFORE ➔ AFTER)',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF6EE7B7)),
                      ),
                    ],
                  ),
                ),
                afterBlock,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: beforeBlock),
                const Padding(
                  padding: EdgeInsets.only(top: 68, left: 4, right: 4),
                  child: Icon(Icons.arrow_forward_rounded, size: 18, color: UbColors.emerald),
                ),
                Expanded(child: afterBlock),
              ],
            ),

          // RESULT + RANK DOWN SUMMARY
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: UbColors.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: UbColors.emerald.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'RESULT : ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6EE7B7)),
                    ),
                    Expanded(
                      child: Text(
                        f.result.trim().isNotEmpty ? f.result : (f.cm.trim().isNotEmpty ? f.cm : 'Belum diisi'),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (delta != null && (rankDown || delta.diff > 0)) ...[
                  const SizedBox(height: 4),
                  Text(
                    '✓ Risk Rank ${f.before.effectiveRank} (${delta.beforePt}pt) ➔ ${f.after.effectiveRank} (${delta.afterPt}pt) · Turun ${delta.diff} pt (${delta.pct}%)',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7)),
                  ),
                ],
              ],
            ),
          ),

          // Footer Actions
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: UbColors.cyan,
                    foregroundColor: UbColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openKaizenPaper(f, currentList),
                  icon: const Icon(Icons.description_rounded, size: 16),
                  label: const Text(
                    'Lihat Kertas Kaizen',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openEditAndReturn(f, kaizenMode: true),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text('Edit Kaizen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (!isClosed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (!isProgress) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: UbColors.amber,
                        side: BorderSide(color: UbColors.amber.withValues(alpha: 0.45)),
                      ),
                      onPressed: _busy ? null : () => _quickStatus(f, 'progress'),
                      child: const Text('Ubah ke On Progres', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6EE7B7),
                      side: BorderSide(color: UbColors.emerald.withValues(alpha: 0.5)),
                    ),
                    onPressed: _busy ? null : () => _quickStatus(f, 'closed'),
                    child: const Text('✓ Tandai Selesai (Display)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKaizenHalfPanel({
    required String label,
    required String photoUrl,
    required String description,
    required String meta,
    required SafetyRisk risk,
    required bool isAfter,
    required String findingNo,
    required VoidCallback onEmptyPhotoTap,
  }) {
    final accent = isAfter ? UbColors.emerald : UbColors.rose;
    final rk = risk.effectiveRank;
    final pt = risk.totalPoints;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: UbColors.bg.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge + Risk Rank
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAfter ? 'AFTER' : 'BEFORE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isAfter ? UbColors.bg : Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Rank ${rk.isEmpty ? "-" : rk} (${pt ?? "-"}pt)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isAfter ? const Color(0xFF6EE7B7) : const Color(0xFFFDA4AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Photo Frame
          InkWell(
            onTap: photoUrl.isNotEmpty
                ? () => showSafetyPhotoLightbox(
                      context,
                      url: photoUrl,
                      label: '${isAfter ? "AFTER" : "BEFORE"} · #$findingNo',
                      caption: description,
                      isAfter: isAfter,
                    )
                : onEmptyPhotoTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: _kaizenVertical ? 175 : 132,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, size: 28, color: UbColors.textMuted),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAfter ? Icons.add_photo_alternate_outlined : Icons.image_not_supported_outlined,
                            size: 24,
                            color: UbColors.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAfter ? '+ Tambah Foto After' : 'Belum ada Foto Before',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: UbColors.textMuted),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: UbColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCardTile({
    required String photoUrl,
    required String badge,
    required String caption,
    required String findingNo,
    required bool isAfter,
    required VoidCallback onEmptyTap,
    required String emptyLabel,
  }) {
    final accent = isAfter ? UbColors.emerald : UbColors.rose;
    return InkWell(
      onTap: photoUrl.isNotEmpty
          ? () => showSafetyPhotoLightbox(
                context,
                url: photoUrl,
                label: '$badge · #$findingNo',
                caption: caption,
                isAfter: isAfter,
              )
          : onEmptyTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 125,
        width: double.infinity,
        decoration: BoxDecoration(
          color: UbColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: photoUrl.isNotEmpty ? accent.withValues(alpha: 0.45) : Colors.white12,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl.isNotEmpty)
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 28, color: UbColors.textMuted),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 22, color: accent),
                    const SizedBox(height: 4),
                    Text(
                      emptyLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isAfter ? UbColors.bg : Colors.white,
                  ),
                ),
              ),
            ),
            if (photoUrl.isNotEmpty)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 3),
                      Text('Perbesar', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardConditionBox(SafetyFinding f) {
    final activeSources = f.sources
        .where((i) => i >= 0 && i < SafetyRiskMaster.flatSources.length)
        .map((i) => SafetyRiskMaster.flatSources[i])
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: UbColors.bg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HAZARD CONDITION & SOURCE K3',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: UbColors.amber),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(SafetyRiskMaster.hazards.length, (i) {
              final active = f.hazard == i;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? UbColors.amber.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: active ? UbColors.amber : Colors.white10),
                ),
                child: Text(
                  '${active ? "● " : "○ "}${SafetyRiskMaster.hazards[i]}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                    color: active ? Colors.white : UbColors.textMuted,
                  ),
                ),
              );
            }),
          ),
          if (activeSources.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Sumber: ${activeSources.join(" · ")}',
              style: const TextStyle(fontSize: 10.5, color: UbColors.cyan, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedRiskBox(String title, SafetyRisk r, Color color) {
    final pt = r.totalPoints;
    final rank = r.effectiveRank;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: UbColors.bg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: color)),
              if (r.code.isNotEmpty)
                Text(
                  'STOP 6: ${r.code}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white70),
                ),
            ],
          ),
          if (r.accident.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              r.accident,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  pt != null
                      ? '${r.injury.point ?? 0}+${r.frequency.point ?? 0}+${r.countermeasure.point ?? 0} = $pt pt'
                      : 'Belum dinilai',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: rank.isNotEmpty ? color : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rank.isEmpty ? '–' : rank,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: rank.isNotEmpty ? (color == UbColors.emerald ? UbColors.bg : Colors.white) : UbColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}
