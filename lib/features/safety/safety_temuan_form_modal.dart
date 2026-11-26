import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/safety_finding_models.dart';

Future<SafetyFinding?> showSafetyTemuanModal(
  BuildContext context, {
  required SafetyFinding initial,
  bool kaizenMode = false,
}) {
  return showModalBottomSheet<SafetyFinding>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: UbColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _SafetyTemuanFormSheet(
      initial: initial.copyWith(),
      kaizenMode: kaizenMode,
    ),
  );
}

class _SafetyTemuanFormSheet extends StatefulWidget {
  const _SafetyTemuanFormSheet({
    required this.initial,
    required this.kaizenMode,
  });

  final SafetyFinding initial;
  final bool kaizenMode;

  @override
  State<_SafetyTemuanFormSheet> createState() => _SafetyTemuanFormSheetState();
}

class _SafetyTemuanFormSheetState extends State<_SafetyTemuanFormSheet> {
  late SafetyFinding _f;
  int _step = 0; // 0 = BEFORE, 1 = AFTER, 2 = REVIEW

  late final TextEditingController _noCtrl;
  late final TextEditingController _foundAtCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _procCtrl;
  late final TextEditingController _captionCtrl;
  late final TextEditingController _themeCtrl;
  late final TextEditingController _stdCtrl;
  late final TextEditingController _cmCtrl;
  late final TextEditingController _picCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _resultCtrl;
  late final TextEditingController _beforeAccCtrl;
  late final TextEditingController _afterAccCtrl;

  @override
  void initState() {
    super.initState();
    _f = widget.initial;
    if (widget.kaizenMode && _f.theme.trim().isEmpty && _f.caption.trim().isNotEmpty) {
      _f.theme = 'MENANGGULANGI ${_f.caption}'.toUpperCase();
    }
    if (widget.kaizenMode && _f.after.code.isEmpty && _f.before.code.isNotEmpty) {
      _f.after.code = _f.before.code;
      _f.after.typeName = _f.before.typeName;
      if (_f.after.accident.isEmpty) _f.after.accident = _f.before.accident;
    }

    _noCtrl = TextEditingController(text: _f.no);
    _foundAtCtrl = TextEditingController(text: _f.foundAt);
    _locCtrl = TextEditingController(text: _f.location);
    _procCtrl = TextEditingController(text: _f.process);
    _captionCtrl = TextEditingController(text: _f.caption);
    _themeCtrl = TextEditingController(text: _f.theme);
    _stdCtrl = TextEditingController(text: _f.standard);
    _cmCtrl = TextEditingController(text: _f.cm);
    _picCtrl = TextEditingController(text: _f.pic);
    _dateCtrl = TextEditingController(text: _f.date);
    _resultCtrl = TextEditingController(text: _f.result);
    _beforeAccCtrl = TextEditingController(text: _f.before.accident);
    _afterAccCtrl = TextEditingController(text: _f.after.accident);
  }

  @override
  void dispose() {
    _noCtrl.dispose();
    _foundAtCtrl.dispose();
    _locCtrl.dispose();
    _procCtrl.dispose();
    _captionCtrl.dispose();
    _themeCtrl.dispose();
    _stdCtrl.dispose();
    _cmCtrl.dispose();
    _picCtrl.dispose();
    _dateCtrl.dispose();
    _resultCtrl.dispose();
    _beforeAccCtrl.dispose();
    _afterAccCtrl.dispose();
    super.dispose();
  }

  void _syncFieldsToModel() {
    _f
      ..no = _noCtrl.text.trim()
      ..foundAt = _foundAtCtrl.text.trim()
      ..location = _locCtrl.text.trim().isEmpty ? 'UB ASSY' : _locCtrl.text.trim()
      ..process = _procCtrl.text.trim()
      ..caption = _captionCtrl.text.trim()
      ..theme = _themeCtrl.text.trim()
      ..standard = _stdCtrl.text.trim()
      ..cm = _cmCtrl.text.trim()
      ..pic = _picCtrl.text.trim()
      ..date = _dateCtrl.text.trim()
      ..result = _resultCtrl.text.trim();
    _f.before.accident = _beforeAccCtrl.text.trim();
    _f.after.accident = _afterAccCtrl.text.trim();
  }

