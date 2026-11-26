import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/chokotei_models.dart';
import '../../models/quality_daily_models.dart';
import '../../services/chokotei_store.dart';
import 'chokotei_manual_screen.dart';

class ChokoteiAnalyticsScreen extends StatefulWidget {
  const ChokoteiAnalyticsScreen({super.key});

  @override
  State<ChokoteiAnalyticsScreen> createState() => _ChokoteiAnalyticsScreenState();
}

class _ChokoteiAnalyticsScreenState extends State<ChokoteiAnalyticsScreen> {
  String _ym = QualityMath.wibYm();
  String _shift = 'RED'; // RED | WHITE
  String _catFilter = 'ALL'; // ALL | INT | EXT
  String _statusFilter = 'ALL'; // ALL | open | in_progress | solved
  String _search = '';
  bool _loading = true;
  bool _fromServer = false;
  List<ChokoteiIssue> _issues = const [];
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
    final res = await ChokoteiStore.instance.fetchChokoteiList(_ym, _shift);
    if (!mounted) return;
    setState(() {
      _issues = res.issues;
      _fromServer = res.fromServer;
      _loading = false;
    });
  }

  Future<void> _openFollowupModal(ChokoteiIssue issue) async {
    var status = issue.actionStatus;
    final planCtrl = TextEditingController(text: issue.actionPlan);
    final picCtrl = TextEditingController(text: issue.actionPic.isNotEmpty ? issue.actionPic : 'SLAMET.H');

    try {
      final saved = await showModalBottomSheet<bool>(
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
                  const Text('Update Kaizen & Action Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: UbColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: UbColors.rose.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${issue.machine} · -${issue.lossUnits} U (${issue.delayMin}m)', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.amber)),
                        const SizedBox(height: 4),
                        Text(issue.problem, style: const TextStyle(fontSize: 12.5, color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Status Kaizen', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _stBtn('open', 'Open', UbColors.rose, status == 'open', () => setM(() => status = 'open')),
                      const SizedBox(width: 6),
                      _stBtn('in_progress', 'Proses', UbColors.amber, status == 'in_progress', () => setM(() => status = 'in_progress')),
                      const SizedBox(width: 6),
                      _stBtn('solved', 'Solved', UbColors.emerald, status == 'solved', () => setM(() => status = 'solved')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: planCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Kaizen Action Plan (Permanen)',
                      hintText: 'Preventive Maintenance / Yokoten...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: ['Cleaning & kalibrasi sensor', 'Ganti sparepart aus', 'Yokoten stasiun serupa'].map((p) {
                      return ActionChip(
                        label: Text('+ $p', style: const TextStyle(fontSize: 10)),
                        onPressed: () {
                          final cur = planCtrl.text.trim();
                          planCtrl.text = cur.isEmpty ? p : '$cur. $p';
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: picCtrl,
                    decoration: const InputDecoration(labelText: 'PIC Eksekutor', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Simpan Tindak Lanjut', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (saved == true) {
        final res = await ChokoteiStore.instance.saveFollowup(
          issueId: issue.id,
          actionStatus: status,
          actionPlan: planCtrl.text.trim(),
          actionPic: picCtrl.text.trim(),
        );
        setState(() {
          issue.actionStatus = status;
          issue.actionPlan = planCtrl.text.trim();
          issue.actionPic = picCtrl.text.trim();
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      }
    } finally {
      planCtrl.dispose();
      picCtrl.dispose();
    }
  }

  Widget _stBtn(String key, String label, Color color, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? color : UbColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? color : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: active ? Colors.white : UbColors.textMuted)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ChokoteiMath.computeStats(_issues);
    final pareto = ChokoteiMath.computePareto(_issues);
    final vitalFew = pareto.where((m) => m.isVitalFew).toList();
    final q = _search.trim().toLowerCase();

    final filtered = _issues.where((r) {
      if (_catFilter != 'ALL' && r.category != _catFilter) return false;
      if (_statusFilter != 'ALL' && r.actionStatus != _statusFilter) return false;
      if (q.isEmpty) return true;
      return '${r.machine} ${r.problem} ${r.countermeasure} ${r.actionPic} ${r.actionPlan}'.toLowerCase().contains(q);
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
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
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
                            const Text('Chokotei & Pareto', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (_fromServer ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(_fromServer ? 'LIVE' : 'LOKAL', style: TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w900, color: _fromServer ? UbColors.emerald : UbColors.amber)),
                            ),
                          ],
                        ),
                        const Text('Pareto 80/20 Mesin & Action Plan PIC', style: TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UbColors.cyan,
                      side: BorderSide(color: UbColors.cyan.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ChokoteiManualScreen()),
                    ),
                    child: const Text('Manual', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: UbColors.amber),
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
                          // Month Nav + Shift Toggle
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: UbColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        setState(() => _ym = QualityMath.shiftYm(_ym, -1));
                                        _load();
                                      },
                                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                    ),
                                    Text(QualityMath.formatYmLabel(_ym), style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900)),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        setState(() => _ym = QualityMath.shiftYm(_ym, 1));
                                        _load();
                                      },
                                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _shiftChip('RED', UbColors.rose, Colors.white),
                              const SizedBox(width: 6),
                              _shiftChip('WHITE', Colors.white, UbColors.bg),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 4 KPI Cards
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.1,
                            children: [
                              _kpiBox('Total Kasus', '${stats.totalRecords}', 'INT ${stats.intCount} · EXT ${stats.extCount}', Colors.white),
                              _kpiBox('Total Unit Loss', '-${stats.totalLoss} U', 'Minus output stop', UbColors.rose),
                              _kpiBox('Total Waktu Stop', '${stats.totalDelay} m', '${(stats.totalDelay / 60).toStringAsFixed(1)} jam', UbColors.cyan),
                              _kpiBox('Kaizen Solved', '${stats.solvedPercent}%', '${stats.solvedCount} OK · ${stats.openCount} Open', UbColors.emerald),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Vital Few 80/20 Alert
                          if (vitalFew.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: UbColors.amber.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: UbColors.amber.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PRIORITAS KAIZEN (VITAL FEW 80/20)', style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.amber)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fokus perbaikan pada mesin: ${vitalFew.take(3).map((m) => m.machine).join(", ")} untuk menekan hingga 80% unit loss.',
                                    style: const TextStyle(fontSize: 11.5, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Machine Ranking Pareto Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: UbColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Ranking Mesin & Pareto 80/20', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white)),
                                    Text('${pareto.length} Mesin', style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (pareto.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: Text('Belum ada problem mesin di bulan ini.', style: TextStyle(fontSize: 12, color: UbColors.textMuted))),
                                  )
                                else
                                  ...pareto.take(6).toList().asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final m = entry.value;
                                    final maxL = pareto.first.totalLoss > 0 ? pareto.first.totalLoss : 1;
                                    final frac = (m.totalLoss / maxL).clamp(0.06, 1.0);
                                    return InkWell(
                                      onTap: () {
                                        _searchCtrl.text = m.machine;
                                        setState(() => _search = m.machine);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text('#${idx + 1} ${m.machine}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                                                const SizedBox(width: 6),
                                                if (m.isVitalFew)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(color: UbColors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                                                    child: const Text('80% Vital', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: UbColors.amber)),
                                                  ),
                                                const Spacer(),
                                                Text('-${m.totalLoss}U · ${m.totalDelay}m · ${m.cumLossPercent}%', style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w800, color: UbColors.rose)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(99),
                                              child: LinearProgressIndicator(
                                                value: frac,
                                                minHeight: 7,
                                                backgroundColor: UbColors.bg,
                                                valueColor: AlwaysStoppedAnimation<Color>(m.isVitalFew ? UbColors.rose : UbColors.cyan),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Search & Filter Bar
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _search = v),
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Cari mesin, problem, PIC...',
                              hintStyle: const TextStyle(fontSize: 12, color: UbColors.textMuted),
                              prefixIcon: const Icon(Icons.search_rounded, size: 17),
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
                              fillColor: UbColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...['ALL', 'INT', 'EXT'].map((c) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(c, style: const TextStyle(fontSize: 10.5)),
                                        selected: _catFilter == c,
                                        onSelected: (_) => setState(() => _catFilter = c),
                                      ),
                                    )),
                                ...['ALL', 'open', 'in_progress', 'solved'].map((st) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(st == 'ALL' ? 'Semua Status' : (st == 'in_progress' ? 'Proses' : st), style: const TextStyle(fontSize: 10.5)),
                                        selected: _statusFilter == st,
                                        onSelected: (_) => setState(() => _statusFilter = st),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Issue Cards
                          if (filtered.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                              child: const Center(child: Text('Tidak ada problem yang sesuai filter.', style: TextStyle(fontSize: 12.5, color: UbColors.textMuted))),
                            )
                          else
                            ...filtered.map(_buildIssueCard),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shiftChip(String val, Color bg, Color fg) {
    final active = _shift == val;
    return InkWell(
      onTap: () {
        if (_shift != val) {
          setState(() => _shift = val);
          _load();
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? bg : UbColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? bg : Colors.white12),
        ),
        child: Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: active ? fg : UbColors.textMuted)),
      ),
    );
  }

  Widget _kpiBox(String label, String val, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: UbColors.textMuted)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: UbColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildIssueCard(ChokoteiIssue r) {
    final stColor = r.actionStatus == 'solved' ? UbColors.emerald : (r.actionStatus == 'in_progress' ? UbColors.amber : UbColors.rose);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: UbColors.amber.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
                child: Text(r.machine, style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.amber)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: (r.category == 'EXT' ? UbColors.amber : UbColors.rose).withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
                child: Text(r.category, style: TextStyle(fontFamily: 'monospace', fontSize: 9.5, fontWeight: FontWeight.w900, color: r.category == 'EXT' ? UbColors.amber : UbColors.rose)),
              ),
              const SizedBox(width: 6),
              Text(r.tanggal, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: UbColors.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: stColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
                child: Text(r.actionStatus == 'in_progress' ? 'PROSES' : r.actionStatus.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: stColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(r.problem, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Loss: -${r.lossUnits} U · Stop: ${r.delayMin}m · PIC: ${r.actionPic.isEmpty ? "-" : r.actionPic}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
          if (r.actionPlan.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Plan: ${r.actionPlan}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF6EE7B7))),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: UbColors.cyan,
                side: BorderSide(color: UbColors.cyan.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
              ),
              onPressed: () => _openFollowupModal(r),
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: const Text('Update Action Plan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
