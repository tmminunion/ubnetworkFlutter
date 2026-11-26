import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/quality_daily_models.dart';
import '../../models/roster_attendance_models.dart';
import '../../services/roster_attendance_store.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _ym = QualityMath.wibYm();
  String _shift = 'WHITE'; // WHITE | RED
  String _tab = 'matrix'; // matrix | ranking | analytics
  String _search = '';
  bool _loading = true;
  bool _fromServer = false;
  List<MemberAttendanceRow> _members = const [];
  AttendanceSummaryKpi _kpi = const AttendanceSummaryKpi(
    avgAttendanceRate: 100,
    totalHadir: 0,
    totalSakit: 0,
    totalIzin: 0,
    totalCuti: 0,
    totalDinas: 0,
    totalAlpa: 0,
    totalAbsent: 0,
    perfectMembersCount: 0,
    totalMembers: 0,
  );
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
    final res = await RosterAttendanceStore.instance.fetchMonthlyAttendance(_ym, _shift);
    if (!mounted) return;
    setState(() {
      _members = res.members;
      _kpi = res.kpi;
      _fromServer = res.fromServer;
      _loading = false;
    });
  }

  ({String letter, Color color}) _badgeOf(String? status) {
    if (status == null || status.isEmpty) return (letter: '-', color: UbColors.textMuted);
    final low = status.toLowerCase();
    if (low.contains('sakit')) return (letter: 'S', color: UbColors.amber);
    if (low.contains('izin') || low.contains('ijin')) return (letter: 'I', color: const Color(0xFF38BDF8));
    if (low.contains('cuti')) return (letter: 'C', color: UbColors.purple);
    if (low.contains('dinas')) return (letter: 'D', color: const Color(0xFF818CF8));
    if (low.contains('alpa')) return (letter: 'A', color: UbColors.rose);
    return (letter: 'H', color: UbColors.emerald);
  }

  void _openMemberDetail(MemberAttendanceRow m) {
    final dim = QualityMath.daysInMonth(_ym);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('${m.role} · ${m.defaultPos} · Shift ${m.shift}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted)),
                    ],
                  ),
                ),
                Text('${m.attendanceRate}%', style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w900, color: UbColors.emerald)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniBox('H', '${m.hadirCount}', UbColors.emerald),
                _miniBox('S', '${m.sakitCount}', UbColors.amber),
                _miniBox('I', '${m.izinCount}', const Color(0xFF38BDF8)),
                _miniBox('C', '${m.cutiCount}', UbColors.purple),
                _miniBox('A', '${m.alpaCount}', UbColors.rose),
              ],
            ),
            const SizedBox(height: 12),
            Text('Kalender ${QualityMath.formatYmLabel(_ym)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: List.generate(dim, (i) {
                final d = i + 1;
                final key = '$_ym-${d.toString().padLeft(2, '0')}';
                final b = _badgeOf(m.history[key]);
                return Container(
                  width: 36,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: b.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: b.color.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    children: [
                      Text('$d', style: const TextStyle(fontSize: 8.5, color: UbColors.textMuted)),
                      Text(b.letter, style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: b.color)),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBox(String l, String v, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 5),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: UbColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
          child: Column(
            children: [
              Text(l, style: const TextStyle(fontSize: 9.5, color: UbColors.textMuted)),
              Text(v, style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w900, color: c)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final dim = QualityMath.daysInMonth(_ym);
    final q = _search.trim().toLowerCase();
    final filtered = _members.where((m) {
      if (q.isEmpty) return true;
      return '${m.name} ${m.noreg} ${m.defaultPos}'.toLowerCase().contains(q);
    }).toList();

    final topAbsentees = _members.where((m) => m.totalAbsent > 0).toList()
      ..sort((a, b) => b.totalAbsent.compareTo(a.totalAbsent));
    final perfectClub = _members.where((m) => m.totalAbsent == 0).toList();

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
                            const Text('Rekap Absensi Tim', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: (_fromServer ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                              child: Text(_fromServer ? 'LIVE' : 'LOKAL', style: TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w900, color: _fromServer ? UbColors.emerald : UbColors.amber)),
                            ),
                          ],
                        ),
                        Text('Shift $_shift · ${QualityMath.formatYmLabel(_ym)}', style: const TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: UbColors.emerald),
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
                                decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
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
                              _shiftChip('WHITE', Colors.white, UbColors.bg),
                              const SizedBox(width: 6),
                              _shiftChip('RED', UbColors.rose, Colors.white),
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
                            childAspectRatio: 2.05,
                            children: [
                              _kpiBox('Kehadiran', '${_kpi.avgAttendanceRate}%', 'Target 95%', _kpi.avgAttendanceRate >= 95 ? UbColors.emerald : UbColors.amber),
                              _kpiBox('Total Hadir', '${_kpi.totalHadir}', 'Man-Days', UbColors.cyan),
                              _kpiBox('Ketidakhadiran', '${_kpi.totalAbsent}', 'S:${_kpi.totalSakit} C:${_kpi.totalCuti} I:${_kpi.totalIzin}', UbColors.rose),
                              _kpiBox('Disiplin 100%', '${_kpi.perfectMembersCount}/${_kpi.totalMembers}', 'Nol absen', UbColors.amber),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 3 Tabs
                          Row(
                            children: [
                              _tabPill('matrix', 'Matriks 1–31', UbColors.cyan),
                              const SizedBox(width: 6),
                              _tabPill('ranking', 'Sering Absen', UbColors.rose),
                              const SizedBox(width: 6),
                              _tabPill('analytics', 'Distribusi', UbColors.emerald),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (_tab == 'matrix') ...[
                            TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _search = v),
                              style: const TextStyle(fontSize: 12.5),
                              decoration: InputDecoration(
                                hintText: 'Cari nama / NoReg / pos...',
                                hintStyle: const TextStyle(fontSize: 12, color: UbColors.textMuted),
                                prefixIcon: const Icon(Icons.search_rounded, size: 17),
                                isDense: true,
                                filled: true,
                                fillColor: UbColors.surface,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                              clipBehavior: Clip.antiAlias,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowHeight: 34,
                                  dataRowMinHeight: 42,
                                  dataRowMaxHeight: 46,
                                  columnSpacing: 8,
                                  horizontalMargin: 8,
                                  headingRowColor: WidgetStateProperty.all(UbColors.bg),
                                  columns: [
                                    const DataColumn(label: Text('Anggota', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900))),
                                    ...List.generate(dim, (i) => DataColumn(label: Text('${i + 1}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w800)))),
                                    const DataColumn(label: Text('Rate%', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.emerald))),
                                  ],
                                  rows: filtered.map((m) {
                                    return DataRow(
                                      onSelectChanged: (_) => _openMemberDetail(m),
                                      cells: [
                                        DataCell(
                                          SizedBox(
                                            width: 120,
                                            child: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                          ),
                                        ),
                                        ...List.generate(dim, (i) {
                                          final key = '$_ym-${(i + 1).toString().padLeft(2, '0')}';
                                          final b = _badgeOf(m.history[key]);
                                          return DataCell(
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(color: b.color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(5)),
                                              alignment: Alignment.center,
                                              child: Text(b.letter, style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: b.color)),
                                            ),
                                          );
                                        }),
                                        DataCell(
                                          Text(
                                            '${m.attendanceRate}%',
                                            style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: m.attendanceRate >= 95 ? UbColors.emerald : UbColors.amber),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ] else if (_tab == 'ranking') ...[
                            if (topAbsentees.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                                child: const Center(child: Text('Luar biasa! Tidak ada personel yang absen bulan ini.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: UbColors.emerald))),
                              )
                            else
                              ...topAbsentees.asMap().entries.map((e) {
                                final m = e.value;
                                return ListTile(
                                  onTap: () => _openMemberDetail(m),
                                  tileColor: UbColors.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  leading: CircleAvatar(backgroundColor: UbColors.rose.withValues(alpha: 0.2), child: Text('#${e.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.rose))),
                                  title: Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                                  subtitle: Text('S:${m.sakitCount} · C:${m.cutiCount} · I:${m.izinCount} · A:${m.alpaCount}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted)),
                                  trailing: Text('${m.totalAbsent} Hari', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: UbColors.rose)),
                                );
                              }),
                            const SizedBox(height: 14),
                            Text('🏆 100% Attendance Club (${perfectClub.length})', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: UbColors.amber)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: perfectClub
                                  .map(
                                    (p) => ActionChip(
                                      label: Text('${p.name} (100%)', style: const TextStyle(fontSize: 11)),
                                      onPressed: () => _openMemberDetail(p),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ] else ...[
                            _distBar('🤒 Sakit', _kpi.totalSakit, _kpi.totalAbsent, UbColors.amber),
                            _distBar('🏖️ Cuti Resmi', _kpi.totalCuti, _kpi.totalAbsent, UbColors.purple),
                            _distBar('📋 Izin Keperluan', _kpi.totalIzin, _kpi.totalAbsent, const Color(0xFF38BDF8)),
                            _distBar('❌ Alpa', _kpi.totalAlpa, _kpi.totalAbsent, UbColors.rose),
                          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(color: active ? bg : UbColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? bg : Colors.white12)),
        child: Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: active ? fg : UbColors.textMuted)),
      ),
    );
  }

  Widget _kpiBox(String label, String val, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: UbColors.textMuted)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 17, fontWeight: FontWeight.w900, color: color)),
          Text(sub, style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: UbColors.textMuted)),
        ],
      ),
    );
  }

  Widget _tabPill(String key, String label, Color color) {
    final active = _tab == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = key),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: active ? color : UbColors.surface, borderRadius: BorderRadius.circular(11), border: Border.all(color: active ? color : Colors.white12)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? UbColors.bg : UbColors.textMuted)),
        ),
      ),
    );
  }

  Widget _distBar(String label, int count, int total, Color color) {
    final frac = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              Text('$count Kasus', style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: frac, minHeight: 7, backgroundColor: UbColors.bg, valueColor: AlwaysStoppedAnimation<Color>(color)),
          ),
        ],
      ),
    );
  }
}
