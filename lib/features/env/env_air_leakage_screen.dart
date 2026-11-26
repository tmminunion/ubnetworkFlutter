import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/cost_env_models.dart';
import '../../services/cost_env_store.dart';

class EnvAirLeakageScreen extends StatefulWidget {
  const EnvAirLeakageScreen({super.key});

  @override
  State<EnvAirLeakageScreen> createState() => _EnvAirLeakageScreenState();
}

class _EnvAirLeakageScreenState extends State<EnvAirLeakageScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Checksheet state
  final String _csDate = costEnvTodayYmd();
  String _csShift = 'red';
  final TextEditingController _inspectorCtrl = TextEditingController();
  List<AirCheckPoint> _points = const [];

  // Findings state
  List<AirLeakageFinding> _findings = const [];
  String _statusFilter = 'all'; // all | open | progress | closed | kaizen
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _inspectorCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cs = await CostEnvStore.instance.loadAirChecksheet(_csDate, _csShift);
    final fl = await CostEnvStore.instance.loadAirFindings();
    if (!mounted) return;
    _inspectorCtrl.text = cs.inspector;
    setState(() {
      _points = cs.points;
      _findings = fl;
      _loading = false;
    });
  }

  Future<void> _saveChecksheet() async {
    await CostEnvStore.instance.saveAirChecksheet(_csDate, _csShift, _inspectorCtrl.text.trim(), _points);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checksheet Air Leakage harian tersimpan!')),
    );
  }

  Future<void> _openFindingForm({AirLeakageFinding? existing, String? prefillArea, String? prefillProblem}) async {
    final areaCtrl = TextEditingController(text: existing?.area ?? prefillArea ?? '');
    final memCtrl = TextEditingController(text: existing?.member ?? _inspectorCtrl.text.trim());
    final probCtrl = TextEditingController(text: existing?.problem ?? prefillProblem ?? '#lub ');
    final picCtrl = TextEditingController(text: existing?.pic ?? '');
    final cmCtrl = TextEditingController(text: existing?.countermeasure ?? '');
    final kzTitleCtrl = TextEditingController(text: existing?.kaizenTitle ?? '');
    final kzBenCtrl = TextEditingController(text: existing?.kaizenBenefit ?? '');
    var shift = existing?.shift ?? _csShift;
    var severity = existing?.severity ?? 'sedang';
    var status = existing?.status ?? 'open';

    try {
      final ok = await showModalBottomSheet<bool>(
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
                  Text(existing == null ? 'Tambah Temuan #lub' : 'Edit #${existing.id} (#lub / #klub)', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'Area / Station', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: memCtrl, decoration: const InputDecoration(labelText: 'Pelapor', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: probCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Problem Kebocoran Angin (#lub) *', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: shift,
                          decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'red', child: Text('RED')),
                            DropdownMenuItem(value: 'white', child: Text('WHITE')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => shift = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: severity,
                          decoration: const InputDecoration(labelText: 'Tingkat', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'kecil', child: Text('Kecil')),
                            DropdownMenuItem(value: 'sedang', child: Text('Sedang')),
                            DropdownMenuItem(value: 'besar', child: Text('Besar')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => severity = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'open', child: Text('Open')),
                            DropdownMenuItem(value: 'progress', child: Text('Progress')),
                            DropdownMenuItem(value: 'closed', child: Text('Closed')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => status = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: picCtrl, decoration: const InputDecoration(labelText: 'PIC Perbaikan', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: cmCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Penanggulangan (#kaizen #klub)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: kzTitleCtrl, decoration: const InputDecoration(labelText: 'Judul Kaizen (#klub)', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: kzBenCtrl, decoration: const InputDecoration(labelText: 'Dampak / Hemat', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg),
                    onPressed: () {
                      if (probCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Simpan Temuan #lub', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (ok == true) {
        final next = List<AirLeakageFinding>.from(_findings);
        final isKz = cmCtrl.text.trim().isNotEmpty || kzTitleCtrl.text.trim().isNotEmpty;
        final item = AirLeakageFinding(
          id: existing?.id ?? 'LUB${(next.length + 1).toString().padLeft(2, '0')}',
          date: existing?.date ?? _csDate,
          shift: shift,
          member: memCtrl.text.trim(),
          area: areaCtrl.text.trim(),
          problem: probCtrl.text.trim(),
          severity: severity,
          countermeasure: cmCtrl.text.trim(),
          kaizenTitle: kzTitleCtrl.text.trim(),
          kaizenBenefit: kzBenCtrl.text.trim(),
          isKaizen: isKz,
          pic: picCtrl.text.trim(),
          status: status,
        );
        if (existing != null) {
          final idx = next.indexWhere((e) => e.id == existing.id);
          if (idx >= 0) next[idx] = item;
        } else {
          next.insert(0, item);
        }
        await CostEnvStore.instance.saveAirFindings(next);
        await CostEnvStore.instance.syncUpsertAirFinding(item, isEdit: existing != null);
        if (mounted) {
          setState(() => _findings = next);
          _tabCtrl.animateTo(1);
        }
      }
    } finally {
      areaCtrl.dispose();
      memCtrl.dispose();
      probCtrl.dispose();
      picCtrl.dispose();
      cmCtrl.dispose();
      kzTitleCtrl.dispose();
      kzBenCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalNg = _points.where((p) => p.status == 'NG').length;
    final filteredFindings = _findings.where((f) {
      if (_statusFilter == 'kaizen' && !f.isKaizen) return false;
      if (_statusFilter != 'all' && _statusFilter != 'kaizen' && f.status != _statusFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return f.problem.toLowerCase().contains(q) || f.area.toLowerCase().contains(q) || f.id.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Air Leakage (#lub · #klub)', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('Checksheet Harian & Temuan Kebocoran Angin', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: UbColors.cyan,
          labelColor: UbColors.cyan,
          unselectedLabelColor: UbColors.textMuted,
          tabs: [
            const Tab(text: 'Checksheet Harian'),
            Tab(text: 'Temuan #lub (${_findings.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.emerald,
        foregroundColor: UbColors.bg,
        onPressed: () => _openFindingForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Temuan #lub', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // TAB 1: CHECKSHEET HARIAN
                ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('Tanggal: $_csDate', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 12)),
                              const Spacer(),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'red', label: Text('RED', style: TextStyle(fontSize: 11))),
                                  ButtonSegment(value: 'white', label: Text('WHITE', style: TextStyle(fontSize: 11))),
                                ],
                                selected: {_csShift},
                                onSelectionChanged: (s) {
                                  setState(() => _csShift = s.first);
                                  _load();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _inspectorCtrl,
                            decoration: const InputDecoration(labelText: 'Pemeriksa (PIC)', border: OutlineInputBorder(), isDense: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._points.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final pt = entry.value;
                      final isNg = pt.status == 'NG';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: UbColors.cyan.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
                                    child: Text(pt.code, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(pt.point, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                                ],
                              ),
                              Text('Area: ${pt.area}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('OK', style: TextStyle(fontWeight: FontWeight.w900)),
                                    selected: !isNg,
                                    selectedColor: UbColors.emerald.withValues(alpha: 0.3),
                                    onSelected: (_) {
                                      final next = List<AirCheckPoint>.from(_points);
                                      next[idx] = pt.copyWith(status: 'OK');
                                      setState(() => _points = next);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('NG (#lub)', style: TextStyle(fontWeight: FontWeight.w900)),
                                    selected: isNg,
                                    selectedColor: UbColors.rose.withValues(alpha: 0.3),
                                    onSelected: (_) {
                                      final next = List<AirCheckPoint>.from(_points);
                                      next[idx] = pt.copyWith(status: 'NG');
                                      setState(() => _points = next);
                                    },
                                  ),
                                  const Spacer(),
                                  if (isNg)
                                    FilledButton.tonal(
                                      onPressed: () => _openFindingForm(
                                        prefillArea: pt.area,
                                        prefillProblem: '#lub Kebocoran angin di ${pt.point} (${pt.area})',
                                      ),
                                      child: const Text('+ Input #lub', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _saveChecksheet,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text('Simpan Checksheet (${_points.length} Titik · $totalNg NG)', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),

                // TAB 2: TEMUAN #lub & KAIZEN #klub
                ListView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 84),
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final st in ['all', 'open', 'progress', 'closed', 'kaizen'])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(st == 'kaizen' ? 'Kaizen #klub' : st.toUpperCase(), style: const TextStyle(fontSize: 10.5)),
                                selected: _statusFilter == st,
                                onSelected: (_) => setState(() => _statusFilter = st),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => setState(() => _search = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Cari #lub, #klub, area...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 17),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (filteredFindings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text('Belum ada temuan Air Leakage (#lub).', style: TextStyle(color: UbColors.textMuted))),
                      )
                    else
                      ...filteredFindings.map((f) {
                        final sc = f.status == 'closed' ? UbColors.emerald : (f.status == 'progress' ? UbColors.amber : UbColors.rose);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('#${f.id}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: UbColors.amber)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(color: sc.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
                                      child: Text(f.status.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: sc)),
                                    ),
                                    if (f.isKaizen) ...[
                                      const SizedBox(width: 6),
                                      const Text('#kaizen #klub', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                                    ],
                                    const Spacer(),
                                    Text(f.date, style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(f.area.isEmpty ? 'Area Line' : f.area, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                Text(f.problem, style: const TextStyle(fontSize: 12.5, color: UbColors.textPrimary)),
                                if (f.countermeasure.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('CM (#klub): ${f.countermeasure}', style: const TextStyle(fontSize: 11.5, color: UbColors.emerald)),
                                  ),
                                Row(
                                  children: [
                                    Text('Pelapor: ${f.member.isEmpty ? '-' : f.member} · PIC: ${f.pic.isEmpty ? '-' : f.pic}', style: const TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                                    const Spacer(),
                                    IconButton(icon: const Icon(Icons.edit_rounded, size: 17, color: UbColors.cyan), onPressed: () => _openFindingForm(existing: f)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 17, color: UbColors.rose),
                                      onPressed: () async {
                                        final next = _findings.where((e) => e.id != f.id).toList();
                                        await CostEnvStore.instance.saveAirFindings(next);
                                        if (mounted) setState(() => _findings = next);
                                        await CostEnvStore.instance.syncDeleteAirFinding(f.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ],
            ),
    );
  }
}
