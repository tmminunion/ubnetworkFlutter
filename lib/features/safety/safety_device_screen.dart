import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';

class SafetyDeviceItem {
  SafetyDeviceItem({
    required this.id,
    required this.name,
    required this.pos,
    required this.type,
    required this.standard,
    required this.status,
    required this.inspectedAt,
    required this.inspector,
  });

  final String id;
  final String name;
  final String pos;
  final String type; // Interlock | Sensor | E-Stop | Mechanical
  final String standard;
  String status; // OK | NG
  String inspectedAt;
  String inspector;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pos': pos,
        'type': type,
        'standard': standard,
        'status': status,
        'inspectedAt': inspectedAt,
        'inspector': inspector,
      };

  factory SafetyDeviceItem.fromJson(Map<String, dynamic> json) => SafetyDeviceItem(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        pos: (json['pos'] ?? '').toString(),
        type: (json['type'] ?? 'Sensor').toString(),
        standard: (json['standard'] ?? '').toString(),
        status: (json['status'] ?? 'OK').toString() == 'NG' ? 'NG' : 'OK',
        inspectedAt: (json['inspectedAt'] ?? '--:--').toString(),
        inspector: (json['inspector'] ?? '').toString(),
      );
}

List<SafetyDeviceItem> defaultSafetyDevices() => [
      SafetyDeviceItem(
        id: 'DEV-01',
        name: 'Interlock Door Switch Gate Robot 1',
        pos: 'Pos 1 Underbody Main',
        type: 'Interlock',
        standard: 'Robot seketika berhenti saat pintu pagar dibuka > 5mm',
        status: 'OK',
        inspectedAt: '07:15',
        inspector: 'NUNU FATULAH',
      ),
      SafetyDeviceItem(
        id: 'DEV-02',
        name: 'Light Curtain Sensor Area Loading Front Floor',
        pos: 'Pos 1 Underbody Main',
        type: 'Sensor',
        standard: 'Siklus terputus seketika saat tangan memotong berkas infra-merah',
        status: 'OK',
        inspectedAt: '07:18',
        inspector: 'NUNU FATULAH',
      ),
      SafetyDeviceItem(
        id: 'DEV-03',
        name: 'Emergency Stop Push-Button Konsol Utama Lini',
        pos: 'Main Control Desk',
        type: 'E-Stop',
        standard: 'Lini trip total, lampu indikator Andon merah menyala & alarm berbunyi',
        status: 'OK',
        inspectedAt: '07:20',
        inspector: 'DWI MULYONO',
      ),
      SafetyDeviceItem(
        id: 'DEV-04',
        name: 'Safety Mat Pressure Switch Area Spot Welding',
        pos: 'Pos 2 Cross Member',
        type: 'Sensor',
        standard: 'Sensor aktif saat terinjak bobot > 25 kg di zona terlarang',
        status: 'OK',
        inspectedAt: '07:22',
        inspector: 'SUGENG SURYADI',
      ),
      SafetyDeviceItem(
        id: 'DEV-05',
        name: 'Lock Pin Manual Jig Fitting Underbody Center',
        pos: 'Pos 3 Assembly Jig',
        type: 'Mechanical',
        standard: 'Pin pengunci fisik terpasang kokoh, bebas aus, dan rantai terikat',
        status: 'OK',
        inspectedAt: '07:25',
        inspector: 'YANA SUHERYANA',
      ),
      SafetyDeviceItem(
        id: 'DEV-06',
        name: 'Area Laser Scanner Jalur AGV / Dolly Material',
        pos: 'Buffer Rak Komponen',
        type: 'Sensor',
        standard: 'AGV berhenti otomatis saat objek terdeteksi pada radius 1.2 meter',
        status: 'OK',
        inspectedAt: '07:30',
        inspector: 'NUNU FATULAH',
      ),
    ];

class SafetyDeviceScreen extends StatefulWidget {
  const SafetyDeviceScreen({super.key});

  @override
  State<SafetyDeviceScreen> createState() => _SafetyDeviceScreenState();
}

class _SafetyDeviceScreenState extends State<SafetyDeviceScreen> {
  String _shift = 'WHITE';
  List<SafetyDeviceItem> _devices = defaultSafetyDevices();
  bool _loading = true;

  static String _keyFor(String shift) => 'ubf_safety_devices_v1_$shift';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(_shift));
    List<SafetyDeviceItem> list = defaultSafetyDevices();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list = decoded.whereType<Map>().map((m) => SafetyDeviceItem.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _devices = list;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(_shift), jsonEncode(_devices.map((d) => d.toJson()).toList()));
  }

  Future<void> _toggleStatus(SafetyDeviceItem item) async {
    final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final hhmm = '${wib.hour.toString().padLeft(2, '0')}:${wib.minute.toString().padLeft(2, '0')}';
    setState(() {
      item.status = item.status == 'OK' ? 'NG' : 'OK';
      item.inspectedAt = hhmm;
    });
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.id} diubah ke ${item.status} ($hhmm WIB)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final okCount = _devices.where((d) => d.status == 'OK').length;
    final allOk = okCount == _devices.length;

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                        Text('Safety Device & Interlock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Inspeksi Awal Shift · JIS / ISO 13849 (PL e)', style: TextStyle(fontSize: 10.5, color: UbColors.textMuted)),
                      ],
                    ),
                  ),
                  // Shift Switcher
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: UbColors.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        _shiftPill('WHITE', Colors.white, UbColors.bg),
                        const SizedBox(width: 4),
                        _shiftPill('RED', UbColors.rose, Colors.white),
                      ],
                    ),
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
                        // Status Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (allOk ? UbColors.emerald : UbColors.rose).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: (allOk ? UbColors.emerald : UbColors.rose).withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                allOk ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                                size: 32,
                                color: allOk ? UbColors.emerald : UbColors.rose,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      allOk ? '100% LAYAK OPERASI' : 'ADA ABNORMAL (NG)',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: allOk ? UbColors.emerald : UbColors.rose,
                                      ),
                                    ),
                                    Text(
                                      '$okCount / ${_devices.length} Unit OK · Shift $_shift · JIS/ISO 13849',
                                      style: const TextStyle(fontSize: 11.5, color: UbColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Tap tombol OK / NG pada setiap perangkat untuk mencatat hasil uji fungsi:',
                            style: TextStyle(fontSize: 11.5, color: UbColors.textMuted),
                          ),
                        ),

                        ..._devices.map(_buildDeviceCard),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shiftPill(String val, Color activeBg, Color activeFg) {
    final active = _shift == val;
    return InkWell(
      onTap: () {
        if (_shift != val) {
          setState(() => _shift = val);
          _load();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          val,
          style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w900, color: active ? activeFg : UbColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(SafetyDeviceItem d) {
    final isOk = d.status == 'OK';
    final statusColor = isOk ? UbColors.emerald : UbColors.rose;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UbColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isOk ? Colors.white10 : UbColors.rose.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: UbColors.cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(d.id, style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w900, color: UbColors.cyan)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(d.type, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: UbColors.textPrimary)),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _toggleStatus(d),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isOk ? Icons.check_rounded : Icons.close_rounded, size: 15, color: statusColor),
                      const SizedBox(width: 4),
                      Text(d.status, style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: statusColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(d.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 2),
          Text('${d.pos} · Jam Cek: ${d.inspectedAt} · ${d.inspector}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
          const SizedBox(height: 6),
          Text(d.standard, style: const TextStyle(fontSize: 11.5, color: UbColors.textPrimary, height: 1.35)),
        ],
      ),
    );
  }
}
