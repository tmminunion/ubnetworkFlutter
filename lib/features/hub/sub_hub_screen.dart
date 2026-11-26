import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/hub_catalog.dart';
import '../checksheet/checksheet_screen.dart';
import '../productivity/cbu_monitoring_screen.dart';
import '../productivity/chokotei_analytics_screen.dart';
import '../productivity/ckd_monitoring_screen.dart';
import '../productivity/chokotei_manual_screen.dart';
import '../productivity/attendance_screen.dart';
import '../productivity/prod_monitoring_screen.dart';
import '../productivity/after_prod_screen.dart';
import '../productivity/prod_kaizen_screen.dart';
import '../productivity/roster_screen.dart';
import '../productivity/shift_template_screen.dart';
import '../productivity/task_hub_screen.dart';
import '../quality/quality_daily_screen.dart';
import '../safety/kyt_monitoring_screen.dart';
import '../safety/safety_temuan_screen.dart';
import '../safety/safety_bira_screen.dart';
import '../safety/safety_device_screen.dart';
import '../safety/safety_kpi_screen.dart';
import '../safety/sga_group_screen.dart';
import 'display_board_screen.dart';

class SubHubScreen extends StatelessWidget {
  const SubHubScreen({
    super.key,
    required this.config,
    this.onOpenSettings,
  });

  final SubHubConfig config;
  final VoidCallback? onOpenSettings;

  void _handleModuleTap(BuildContext context, SubModuleItem mod) {
    if (mod.route == '/productivity/checksheet' || mod.route == '/productivity/print') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ChecksheetScreen()),
      );
      return;
    }

    if (mod.route == '/kyt/monitoring') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const KytMonitoringScreen()),
      );
      return;
    }

    if (mod.route == '/quality/daily/out') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const QualityDailyScreen(kind: 'out')),
      );
      return;
    }

    if (mod.route == '/quality/daily/in') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const QualityDailyScreen(kind: 'in')),
      );
      return;
    }

    if (mod.route == '/safety/device') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SafetyDeviceScreen()),
      );
      return;
    }

    if (mod.route == '/safety/bira') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SafetyBiraScreen()),
      );
      return;
    }

    if (mod.route == '/safety/kpi') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SafetyKpiScreen()),
      );
      return;
    }

    if (mod.route == '/safety/group') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SgaGroupScreen()),
      );
      return;
    }

    if (mod.route == '/safety/temuan') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SafetyTemuanScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/roster') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RosterScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/absensi') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AttendanceScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/cbu') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CbuMonitoringScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/ckd') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CkdMonitoringScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/chokotei') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ChokoteiAnalyticsScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/chokotei-manual') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ChokoteiManualScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/after-prod') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AfterProdScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/tasks') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TaskHubScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/shift-template') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ShiftTemplateScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/kaizen') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProdKaizenScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/monitoring') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProdMonitoringScreen()),
      );
      return;
    }

    if (mod.route == '/productivity/settings' && onOpenSettings != null) {
      onOpenSettings!();
      return;
    }

    if (mod.route.startsWith('/display/')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DisplayBoardScreen()),
      );
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
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: mod.gradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(mod.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mod.title,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mod.badge,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: mod.accentColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mod.desc,
              style: const TextStyle(fontSize: 12.5, color: UbColors.textMuted, height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: UbColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(Icons.route_rounded, size: 15, color: mod.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Route: ${mod.route} · Tahap migrasi native Flutter',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: config.gradient.first,
                  foregroundColor: UbColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w900)),
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
    final crossAxisCount = width >= 980 ? 3 : (width >= 620 ? 2 : 1);

    return Scaffold(
      backgroundColor: UbColors.bg,
      body: Stack(
        children: [
          // Ambient glow matching macOS wallpaper
          Positioned(
            top: -90,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.gradient.first.withValues(alpha: 0.16),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. TOP macOS WINDOW TITLEBAR HEADER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: UbColors.bg.withValues(alpha: 0.85),
                    border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      // Traffic lights
                      if (width >= 520) ...[
                        _TrafficDot(color: const Color(0xFFFF5F56), onTap: () => Navigator.pop(context)),
                        const SizedBox(width: 6),
                        const _TrafficDot(color: Color(0xFFFFBD2E)),
                        const SizedBox(width: 6),
                        const _TrafficDot(color: Color(0xFF27C93F)),
                        const SizedBox(width: 12),
                      ],
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: config.gradient,
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          config.code,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    config.title.split(' (').first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: config.accentColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: config.accentColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    config.typeLabel,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: config.accentColor),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              config.pathLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: UbColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. MAIN WORKSPACE
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Hero Header Card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: UbColors.surface.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: config.gradient,
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Icon(config.icon, color: Colors.white, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        config.title,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        config.subtitle,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: config.accentColor),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: config.accentColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: config.accentColor.withValues(alpha: 0.25)),
                                        ),
                                        child: Text(
                                          config.tagline,
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: config.accentColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Section Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: config.accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Daftar Modul ${config.title.split(' (').first}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: config.accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: config.accentColor.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  '${config.modules.length} Modul',
                                  style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w700, color: config.accentColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Sub-Modules Grid
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 178,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final mod = config.modules[index];
                              return _SubModuleCard(
                                module: mod,
                                pillarAccent: config.accentColor,
                                onTap: () => _handleModuleTap(context, mod),
                              );
                            },
                            childCount: config.modules.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficDot extends StatelessWidget {
  const _TrafficDot({required this.color, this.onTap});

  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _SubModuleCard extends StatelessWidget {
  const _SubModuleCard({
    required this.module,
    required this.pillarAccent,
    required this.onTap,
  });

  final SubModuleItem module;
  final Color pillarAccent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: UbColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: module.isNativeReady
                ? pillarAccent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: module.gradient,
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(module.icon, color: Colors.white, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: module.isNativeReady
                        ? UbColors.emerald.withValues(alpha: 0.18)
                        : module.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: module.isNativeReady
                          ? UbColors.emerald.withValues(alpha: 0.45)
                          : module.accentColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    module.badge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: module.isNativeReady ? const Color(0xFF6EE7B7) : module.accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              module.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                module.desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: UbColors.textMuted, height: 1.35),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      module.route,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        color: pillarAccent.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: module.isNativeReady
                          ? pillarAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: module.isNativeReady ? pillarAccent : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
