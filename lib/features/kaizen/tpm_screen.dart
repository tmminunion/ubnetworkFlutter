import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/kaizen_activity_models.dart';
import '../../services/auth_service.dart';
import '../../services/kaizen_activity_store.dart';
import '../checksheet/checksheet_screen.dart';
import '../productivity/chokotei_analytics_screen.dart';
import '../productivity/prod_monitoring_screen.dart';

class TpmScreen extends StatefulWidget {
  const TpmScreen({super.key});

  @override
  State<TpmScreen> createState() => _TpmScreenState();
}

class _TpmScreenState extends State<TpmScreen> {
  List<TpmActionPlan> _plans = [];
  Map<String, bool> _amChecks = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await KaizenActivityStore.instance.loadTpmPlans();
    final checks = await KaizenActivityStore.instance.loadTpmAmChecks();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _amChecks = checks;
      _loading = false;
    });
  }

  Future<void> _addActionPlanModal() async {
    final titleCtrl = TextEditingController();
    final picCtrl = TextEditingController(
      text: AuthService.instance.currentUser?.name ?? 'Shift Merah (GL Kamaludin)',
    );
    final dueCtrl = TextEditingController(text: '30 Nov 2026');
    var cat = 'Initial Cleaning';

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
                  'Tambah Action Plan / Fuguai Tag TPM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: cat,
                  dropdownColor: UbColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Kategori Pilar TPM'),
                  items: [
                    'Initial Cleaning',
                    'Source of Contamination',
                    'AM Standards',
                    'One Point Lesson',
                    'White Tag Fuguai',
                    'Red Tag Maintenance',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setM(() => cat = v ?? 'Initial Cleaning'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Uraian Temuan Fuguai / Rencana Pemeliharaan',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: picCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'PIC Pelaksana'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: dueCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Target Selesai'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: UbColors.emerald),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Simpan Action Plan TPM', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true && titleCtrl.text.trim().isNotEmpty) {
      setState(() {
        _plans.insert(
          0,
          TpmActionPlan(
            id: 'TPM-${(_plans.length + 1).toString().padLeft(2, '0')}',
            title: titleCtrl.text.trim(),
            pic: picCtrl.text.trim(),
            dueDate: dueCtrl.text.trim(),
            status: 'Pending',
            category: cat,
          ),
        );
      });
      await KaizenActivityStore.instance.saveTpmPlans(_plans);
    }
    titleCtrl.dispose();
    picCtrl.dispose();
    dueCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = KaizenActivitySeeds.tpmSopItems.where((s) => _amChecks[s.id] == true).length;
    final amPct = ((checkedCount / KaizenActivitySeeds.tpmSopItems.length) * 100).round();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.bg,
        title: const Text(
          'TPM (Jishu Hozen)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.emerald,
        foregroundColor: Colors.white,
        onPressed: _addActionPlanModal,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Fuguai / Plan', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
              children: [
                // Hero Banner 1:1 TPM Next.js
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0D9488).withValues(alpha: 0.28),
                        UbColors.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: UbColors.emerald.withValues(alpha: 0.4)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STANDAR SHOPFLOOR • AUTONOMOUS MAINTENANCE',
                        style: TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Total Productive Maintenance (TPM)',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Rawat Mesin Seperti Milik Sendiri Demi Zero Breakdown & Zero Defect. Melibatkan seluruh operator Underbody dalam pembersihan sebagai inspeksi (CLIT) dan eliminasi Chokotei.',
                        style: TextStyle(color: UbColors.textMuted, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4 KPI Cards (OEE, MTBF, MTTR, AM Compliance)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.55,
                  children: KaizenActivitySeeds.tpmMetrics.map((m) {
                    final val = m.label.contains('Autonomous') ? '$amPct' : m.value;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: UbColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: UbColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: UbColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                val,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                m.unit,
                                style: const TextStyle(color: UbColors.emerald, fontSize: 11.5, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          Text(
                            m.statusText,
                            style: const TextStyle(color: UbColors.cyan, fontSize: 10.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // SOP Jishu Hozen Interactive Checklist
                const Text(
                  'Standar Pemeliharaan Mandiri (Jishu Hozen)',
                  style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ...KaizenActivitySeeds.tpmSopItems.map((sop) {
                  final checked = _amChecks[sop.id] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: UbColors.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: checked ? UbColors.emerald.withValues(alpha: 0.4) : UbColors.border,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: checked,
                      activeColor: UbColors.emerald,
                      onChanged: (v) async {
                        setState(() => _amChecks[sop.id] = v ?? false);
                        await KaizenActivityStore.instance.saveTpmAmChecks(_amChecks);
                      },
                      title: Text(
                        sop.title,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sop.desc, style: const TextStyle(color: UbColors.textMuted, fontSize: 11.5)),
                            const SizedBox(height: 4),
                            Text(
                              sop.standard,
                              style: const TextStyle(fontFamily: 'monospace', color: UbColors.cyan, fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Action Plans TPM
                const Text(
                  'Action Plan & Fuguai Tagging TPM',
                  style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ..._plans.map((p) {
                  final col = p.status == 'Done'
                      ? UbColors.emerald
                      : (p.status == 'In Progress' ? UbColors.amber : UbColors.cyan);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: UbColors.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: col.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${p.id} • ${p.category}',
                              style: const TextStyle(fontFamily: 'monospace', color: UbColors.cyan, fontSize: 10.5, fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  p.status = p.status == 'Pending'
                                      ? 'In Progress'
                                      : (p.status == 'In Progress' ? 'Done' : 'Pending');
                                });
                                await KaizenActivityStore.instance.saveTpmPlans(_plans);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: col.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  p.status,
                                  style: TextStyle(color: col, fontSize: 10.5, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                setState(() => _plans.removeWhere((x) => x.id == p.id));
                                await KaizenActivityStore.instance.saveTpmPlans(_plans);
                              },
                              icon: const Icon(Icons.delete_outline, size: 17, color: UbColors.textMuted),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('PIC: ${p.pic} • Target: ${p.dueDate}', style: const TextStyle(color: UbColors.textMuted, fontSize: 11.5)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Modul Terkait (1:1 Next.js Related Links)
                const Text(
                  'Integrasi Modul Produktivitas & Mesin',
                  style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                _relatedTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Analisis Chokotei & Pareto 80/20',
                  subtitle: 'Pantau ranking mesin paling sering mengalami minor stoppage',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChokoteiAnalyticsScreen())),
                ),
                _relatedTile(
                  icon: Icons.assignment_rounded,
                  title: 'Daily Production Checksheet A3',
                  subtitle: 'Catat menit line stop akibat kendala mesin per jam',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChecksheetScreen())),
                ),
                _relatedTile(
                  icon: Icons.trending_up_rounded,
                  title: 'Monitoring Produksi Bulanan 1–31',
                  subtitle: 'Evaluasi dampak downtime mesin terhadap target efisiensi 98%',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProdMonitoringScreen())),
                ),
              ],
            ),
    );
  }

  Widget _relatedTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        tileColor: UbColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: UbColors.border),
        ),
        leading: Icon(icon, color: UbColors.emerald),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(color: UbColors.textMuted, fontSize: 11.5)),
        trailing: const Icon(Icons.chevron_right_rounded, color: UbColors.textMuted),
      ),
    );
  }
}
