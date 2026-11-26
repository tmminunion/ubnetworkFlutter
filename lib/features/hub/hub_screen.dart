import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/hub_catalog.dart';
import '../../models/checksheet_models.dart';
import '../../services/auth_service.dart';
import '../../services/local_store.dart';
import '../checksheet/checksheet_screen.dart';
import 'display_board_screen.dart';
import '../safety/sga_group_screen.dart';
import 'sub_hub_screen.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({
    super.key,
    this.authUser,
    this.onLogout,
  });

  final UbAuthUser? authUser;
  final VoidCallback? onLogout;

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  UbSettings _cfg = UbSettings();
  List<ChecksheetReport> _reports = const [];
  bool _loading = true;
  bool _gridMode = true;
  bool _pillarsCollapsed = false;
  bool _kaizenCollapsed = false;
  String _searchQuery = '';
  String _clockWib = '--:--';
  Timer? _clockTimer;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) => _updateClock());
    _load();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _updateClock() {
    final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final hh = wib.hour.toString().padLeft(2, '0');
    final mm = wib.minute.toString().padLeft(2, '0');
    if (mounted) {
      setState(() => _clockWib = '$hh:$mm');
    }
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

  Future<void> _openSubHub(String pillarId) async {
    final config = HubCatalog.subHubs[pillarId];
    if (config == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubHubScreen(
          config: config,
          onOpenSettings: _openSettings,
        ),
      ),
    );
    await _load();
  }

  void _openDisplayBoard() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DisplayBoardScreen()),
    );
  }

  void _showRoutePreview({
    required String title,
    required String subtitle,
    required String route,
    required IconData icon,
    required Color color,
  }) {
    if (route == '/safety/group') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SgaGroupScreen()),
      );
      return;
    }
    if (route == '/productivity/tasks' || route == '/productivity/after-prod') {
      _openSubHub('productivity');
      return;
    }
    if (route == '/env/daily' || route == '/env/temuan') {
      _openSubHub('env');
      return;
    }
    if (route == '/bacadoa' || route == '/idnu') {
      _openSubHub('hr');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: UbColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: UbColors.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'Route: $route · Modul ini akan dibuka penuh saat migrasi native tahap berikutnya.',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLocalHistorySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.58,
        maxChildSize: 0.88,
        minChildSize: 0.35,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riwayat Checksheet A3 Lokal', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('Tersimpan offline di perangkat ini', style: TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
                    ],
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: UbColors.cyan,
                      foregroundColor: UbColors.bg,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openChecksheet();
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Baru', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: _reports.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Belum ada checksheet tersimpan di perangkat ini. Masuk ke Pilar Productivity → Daily Production Checksheet untuk mulai.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: UbColors.textMuted),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(14),
                      itemCount: _reports.length,
                      itemBuilder: (_, idx) {
                        final r = _reports[idx];
                        final st = UbMasterData.computeStats(r);
                        final synced = r.syncStatus == 'synced';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(ctx);
                              _openChecksheet(date: r.tanggal, shift: r.shift);
                            },
                            leading: CircleAvatar(
                              backgroundColor: r.shift == 'RED'
                                  ? UbColors.rose.withValues(alpha: 0.2)
                                  : UbColors.cyan.withValues(alpha: 0.2),
                              child: Text(
                                r.shift == 'RED' ? 'R' : 'W',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: r.shift == 'RED' ? UbColors.rose : UbColors.cyan,
                                ),
                              ),
                            ),
                            title: Text(
                              '${UbMasterData.formatDDMMYYYY(r.tanggal)} • ${r.shift}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
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
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: synced ? UbColors.emerald : UbColors.amber,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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

  bool _matchesSearch(String a, String b, [String c = '']) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return a.toLowerCase().contains(q) || b.toLowerCase().contains(q) || c.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final uph = _cfg.taktTime > 0 ? (60 / _cfg.taktTime).round() : 25;
    final pendingCount = _reports.where((r) => r.syncStatus != 'synced').length;

    final filteredPillars = HubCatalog.kpiPillars
        .where((p) => _matchesSearch(p.title, p.subtitle, '${p.code} ${p.highlight}'))
        .toList();
    final filteredKaizen = HubCatalog.kaizenActivities
        .where((k) => _matchesSearch(k.title, k.subtitle, '${k.code} ${k.highlight}'))
        .toList();
    final filteredQuick = HubCatalog.quickApps
        .where((q) => _matchesSearch(q.title, q.subtitle, q.route))
        .toList();

    final pillarCols = !_gridMode ? 1 : (width >= 960 ? 3 : (width >= 600 ? 2 : 2));
    final kaizenCols = !_gridMode ? 1 : (width >= 1020 ? 5 : (width >= 680 ? 3 : 2));
    final quickCols = width >= 960 ? 4 : (width >= 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: Stack(
        children: [
          // macOS ambient dark wallpaper glows
          Positioned(
            top: -110,
            left: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            top: 260,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: 40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // =========================================================
                // 1. TOP macOS STATUS BAR
                // =========================================================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: UbColors.bg.withValues(alpha: 0.86),
                    border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      // UB Logo
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white24),
                        ),
                        alignment: Alignment.center,
                        child: const Text('UB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'UBnetwork',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.2),
                      ),
                      const SizedBox(width: 8),
                      // Live TT Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: UbColors.emerald.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: UbColors.emerald.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399)),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'TT: ${_cfg.taktTime}m ($uph UPH)',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7)),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (width >= 430)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '$_clockWib WIB',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700, color: UbColors.textMuted),
                          ),
                        ),
                      // Local Checksheet History Badge
                      InkWell(
                        onTap: _openLocalHistorySheet,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_rounded,
                                size: 14,
                                color: pendingCount > 0 ? UbColors.amber : UbColors.cyan,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_reports.length}',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _openSettings,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: UbColors.purple.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: UbColors.purple.withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _cfg.role,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFD8B4FE)),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.settings_rounded, size: 13, color: Color(0xFFD8B4FE)),
                            ],
                          ),
                        ),
                      ),
                      if (widget.onLogout != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: widget.onLogout,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: UbColors.rose.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: UbColors.rose.withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFFDA4AF)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // =========================================================
                // 2. MAIN SCROLLABLE HUB WORKSPACE
                // =========================================================
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                            children: [
                              // TOP DESKTOP STATUS & SEARCH BAR
                              _buildDesktopSearchBar(),
                              const SizedBox(height: 14),

                              // MENU UTAMA (TOP 2 CARDS: DISPLAY KPI & MONITOR)
                              _buildTopMenuCards(width),
                              const SizedBox(height: 16),

                              // WINDOW 1: 6 PILAR UTAMA MANUFAKTUR (S-Q-P-C-HR-E)
                              _MacWindowContainer(
                                title: '6 Pilar Utama Manufaktur (S - Q - P - C - HR - E)',
                                subtitle: '${filteredPillars.length} Pilar KPI',
                                dotColor: UbColors.cyan,
                                collapsed: _pillarsCollapsed,
                                onToggleCollapse: () => setState(() => _pillarsCollapsed = !_pillarsCollapsed),
                                child: filteredPillars.isEmpty
                                    ? _emptySearchState()
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: pillarCols,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          mainAxisExtent: _gridMode ? 150 : 94,
                                        ),
                                        itemCount: filteredPillars.length,
                                        itemBuilder: (_, idx) => _PillarCard(
                                          item: filteredPillars[idx],
                                          compactRow: !_gridMode,
                                          onTap: () => _openSubHub(filteredPillars[idx].id),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // WINDOW 2: AKTIVITAS KAIZEN (SGA, QCC, TPM, 5R, SW)
                              _MacWindowContainer(
                                title: 'Aktivitas Kaizen & Budaya Kerja',
                                subtitle: '${filteredKaizen.length} Aktivitas',
                                dotColor: UbColors.amber,
                                collapsed: _kaizenCollapsed,
                                onToggleCollapse: () => setState(() => _kaizenCollapsed = !_kaizenCollapsed),
                                child: filteredKaizen.isEmpty
                                    ? _emptySearchState()
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: kaizenCols,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          mainAxisExtent: _gridMode ? 142 : 90,
                                        ),
                                        itemCount: filteredKaizen.length,
                                        itemBuilder: (_, idx) {
                                          final k = filteredKaizen[idx];
                                          return _PillarCard(
                                            item: k,
                                            compactRow: !_gridMode,
                                            onTap: () => _showRoutePreview(
                                              title: '${k.title} (${k.subtitle})',
                                              subtitle: k.highlight,
                                              route: k.route,
                                              icon: k.icon,
                                              color: k.accentColor,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // SECTION 3: UB QUICK APP DX
                              _buildQuickAppsSection(filteredQuick, quickCols),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSearchBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UbColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Underbody Display — ${_cfg.lineName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Display Center dan Aktivitas Manufaktur',
                      style: TextStyle(fontSize: 11.5, color: UbColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Grid / List Toggle
              Container(
                decoration: BoxDecoration(
                  color: UbColors.bg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _gridMode = true),
                      icon: Icon(Icons.grid_view_rounded, size: 18, color: _gridMode ? UbColors.cyan : UbColors.textMuted),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _gridMode = false),
                      icon: Icon(Icons.view_list_rounded, size: 18, color: !_gridMode ? UbColors.cyan : UbColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cari pilar SQPCEHR, Kaizen, atau Quick App...',
              hintStyle: const TextStyle(fontSize: 12.5, color: UbColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: UbColors.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close_rounded, size: 16, color: UbColors.textMuted),
                    )
                  : null,
              filled: true,
              fillColor: UbColors.bg.withValues(alpha: 0.75),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: UbColors.cyan),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMenuCards(double width) {
    final displayCard = _TopActionCard(
      title: 'Display',
      subtitle: 'Display KPI · GL Management Board',
      badge: '7 Pilar · 28 Board',
      icon: Icons.monitor_rounded,
      gradient: const [Color(0xFF0284C7), Color(0xFF4F46E5)],
      onTap: _openDisplayBoard,
    );

    final monitorCard = _TopActionCard(
      title: 'Monitor',
      subtitle: 'Monitor Display · Slide Show TV',
      badge: 'Shopfloor TV',
      icon: Icons.slideshow_rounded,
      gradient: const [Color(0xFF059669), Color(0xFF0891B2)],
      onTap: () => _showRoutePreview(
        title: 'Monitor Display',
        subtitle: 'Slide Show TV Shopfloor & Safety Patrol',
        route: '/monitor',
        icon: Icons.slideshow_rounded,
        color: UbColors.emerald,
      ),
    );

    if (width >= 560) {
      return Row(
        children: [
          Expanded(child: displayCard),
          const SizedBox(width: 12),
          Expanded(child: monitorCard),
        ],
      );
    }

    return Column(
      children: [
        displayCard,
        const SizedBox(height: 10),
        monitorCard,
      ],
    );
  }

  Widget _buildQuickAppsSection(List<QuickAppItem> items, int cols) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UbColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.apps_rounded, size: 17, color: UbColors.cyan),
                  SizedBox(width: 8),
                  Text('UB Quick App Dx', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              InkWell(
                onTap: () => _openChecksheet(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: UbColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: UbColors.cyan.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '⚡ Checksheet A3',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: UbColors.cyan),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _emptySearchState()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 74,
              ),
              itemCount: items.length,
              itemBuilder: (_, idx) {
                final q = items[idx];
                return InkWell(
                  onTap: () => _showRoutePreview(
                    title: q.title,
                    subtitle: q.subtitle,
                    route: q.route,
                    icon: q.icon,
                    color: q.color,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: UbColors.bg.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: q.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(q.icon, size: 18, color: q.color),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                q.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: UbColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _emptySearchState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text('Tidak ada item yang cocok dengan pencarian.', style: TextStyle(fontSize: 12, color: UbColors.textMuted)),
      ),
    );
  }
}

class _TopActionCard extends StatelessWidget {
  const _TopActionCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(icon, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(badge, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.88)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}

class _MacWindowContainer extends StatelessWidget {
  const _MacWindowContainer({
    required this.title,
    required this.subtitle,
    required this.dotColor,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color dotColor;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UbColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // macOS Window Titlebar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                const _Dot(Color(0xFFFF5F56)),
                const SizedBox(width: 6),
                const _Dot(Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                const _Dot(Color(0xFF27C93F)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: dotColor),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onToggleCollapse,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                      size: 18,
                      color: UbColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.item,
    required this.compactRow,
    required this.onTap,
  });

  final HubPillarItem item;
  final bool compactRow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (compactRow) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: UbColors.bg.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: item.gradient, begin: Alignment.bottomLeft, end: Alignment.topRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(item.code, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(item.badge, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: item.accentColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.subtitle, style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(item.highlight, style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w700, color: item.accentColor)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: UbColors.textMuted),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: UbColors.bg.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item.gradient,
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.code,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: item.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: item.accentColor.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      item.badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: item.accentColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: UbColors.textMuted),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.highlight,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: item.accentColor),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 14, color: item.accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
