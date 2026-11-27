import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/local_store.dart';
import '../../services/ub_web_api.dart';
import 'cbu_monitoring_screen.dart';
import 'roster_screen.dart';

class LineVehicleModelSetting {
  LineVehicleModelSetting({
    required this.code,
    required this.name,
    this.defaultQty = 0,
    this.ratio = 1.0,
  });

  String code;
  String name;
  int defaultQty;
  double ratio;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'default_qty': defaultQty,
        'ratio': ratio,
      };

  factory LineVehicleModelSetting.fromJson(Map<String, dynamic> j) => LineVehicleModelSetting(
        code: (j['code'] ?? '').toString().trim(),
        name: (j['name'] ?? '').toString().trim(),
        defaultQty: j['default_qty'] is num
            ? (j['default_qty'] as num).toInt()
            : (int.tryParse('${j['default_qty'] ?? j['qty'] ?? 0}') ?? 0),
        ratio: j['ratio'] is num
            ? (j['ratio'] as num).toDouble()
            : (double.tryParse('${j['ratio'] ?? 1.0}') ?? 1.0),
      );
}

class LinePartItemSetting {
  LinePartItemSetting({
    required this.partNo,
    required this.partName,
    this.qty = 1,
  });

  String partNo;
  String partName;
  int qty;

  Map<String, dynamic> toJson() => {
        'part_no': partNo,
        'part_name': partName,
        'qty': qty,
      };

  factory LinePartItemSetting.fromJson(Map<String, dynamic> j) => LinePartItemSetting(
        partNo: (j['part_no'] ?? j['partNo'] ?? '').toString().trim(),
        partName: (j['part_name'] ?? j['partName'] ?? '').toString().trim(),
        qty: j['qty'] is num ? (j['qty'] as num).toInt() : (int.tryParse('${j['qty'] ?? 1}') ?? 1),
      );
}

/// 1:1 Native Flutter Screen for `ubnetwork/app/productivity/settings/page.tsx`
/// Syncs directly with server MySQL via `GET /api/ub?action=get_settings` & `POST /api/ub?action=save_settings`.
/// No manual API URL / API Key fields — strictly server production settings (Takt Time, Line, Leaders, CBU, CKD, Service).
class ProductivitySettingsScreen extends StatefulWidget {
  const ProductivitySettingsScreen({super.key});

  @override
  State<ProductivitySettingsScreen> createState() => _ProductivitySettingsScreenState();
}

class _ProductivitySettingsScreenState extends State<ProductivitySettingsScreen> {
  String _tab = 'leaders'; // leaders | models | ckd | service
  bool _loading = true;
  bool _saving = false;
  bool _fromServer = false;
  int _simUnits = 212;

  late final TextEditingController _lineCtrl;
  late final TextEditingController _taktCtrl;
  late final TextEditingController _picRedCtrl;
  late final TextEditingController _spvRedCtrl;
  late final TextEditingController _picWhiteCtrl;
  late final TextEditingController _spvWhiteCtrl;
  late final TextEditingController _simUnitsCtrl;

  double _currentTakt = 2.4;
  List<LineVehicleModelSetting> _models = [];
  List<LinePartItemSetting> _ckdParts = [];
  List<LinePartItemSetting> _serviceParts = [];

  @override
  void initState() {
    super.initState();
    _lineCtrl = TextEditingController(text: 'UB Assy');
    _taktCtrl = TextEditingController(text: '2,4');
    _picRedCtrl = TextEditingController(text: 'KAMALUDIN');
    _spvRedCtrl = TextEditingController(text: 'MASRURI / TRI RUSTIANTORO');
    _picWhiteCtrl = TextEditingController(text: 'DWI MULYONO');
    _spvWhiteCtrl = TextEditingController(text: 'DADANG SURYADI / NUNU FATULAH');
    _simUnitsCtrl = TextEditingController(text: '212');
    _seedDefaults();
    _fetchServerSettings();
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _taktCtrl.dispose();
    _picRedCtrl.dispose();
    _spvRedCtrl.dispose();
    _picWhiteCtrl.dispose();
    _spvWhiteCtrl.dispose();
    _simUnitsCtrl.dispose();
    super.dispose();
  }

