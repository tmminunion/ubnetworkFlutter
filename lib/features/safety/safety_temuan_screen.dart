import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';
import '../../models/safety_finding_models.dart';
import '../../services/safety_findings_store.dart';
import 'safety_temuan_form_modal.dart';

class SafetyTemuanScreen extends StatefulWidget {
  const SafetyTemuanScreen({super.key});

  @override
  State<SafetyTemuanScreen> createState() => _SafetyTemuanScreenState();
}

class _SafetyTemuanScreenState extends State<SafetyTemuanScreen> {
  List<SafetyFinding> _all = const [];
  bool _loading = true;
  String _tab = 'temuan'; // temuan | kaizen
  String _statusFilter = 'all'; // all | open_combined | open | progress | closed
  String _shiftFilter = 'all'; // all | red | white
  int? _hazardFilter; // null or 0..3
  String _sortMode = 'open'; // open | new | risk | no_desc
  String _search = '';
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
    final items = await SafetyFindingsStore.instance.listFindings();
    if (!mounted) return;
    setState(() {
      _all = items;
      _loading = false;
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
      await SafetyFindingsStore.instance.upsertFinding(res);
      await _load();
    }
  }

  Future<void> _openEdit(SafetyFinding item, {bool kaizenMode = false}) async {
    final res = await showSafetyTemuanModal(context, initial: item, kaizenMode: kaizenMode);
    if (res != null) {
      await SafetyFindingsStore.instance.upsertFinding(res);
      await _load();
    }
  }

  Future<void> _quickStatus(SafetyFinding item, String nextStatus) async {
    final updated = item.copyWith(status: nextStatus);
    await SafetyFindingsStore.instance.upsertFinding(updated);
    await _load();
  }

