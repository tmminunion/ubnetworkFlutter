import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/kaizen_activity_models.dart';
import '../../services/kaizen_activity_store.dart';
import 'ireporter_paper_canvas.dart';

enum _SwPaperMode { tskk, observation }

class SwObservasiScreen extends StatefulWidget {
  const SwObservasiScreen({super.key});

  @override
  State<SwObservasiScreen> createState() => _SwObservasiScreenState();
}

class _SwObservasiScreenState extends State<SwObservasiScreen> {
  final GlobalKey _paperKey = GlobalKey();

  List<SwProfile> _profiles = [];
  SwProfile? _activeProfile;
  List<SwJob> _jobs = [];
  SwJob? _activeJob;
  List<SwElement> _elements = [];
  List<SwObservation> _observations = [];
  _SwPaperMode _mode = _SwPaperMode.tskk;

  bool _loading = true;
  bool _online = false;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _load(profileId: 'prof-tt-24');
  }

  Future<void> _load({required String profileId, String? jobId}) async {
    setState(() => _loading = true);
    final res = await KaizenActivityStore.instance.loadSw(
      profileId: profileId,
      jobId: jobId,
    );
    if (!mounted) return;
    setState(() {
      _profiles = res.profiles;
      _activeProfile = res.activeProfile;
      _jobs = res.jobs;
      _activeJob = res.activeJob;
      _elements = res.elements;
      _observations = res.observations;
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
    final job = _activeJob;
    if (job == null || _printing) return;
    setState(() => _printing = true);
    try {
      await IReporterPaperCanvas.printA3Landscape(
        context: context,
        boundaryKey: _paperKey,
        fileName: 'SW_${_mode.name.toUpperCase()}_${job.jobCode}.pdf',
      );
    } catch (e) {
      _toast('Gagal cetak PDF A3: $e', isErr: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  void _showEisModal(SwElement el) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: UbColors.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (el.eisId ?? 'EIS-STD').toUpperCase(),
                      style: const TextStyle(color: UbColors.cyan, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Element Instruction Sheet (EIS)',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(el.title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: UbColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: UbColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Built-in Quality: ${el.qualityPoint}', style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Safety & APD: ${el.safetyPoint}', style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.w700)),
                    const Divider(color: Colors.white12, height: 16),
                    const Text(
                      'Parameter Standar Mesin Spot Gun Px 10:\n• Weld Current: 9.8 kA (Inverter MF)\n• Weld Time: 14 cycles (280 ms)\n• Pressure: 350 daN (0.45 MPa)\n• Pitch Spot: 30 ± 2 mm',
                      style: TextStyle(fontFamily: 'monospace', color: UbColors.textMuted, fontSize: 11.5, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openElementModal({SwElement? existing}) async {
    final job = _activeJob;
    if (job == null) return;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final manCtrl = TextEditingController(text: (existing?.manualTime ?? 6.0).toString());
    final macCtrl = TextEditingController(text: (existing?.machineTime ?? 0.0).toString());
    final walkCtrl = TextEditingController(text: (existing?.walkTime ?? 1.5).toString());
    final qCtrl = TextEditingController(text: existing?.qualityPoint ?? 'Inspeksi visual BIQ');
    final sCtrl = TextEditingController(text: existing?.safetyPoint ?? 'Wajib APD sarung tangan & goggle');

    final action = await showModalBottomSheet<String>(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    existing == null ? 'Tambah Elemen Kerja TSKK' : 'Edit Langkah ${existing.stepNumber} TSKK',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  if (existing != null)
                    Row(
                      children: [
                        if (existing.hasEIS)
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showEisModal(existing);
                            },
                            child: const Text('Lihat EIS', style: TextStyle(color: UbColors.cyan)),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx, 'delete'),
                          icon: const Icon(Icons.delete_outline, color: UbColors.rose),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Uraian Elemen Kerja Standar'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: manCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Manual (s)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: macCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Mesin (s)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: walkCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Jalan (s)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Titik Kritis Kualitas (BIQ)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Poin Keselamatan (Safety / APD)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: UbColors.primaryBlue),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, 'save');
                },
                child: const Text('Simpan Elemen TSKK', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'delete' && existing != null) {
      setState(() {
        _elements.removeWhere((e) => e.id == existing.id);
        for (var i = 0; i < _elements.length; i++) {
          _elements[i].stepNumber = i + 1;
        }
      });
      await KaizenActivityStore.instance.saveSwElements(
        jobId: job.id,
        elements: _elements,
        deletedId: existing.id,
      );
      _toast('Elemen kerja dihapus');
    } else if (action == 'save' && titleCtrl.text.trim().isNotEmpty) {
      final man = double.tryParse(manCtrl.text.trim()) ?? 5.0;
      final mac = double.tryParse(macCtrl.text.trim()) ?? 0.0;
      final wlk = double.tryParse(walkCtrl.text.trim()) ?? 1.0;

      SwElement target;
      if (existing != null) {
        setState(() {
          existing.title = titleCtrl.text.trim();
          existing.manualTime = man;
          existing.machineTime = mac;
          existing.walkTime = wlk;
          existing.qualityPoint = qCtrl.text.trim();
          existing.safetyPoint = sCtrl.text.trim();
        });
        target = existing;
      } else {
        target = SwElement(
          id: 'el-${job.id}-${DateTime.now().millisecondsSinceEpoch}',
          jobId: job.id,
          stepNumber: _elements.length + 1,
          title: titleCtrl.text.trim(),
          manualTime: man,
          machineTime: mac,
          walkTime: wlk,
          qualityPoint: qCtrl.text.trim(),
          safetyPoint: sCtrl.text.trim(),
          hasEIS: false,
        );
        setState(() => _elements.add(target));
      }
      final synced = await KaizenActivityStore.instance.saveSwElements(
        jobId: job.id,
        elements: _elements,
        upserted: target,
      );
      _toast(synced ? 'TSKK tersimpan & sinkron ke server' : 'TSKK tersimpan di cache lokal');
    }

    titleCtrl.dispose();
    manCtrl.dispose();
    macCtrl.dispose();
    walkCtrl.dispose();
    qCtrl.dispose();
    sCtrl.dispose();
  }

  Future<void> _editObservationModal(SwObservation obs) async {
    final job = _activeJob;
    if (job == null) return;
    final manCtrl = TextEditingController(text: obs.actualManualSec.toString());
    final macCtrl = TextEditingController(text: obs.actualMachineSec.toString());
    final wlkCtrl = TextEditingController(text: obs.actualWalkSec.toString());
    final mudaCtrl = TextEditingController(text: obs.wasteMotionNotes);
    final cmCtrl = TextEditingController(text: obs.countermeasure);

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
                'Input Stopwatch Siklus #${obs.cycleNo} (${job.jobCode})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: manCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Manual (s)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: macCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Mesin (s)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: wlkCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Jalan (s)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mudaCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Catatan Pemborosan Gerak (Muda)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cmCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Rencana Perbaikan Kaizen'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: UbColors.emerald),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Simpan Observasi Siklus', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      setState(() {
        obs.actualManualSec = double.tryParse(manCtrl.text.trim()) ?? obs.actualManualSec;
        obs.actualMachineSec = double.tryParse(macCtrl.text.trim()) ?? obs.actualMachineSec;
        obs.actualWalkSec = double.tryParse(wlkCtrl.text.trim()) ?? obs.actualWalkSec;
        obs.varianceSec = double.parse((obs.actualTotalSec - job.targetCycleTime).toStringAsFixed(1));
        obs.wasteMotionNotes = mudaCtrl.text.trim();
        obs.countermeasure = cmCtrl.text.trim();
        obs.status = obs.varianceSec > 3
            ? 'OVER_CYCLE'
            : (obs.varianceSec > 0 ? 'KAIZEN_NEEDED' : 'NORMAL');
      });
      final synced = await KaizenActivityStore.instance.saveSwObservation(
        jobId: job.id,
        observations: _observations,
        updated: obs,
      );
      _toast(synced ? 'Siklus #${obs.cycleNo} sinkron ke server' : 'Siklus #${obs.cycleNo} tersimpan lokal');
    }

    manCtrl.dispose();
    macCtrl.dispose();
    wlkCtrl.dispose();
    mudaCtrl.dispose();
    cmCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prof = _activeProfile;
    final job = _activeJob;

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
                          ..._profiles.map((p) {
                            final sel = p.id == prof?.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text('TT ${p.taktTime}m (${p.totalJobs} Pos)'),
                                selected: sel,
                                visualDensity: VisualDensity.compact,
                                selectedColor: p.id == 'prof-tt-24' ? UbColors.primaryBlue : UbColors.amber,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: sel ? Colors.white : UbColors.textMuted,
                                ),
                                onSelected: (_) => _load(profileId: p.id),
                              ),
                            );
                          }),
                          ChoiceChip(
                            label: const Text('Lembar TSKK'),
                            selected: _mode == _SwPaperMode.tskk,
                            visualDensity: VisualDensity.compact,
                            selectedColor: const Color(0xFF0284C7),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _mode == _SwPaperMode.tskk ? Colors.white : UbColors.textMuted,
                            ),
                            onSelected: (_) => setState(() => _mode = _SwPaperMode.tskk),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Observasi 10x'),
                            selected: _mode == _SwPaperMode.observation,
                            visualDensity: VisualDensity.compact,
                            selectedColor: UbColors.emerald,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _mode == _SwPaperMode.observation ? Colors.white : UbColors.textMuted,
                            ),
                            onSelected: (_) => setState(() => _mode = _SwPaperMode.observation),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: prof == null ? null : () => _load(profileId: prof.id, jobId: job?.id),
                    icon: Icon(
                      _online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: 18,
                      color: _online ? UbColors.emerald : UbColors.amber,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (_mode == _SwPaperMode.tskk)
                    IconButton(
                      onPressed: () => _openElementModal(),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 19, color: UbColors.cyan),
                      tooltip: 'Tambah Elemen Kerja',
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

            // SUB-HEADER: HORIZONTAL POS / JOB NAVIGATOR
            if (_jobs.isNotEmpty && prof != null)
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
                    children: _jobs.map((j) {
                      final sel = j.id == job?.id;
                      return GestureDetector(
                        onTap: () => _load(profileId: prof.id, jobId: j.id),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: sel ? UbColors.cyan : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${j.jobCode} · Pos ${j.posNumber}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: sel ? const Color(0xFF020617) : Colors.white70,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // FULLSCREEN i-REPORTER A3 PAPER CANVAS
            Expanded(
              child: _loading || prof == null || job == null
                  ? const Center(child: CircularProgressIndicator())
                  : IReporterPaperCanvas(
                      paperBoundaryKey: _paperKey,
                      dotColor: const Color(0xFF38BDF8),
                      paperChild: _buildSwPaper(prof, job),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwPaper(SwProfile prof, SwJob job) {
    const borderBold = BorderSide(color: Color(0xFF0F172A), width: 2.2);
    const borderThin = BorderSide(color: Color(0xFF0F172A), width: 1.1);
    final totalMan = _elements.fold(0.0, (a, b) => a + b.manualTime);
    final totalMac = _elements.fold(0.0, (a, b) => a + b.machineTime);
    final totalWalk = _elements.fold(0.0, (a, b) => a + b.walkTime);
    final totalCycle = totalMan + totalMac + totalWalk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // HEADER RESMI TOYOTA SWCS / SWOS
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
                          'PRODUCTION DIVISION — WELDING PLANT #1 (UNDERBODY ASSY)',
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
                            color: Color(0xFFFEF08A),
                            border: Border.fromBorderSide(borderThin),
                          ),
                          child: Text(
                            _mode == _SwPaperMode.tskk
                                ? 'TABEL STANDAR KERJA KOMBINASI (TSKK / SWCS)'
                                : 'LEMBAR OBSERVASI SIKLUS WAKTU & KAIZEN (TIME STUDY)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${prof.lineCode} · ${prof.title} · ${prof.version}',
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border.fromBorderSide(borderBold),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TAKT TIME: ${prof.taktTimeSec} dtk',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                        ),
                        Text(
                          'Target CT: ${job.targetCycleTime}s | Aktual: ${totalCycle.toStringAsFixed(1)}s',
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
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
                      'Job / Stasiun: [${job.jobCode}] ${job.posName}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Part: ${job.partName} (${job.partNo})',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Operator: ${job.operatorPic} (${job.stationType})',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (_mode == _SwPaperMode.tskk)
          _buildTskkTable(prof, totalMan, totalMac, totalWalk, totalCycle)
        else
          _buildObservationTable(job),
      ],
    );
  }

  Widget _buildTskkTable(
    SwProfile prof,
    double totalMan,
    double totalMac,
    double totalWalk,
    double totalCycle,
  ) {
    final maxScaleSec = (prof.taktTimeSec + 16).toDouble();
    var cursorSec = 0.0;

    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF0F172A), width: 2)),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            child: Row(
              children: [
                const SizedBox(width: 34, child: Text('NO', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900))),
                const Expanded(flex: 4, child: Text('URAIAN ELEMEN KERJA (TAP BARIS UNTUK EDIT / EIS)', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900))),
                const SizedBox(width: 52, child: Text('MAN', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900))),
                const SizedBox(width: 52, child: Text('AUTO', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900))),
                const SizedBox(width: 52, child: Text('WALK', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900))),
                const SizedBox(width: 56, child: Text('TOTAL', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFEF08A), fontSize: 9.5, fontWeight: FontWeight.w900))),
                Expanded(
                  flex: 5,
                  child: Text(
                    'GRAFIK KOMBINASI WAKTU DETIK (GARIS MERAH = TAKT TIME ${prof.taktTimeSec}s)',
                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          ..._elements.map((el) {
            final startFrac = (cursorSec / maxScaleSec).clamp(0.0, 0.95);
            final manFrac = (el.manualTime / maxScaleSec).clamp(0.0, 1.0 - startFrac);
            final macFrac = (el.machineTime / maxScaleSec).clamp(0.0, 1.0 - startFrac - manFrac);
            final walkFrac = (el.walkTime / maxScaleSec).clamp(0.0, 1.0 - startFrac - manFrac - macFrac);
            final ttFrac = (prof.taktTimeSec / maxScaleSec).clamp(0.0, 1.0);
            cursorSec += el.manualTime + el.walkTime;

            return InkWell(
              onTap: () => _openElementModal(existing: el),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text('${el.stepNumber}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(el.title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                                ),
                                if (el.hasEIS)
                                  GestureDetector(
                                    onTap: () => _showEisModal(el),
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      color: const Color(0xFF0284C7),
                                      child: const Text('EIS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              'BIQ: ${el.qualityPoint} · K3: ${el.safetyPoint}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 52, child: Text('${el.manualTime}', textAlign: TextAlign.center)),
                    SizedBox(width: 52, child: Text('${el.machineTime}', textAlign: TextAlign.center)),
                    SizedBox(width: 52, child: Text('${el.walkTime}', textAlign: TextAlign.center)),
                    SizedBox(
                      width: 56,
                      child: Text(
                        el.totalTime.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    // Visual TSKK Bar + Red Takt Time Line
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 22,
                        child: LayoutBuilder(
                          builder: (ctx, box) {
                            final w = box.maxWidth;
                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(height: 18, color: const Color(0xFFF1F5F9)),
                                Positioned(
                                  left: w * startFrac,
                                  child: Row(
                                    children: [
                                      Container(width: w * manFrac, height: 10, color: const Color(0xFF0F172A)),
                                      if (macFrac > 0)
                                        Container(width: w * macFrac, height: 6, color: const Color(0xFF0284C7)),
                                      if (walkFrac > 0)
                                        Container(width: w * walkFrac, height: 6, color: const Color(0xFFD97706)),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: w * ttFrac,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(width: 2.2, color: const Color(0xFFDC2626)),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Summary Footer Row
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                const SizedBox(width: 34),
                const Expanded(
                  flex: 4,
                  child: Text('TOTAL WAKTU SIKLUS STANDAR (DETIK)', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                SizedBox(width: 52, child: Text(totalMan.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900))),
                SizedBox(width: 52, child: Text(totalMac.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900))),
                SizedBox(width: 52, child: Text(totalWalk.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900))),
                SizedBox(
                  width: 56,
                  child: Text(
                    totalCycle.toStringAsFixed(1),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                  ),
                ),
                const Expanded(
                  flex: 5,
                  child: Text(
                    'Legenda: [Hitam = Manual]  [Biru = Otomatis Mesin]  [Oranye = Jalan]  [Garis Merah = Takt Time]',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationTable(SwJob job) {
    final avg = _observations.isEmpty
        ? 0.0
        : _observations.fold(0.0, (a, b) => a + b.actualTotalSec) / _observations.length;
    final shortest = _observations.isEmpty
        ? 0.0
        : _observations.map((o) => o.actualTotalSec).reduce((a, b) => a < b ? a : b);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF0F172A), width: 2)),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF065F46),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            child: const Row(
              children: [
                SizedBox(width: 65, child: Text('SIKLUS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 75, child: Text('MANUAL', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 75, child: Text('MESIN', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 75, child: Text('JALAN', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 85, child: Text('TOTAL (s)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFEF08A), fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 80, child: Text('VAR (+/-)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                Expanded(flex: 3, child: Text('CATATAN PEMBOROSAN GERAK (MUDA)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                Expanded(flex: 3, child: Text('KAIZEN COUNTERMEASURE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                SizedBox(width: 105, child: Text('STATUS (TAP)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
              ],
            ),
          ),
          ..._observations.map((o) {
            final over = o.status == 'OVER_CYCLE';
            return InkWell(
              onTap: () => _editObservationModal(o),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 65, child: Text('#${o.cycleNo}', style: const TextStyle(fontWeight: FontWeight.w900))),
                    SizedBox(width: 75, child: Text('${o.actualManualSec}', textAlign: TextAlign.center)),
                    SizedBox(width: 75, child: Text('${o.actualMachineSec}', textAlign: TextAlign.center)),
                    SizedBox(width: 75, child: Text('${o.actualWalkSec}', textAlign: TextAlign.center)),
                    SizedBox(
                      width: 85,
                      child: Text(
                        o.actualTotalSec.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${o.varianceSec > 0 ? '+' : ''}${o.varianceSec.toStringAsFixed(1)}s',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: o.varianceSec > 0 ? const Color(0xFFB91C1C) : const Color(0xFF047857),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(o.wasteMotionNotes, style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(o.countermeasure, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Container(
                      width: 105,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: over ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        o.status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: over ? const Color(0xFFB91C1C) : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          Container(
            color: const Color(0xFFECFDF5),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Siklus Tercepat (Best Repeatable): ${shortest.toStringAsFixed(1)}s',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                ),
                Text(
                  'Rata-Rata 10 Siklus: ${avg.toStringAsFixed(1)}s (Target Pos: ${job.targetCycleTime}s)',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
