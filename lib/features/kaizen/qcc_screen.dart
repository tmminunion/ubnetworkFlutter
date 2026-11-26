import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/kaizen_activity_models.dart';
import '../../services/kaizen_activity_store.dart';
import 'ireporter_paper_canvas.dart';

class QccScreen extends StatefulWidget {
  const QccScreen({super.key});

  @override
  State<QccScreen> createState() => _QccScreenState();
}

class _QccScreenState extends State<QccScreen> {
  final GlobalKey _paperKey = GlobalKey();

  List<QccCircle> _circles = [];
  QccCircle? _activeCircle;
  QccA3Report? _report;
  bool _loading = true;
  bool _online = false;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _load('circle-laser-precision');
  }

  Future<void> _load(String circleId) async {
    setState(() => _loading = true);
    final res = await KaizenActivityStore.instance.loadQcc(circleId);
    if (!mounted) return;
    setState(() {
      _circles = res.circles;
      _activeCircle = res.activeCircle;
      _report = res.report;
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
    final rep = _report;
    if (rep == null || _printing) return;
    setState(() => _printing = true);
    try {
      await IReporterPaperCanvas.printA3Landscape(
        context: context,
        boundaryKey: _paperKey,
        fileName: 'QCC_A3_${rep.themeNo}.pdf',
      );
    } catch (e) {
      _toast('Gagal cetak PDF A3: $e', isErr: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _editMetaModal() async {
    final rep = _report;
    if (rep == null) return;
    final titleCtrl = TextEditingController(text: rep.title);
    final dateCtrl = TextEditingController(text: rep.conventionDate);
    var cat = rep.kpiCategory;
    var status = rep.status;
    var step = rep.currentStep;

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
                  'Edit Header Risalah A3 QCC',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Judul Tema Perbaikan QCC'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: cat,
                        dropdownColor: UbColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Pilar QCDSM'),
                        items: ['QUALITY', 'COST', 'DELIVERY', 'SAFETY', 'MORALE']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setM(() => cat = v ?? 'QUALITY'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        dropdownColor: UbColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Status Risalah'),
                        items: ['DRAFT', 'REVIEW', 'VERIFIED', 'CONVENTION_READY']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setM(() => status = v ?? 'DRAFT'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: step,
                        dropdownColor: UbColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Progress PDCA (1-8)'),
                        items: List.generate(8, (i) => i + 1)
                            .map((n) => DropdownMenuItem(value: n, child: Text('Step $n')))
                            .toList(),
                        onChanged: (v) => setM(() => step = v ?? 6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: dateCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Target Konvensi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: UbColors.indigo),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Simpan Header Risalah', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      setState(() {
        rep.title = titleCtrl.text.trim();
        rep.conventionDate = dateCtrl.text.trim();
        rep.kpiCategory = cat;
        rep.status = status;
        rep.currentStep = step;
      });
      final synced = await KaizenActivityStore.instance.saveQccReport(rep);
      _toast(synced ? 'Risalah tersimpan & disinkronkan ke server' : 'Tersimpan di cache lokal HP');
    }
    titleCtrl.dispose();
    dateCtrl.dispose();
  }

  Future<void> _editStepModal(int stepNo) async {
    final rep = _report;
    if (rep == null) return;
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final c3 = TextEditingController();

    String l1 = 'Uraian Utama';
    String l2 = 'Detail Tambahan';
    String? l3;

    if (stepNo == 1) {
      l1 = 'Latar Belakang Masalah';
      l2 = 'Baseline Defect (%)';
      l3 = 'Target Defect (%)';
      c1.text = rep.step1Background;
      c2.text = rep.baselineDefectRate.toString();
      c3.text = rep.targetDefectRate.toString();
    } else if (stepNo == 2) {
      l1 = 'Alur Proses Kerja';
      l2 = 'Area Kritis Stratifikasi';
      l3 = 'Fenomena Aktual Genba';
      c1.text = rep.step2Flow;
      c2.text = rep.step2CriticalArea;
      c3.text = rep.step2Phenomenon;
    } else if (stepNo == 3) {
      l1 = 'Akar Masalah Terverifikasi (pisahkan baris)';
      l2 = 'Metode Verifikasi';
      c1.text = rep.verifiedRootCauses.join('\n');
      c2.text = rep.verificationMethod;
    } else if (stepNo == 5) {
      l1 = 'Kondisi Sebelum (Before)';
      l2 = 'Kondisi Sesudah (After)';
      l3 = 'Detail Poka-Yoke Interlock';
      c1.text = rep.beforeCondition;
      c2.text = rep.afterCondition;
      c3.text = rep.pokaYokeDetails;
    } else if (stepNo == 6) {
      l1 = 'Defect Rate Aktual Setelah Kaizen (%)';
      l2 = 'Reduksi Cacat (%)';
      l3 = 'Penghematan Biaya (Tangible Saving)';
      c1.text = rep.resultDefectRate.toString();
      c2.text = rep.reductionPercentage.toString();
      c3.text = rep.tangibleSavingPerMonth;
    } else if (stepNo == 7) {
      l1 = 'Frekuensi Pemeriksaan Standar Baru';
      l2 = 'Target Lini Yokoten (pisahkan baris)';
      c1.text = rep.inspectionFrequency;
      c2.text = rep.yokotenTargets.join('\n');
    } else if (stepNo == 8) {
      l1 = 'Rencana Tema QCC Berikutnya';
      l2 = 'Target Tanggal Mulai';
      l3 = 'Refleksi Gugus QCC';
      c1.text = rep.nextThemeTitle;
      c2.text = rep.targetStartDate;
      c3.text = rep.circleReflections;
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Langkah $stepNo PDCA',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: c1,
                maxLines: stepNo == 1 || stepNo == 3 ? 3 : 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: l1),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: c2,
                maxLines: stepNo == 7 ? 3 : 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: l2),
              ),
              if (l3 != null) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: c3,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: l3),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: UbColors.indigo),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Simpan Langkah $stepNo', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      setState(() {
        if (stepNo == 1) {
          rep.step1Background = c1.text.trim();
          rep.baselineDefectRate = double.tryParse(c2.text.trim()) ?? rep.baselineDefectRate;
          rep.targetDefectRate = double.tryParse(c3.text.trim()) ?? rep.targetDefectRate;
        } else if (stepNo == 2) {
          rep.step2Flow = c1.text.trim();
          rep.step2CriticalArea = c2.text.trim();
          rep.step2Phenomenon = c3.text.trim();
        } else if (stepNo == 3) {
          rep.verifiedRootCauses = c1.text
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          rep.verificationMethod = c2.text.trim();
        } else if (stepNo == 5) {
          rep.beforeCondition = c1.text.trim();
          rep.afterCondition = c2.text.trim();
          rep.pokaYokeDetails = c3.text.trim();
        } else if (stepNo == 6) {
          rep.resultDefectRate = double.tryParse(c1.text.trim()) ?? rep.resultDefectRate;
          rep.reductionPercentage = double.tryParse(c2.text.trim()) ?? rep.reductionPercentage;
          rep.tangibleSavingPerMonth = c3.text.trim();
        } else if (stepNo == 7) {
          rep.inspectionFrequency = c1.text.trim();
          rep.yokotenTargets = c2.text
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        } else if (stepNo == 8) {
          rep.nextThemeTitle = c1.text.trim();
          rep.targetStartDate = c2.text.trim();
          rep.circleReflections = c3.text.trim();
        }
      });
      final synced = await KaizenActivityStore.instance.saveQccReport(rep, stepNumber: stepNo);
      _toast(synced ? 'Langkah $stepNo disinkronkan ke server' : 'Langkah $stepNo tersimpan lokal');
    }
    c1.dispose();
    c2.dispose();
    c3.dispose();
  }

  Future<void> _add5W2HModal() async {
    final rep = _report;
    if (rep == null) return;
    var factor = 'MACHINE';
    final whatCtrl = TextEditingController();
    final whyCtrl = TextEditingController();
    final whereCtrl = TextEditingController(text: 'Pos 1 Underbody');
    final whenCtrl = TextEditingController(text: '2026-11-30');
    final whoCtrl = TextEditingController(text: _activeCircle?.leaderPic ?? 'Tim QCC');
    final costCtrl = TextEditingController(text: 'Rp 500.000');

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
                  'Tambah Rencana Penanggulangan 5W2H',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: factor,
                  dropdownColor: UbColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Faktor 4M+1E'),
                  items: ['MAN', 'MACHINE', 'MATERIAL', 'METHOD', 'ENVIRONMENT']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setM(() => factor = v ?? 'MACHINE'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: whatCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'What (Tindakan Penanggulangan)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: whyCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Why (Alasan / Akar Masalah)'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: whereCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Where (Lokasi)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: whenCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'When (Target)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: whoCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Who (PIC)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'How Much (Biaya)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: UbColors.emerald),
                  onPressed: () {
                    if (whatCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Tambahkan ke Langkah 4', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true && whatCtrl.text.trim().isNotEmpty) {
      final newPlan = QccActionPlan5W2H(
        id: '5W2H-${DateTime.now().millisecondsSinceEpoch}',
        factor: factor,
        what: whatCtrl.text.trim(),
        why: whyCtrl.text.trim(),
        where: whereCtrl.text.trim(),
        when: whenCtrl.text.trim(),
        who: whoCtrl.text.trim(),
        how: 'Eksekusi Genba QCC',
        howMuch: costCtrl.text.trim(),
        status: 'PLANNED',
      );
      setState(() => rep.actionPlans.add(newPlan));
      await KaizenActivityStore.instance.saveQccReport(rep, savedPlan: newPlan);
      _toast('Tindakan 5W2H berhasil ditambahkan');
    }
    whatCtrl.dispose();
    whyCtrl.dispose();
    whereCtrl.dispose();
    whenCtrl.dispose();
    whoCtrl.dispose();
    costCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rep = _report;
    final circle = _activeCircle;

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // TOP CONTROL BAR
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: UbColors.indigo.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: UbColors.indigo.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'QCC A3',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFA5B4FC)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_circles.isNotEmpty && circle != null)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _circles.map((c) {
                            final sel = c.id == circle.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text('${c.circleName} (${c.level})'),
                                selected: sel,
                                visualDensity: VisualDensity.compact,
                                selectedColor: UbColors.indigo,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: sel ? Colors.white : UbColors.textMuted,
                                ),
                                onSelected: (_) => _load(c.id),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    onPressed: circle == null ? null : () => _load(circle.id),
                    icon: Icon(
                      _online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: 18,
                      color: _online ? UbColors.emerald : UbColors.amber,
                    ),
                    tooltip: _online ? 'Online · Sinkron /api/qcc' : 'Offline Cache · Tap muat ulang',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: _add5W2HModal,
                    icon: const Icon(Icons.add_task_rounded, size: 19, color: UbColors.cyan),
                    tooltip: 'Tambah Rencana 5W2H',
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

            // SUB-HEADER: 8 STEP PDCA TRACKER
            if (rep != null)
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
                      const Text(
                        'PDCA 8 STEP: ',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: UbColors.textMuted),
                      ),
                      ...List.generate(8, (idx) {
                        final st = idx + 1;
                        final done = st <= rep.currentStep;
                        final cur = st == rep.currentStep;
                        return GestureDetector(
                          onTap: () => st == 4 ? _add5W2HModal() : _editStepModal(st),
                          child: Container(
                            margin: const EdgeInsets.only(right: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cur
                                  ? UbColors.indigo
                                  : (done ? UbColors.emerald.withValues(alpha: 0.18) : const Color(0xFF1E293B)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: cur
                                    ? const Color(0xFF818CF8)
                                    : (done ? UbColors.emerald.withValues(alpha: 0.5) : Colors.white10),
                              ),
                            ),
                            child: Text(
                              'S$st${done ? ' ✓' : ''}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: cur ? Colors.white : (done ? const Color(0xFF6EE7B7) : UbColors.textMuted),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 10),
                      Text(
                        'Defect: ${rep.baselineDefectRate}% → ${rep.resultDefectRate}% (-${rep.reductionPercentage}%)',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6EE7B7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // FULLSCREEN i-REPORTER A3 PAPER CANVAS
            Expanded(
              child: _loading || rep == null || circle == null
                  ? const Center(child: CircularProgressIndicator())
                  : IReporterPaperCanvas(
                      paperBoundaryKey: _paperKey,
                      dotColor: const Color(0xFF6366F1),
                      paperChild: _buildQccA3Paper(circle, rep),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQccA3Paper(QccCircle circle, QccA3Report rep) {
    const borderBold = BorderSide(color: Color(0xFF0F172A), width: 2.2);
    const borderThin = BorderSide(color: Color(0xFF0F172A), width: 1.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. HEADER RESMI LEMBAR RISALAH A3 QCC TOYOTA (Tap to Edit Meta)
        InkWell(
          onTap: _editMetaModal,
          child: Container(
            decoration: BoxDecoration(border: Border.fromBorderSide(borderBold)),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'WELDING PLANT #1 — UNDERBODY ASSEMBLY DIVISION',
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              border: Border.fromBorderSide(borderThin),
                            ),
                            child: const Text(
                              'RISALAH GUGUS KENDALI MUTU (QCC A3 REPORT)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${rep.themeNo} · PILAR: ${rep.kpiCategory} · STEP ${rep.currentStep}/8',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Approval Box 4 Kolom
                    Container(
                      decoration: const BoxDecoration(border: Border.fromBorderSide(borderThin)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _stampCell('MGR', 'DWI H.'),
                          _stampCell('ADVISOR', 'SUHARTO'),
                          _stampCell('FACILITATOR', 'KAMAL'),
                          _stampCell('LEADER', 'FAUZI', last: true),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF0F172A), thickness: 1.5, height: 12),
                Row(
                  children: [
                    _metaCell('Nama Gugus QCC', '${circle.circleName} (${circle.level})', flex: 2),
                    _metaCell('Lini / Shift', '${circle.lineCode} · Shift ${circle.shift}', flex: 2),
                    _metaCell('Tema Perbaikan (Tap untuk Edit)', rep.title, flex: 4),
                    _metaCell('Target Konvensi', rep.conventionDate, flex: 2, bg: const Color(0xFFFEF3C7)),
                    _metaCell('Status Risalah', rep.status, flex: 2, bg: const Color(0xFFD1FAE5), last: true),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 2. GRID 8 KOTAK PDCA A3 (Kiri: Step 1-4 PLAN | Kanan: Step 5-8 DO-CHECK-ACTION)
        Container(
          decoration: const BoxDecoration(
            border: Border(left: borderBold, right: borderBold, bottom: borderBold),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // KOLOM KIRI: LANGKAH 1 - 4
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(border: Border(right: borderBold)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // STEP 1
                        _pdcaBox(
                          stepTitle: '1. MENENTUKAN TEMA & TARGET (PLAN)',
                          onTap: () => _editStepModal(1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rep.step1Background, style: const TextStyle(fontSize: 10.5)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        border: Border.all(color: const Color(0xFFFCA5A5)),
                                      ),
                                      child: Text(
                                        'Baseline Defect: ${rep.baselineDefectRate}%',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB91C1C)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        border: Border.all(color: const Color(0xFF6EE7B7)),
                                      ),
                                      child: Text(
                                        'Target Mutu: ≤ ${rep.targetDefectRate}% (${rep.targetDeadline})',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ...rep.paretoItems.map((p) {
                                final pct = (p['percentage'] as num?)?.toDouble() ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 175,
                                        child: Text(
                                          '${p['label']} (${p['count']})',
                                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Container(height: 10, color: const Color(0xFFE2E8F0)),
                                            FractionallySizedBox(
                                              widthFactor: (pct / 100).clamp(0.0, 1.0),
                                              child: Container(height: 10, color: const Color(0xFF4F46E5)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        width: 42,
                                        child: Text(
                                          '$pct%',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        // STEP 2
                        _pdcaBox(
                          stepTitle: '2. MEMAHAMI SITUASI & STRATIFIKASI GENBA',
                          onTap: () => _editStepModal(2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Alur: ${rep.step2Flow}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Area Kritis: ${rep.step2CriticalArea}', style: const TextStyle(fontSize: 10)),
                              const SizedBox(height: 3),
                              Text(
                                'Fenomena: ${rep.step2Phenomenon}',
                                style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                        // STEP 3
                        _pdcaBox(
                          stepTitle: '3. ANALISA PENYEBAB (FISHBONE 4M & AKAR MASALAH)',
                          onTap: () => _editStepModal(3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: rep.fishboneBranches.map((b) {
                                  return Container(
                                    width: 318,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: b.isRootCause ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                                      border: Border.all(
                                        color: b.isRootCause ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '[${b.category}] ${b.isRootCause ? '★ ROOT CAUSE' : 'OK'}',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            color: b.isRootCause ? const Color(0xFFB91C1C) : const Color(0xFF475569),
                                          ),
                                        ),
                                        Text(b.rootCause, style: const TextStyle(fontSize: 9.5)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Verifikasi: ${rep.verificationMethod}',
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                              ),
                            ],
                          ),
                        ),
                        // STEP 4 (5W2H Table Interactive)
                        _pdcaBox(
                          stepTitle: '4. RENCANA PENANGGULANGAN 5W2H (Budget: ${rep.totalEstimatedBudget})',
                          isLast: true,
                          trailingAction: '+ Tambah 5W2H',
                          onTap: _add5W2HModal,
                          child: Column(
                            children: [
                              Container(
                                color: const Color(0xFF1E293B),
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                child: const Row(
                                  children: [
                                    SizedBox(width: 62, child: Text('4M', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
                                    Expanded(flex: 4, child: Text('What (Penanggulangan)', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
                                    Expanded(flex: 2, child: Text('Who & When', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
                                    SizedBox(width: 78, child: Text('Biaya', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
                                    SizedBox(width: 74, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
                                  ],
                                ),
                              ),
                              ...rep.actionPlans.map((p) {
                                final done = p.status == 'COMPLETED';
                                return InkWell(
                                  onTap: () async {
                                    setState(() {
                                      p.status = p.status == 'PLANNED'
                                          ? 'IN_PROGRESS'
                                          : (p.status == 'IN_PROGRESS' ? 'COMPLETED' : 'PLANNED');
                                    });
                                    await KaizenActivityStore.instance.saveQccReport(rep, savedPlan: p);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 62,
                                          child: Text(p.factor, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(p.what, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('${p.who}\n(${p.when})', style: const TextStyle(fontSize: 9)),
                                        ),
                                        SizedBox(
                                          width: 78,
                                          child: Text(p.howMuch, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                                        ),
                                        Container(
                                          width: 74,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                          decoration: BoxDecoration(
                                            color: done ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            p.status,
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w900,
                                              color: done ? const Color(0xFF065F46) : const Color(0xFF92400E),
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
                        ),
                      ],
                    ),
                  ),
                ),

                // KOLOM KANAN: LANGKAH 5 - 8
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // STEP 5
                      _pdcaBox(
                        stepTitle: '5. PENERAPAN PENANGGULANGAN (DO — Trial: ${rep.trialDate})',
                        onTap: () => _editStepModal(5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rep.step5Summary, style: const TextStyle(fontSize: 10)),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: Text(
                                      'BEFORE:\n${rep.beforeCondition}',
                                      style: const TextStyle(fontSize: 9.5, color: Color(0xFF991B1B)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Text(
                                      'AFTER:\n${rep.afterCondition}',
                                      style: const TextStyle(fontSize: 9.5, color: Color(0xFF065F46)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (rep.pokaYokeImplemented) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  border: Border.all(color: const Color(0xFF93C5FD)),
                                ),
                                child: Text(
                                  'POKA-YOKE INTERLOCK: ${rep.pokaYokeDetails}',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // STEP 6
                      _pdcaBox(
                        stepTitle: '6. EVALUASI HASIL PERBAIKAN (CHECK)',
                        onTap: () => _editStepModal(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _kpiMiniCard('Sebelum', '${rep.baselineDefectRate}%', const Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                _kpiMiniCard('Sesudah', '${rep.resultDefectRate}%', const Color(0xFF059669)),
                                const SizedBox(width: 8),
                                _kpiMiniCard('Reduksi', '-${rep.reductionPercentage}%', const Color(0xFF2563EB)),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      border: Border.all(color: const Color(0xFFF59E0B)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Tangible Saving:', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700)),
                                        Text(
                                          rep.tangibleSavingPerMonth,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...rep.intangibleBenefits.map(
                              (b) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text('✓ $b', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // STEP 7
                      _pdcaBox(
                        stepTitle: '7. STANDARDISASI & PENCEGAHAN TERULANG (ACTION)',
                        onTap: () => _editStepModal(7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...rep.revisedDocuments.map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  '• [${d['docCode']}] ${d['docTitle']} — ${d['revNo']}',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kontrol Harian: ${rep.inspectionFrequency}',
                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF047857), fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Yokoten Lini: ${rep.yokotenTargets.join(' · ')}',
                              style: const TextStyle(fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                      // STEP 8
                      _pdcaBox(
                        stepTitle: '8. RENCANA TEMA SELANJUTNYA & REFLEKSI TIM',
                        isLast: true,
                        onTap: () => _editStepModal(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E7FF),
                                border: Border.all(color: const Color(0xFF818CF8)),
                              ),
                              child: Text(
                                'Next Theme (${rep.targetStartDate}): ${rep.nextThemeTitle}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF312E81)),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Refleksi Gugus: ${rep.circleReflections}',
                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stampCell(String role, String name, {bool last = false}) {
    return Container(
      width: 58,
      decoration: BoxDecoration(
        border: last ? null : const Border(right: BorderSide(color: Color(0xFF0F172A))),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              role,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFF0F172A)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaCell(String label, String val, {int flex = 1, Color? bg, bool last = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          border: last ? null : const Border(right: BorderSide(color: Color(0xFFCBD5E1))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
            Text(
              val,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdcaBox({
    required String stepTitle,
    required Widget child,
    required VoidCallback onTap,
    String trailingAction = 'Tap Edit',
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF0F172A), width: 1.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  color: const Color(0xFF0F172A),
                  child: Text(
                    stepTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  trailingAction,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }

  Widget _kpiMiniCard(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700)),
            Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}
