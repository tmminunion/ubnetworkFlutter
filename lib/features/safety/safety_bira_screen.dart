import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';

class BiraRecord {
  BiraRecord({
    required this.id,
    required this.tanggal,
    required this.shift,
    required this.observer,
    required this.memberObserved,
    required this.pos,
    required this.perilaku,
    required this.kategori,
    required this.bimbinganDiberikan,
    required this.komitmenMember,
  });

  final String id;
  final String tanggal;
  final String shift; // WHITE | RED
  final String observer;
  final String memberObserved;
  final String pos;
  final String perilaku;
  final String kategori; // Safe Action | Unsafe Action | Nearmiss
  final String bimbinganDiberikan;
  final String komitmenMember;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal,
        'shift': shift,
        'observer': observer,
        'memberObserved': memberObserved,
        'pos': pos,
        'perilaku': perilaku,
        'kategori': kategori,
        'bimbinganDiberikan': bimbinganDiberikan,
        'komitmenMember': komitmenMember,
      };

  factory BiraRecord.fromJson(Map<String, dynamic> json) => BiraRecord(
        id: (json['id'] ?? '').toString(),
        tanggal: (json['tanggal'] ?? '').toString(),
        shift: (json['shift'] ?? 'WHITE').toString(),
        observer: (json['observer'] ?? '').toString(),
        memberObserved: (json['memberObserved'] ?? '').toString(),
        pos: (json['pos'] ?? '').toString(),
        perilaku: (json['perilaku'] ?? '').toString(),
        kategori: (json['kategori'] ?? 'Safe Action').toString(),
        bimbinganDiberikan: (json['bimbinganDiberikan'] ?? '').toString(),
        komitmenMember: (json['komitmenMember'] ?? '').toString(),
      );
}

List<BiraRecord> defaultBiraRecords() => [
      BiraRecord(
        id: 'BIRA-2026-11-01',
        tanggal: '2026-11-03',
        shift: 'WHITE',
        observer: 'NUNU FATULAH',
        memberObserved: 'Sugeng Suryadi',
        pos: 'Pos 1 Underbody Main',
        perilaku: 'Operator mematikan sakelar isolasi sebelum menjangkau part yang macet di fixture',
        kategori: 'Safe Action',
        bimbinganDiberikan: 'Memberikan apresiasi atas kepatuhan prosedur Stop-Call-Wait dan tidak memaksakan tangan masuk',
        komitmenMember: 'Akan konsisten mempertahankan kebiasaan kerja aman dan mengingatkan rekan kerja',
      ),
      BiraRecord(
        id: 'BIRA-2026-11-02',
        tanggal: '2026-11-02',
        shift: 'WHITE',
        observer: 'DWI MULYONO',
        memberObserved: 'Yana Suheryana',
        pos: 'Pos 2 Cross Member',
        perilaku: 'Tali safety helmet agak kendur saat membungkuk memeriksa spot weld',
        kategori: 'Unsafe Action',
        bimbinganDiberikan: 'Mengingatkan langsung di tempat agar tali dagu helm selalu terkunci kencang 2 jari',
        komitmenMember: 'Langsung mengencangkan tali helm dan mengecek ulang sebelum mulai siklus berikutnya',
      ),
    ];

class SafetyBiraScreen extends StatefulWidget {
  const SafetyBiraScreen({super.key});

  @override
  State<SafetyBiraScreen> createState() => _SafetyBiraScreenState();
}

class _SafetyBiraScreenState extends State<SafetyBiraScreen> {
  static const _kBira = 'ubf_safety_bira_v1';

