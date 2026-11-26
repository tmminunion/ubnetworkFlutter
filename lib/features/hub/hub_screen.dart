import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/checksheet_models.dart';
import '../../services/local_store.dart';
import '../checksheet/checksheet_screen.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  UbSettings _cfg = UbSettings();
  List<ChecksheetReport> _reports = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await LocalStore.instance.getSettings();
    final reps = await LocalStore.instance.listReports();
    if (!mounted) return;
    setState(() {
      _cfg = cfg;
      _reports = reps;
      _loading = false;
    });
  }

  Future<void> _openChecksheet({String? date, String? shift}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChecksheetScreen(initialDate: date, initialShift: shift),
      ),
    );
    await _load();
  }

  Future<void> _openSettings() async {
    var role = _cfg.role;
    final lineCtrl = TextEditingController(text: _cfg.lineName);
    final taktCtrl = TextEditingController(text: '${_cfg.taktTime}');
    final apiCtrl = TextEditingController(text: _cfg.serverApiUrl);
    final keyCtrl = TextEditingController(text: _cfg.apiKey);
    var spEnabled = _cfg.enableSharepointSync;

    try {
      final saved = await showModalBottomSheet<bool>(
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
                  const Text('⚙️ Pengaturan Role & Server Sync', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role Akses', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN (Edit RED & WHITE)')),
                      DropdownMenuItem(value: 'RED', child: Text('SHIFT RED')),
                      DropdownMenuItem(value: 'WHITE', child: Text('SHIFT WHITE')),
                      DropdownMenuItem(value: 'VIEWER', child: Text('VIEWER (Read-Only)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setM(() => role = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: lineCtrl, decoration: const InputDecoration(labelText: 'Line Name', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: taktCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Takt Time (m)', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: apiCtrl, decoration: const InputDecoration(labelText: 'Server API URL', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: keyCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'X-UB-API-Key (opsional)', border: OutlineInputBorder(), isDense: true)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: spEnabled,
                    title: const Text('Aktifkan Sync SharePoint (NUDB)', style: TextStyle(fontSize: 13)),
                    onChanged: (v) => setM(() => spEnabled = v),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Simpan Pengaturan', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (saved == true) {
        _cfg
          ..role = role
          ..lineName = lineCtrl.text.trim().isNotEmpty ? lineCtrl.text.trim() : 'UB ASSY'
          ..taktTime = double.tryParse(taktCtrl.text.trim()) ?? 2.4
          ..serverApiUrl = apiCtrl.text.trim()
          ..apiKey = keyCtrl.text.trim()
          ..enableSharepointSync = spEnabled;
        await LocalStore.instance.saveSettings(_cfg);
        await _load();
      }
    } finally {
      lineCtrl.dispose();
      taktCtrl.dispose();
      apiCtrl.dispose();
      keyCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _reports.where((r) => r.syncStatus != 'synced').length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UBnetwork', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text('Underbody Assy · Offline-First Flutter', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: UbColors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: UbColors.purple.withValues(alpha: 0.5)),
            ),
            child: Text(_cfg.role, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD8B4FE))),
          ),
          IconButton(onPressed: _openSettings, icon: const Icon(Icons.settings_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Hero Card: Buka Checksheet A3
                  InkWell(
                    onTap: () => _openChecksheet(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0E7490), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Daily Production Checksheet (A3)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                const SizedBox(height: 3),
                                Text(
                                  'Kanvas A3 Pan & Pinch-Zoom · ${_cfg.lineName} · TT ${_cfg.taktTime}m',
                                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Shift Launchers
                  Row(
                    children: [
                      Expanded(
                        child: _quickCard(
                          title: '🔴 Shift RED',
                          sub: 'Buka hari ini',
                          color: UbColors.rose,
                          onTap: () => _openChecksheet(date: UbMasterData.wibToday(), shift: 'RED'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickCard(
                          title: '⚪ Shift WHITE',
                          sub: 'Buka hari ini',
                          color: UbColors.cyan,
                          onTap: () => _openChecksheet(date: UbMasterData.wibToday(), shift: 'WHITE'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Riwayat Checksheet Lokal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Riwayat Checksheet Lokal', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                      Text(
                        pendingCount > 0 ? '$pendingCount belum sync' : '${_reports.length} tersimpan',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: pendingCount > 0 ? UbColors.amber : UbColors.emerald),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_reports.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: UbColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: UbColors.card),
                      ),
                      child: const Text(
                        'Belum ada checksheet tersimpan di perangkat ini. Tap kartu di atas untuk mulai mengisi Checksheet A3.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: UbColors.textMuted),
                      ),
                    )
                  else
                    ..._reports.map((r) {
                      final st = UbMasterData.computeStats(r);
                      final synced = r.syncStatus == 'synced';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => _openChecksheet(date: r.tanggal, shift: r.shift),
                          leading: CircleAvatar(
                            backgroundColor: r.shift == 'RED' ? UbColors.rose.withValues(alpha: 0.2) : UbColors.cyan.withValues(alpha: 0.2),
                            child: Text(r.shift == 'RED' ? 'R' : 'W', style: TextStyle(fontWeight: FontWeight.w900, color: r.shift == 'RED' ? UbColors.rose : UbColors.cyan)),
                          ),
                          title: Text('${UbMasterData.formatDDMMYYYY(r.tanggal)} • ${r.shift}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                          subtitle: Text(
                            'Act ${st.totalAct}/${st.totalPlan} U · Eff ${st.internalEfficiency}% · Delay ${st.totalDelayMin}m',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (synced ? UbColors.emerald : UbColors.amber).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              synced ? 'SYNCED' : 'LOKAL',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: synced ? UbColors.emerald : UbColors.amber),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _quickCard({required String title, required String sub, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: UbColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
