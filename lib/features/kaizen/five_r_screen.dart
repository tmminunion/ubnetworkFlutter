import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/kaizen_activity_models.dart';
import '../../services/auth_service.dart';
import '../../services/kaizen_activity_store.dart';
import 'ireporter_paper_canvas.dart';

enum _FiveRPaperMode { audit, redTag, shadowBoard }

class FiveRScreen extends StatefulWidget {
  const FiveRScreen({super.key});

  @override
  State<FiveRScreen> createState() => _FiveRScreenState();
}

class _FiveRScreenState extends State<FiveRScreen> {
  final GlobalKey _paperKey = GlobalKey();

  FiveRAuditMaster? _audit;
  List<FiveRRedTag> _redTags = [];
  List<FiveRShadowBoardTool> _shadowBoard = [];
  _FiveRPaperMode _mode = _FiveRPaperMode.audit;
  bool _loading = true;
  bool _online = false;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await KaizenActivityStore.instance.load5R();
    if (!mounted) return;
    setState(() {
      _audit = res.audit;
      _redTags = res.redTags;
      _shadowBoard = res.shadowBoard;
      _online = res.online;
      _loading = false;
    });
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

  Future<void> _printPdf() async {
    final audit = _audit;
    if (audit == null || _printing) return;
    setState(() => _printing = true);
    try {
      await IReporterPaperCanvas.printA3Landscape(
        context: context,
        boundaryKey: _paperKey,
        fileName: '5R_${_mode.name.toUpperCase()}_${audit.auditDate}.pdf',
      );
    } catch (e) {
      _toast('Gagal cetak PDF A3: $e', isErr: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _editChecklistModal(FiveRChecklistItem item) async {
    final audit = _audit;
    if (audit == null) return;
    var score = item.actualScore.toDouble();
    var status = item.status;
    final noteCtrl = TextEditingController(text: item.findingNote);
    final cmCtrl = TextEditingController(text: item.countermeasure);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '[${item.pillar}] ${item.criteriaTitle}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  item.standardDescription,
                  style: const TextStyle(fontSize: 12, color: UbColors.textMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Skor Aktual Audit:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    Text(
                      '${score.round()} / ${item.maxScore}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w900, color: UbColors.emerald),
                    ),
                  ],
                ),
                Slider(
                  value: score,
                  min: 0,
                  max: item.maxScore.toDouble(),
                  divisions: item.maxScore,
                  activeColor: UbColors.emerald,
                  onChanged: (v) => setM(() {
                    score = v;
                    if (v >= item.maxScore - 1) {
                      status = 'OK';
                    } else if (v >= item.maxScore * 0.6) {
                      status = 'DEVIA';
                    } else {
                      status = 'CRITICAL';
                    }
                  }),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: UbColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Status Kriteria'),
                  items: ['OK', 'DEVIA', 'CRITICAL']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setM(() => status = v ?? 'OK'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Catatan Temuan / Kondisi Genba'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cmCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Tindakan Perbaikan (Countermeasure)'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: UbColors.emerald),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Simpan Skor Kriteria', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      setState(() {
        item.actualScore = score.round();
        item.status = status;
        item.findingNote = noteCtrl.text.trim();
        item.countermeasure = cmCtrl.text.trim();
        audit.recalculate(_redTags);
      });
      final synced = await KaizenActivityStore.instance.sync5RAction(
        audit: audit,
        redTags: _redTags,
        shadowBoard: _shadowBoard,
        action: 'updateChecklistItem',
        payload: item.toJson(),
      );
      _toast(synced ? 'Skor 5R tersimpan & sinkron ke server' : 'Skor 5R tersimpan di cache lokal');
    }
    noteCtrl.dispose();
    cmCtrl.dispose();
  }

