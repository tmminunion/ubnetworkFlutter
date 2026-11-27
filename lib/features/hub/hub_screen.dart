import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/hub_catalog.dart';
import '../../models/checksheet_models.dart';
import '../../services/auth_service.dart';
import '../../services/local_store.dart';
import '../../services/ub_web_api.dart';
import '../checksheet/checksheet_screen.dart';
import '../env/env_daily_screen.dart';
import '../env/env_temuan_screen.dart';
import '../hr/bacadoa_screen.dart';
import '../hr/idnu_screen.dart';
import '../kaizen/five_r_screen.dart';
import '../kaizen/qcc_screen.dart';
import '../kaizen/sw_observasi_screen.dart';
import '../kaizen/tpm_screen.dart';
import '../productivity/after_prod_screen.dart';
import '../productivity/task_hub_screen.dart';
import '../quick/docs_screen.dart';
import '../quick/henkaten_board_screen.dart';
import '../quick/postit_board_screen.dart';
import '../quick/ubdrive_screen.dart';
import '../safety/sga_group_screen.dart';
import 'display_board_screen.dart';
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
  bool _loading = true;
  bool _pillarsCollapsed = false;
  bool _kaizenCollapsed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await LocalStore.instance.getSettings();
    if (!mounted) return;
    setState(() {
      _cfg = cfg;
      _loading = false;
    });

    // Sinkronkan Line Name & Takt Time otomatis dari pengaturan server (/api/ub?action=get_settings)
    final res = await UbWebApi.instance.getUb(const {'action': 'get_settings'});
    if (!mounted) return;
    if (res.ok && res.map['status'] == 'success' && res.map['data'] is Map) {
      final d = Map<String, dynamic>.from(res.map['data'] as Map);
      final serverLine = (d['line_name'] ?? cfg.lineName).toString().trim();
      final serverTt = d['current_takt_time'] is num
          ? (d['current_takt_time'] as num).toDouble()
          : double.tryParse('${d['current_takt_time'] ?? ''}'.replaceAll(',', '.'));
      var changed = false;
      if (serverLine.isNotEmpty && serverLine != cfg.lineName) {
        cfg.lineName = serverLine;
        changed = true;
      }
      if (serverTt != null && serverTt > 0 && serverTt != cfg.taktTime) {
        cfg.taktTime = serverTt;
        changed = true;
      }
      if (changed) {
        await LocalStore.instance.saveSettings(cfg);
        if (mounted) setState(() => _cfg = cfg);
      }
    }
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
        builder: (_) => SubHubScreen(config: config),
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
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SgaGroupScreen()));
      return;
    }
    if (route == '/qcc') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QccScreen()));
      return;
    }
    if (route == '/tpm') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TpmScreen()));
      return;
    }
    if (route == '/5r') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FiveRScreen()));
      return;
    }
    if (route == '/sw') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SwObservasiScreen()));
      return;
    }
    if (route == '/henkaten') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HenkatenBoardScreen()));
      return;
    }
    if (route == '/postit') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PostitBoardScreen()));
      return;
    }
    if (route == '/ubdrive') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const UbdriveScreen()));
      return;
    }
    if (route == '/docs') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DocsScreen()));
      return;
    }
    if (route == '/productivity/tasks') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TaskHubScreen()));
      return;
    }
    if (route == '/productivity/after-prod') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AfterProdScreen()));
      return;
    }
    if (route == '/env/daily') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EnvDailyScreen()));
      return;
    }
    if (route == '/env/temuan') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EnvTemuanScreen()));
      return;
    }
    if (route == '/bacadoa') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BacaDoaScreen()));
      return;
    }
    if (route == '/idnu') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IdnuScreen()));
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final user = widget.authUser ?? AuthService.instance.currentUser;
    final userShift = (user?.shift ?? '').toUpperCase();
    final ttLabel = '${_cfg.taktTime}'.replaceAll('.', ',');

    final pillarCols = width >= 960 ? 3 : 2;
    final kaizenCols = width >= 1020 ? 5 : (width >= 680 ? 3 : 2);
    final quickCols = width >= 960 ? 4 : (width >= 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -110,
            left: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.09),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // =========================================================
                // 1. SIMPLE COMPACT HEADER BAR (1:1 Next.js — Tanpa Task Lokal & Tanpa Pengaturan API)
                // =========================================================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: UbColors.bg.withValues(alpha: 0.9),
                    border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text('UB', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            const Text(
                              'UBnetwork',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '· ${_cfg.lineName} · TT ${ttLabel}m',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: UbColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (user != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: userShift == 'RED'
                                      ? UbColors.rose
                                      : (userShift == 'WHITE' ? Colors.white : UbColors.amber),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  userShift == 'RED' ? 'R' : (userShift == 'WHITE' ? 'W' : 'A'),
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: userShift == 'RED' ? Colors.white : UbColors.bg,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 108),
                                child: Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (widget.onLogout != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: widget.onLogout,
                          borderRadius: BorderRadius.circular(9),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: UbColors.rose.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: UbColors.rose.withValues(alpha: 0.35)),
                            ),
                            child: const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFFDA4AF)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // =========================================================
                // 2. COMPACT MAIN WORKSPACE
                // =========================================================
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 22),
                            children: [
                              // DISPLAY KPI BANNER
                              _TopActionCard(
                                title: 'Display KPI',
                                subtitle: 'GL Management Board · 7 Pilar × 4 Kertas',
                                badge: '28 Board',
                                icon: Icons.monitor_rounded,
                                gradient: const [Color(0xFF0284C7), Color(0xFF4F46E5)],
                                onTap: _openDisplayBoard,
                              ),
                              const SizedBox(height: 10),

                              // WINDOW 1: 6 PILAR UTAMA MANUFAKTUR (S-Q-P-C-HR-E)
                              _CompactSectionContainer(
                                title: '6 Pilar Manufaktur (S-Q-P-C-HR-E)',
                                subtitle: '${HubCatalog.kpiPillars.length} Pilar',
                                dotColor: UbColors.cyan,
                                collapsed: _pillarsCollapsed,
                                onToggleCollapse: () => setState(() => _pillarsCollapsed = !_pillarsCollapsed),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: pillarCols,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    mainAxisExtent: 92,
                                  ),
                                  itemCount: HubCatalog.kpiPillars.length,
                                  itemBuilder: (_, idx) => _PillarCard(
                                    item: HubCatalog.kpiPillars[idx],
                                    onTap: () => _openSubHub(HubCatalog.kpiPillars[idx].id),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // WINDOW 2: AKTIVITAS KAIZEN (SGA, QCC, TPM, 5R, SW)
                              _CompactSectionContainer(
                                title: 'Aktivitas Kaizen',
                                subtitle: '${HubCatalog.kaizenActivities.length} Menu',
                                dotColor: UbColors.amber,
                                collapsed: _kaizenCollapsed,
                                onToggleCollapse: () => setState(() => _kaizenCollapsed = !_kaizenCollapsed),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: kaizenCols,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    mainAxisExtent: 90,
                                  ),
                                  itemCount: HubCatalog.kaizenActivities.length,
                                  itemBuilder: (_, idx) {
                                    final k = HubCatalog.kaizenActivities[idx];
                                    return _PillarCard(
                                      item: k,
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
                              const SizedBox(height: 10),

                              // SECTION 3: UB QUICK APP DX
                              _buildQuickAppsSection(HubCatalog.quickApps, quickCols),
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

  Widget _buildQuickAppsSection(List<QuickAppItem> items, int cols) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: UbColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.apps_rounded, size: 15, color: UbColors.cyan),
                  SizedBox(width: 6),
                  Text('UB Quick App Dx', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              InkWell(
                onTap: () => _openChecksheet(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: UbColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: UbColors.cyan.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '⚡ Checksheet A3',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: UbColors.cyan),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              mainAxisExtent: 64,
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
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: UbColors.bg.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: q.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(q.icon, size: 16, color: q.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              q.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9.5, color: UbColors.textMuted),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(badge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.88)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CompactSectionContainer extends StatelessWidget {
  const _CompactSectionContainer({
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggleCollapse,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
              ),
              child: Row(
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: dotColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                    size: 16,
                    color: UbColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.all(9),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.item,
    required this.onTap,
  });

  final HubPillarItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: UbColors.bg.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item.gradient,
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.code,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: item.accentColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: UbColors.textMuted),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 12, color: item.accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