  Future<void> _confirmDelete(SafetyFinding item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UbColors.surface,
        title: Text('Hapus Temuan #${item.no}?'),
        content: Text('Temuan "${item.caption}" beserta data Kaizen akan dihapus dari perangkat.'),
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
      await SafetyFindingsStore.instance.deleteFinding(item.id);
      await _load();
    }
  }

  void _resetFilters() {
    _searchCtrl.clear();
    setState(() {
      _statusFilter = 'all';
      _shiftFilter = 'all';
      _hazardFilter = null;
      _sortMode = 'open';
      _search = '';
    });
  }

  List<SafetyFinding> get _filtered {
    final q = _search.trim().toLowerCase();
    final list = _all.where((f) {
      if (_tab == 'kaizen' && !f.hasKaizenReport && f.status != 'closed') return false;
      if (_shiftFilter != 'all' && f.shift != _shiftFilter) return false;
      if (_hazardFilter != null && f.hazard != _hazardFilter) return false;
      if (_statusFilter == 'open_combined' && f.status == 'closed') return false;
      if (_statusFilter == 'open' && f.status != 'open') return false;
      if (_statusFilter == 'progress' && f.status != 'progress') return false;
      if (_statusFilter == 'closed' && f.status != 'closed') return false;
      if (q.isNotEmpty) {
        final hay = '${f.no} ${f.caption} ${f.location} ${f.process} ${f.pic} ${f.standard} ${f.cm} ${f.theme}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    int statusRank(String s) => s == 'open' ? 0 : (s == 'progress' ? 1 : 2);
    list.sort((a, b) {
      if (_sortMode == 'open') {
        final d = statusRank(a.status).compareTo(statusRank(b.status));
        if (d != 0) return d;
      } else if (_sortMode == 'risk') {
        final ra = a.before.totalPoints ?? -1;
        final rb = b.before.totalPoints ?? -1;
        if (rb != ra) return rb.compareTo(ra);
      } else if (_sortMode == 'no_desc') {
        final na = int.tryParse(a.no) ?? 0;
        final nb = int.tryParse(b.no) ?? 0;
        if (nb != na) return nb.compareTo(na);
      }
      return b.foundAt.compareTo(a.foundAt);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cAll = _all.length;
    final cOnlyOpen = _all.where((e) => e.status == 'open').length;
    final cProgress = _all.where((e) => e.status == 'progress').length;
    final cOpenCombined = cOnlyOpen + cProgress;
    final cClosed = _all.where((e) => e.status == 'closed').length;
    final items = _filtered;

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // macOS Top Bar
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
                    child: const Icon(Icons.assignment_late_rounded, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Temuan Safety', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('List Up Problem & Kaizen Report', style: TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: UbColors.cyan,
                      foregroundColor: UbColors.bg,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _openCreate,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Temuan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
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
                          // 4 KPI Summary Cards
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: MediaQuery.of(context).size.width >= 680 ? 4 : 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.05,
                            children: [
                              _kpiCard('Total Temuan', '$cAll', Colors.white, _tab == 'temuan' && _statusFilter == 'all', () {
                                setState(() {
                                  _tab = 'temuan';
                                  _statusFilter = 'all';
                                });
                              }),
                              _kpiCard('Belum & Proses', '$cOpenCombined', UbColors.rose, _tab == 'temuan' && _statusFilter == 'open_combined', () {
                                setState(() {
                                  _tab = 'temuan';
                                  _statusFilter = 'open_combined';
                                });
                              }),
                              _kpiCard('Dalam Proses', '$cProgress', UbColors.amber, _tab == 'temuan' && _statusFilter == 'progress', () {
                                setState(() {
                                  _tab = 'temuan';
                                  _statusFilter = 'progress';
                                });
                              }),
                              _kpiCard('Selesai / Kaizen', '$cClosed', UbColors.emerald, _tab == 'kaizen' || _statusFilter == 'closed', () {
                                setState(() {
                                  _tab = 'kaizen';
                                  _statusFilter = 'all';
                                });
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Tab Switcher (Temuan vs Kaizen Report)
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
                                  label: 'Kaizen Report ($cClosed)',
                                  onTap: () => setState(() => _tab = 'kaizen'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Filter & Search Panel
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
                                TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) => setState(() => _search = v),
                                  style: const TextStyle(fontSize: 12.5),
                                  decoration: InputDecoration(
                                    hintText: 'Cari temuan, lokasi, PIC, proses, rekomendasi...',
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
                                      _filterChip('Shift Red', _shiftFilter == 'red', () => setState(() => _shiftFilter = 'red'), color: UbColors.rose),
                                      const SizedBox(width: 6),
                                      _filterChip('Shift White', _shiftFilter == 'white', () => setState(() => _shiftFilter = 'white'), color: Colors.white),
                                      const SizedBox(width: 10),
                                      _filterChip('Risiko Tertinggi', _sortMode == 'risk', () => setState(() => _sortMode = _sortMode == 'risk' ? 'open' : 'risk'), color: UbColors.amber),
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

                          // Items List
                          if (items.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: UbColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.assignment_outlined, size: 34, color: UbColors.textMuted),
                                  SizedBox(height: 8),
                                  Text('Tidak ada temuan yang cocok dengan filter ini.', style: TextStyle(fontSize: 13, color: UbColors.textMuted)),
                                ],
                              ),
                            )
                          else
                            ...items.map(_buildFindingCard),
                        ],
                      ),
                    ),
            ),
          ],
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
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: UbColors.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _tabPill({required bool active, required IconData icon, required String label, required VoidCallback onTap}) {
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

  Widget _buildFindingCard(SafetyFinding f) {
    final statusColor = f.status == 'closed' ? UbColors.emerald : (f.status == 'progress' ? UbColors.amber : UbColors.rose);
    final statusText = SafetyRiskMaster.statusLabels[f.status] ?? f.status;
    final delta = f.riskDelta;
    final rankDown = SafetyRiskMaster.isRankDown(f.before.effectiveRank, f.after.effectiveRank);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Metadata Row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _badge('#${f.no}', UbColors.cyan),
              _badge(statusText, statusColor),
              _badge(f.shift == 'red' ? 'Shift Red' : 'Shift White', f.shift == 'red' ? UbColors.rose : Colors.white70),
              if (f.foundAt.isNotEmpty) _badge(f.foundAt, UbColors.textMuted),
              if (f.hasKaizenReport) _badge('Kaizen Siap', UbColors.emerald),
            ],
          ),
          const SizedBox(height: 10),

          // Problem Caption / Theme
          Text(
            _tab == 'kaizen' && f.theme.isNotEmpty ? f.theme : f.caption,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            '${f.location}${f.process.isNotEmpty ? " · ${f.process}" : ""} · PIC: ${f.pic.isEmpty ? "-" : f.pic} · Hazard: ${SafetyRiskMaster.hazards[f.hazard]}',
            style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted),
          ),
          const SizedBox(height: 10),

          // Risk Before vs After Side-by-Side
          Row(
            children: [
              Expanded(child: _riskMiniBox('RISK BEFORE', f.before, UbColors.rose)),
              const SizedBox(width: 8),
              Expanded(child: _riskMiniBox('RISK AFTER', f.after, UbColors.emerald)),
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

          if (f.cm.isNotEmpty || f.standard.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: UbColors.bg.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (f.standard.isNotEmpty)
                    Text('Standar: ${f.standard}', style: const TextStyle(fontSize: 11.5, color: UbColors.textPrimary)),
                  if (f.cm.isNotEmpty) ...[
                    if (f.standard.isNotEmpty) const SizedBox(height: 4),
                    Text('Penanggulangan: ${f.cm}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF6EE7B7))),
                  ],
                ],
              ),
            ),
          ],

          // Action Row
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _actionBtn(Icons.auto_awesome_rounded, 'Kaizen', UbColors.emerald, () => _openEdit(f, kaizenMode: true)),
              _actionBtn(Icons.edit_rounded, 'Edit', UbColors.cyan, () => _openEdit(f)),
              if (f.status == 'open')
                _actionBtn(Icons.play_arrow_rounded, 'Proses', UbColors.amber, () => _quickStatus(f, 'progress')),
              if (f.status != 'closed')
                _actionBtn(Icons.check_circle_rounded, 'Selesai', UbColors.emerald, () => _quickStatus(f, 'closed')),
              _actionBtn(Icons.delete_outline_rounded, 'Hapus', UbColors.rose, () => _confirmDelete(f)),
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
      child: Text(text, style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _riskMiniBox(String title, SafetyRisk r, Color color) {
    final pt = r.totalPoints;
    final rank = r.effectiveRank;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: UbColors.bg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: color)),
              if (r.code.isNotEmpty)
                Text('STOP 6: ${r.code}', style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pt != null ? '$pt pt' : 'Belum dinilai',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
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