  Future<void> _addRedTagModal() async {
    final audit = _audit;
    if (audit == null) return;
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController(text: 'Pos 1 Sub-Assy Front');
    final picCtrl = TextEditingController(
      text: AuthService.instance.currentUser?.name ?? 'Cecep Suryana',
    );
    var cat = 'EQUIPMENT';
    var reason = 'RUSAK';
    var disp = 'SCRAP';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Registrasi Label Merah (Red-Tag 5R)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Nama Barang / Perkakas Tak Perlu'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: cat,
                        dropdownColor: UbColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Kategori'),
                        items: ['EQUIPMENT', 'TOOL', 'MATERIAL_PART', 'JIG_FIXTURE', 'DOCUMENT']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setM(() => cat = v ?? 'EQUIPMENT'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: reason,
                        dropdownColor: UbColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Alasan Red-Tag'),
                        items: ['RUSAK', 'TIDAK_TERPAKAI', 'BERLEBIH', 'KEDALUWARSA', 'SALAH_TEMPAT']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setM(() => reason = v ?? 'RUSAK'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Lokasi Ditemukan'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: picCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'PIC Eksekusi'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: disp,
                        dropdownColor: UbColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Disposisi'),
                        items: ['SCRAP', 'PINDAH_GUDANG', 'REPARASI', 'KEMBALIKAN_SUPPLIER']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setM(() => disp = v ?? 'SCRAP'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: UbColors.rose),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Tempel Red-Tag (SLA 48 Jam)', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      final now = DateTime.now().toUtc().add(const Duration(hours: 7));
      final exp = now.add(const Duration(days: 2));
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final newTag = FiveRRedTag(
        id: 'rt-${now.millisecondsSinceEpoch}',
        tagNumber: 'RT-UB-${now.year}${now.month.toString().padLeft(2, '0')}-${(_redTags.length + 1).toString().padLeft(3, '0')}',
        itemName: nameCtrl.text.trim(),
        category: cat,
        stationLocation: locCtrl.text.trim(),
        taggedDate: fmt(now),
        expiryDate: fmt(exp),
        reason: reason,
        assignedPic: picCtrl.text.trim(),
        dispositionAction: disp,
        status: 'OPEN',
      );
      setState(() {
        _redTags.insert(0, newTag);
        _mode = _FiveRPaperMode.redTag;
        audit.recalculate(_redTags);
      });
      await KaizenActivityStore.instance.sync5RAction(
        audit: audit,
        redTags: _redTags,
        shadowBoard: _shadowBoard,
        action: 'createRedTag',
        payload: newTag.toJson(),
      );
      _toast('Red-Tag ${newTag.tagNumber} berhasil diregistrasi');
    }
    nameCtrl.dispose();
    locCtrl.dispose();
    picCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audit = _audit;

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: UbColors.bg.withValues(alpha: 0.94),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _modeChip(
                            _FiveRPaperMode.audit,
                            'Audit 5R (${audit?.totalScore ?? 96}/100)',
                            const Color(0xFF0D9488),
                          ),
                          const SizedBox(width: 6),
                          _modeChip(
                            _FiveRPaperMode.redTag,
                            'Red-Tag (${_redTags.where((r) => r.status == 'OPEN').length} Open)',
                            UbColors.rose,
                          ),
                          const SizedBox(width: 6),
                          _modeChip(
                            _FiveRPaperMode.shadowBoard,
                            'Shadow Board (${_shadowBoard.where((t) => t.isPresent).length}/${_shadowBoard.length})',
                            UbColors.primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: Icon(
                      _online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: 18,
                      color: _online ? UbColors.emerald : UbColors.amber,
                    ),
                    tooltip: _online ? 'Online · Sinkron /api/5r' : 'Offline Cache',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: _addRedTagModal,
                    icon: const Icon(Icons.sell_rounded, size: 18, color: UbColors.rose),
                    tooltip: 'Tambah Label Merah (Red-Tag)',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: _printing ? null : _printPdf,
                    icon: _printing
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.print_rounded, size: 19, color: Colors.white),
                    tooltip: 'Cetak Presisi A3 Landscape',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // SUB-HEADER: 5 PILAR SCORES
            if (audit != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _scoreBadge('Ringkas', audit.seiri, UbColors.emerald),
                      _scoreBadge('Rapi', audit.seiton, UbColors.cyan),
                      _scoreBadge('Resik', audit.seiso, UbColors.primaryBlue),
                      _scoreBadge('Rawat', audit.seiketsu, UbColors.purple),
                      _scoreBadge('Rajin', audit.shitsuke, UbColors.amber),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: UbColors.emerald,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'RANK ${audit.rankGrade} (${audit.totalScore}/100)',
                          style: const TextStyle(color: Color(0xFF022C22), fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // FULLSCREEN i-REPORTER A3 PAPER CANVAS
            Expanded(
              child: _loading || audit == null
                  ? const Center(child: CircularProgressIndicator())
                  : IReporterPaperCanvas(
                      paperBoundaryKey: _paperKey,
                      dotColor: const Color(0xFF14B8A6),
                      paperChild: _buildFiveRA3Paper(audit),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(_FiveRPaperMode m, String label, Color activeCol) {
    final sel = _mode == m;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      visualDensity: VisualDensity.compact,
      selectedColor: activeCol,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: sel ? Colors.white : UbColors.textMuted,
      ),
      onSelected: (_) => setState(() => _mode = m),
    );
  }

  Widget _scoreBadge(String label, int val, Color col) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $val/20',
        style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildFiveRA3Paper(FiveRAuditMaster audit) {
    const borderBold = BorderSide(color: Color(0xFF0F172A), width: 2.2);
    const borderThin = BorderSide(color: Color(0xFF0F172A), width: 1.1);

    final sheetTitle = _mode == _FiveRPaperMode.audit
        ? 'CHECKSHEET AUDIT GENBA 5R (5S SHOPFLOOR EXCELLENCE)'
        : _mode == _FiveRPaperMode.redTag
            ? 'REGISTER KAMPANYE LABEL MERAH (RED-TAG CAMPAIGN SLA 48H)'
            : 'INVENTARIS PAPAN BAYANGAN PERKAKAS (TOOL SHADOW BOARD)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // HEADER DOKUMEN RESMI TOYOTA 5R
        Container(
          decoration: const BoxDecoration(border: Border.fromBorderSide(borderBold)),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'T',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PT. TOYOTA MOTOR MANUFACTURING INDONESIA',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'WELDING PLANT #1 — UNDERBODY SHOPFLOOR 5R / 5S COMMITTEE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFCCFBF1),
                            border: Border.fromBorderSide(borderThin),
                          ),
                          child: Text(
                            sheetTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${audit.auditCode} · LINI: ${audit.lineCode} · SHIFT ${audit.shift}',
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: audit.rankGrade == 'A' ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                      border: const Border.fromBorderSide(borderBold),
                    ),
                    child: Column(
                      children: [
                        const Text('TOTAL SKOR 5R', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900)),
                        Text(
                          '${audit.totalScore}/100 (RANK ${audit.rankGrade})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF0F172A), thickness: 1.5, height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Stasiun Kerja: ${audit.stationName}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Auditor: ${audit.auditorName}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'PIC Area: ${audit.teamLeaderPic}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    'Tanggal Audit: ${audit.auditDate}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (_mode == _FiveRPaperMode.audit) _buildAuditTable(audit),
        if (_mode == _FiveRPaperMode.redTag) _buildRedTagTable(audit),
        if (_mode == _FiveRPaperMode.shadowBoard) _buildShadowBoardGrid(audit),
      ],
    );
  }

  Widget _buildAuditTable(FiveRAuditMaster audit) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF0F172A), width: 2)),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            child: const Row(
              children: [
                SizedBox(width: 95, child: Text('PILAR 5R', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                Expanded(flex: 3, child: Text('KRITERIA PEMERIKSAAN (TAP BARIS UNTUK AUDIT)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                Expanded(flex: 4, child: Text('STANDAR KONDISI NORMAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                Expanded(flex: 3, child: Text('CATATAN TEMUAN GENBA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 60, child: Text('MAX', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 65, child: Text('AKTUAL', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 80, child: Text('STATUS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
              ],
            ),
          ),
          ...audit.checklists.map((c) {
            final isOk = c.status == 'OK';
            return InkWell(
              onTap: () => _editChecklistModal(c),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 95,
                      child: Text(
                        c.pillar,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(c.criteriaTitle, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(c.standardDescription, style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        c.findingNote.isEmpty ? '-' : c.findingNote,
                        style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('${c.maxScore}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(
                      width: 65,
                      child: Text(
                        '${c.actualScore}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      width: 80,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: isOk ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c.status,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: isOk ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRedTagTable(FiveRAuditMaster audit) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF0F172A), width: 2)),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF991B1B),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            child: const Row(
              children: [
                SizedBox(width: 130, child: Text('NO. RED-TAG', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                Expanded(flex: 3, child: Text('NAMA BARANG / KOMPONEN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                Expanded(flex: 2, child: Text('LOKASI STASIUN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 115, child: Text('ALASAN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 135, child: Text('PIC & DISPOSISI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 95, child: Text('SLA EXPIRY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 105, child: Text('STATUS (TAP)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
              ],
            ),
          ),
          ..._redTags.map((rt) {
            final closed = rt.status == 'DISPOSED' || rt.status == 'CLOSED';
            return InkWell(
              onTap: () async {
                setState(() {
                  rt.status = rt.status == 'OPEN'
                      ? 'IN_PROGRESS'
                      : (rt.status == 'IN_PROGRESS'
                          ? 'DISPOSED'
                          : (rt.status == 'DISPOSED' ? 'CLOSED' : 'OPEN'));
                  audit.recalculate(_redTags);
                });
                await KaizenActivityStore.instance.sync5RAction(
                  audit: audit,
                  redTags: _redTags,
                  shadowBoard: _shadowBoard,
                  action: 'updateRedTag',
                  payload: {'id': rt.id, 'status': rt.status},
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        rt.tagNumber,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('${rt.itemName} [${rt.category}]', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(rt.stationLocation, style: const TextStyle(fontSize: 10)),
                    ),
                    SizedBox(
                      width: 115,
                      child: Text(rt.reason, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                    SizedBox(
                      width: 135,
                      child: Text('${rt.assignedPic}\n(${rt.dispositionAction})', style: const TextStyle(fontSize: 9.5)),
                    ),
                    SizedBox(
                      width: 95,
                      child: Text(rt.expiryDate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      width: 105,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: closed ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rt.status,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: closed ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShadowBoardGrid(FiveRAuditMaster audit) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _shadowBoard.map((tool) {
        return InkWell(
          onTap: () async {
            final user = AuthService.instance.currentUser?.name ?? 'Operator';
            setState(() {
              tool.isPresent = !tool.isPresent;
              tool.borrowerPic = tool.isPresent ? null : user;
            });
            await KaizenActivityStore.instance.sync5RAction(
              audit: audit,
              redTags: _redTags,
              shadowBoard: _shadowBoard,
              action: 'toggleToolPresent',
              payload: {'toolId': tool.id, 'borrowerPic': user},
            );
          },
          child: Container(
            width: 332,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tool.isPresent ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              border: Border.all(
                color: tool.isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tool.shadowAddress,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w900),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: tool.isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      child: Text(
                        tool.isPresent ? 'ADA DI PAPAN' : 'DIPINJAM',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tool.toolName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kode: ${tool.toolCode} · Kondisi: ${tool.condition}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                Text(
                  tool.isPresent
                      ? 'Tap untuk pinjam / ambil perkakas'
                      : 'Peminjam: ${tool.borrowerPic ?? "Operator"} (Tap untuk kembalikan)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: tool.isPresent ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
