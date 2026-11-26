import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';

class NearmissLog {
  NearmissLog({
    required this.id,
    required this.tanggal,
    required this.lokasi,
    required this.deskripsi,
    required this.kategori,
    required this.countermeasure,
    required this.pic,
    required this.status,
  });

  final String id;
  final String tanggal;
  final String lokasi;
  final String deskripsi;
  final String kategori; // Terjepit | Tersayat | Terpeleset | Tertabrak
  final String countermeasure;
  final String pic;
  final String status; // Closed | In Progress

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'kategori': kategori,
        'countermeasure': countermeasure,
        'pic': pic,
        'status': status,
      };

  factory NearmissLog.fromJson(Map<String, dynamic> json) => NearmissLog(
        id: (json['id'] ?? '').toString(),
        tanggal: (json['tanggal'] ?? '').toString(),
        lokasi: (json['lokasi'] ?? '').toString(),
        deskripsi: (json['deskripsi'] ?? '').toString(),
        kategori: (json['kategori'] ?? 'Terjepit').toString(),
        countermeasure: (json['countermeasure'] ?? '').toString(),
        pic: (json['pic'] ?? '').toString(),
        status: (json['status'] ?? 'Closed').toString(),
      );
}

List<NearmissLog> defaultNearmissLogs() => [
      NearmissLog(
        id: 'NM-2026-089',
        tanggal: '2026-10-28',
        lokasi: 'Pos 1 Underbody Main',
        deskripsi: 'Kabel pneumatik selang klem menggelayut di dekat jalur kepala robot spot',
        kategori: 'Terjepit',
        countermeasure: 'Pemasangan cable chain guide baru & penataan ulang jalur selang oleh maintenance',
        pic: 'GL Kamaludin',
        status: 'Closed',
      ),
      NearmissLog(
        id: 'NM-2026-090',
        tanggal: '2026-11-01',
        lokasi: 'Buffer Area Rak Dolly Cross Member',
        deskripsi: 'Ceceran pelumas tipis dari roda troli dolly material yang macet',
        kategori: 'Terpeleset',
        countermeasure: 'Pembersihan seketika dengan absorbent pad & penggantian roda bearing troli',
        pic: 'TL Nunu Fatulah',
        status: 'Closed',
      ),
      NearmissLog(
        id: 'NM-2026-091',
        tanggal: '2026-11-02',
        lokasi: 'Pos 2 Respot Welding',
        deskripsi: 'Percikan gram las (spatter) melayang ke luar screen partisi pengaman',
        kategori: 'Tersayat',
        countermeasure: 'Perpanjangan screen pelindung transparan anti-spatter setinggi 2.2 meter',
        pic: 'Dwi Mulyono',
        status: 'In Progress',
      ),
    ];

class SafetyKpiScreen extends StatefulWidget {
  const SafetyKpiScreen({super.key});

  @override
  State<SafetyKpiScreen> createState() => _SafetyKpiScreenState();
}

class _SafetyKpiScreenState extends State<SafetyKpiScreen> {
  static const _kNearmiss = 'ubf_safety_nearmiss_v1';