  List<BiraRecord> _records = defaultBiraRecords();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBira);
    List<BiraRecord> list = defaultBiraRecords();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list = decoded.whereType<Map>().map((m) => BiraRecord.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _records = list;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBira, jsonEncode(_records.map((r) => r.toJson()).toList()));
  }

  Future<void> _openCreateModal() async {
    var shift = 'WHITE';
    var kategori = 'Safe Action';
    final posCtrl = TextEditingController(text: 'Pos 1 Underbody Main');
    final obsCtrl = TextEditingController(text: 'NUNU FATULAH');
    final memCtrl = TextEditingController();
    final perCtrl = TextEditingController();
    final bimCtrl = TextEditingController();

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
                  const Text('Catatan BIRA K3 Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: shift,
                          decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'WHITE', child: Text('WHITE Shift')),
                            DropdownMenuItem(value: 'RED', child: Text('RED Shift')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => shift = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: posCtrl,
                          decoration: const InputDecoration(labelText: 'Pos Kerja', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: obsCtrl,
                          decoration: const InputDecoration(labelText: 'Observer (GL/TL)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: memCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Member', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: ['Safe Action', 'Unsafe Action', 'Nearmiss'].map((k) {
                      return ChoiceChip(
                        label: Text(k, style: const TextStyle(fontSize: 11)),
                        selected: kategori == k,
                        selectedColor: UbColors.emerald.withValues(alpha: 0.25),
                        onSelected: (_) => setM(() => kategori = k),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: perCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Perilaku yang Diamati', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bimCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Bimbingan & Arahan Diberikan', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.emerald, foregroundColor: UbColors.bg),
                    onPressed: () {
                      if (memCtrl.text.trim().isEmpty || perCtrl.text.trim().isEmpty || bimCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Harap lengkapi nama member, perilaku, dan bimbingan.')),
                        );
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Simpan BIRA', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (saved == true) {
        final today = UbMasterData.wibToday();
        final ym = today.substring(0, 7);
        final rec = BiraRecord(
          id: 'BIRA-$ym-${(_records.length + 1).toString().padLeft(2, '0')}',
          tanggal: today,
          shift: shift,
          observer: obsCtrl.text.trim(),
          memberObserved: memCtrl.text.trim(),
          pos: posCtrl.text.trim(),
          perilaku: perCtrl.text.trim(),
          kategori: kategori,
          bimbinganDiberikan: bimCtrl.text.trim(),
          komitmenMember: 'Berkomitmen mematuhi SOP K3 Underbody',
        );
        setState(() => _records = [rec, ..._records]);
        await _save();
      }
    } finally {
      posCtrl.dispose();
      obsCtrl.dispose();
      memCtrl.dispose();
      perCtrl.dispose();
      bimCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePct = _records.isEmpty
        ? 0
        : ((_records.where((r) => r.kategori == 'Safe Action').length / _records.length) * 100).round();

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BIRA (Bimbingan & Arahan K3)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Coaching Empatik & Observasi Perilaku', style: TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: UbColors.emerald,
                      foregroundColor: UbColors.bg,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: _openCreateModal,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('BIRA', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _kpiTile('Total Bimbingan', '${_records.length} Sesi', UbColors.emerald),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _kpiTile('Safe Behavior', '$safePct%', UbColors.cyan),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ..._records.map(_buildBiraCard),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: UbColors.textMuted)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildBiraCard(BiraRecord r) {
    final badgeColor = r.kategori == 'Safe Action'
        ? UbColors.emerald
        : (r.kategori == 'Unsafe Action' ? UbColors.amber : UbColors.rose);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            children: [
              Text(r.id, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.cyan)),
              const SizedBox(width: 8),
              Text('${r.tanggal} (${r.shift})', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: UbColors.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(r.kategori, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${r.memberObserved} · ${r.pos}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Perilaku: ${r.perilaku}', style: const TextStyle(fontSize: 12, color: UbColors.textMuted, height: 1.35)),
          const SizedBox(height: 4),
          Text('Bimbingan: ${r.bimbinganDiberikan}', style: const TextStyle(fontSize: 12, color: Color(0xFF6EE7B7), height: 1.35)),
          const SizedBox(height: 6),
          Text('Observer: ${r.observer}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
        ],
      ),
    );
  }
}