  void _submit() {
    _syncFieldsToModel();
    if (_f.caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uraian problem (caption) wajib diisi.')),
      );
      setState(() => _step = 0);
      return;
    }
    Navigator.of(context).pop(_f);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: UbColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (widget.kaizenMode ? UbColors.emerald : UbColors.cyan).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (widget.kaizenMode ? UbColors.emerald : UbColors.cyan).withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    widget.kaizenMode ? 'KAIZEN #${_f.no}' : (_f.no.isEmpty ? 'NEW' : 'REF #${_f.no}'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: widget.kaizenMode ? const Color(0xFF6EE7B7) : UbColors.cyan,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.kaizenMode ? 'Safety Kaizen Report' : 'Temuan Safety (List Up Problem)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: UbColors.textMuted),
                ),
              ],
            ),
          ),

          // Step Tabs (01 BEFORE · 02 AFTER · 03 REVIEW)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: UbColors.surface.withValues(alpha: 0.6),
            child: Row(
              children: [
                _stepBtn(0, '01', 'BEFORE', UbColors.rose),
                const SizedBox(width: 8),
                _stepBtn(1, '02', 'AFTER', UbColors.emerald),
                const SizedBox(width: 8),
                _stepBtn(2, '03', 'REVIEW', UbColors.cyan),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 20),
              child: _step == 0
                  ? _buildBeforeTab()
                  : (_step == 1 ? _buildAfterTab() : _buildReviewTab()),
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: UbColors.surface,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                if (_step > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      _syncFieldsToModel();
                      setState(() => _step -= 1);
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Kembali', style: TextStyle(fontSize: 12)),
                  )
                else
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: UbColors.textMuted)),
                  ),
                const Spacer(),
                if (_step < 2)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UbColors.emerald,
                      side: BorderSide(color: UbColors.emerald.withValues(alpha: 0.5)),
                    ),
                    onPressed: () {
                      _syncFieldsToModel();
                      setState(() => _step += 1);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(_step == 0 ? 'Lanjut AFTER' : 'Review', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: UbColors.cyan,
                    foregroundColor: UbColors.bg,
                  ),
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: Text(
                    widget.kaizenMode ? 'Simpan Kaizen' : 'Simpan',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(int idx, String numLabel, String title, Color color) {
    final active = _step == idx;
    return Expanded(
      child: InkWell(
        onTap: () {
          _syncFieldsToModel();
          setState(() => _step = idx);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.2) : UbColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? color.withValues(alpha: 0.7) : Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? color : Colors.white10,
                ),
                alignment: Alignment.center,
                child: Text(
                  numLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: active ? UbColors.bg : UbColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : UbColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeforeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shift & Status quick selector
        Row(
          children: [
            Expanded(
              child: _shiftSelector(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _f.status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('OPEN (Belum)')),
                  DropdownMenuItem(value: 'progress', child: Text('PROGRESS (Proses)')),
                  DropdownMenuItem(value: 'closed', child: Text('CLOSED (Selesai)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _f.status = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (widget.kaizenMode) ...[
          TextField(
            controller: _themeCtrl,
            decoration: const InputDecoration(
              labelText: 'THEMA KAIZEN REPORT',
              hintText: 'MENANGGULANGI ...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
        ],

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _foundAtCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Temuan (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _noCtrl,
                decoration: const InputDecoration(
                  labelText: '#No',
                  hintText: 'Auto',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lokasi / Line',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _procCtrl,
                decoration: const InputDecoration(
                  labelText: 'Proses / Station',
                  hintText: 'mis. SOB 560',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _captionCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Uraian Problem Finding (Wajib diisi)',
            hintText: 'Jelaskan kondisi / tindakan tidak aman di shopfloor...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),

        // Hazard Condition (4 Kategori)
        const Text('Kategori Hazard Condition (4 Kategori)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: UbColors.amber)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(SafetyRiskMaster.hazards.length, (i) {
            final selected = _f.hazard == i;
            return ChoiceChip(
              label: Text('${i + 1}. ${SafetyRiskMaster.hazards[i]}', style: const TextStyle(fontSize: 11)),
              selected: selected,
              selectedColor: UbColors.amber.withValues(alpha: 0.28),
              onSelected: (_) => setState(() => _f.hazard = i),
            );
          }),
        ),
        const SizedBox(height: 14),

        // 12 Sumber K3
        const Text('Sumber Temuan (Source K3)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: UbColors.cyan)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(SafetyRiskMaster.flatSources.length, (i) {
            final selected = _f.sources.contains(i);
            return FilterChip(
              label: Text(SafetyRiskMaster.flatSources[i], style: const TextStyle(fontSize: 10.5)),
              selected: selected,
              selectedColor: UbColors.cyan.withValues(alpha: 0.25),
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _f.sources.add(i);
                  } else {
                    _f.sources.remove(i);
                  }
                });
              },
            );
          }),
        ),
        const SizedBox(height: 16),

        // Risk Assessment BEFORE
        _buildRiskEditor(
          title: 'Risk Assessment Awal (BEFORE)',
          risk: _f.before,
          accCtrl: _beforeAccCtrl,
          isBefore: true,
        ),
      ],
    );
  }

  Widget _buildAfterTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _stdCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Recommendation (Standar K3 / SOP / JSA)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _cmCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Countermeasure (Tindakan Penanggulangan Nyata)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _picCtrl,
                decoration: const InputDecoration(
                  labelText: 'PIC (GL / TL)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tgl Target / Realisasi',
                  hintText: 'dd/mm/yy',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _resultCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'RESULT (Dampak / Hasil Kaizen A4)',
            hintText: 'Contoh: Potensi bahaya terhindar, area kerja lebih aman.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildRiskEditor(
          title: 'Risk Assessment Sesudah (AFTER)',
          risk: _f.after,
          accCtrl: _afterAccCtrl,
          isBefore: false,
        ),
      ],
    );
  }

  Widget _buildReviewTab() {
    _syncFieldsToModel();
    final delta = _f.riskDelta;
    final rankDown = SafetyRiskMaster.isRankDown(_f.before.effectiveRank, _f.after.effectiveRank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: UbColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: UbColors.cyan.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temuan #${_f.no.isEmpty ? "AUTO" : _f.no} · Shift ${_f.shift.toUpperCase()} · ${_f.status.toUpperCase()}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: UbColors.cyan),
              ),
              const SizedBox(height: 4),
              Text(
                _f.caption.isEmpty ? '(Uraian problem belum diisi)' : _f.caption,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Lokasi: ${_f.location} · Proses: ${_f.process.isEmpty ? "-" : _f.process} · PIC: ${_f.pic.isEmpty ? "-" : _f.pic}',
                style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (delta != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (rankDown || delta.diff > 0 ? UbColors.emerald : UbColors.surface).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (rankDown || delta.diff > 0 ? UbColors.emerald : Colors.white24).withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_down_rounded, color: rankDown || delta.diff > 0 ? UbColors.emerald : UbColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Penurunan Risiko: ${delta.beforePt} pt (${_f.before.effectiveRank}) ➔ ${delta.afterPt} pt (${_f.after.effectiveRank})',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text(
                        rankDown
                            ? '✓ RANK DOWN SUKSES (-${delta.diff} pt / ${delta.pct}%)'
                            : (delta.diff > 0 ? 'Turun ${delta.diff} pt (${delta.pct}%)' : 'Belum ada penurunan poin'),
                        style: TextStyle(fontSize: 11, color: rankDown || delta.diff > 0 ? const Color(0xFF6EE7B7) : UbColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _reviewBox('Standar K3 (Recommendation)', _f.standard),
        const SizedBox(height: 8),
        _reviewBox('Tindakan Penanggulangan (Countermeasure)', _f.cm),
        if (_f.result.isNotEmpty) ...[
          const SizedBox(height: 8),
          _reviewBox('Result Kaizen', _f.result),
        ],
      ],
    );
  }

  Widget _reviewBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: UbColors.textMuted)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? '–' : value, style: const TextStyle(fontSize: 12.5, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _shiftSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _f.shift = 'red'),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _f.shift == 'red' ? UbColors.rose : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Shift RED',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: _f.shift == 'red' ? Colors.white : UbColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _f.shift = 'white'),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _f.shift == 'white' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Shift WHITE',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: _f.shift == 'white' ? UbColors.bg : UbColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskEditor({
    required String title,
    required SafetyRisk risk,
    required TextEditingController accCtrl,
    required bool isBefore,
  }) {
    final tone = isBefore ? UbColors.rose : UbColors.emerald;
    final eval = risk.evaluation;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 16, color: tone),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: tone)),
              ),
              if (eval.rank.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: tone,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'RANK ${eval.rank} (${eval.total} pt)',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isBefore ? Colors.white : UbColors.bg,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Tipe Bahaya STOP 6', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: UbColors.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: SafetyRiskMaster.stop6Options.map((opt) {
              final active = risk.code.toUpperCase() == opt.code;
              return ChoiceChip(
                label: Text('${opt.code} · ${opt.name.split(' ').first}', style: const TextStyle(fontSize: 10.5)),
                selected: active,
                selectedColor: UbColors.cyan.withValues(alpha: 0.25),
                onSelected: (_) => setState(() {
                  risk.code = opt.code;
                  risk.typeName = opt.name;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: accCtrl,
            decoration: const InputDecoration(
              labelText: 'Kind of Accident (Potensi Bahaya)',
              hintText: 'mis. Tersengat listrik / Tersayat / Terjepit',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          _matrixPicker(
            label: '① Level Kecelakaan (Severity)',
            options: SafetyRiskMaster.injuryLevels,
            selectedPoint: risk.injury.point,
            onSelect: (opt) => setState(() {
              risk.injury = SafetyRiskPart(desc: opt.desc, point: opt.point);
              final nextEval = risk.evaluation;
              if (nextEval.rank.isNotEmpty) risk.rank = nextEval.rank;
            }),
          ),
          const SizedBox(height: 10),
          _matrixPicker(
            label: '② Frekuensi Kerja (Frequency)',
            options: SafetyRiskMaster.frequencyLevels,
            selectedPoint: risk.frequency.point,
            onSelect: (opt) => setState(() {
              risk.frequency = SafetyRiskPart(desc: opt.desc, point: opt.point);
              final nextEval = risk.evaluation;
              if (nextEval.rank.isNotEmpty) risk.rank = nextEval.rank;
            }),
          ),
          const SizedBox(height: 10),
          _matrixPicker(
            label: '③ Level Countermeasure (Pencegahan)',
            options: SafetyRiskMaster.countermeasureLevels,
            selectedPoint: risk.countermeasure.point,
            onSelect: (opt) => setState(() {
              risk.countermeasure = SafetyRiskPart(desc: opt.desc, point: opt.point);
              final nextEval = risk.evaluation;
              if (nextEval.rank.isNotEmpty) risk.rank = nextEval.rank;
            }),
          ),
        ],
      ),
    );
  }

  Widget _matrixPicker({
    required String label,
    required List<RiskOption> options,
    required int? selectedPoint,
    required void Function(RiskOption opt) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: UbColors.textPrimary)),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((opt) {
            final active = selectedPoint == opt.point;
            return ChoiceChip(
              label: Text('${opt.label} (${opt.point}pt)', style: const TextStyle(fontSize: 10.5)),
              selected: active,
              selectedColor: UbColors.cyan.withValues(alpha: 0.28),
              onSelected: (_) => onSelect(opt),
            );
          }).toList(),
        ),
      ],
    );
  }
}