  List<NearmissLog> _logs = defaultNearmissLogs();
  String _filterCategory = 'ALL';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kNearmiss);
    List<NearmissLog> list = defaultNearmissLogs();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list = decoded.whereType<Map>().map((m) => NearmissLog.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _logs = list;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNearmiss, jsonEncode(_logs.map((e) => e.toJson()).toList()));
  }

  Future<void> _openAddNearmiss() async {
    var kat = 'Terjepit';
    var status = 'In Progress';
    final lokCtrl = TextEditingController(text: 'Pos 1 Underbody Main');
    final descCtrl = TextEditingController();
    final cmCtrl = TextEditingController();
    final picCtrl = TextEditingController();

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
                  const Text('Catat Nearmiss (Hiyari Hatto)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lokCtrl,
                    decoration: const InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: ['Terjepit', 'Tersayat', 'Terpeleset', 'Tertabrak'].map((k) {
                      return ChoiceChip(
                        label: Text(k, style: const TextStyle(fontSize: 11)),
                        selected: kat == k,
                        selectedColor: UbColors.purple.withValues(alpha: 0.3),
                        onSelected: (_) => setM(() => kat = k),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Deskripsi Kejadian Nyaris Celaka', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cmCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Penanggulangan (Countermeasure)', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: picCtrl,
                          decoration: const InputDecoration(labelText: 'PIC', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                            DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => status = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.purple, foregroundColor: Colors.white),
                    onPressed: () {
                      if (descCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Simpan Nearmiss', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (saved == true) {
        final today = UbMasterData.wibToday();
        final item = NearmissLog(
          id: 'NM-${today.substring(0, 4)}-${(90 + _logs.length).toString().padLeft(3, '0')}',
          tanggal: today,
          lokasi: lokCtrl.text.trim(),
          deskripsi: descCtrl.text.trim(),
          kategori: kat,
          countermeasure: cmCtrl.text.trim().isEmpty ? 'Sedang ditindaklanjuti' : cmCtrl.text.trim(),
          pic: picCtrl.text.trim().isEmpty ? 'GL/TL Shift' : picCtrl.text.trim(),
          status: status,
        );
        setState(() => _logs = [item, ..._logs]);
        await _save();
      }
    } finally {
      lokCtrl.dispose();
      descCtrl.dispose();
      cmCtrl.dispose();
      picCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterCategory == 'ALL'
        ? _logs
        : _logs.where((n) => n.kategori == _filterCategory).toList();

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
                        Text('Safety KPI & Zero Accident', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Zero LTI Tracker & Hiyari Hatto', style: TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: UbColors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: _openAddNearmiss,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Nearmiss', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
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
                        // Hero Zero LTI Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: UbColors.emerald.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('REKOR ZERO LTI UNDERBODY', style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: UbColors.emerald)),
                                    SizedBox(height: 4),
                                    Text('Hari Kerja Selamat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                                    SizedBox(height: 2),
                                    Text('Sejak 05 Des 2022 tanpa Lost Time Injury', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: UbColors.bg.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: UbColors.emerald.withValues(alpha: 0.4)),
                                ),
                                child: const Column(
                                  children: [
                                    Text('1.428', style: TextStyle(fontFamily: 'monospace', fontSize: 28, fontWeight: FontWeight.w900, color: UbColors.emerald)),
                                    Text('HARI', style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 4 KPI Metrics
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.15,
                          children: [
                            _metricBox('Target LTI 2026', '0 Kasus', Colors.white),
                            _metricBox('Laporan Nearmiss', '${_logs.length} Temuan', UbColors.cyan),
                            _metricBox('Skor Safety Patrol', '99.4%', UbColors.purple),
                            _metricBox('Kepatuhan APD', '100%', UbColors.emerald),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Nearmiss Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['ALL', 'Terjepit', 'Tersayat', 'Terpeleset', 'Tertabrak'].map((k) {
                              final active = _filterCategory == k;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(k, style: const TextStyle(fontSize: 11)),
                                  selected: active,
                                  selectedColor: UbColors.purple.withValues(alpha: 0.35),
                                  onSelected: (_) => setState(() => _filterCategory = k),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        ...filtered.map(_buildNearmissCard),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: UbColors.textMuted)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildNearmissCard(NearmissLog n) {
    final closed = n.status == 'Closed';
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
              Text(n.id, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.purple)),
              const SizedBox(width: 8),
              Text(n.tanggal, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: UbColors.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: (closed ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  n.status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: closed ? UbColors.emerald : UbColors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${n.lokasi} · ${n.kategori}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text(n.deskripsi, style: const TextStyle(fontSize: 12, color: UbColors.textMuted, height: 1.35)),
          const SizedBox(height: 6),
          Text('CM: ${n.countermeasure}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF6EE7B7), height: 1.35)),
          const SizedBox(height: 4),
          Text('PIC: ${n.pic}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
        ],
      ),
    );
  }
}