  void _seedDefaults() {
    _models = [
      LineVehicleModelSetting(code: 'zenix', name: 'Innova Zenix', defaultQty: 132, ratio: 1.0),
      LineVehicleModelSetting(code: 'fortuner', name: 'Fortuner', defaultQty: 137, ratio: 0.7),
      LineVehicleModelSetting(code: 'innova', name: 'Kijang Innova', defaultQty: 149, ratio: 0.5),
    ];
    _ckdParts = [
      LinePartItemSetting(partNo: '57403-KK010', partName: 'Member Floor Side Inner RR RH', qty: 1),
      LinePartItemSetting(partNo: '57404-KK010', partName: 'Member Floor Side Inner RR LH', qty: 1),
    ];
    _serviceParts = [
      LinePartItemSetting(partNo: '57201-BZ901', partName: 'Service Panel Front Underbody', qty: 1),
      LinePartItemSetting(partNo: '57202-BZ902', partName: 'Service Bracket Exhaust Pipe', qty: 1),
    ];
  }

  Future<void> _fetchServerSettings() async {
    setState(() => _loading = true);
    final localCfg = await LocalStore.instance.getSettings();
    _lineCtrl.text = localCfg.lineName;
    _currentTakt = localCfg.taktTime;
    _taktCtrl.text = _formatTakt(_currentTakt);

    final res = await UbWebApi.instance.getUb(const {'action': 'get_settings'});
    if (!mounted) return;

    if (res.ok && res.map['status'] == 'success' && res.map['data'] is Map) {
      final d = Map<String, dynamic>.from(res.map['data'] as Map);
      final lineName = (d['line_name'] ?? localCfg.lineName).toString().trim();
      final tt = d['current_takt_time'] is num
          ? (d['current_takt_time'] as num).toDouble()
          : (double.tryParse('${d['current_takt_time'] ?? localCfg.taktTime}'.replaceAll(',', '.')) ?? localCfg.taktTime);

      _lineCtrl.text = lineName.isEmpty ? 'UB Assy' : lineName;
      _currentTakt = tt > 0 ? tt : 2.4;
      _taktCtrl.text = _formatTakt(_currentTakt);
      _picRedCtrl.text = (d['pic_red'] ?? _picRedCtrl.text).toString();
      _spvRedCtrl.text = (d['spv_red'] ?? _spvRedCtrl.text).toString();
      _picWhiteCtrl.text = (d['pic_white'] ?? _picWhiteCtrl.text).toString();
      _spvWhiteCtrl.text = (d['spv_white'] ?? _spvWhiteCtrl.text).toString();

      if (d['models'] is List && (d['models'] as List).isNotEmpty) {
        _models = (d['models'] as List)
            .whereType<Map>()
            .map((m) => LineVehicleModelSetting.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      if (d['ckd_parts'] is List) {
        _ckdParts = (d['ckd_parts'] as List)
            .whereType<Map>()
            .map((m) => LinePartItemSetting.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      if (d['service_parts'] is List) {
        _serviceParts = (d['service_parts'] as List)
            .whereType<Map>()
            .map((m) => LinePartItemSetting.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }

      // Sync local cache immediately so Home & Checksheet match server Takt Time
      localCfg
        ..lineName = _lineCtrl.text.trim()
        ..taktTime = _currentTakt;
      await LocalStore.instance.saveSettings(localCfg);

      setState(() {
        _fromServer = true;
        _loading = false;
      });
      return;
    }

    setState(() {
      _fromServer = false;
      _loading = false;
    });
  }

  String _formatTakt(double v) {
    final s = v == v.roundToDouble() ? v.toStringAsFixed(1) : v.toString();
    return s.replaceAll('.', ',');
  }

  void _setPresetTakt(double tt) {
    setState(() {
      _currentTakt = tt;
      _taktCtrl.text = _formatTakt(tt);
    });
  }

  Future<void> _saveSettingsToServer() async {
    if (_saving) return;
    final parsedTt = double.tryParse(_taktCtrl.text.trim().replaceAll(',', '.')) ?? _currentTakt;
    final safeTt = parsedTt > 0 ? parsedTt : 2.4;
    final safeLine = _lineCtrl.text.trim().isEmpty ? 'UB Assy' : _lineCtrl.text.trim();

    setState(() {
      _saving = true;
      _currentTakt = safeTt;
      _taktCtrl.text = _formatTakt(safeTt);
    });

    final payload = <String, dynamic>{
      'line_name': safeLine,
      'pic_red': _picRedCtrl.text.trim(),
      'spv_red': _spvRedCtrl.text.trim(),
      'pic_white': _picWhiteCtrl.text.trim(),
      'spv_white': _spvWhiteCtrl.text.trim(),
      'current_takt_time': safeTt,
      'models': _models.map((m) => m.toJson()).toList(),
      'ckd_parts': _ckdParts.map((p) => p.toJson()).toList(),
      'service_parts': _serviceParts.map((p) => p.toJson()).toList(),
    };

    // Update local settings cache immediately
    final cfg = await LocalStore.instance.getSettings();
    cfg
      ..lineName = safeLine
      ..taktTime = safeTt;
    await LocalStore.instance.saveSettings(cfg);

    final res = await UbWebApi.instance.postUb('save_settings', payload);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (res.ok && res.map['status'] == 'success') _fromServer = true;
    });

    if (res.ok && res.map['status'] == 'success') {
      _toast('Pengaturan Lini & Takt Time (${_formatTakt(safeTt)}m) tersimpan ke Server!');
    } else {
      _toast(
        'Gagal simpan ke server (${res.error ?? "cek koneksi/login"}), tersimpan di cache lokal.',
        isErr: true,
      );
    }
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

  Future<void> _promptAddModel() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final ratioCtrl = TextEditingController(text: '1.0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UbColors.surface,
        title: const Text('Tambah Model Mobil CBU', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Kode Model (mis. zenix, hilux)', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap Model', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ratioCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Rasio Produksi (mis. 1.0)', isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tambah')),
        ],
      ),
    );
    if (ok == true && codeCtrl.text.trim().isNotEmpty && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _models.add(
          LineVehicleModelSetting(
            code: codeCtrl.text.trim().toLowerCase(),
            name: nameCtrl.text.trim(),
            ratio: double.tryParse(ratioCtrl.text.trim().replaceAll(',', '.')) ?? 1.0,
          ),
        );
      });
    }
  }

  Future<void> _promptAddPart({required bool isCkd}) async {
    final noCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UbColors.surface,
        title: Text(
          isCkd ? 'Tambah Part CKD Export' : 'Tambah Service Part',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noCtrl,
              decoration: const InputDecoration(labelText: 'Nomor Part (mis. 57403-KK010)', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Part Komponen', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Qty / Unit', isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tambah')),
        ],
      ),
    );
    if (ok == true && noCtrl.text.trim().isNotEmpty && nameCtrl.text.trim().isNotEmpty) {
      final item = LinePartItemSetting(
        partNo: noCtrl.text.trim().toUpperCase(),
        partName: nameCtrl.text.trim(),
        qty: int.tryParse(qtyCtrl.text.trim()) ?? 1,
      );
      setState(() {
        if (isCkd) {
          _ckdParts.add(item);
        } else {
          _serviceParts.add(item);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UbColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header (1:1 Next.js `/productivity/settings`)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: UbColors.surface.withValues(alpha: 0.92),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: UbColors.emerald.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: UbColors.emerald.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _lineCtrl.text.isEmpty ? 'UB ASSY' : _lineCtrl.text.toUpperCase(),
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF6EE7B7)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (_fromServer ? UbColors.cyan : UbColors.amber).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                _fromServer ? 'SERVER MYSQL' : 'CACHE LOKAL',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: _fromServer ? UbColors.cyan : UbColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pengaturan Lini & Opsi Produksi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _fetchServerSettings,
                    icon: const Icon(Icons.sync_rounded, size: 19, color: UbColors.cyan),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Ambil Pengaturan Server',
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: UbColors.emerald,
                      foregroundColor: UbColors.bg,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: (_loading || _saving) ? null : _saveSettingsToServer,
                    icon: Icon(_saving ? Icons.hourglass_top_rounded : Icons.save_rounded, size: 16),
                    label: Text(
                      _saving ? 'Simpan...' : 'Simpan',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),

            // 4 Navigation Tabs (1:1 Next.js)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: UbColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      _tabBtn('leaders', Icons.timer_rounded, 'PIC, SPV & Takt Time'),
                      const SizedBox(width: 4),
                      _tabBtn('models', Icons.directions_car_rounded, 'Unit Mobil & Rasio'),
                      const SizedBox(width: 4),
                      _tabBtn('ckd', Icons.inventory_2_rounded, 'Part CKD Export'),
                      const SizedBox(width: 4),
                      _tabBtn('service', Icons.build_rounded, 'Service Part'),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: UbColors.cyan),
                          SizedBox(height: 10),
                          Text('Mengambil pengaturan lini dari server...', style: TextStyle(fontSize: 12.5, color: UbColors.textMuted)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchServerSettings,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                        children: [
                          if (_tab == 'leaders') _buildLeadersAndTaktTab(),
                          if (_tab == 'models') _buildModelsTab(),
                          if (_tab == 'ckd') _buildPartsTab(isCkd: true),
                          if (_tab == 'service') _buildPartsTab(isCkd: false),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String id, IconData icon, String label) {
    final active = _tab == id;
    return InkWell(
      onTap: () => setState(() => _tab = id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF2563EB)]) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : UbColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : UbColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: TAKT TIME, LINE NAME & SHIFT LEADERS
  // ===========================================================================
  Widget _buildLeadersAndTaktTab() {
    final uph = _currentTakt > 0 ? (60 / _currentTakt).round() : 25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Takt Time & Line Name Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: UbColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: UbColors.cyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: UbColors.cyan),
                  SizedBox(width: 8),
                  Text(
                    'Parameter Umum Lini & Takt Time Berjalan',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _lineCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  labelText: 'Nama Lini Produksi',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taktCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        final parsed = double.tryParse(v.replaceAll(',', '.'));
                        if (parsed != null && parsed > 0) {
                          setState(() => _currentTakt = parsed);
                        }
                      },
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Takt Time Aktif Global (Menit)',
                        hintText: '1,9 atau 2,4',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: UbColors.cyan.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: UbColors.cyan.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TT ${_formatTakt(_currentTakt)}m',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w900, color: UbColors.cyan),
                        ),
                        Text(
                          '~$uph Unit/Jam',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Preset Cepat:', style: TextStyle(fontSize: 11, color: UbColors.textMuted, fontWeight: FontWeight.w700)),
                  for (final tt in const [1.6, 1.9, 2.3, 2.4])
                    InkWell(
                      onTap: () => _setPresetTakt(tt),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (_currentTakt - tt).abs() < 0.05 ? UbColors.cyan : UbColors.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_currentTakt - tt).abs() < 0.05 ? UbColors.cyan : Colors.white12,
                          ),
                        ),
                        child: Text(
                          '${_formatTakt(tt)}m (~${(60 / tt).round()}u/h)',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: (_currentTakt - tt).abs() < 0.05 ? UbColors.bg : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Standar kalkulasi target global seluruh lembar Checksheet Produksi, Template Shift, & Monitoring di server.',
                style: TextStyle(fontSize: 11, color: UbColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // RED SHIFT LEADERS
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: UbColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: UbColors.rose.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: UbColors.rose)),
                  const SizedBox(width: 8),
                  const Text(
                    'PIMPINAN SHIFT MERAH (RED SHIFT)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _picRedCtrl,
                decoration: const InputDecoration(
                  labelText: 'GL Shift Merah (Pimpinan Tertinggi)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _spvRedCtrl,
                decoration: const InputDecoration(
                  labelText: 'Team Leader (TL) Shift Merah',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // WHITE SHIFT LEADERS
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: UbColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Text(
                    'PIMPINAN SHIFT PUTIH (WHITE SHIFT)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _picWhiteCtrl,
                decoration: const InputDecoration(
                  labelText: 'GL Shift Putih (Pimpinan Tertinggi)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _spvWhiteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Team Leader (TL) Shift Putih',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RosterScreen()),
          ),
          icon: const Icon(Icons.groups_rounded, size: 17, color: UbColors.cyan),
          label: const Text('Buka Struktural Tim & Roster (GL / TL / TM)'),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: UNIT MOBIL CBU & SIMULASI RASIO HAMILTON-HARE
  // ===========================================================================
  Widget _buildModelsTab() {
    final totalRatio = _models.fold<double>(0, (a, m) => a + (m.ratio > 0 ? m.ratio : 0));
    final simAlloc = <String, int>{};
    if (totalRatio > 0 && _simUnits > 0 && _models.isNotEmpty) {
      final quotas = _models.map((m) {
        final exact = ((m.ratio > 0 ? m.ratio : 0) / totalRatio) * _simUnits;
        final base = exact.floor();
        return (code: m.code, base: base, rem: exact - base);
      }).toList();
      var remUnits = _simUnits - quotas.fold<int>(0, (a, q) => a + q.base);
      for (final q in quotas) {
        simAlloc[q.code] = q.base;
      }
      final sorted = [...quotas]..sort((a, b) => b.rem.compareTo(a.rem));
      for (var i = 0; i < remUnits && i < sorted.length; i++) {
        simAlloc[sorted[i].code] = (simAlloc[sorted[i].code] ?? 0) + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CbuMonitoringScreen()),
              ),
              icon: const Icon(Icons.bar_chart_rounded, size: 16),
              label: const Text('Monitoring CBU 1-31', style: TextStyle(fontSize: 12)),
            ),
            FilledButton.tonalIcon(
              onPressed: _promptAddModel,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Tambah Model', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._models.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          final share = totalRatio > 0 ? ((m.ratio / totalRatio) * 100).toStringAsFixed(1) : '0.0';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: UbColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: UbColors.cyan.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        m.code.toUpperCase(),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: UbColors.cyan),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    Text('Share $share%', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _models.removeAt(idx)),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: UbColors.rose),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Rasio: ${m.ratio}x',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w800, color: UbColors.amber),
                    ),
                    const SizedBox(width: 4),
                    for (final pval in const [0.3, 0.5, 0.7, 1.0, 1.2, 1.5])
                      InkWell(
                        onTap: () => setState(() => m.ratio = pval),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (m.ratio - pval).abs() < 0.01 ? UbColors.amber.withValues(alpha: 0.25) : UbColors.bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (m.ratio - pval).abs() < 0.01 ? UbColors.amber : Colors.white12,
                            ),
                          ),
                          child: Text(
                            '$pval',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: (m.ratio - pval).abs() < 0.01 ? UbColors.amber : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),

        // Simulasi Hamilton-Hare Card
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: UbColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: UbColors.purple.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Simulasi Pembagian Unit CBU (Hamilton-Hare)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _simUnitsCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _simUnits = int.tryParse(v) ?? 0),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w900, color: UbColors.cyan),
                      decoration: const InputDecoration(
                        labelText: 'Total Unit',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _models.map((m) {
                  final u = simAlloc[m.code] ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: UbColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      '${m.name}: $u Unit',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3 & 4: PART CKD EXPORT & SERVICE PART
  // ===========================================================================
  Widget _buildPartsTab({required bool isCkd}) {
    final list = isCkd ? _ckdParts : _serviceParts;
    final accent = isCkd ? UbColors.emerald : UbColors.purple;

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isCkd ? 'Daftar Part CKD Export Lini Underbody' : 'Daftar Service Part Lini Underbody',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _promptAddPart(isCkd: isCkd),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tambah Part', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Belum ada daftar part.', style: TextStyle(fontSize: 12, color: UbColors.textMuted)),
              ),
            )
          else
            ...list.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: UbColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Text(
                      '${idx + 1}.',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: UbColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.partNo,
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: accent),
                          ),
                          Text(
                            p.partName,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${p.qty} pcs',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white70),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => list.removeAt(idx)),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: UbColors.rose),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
