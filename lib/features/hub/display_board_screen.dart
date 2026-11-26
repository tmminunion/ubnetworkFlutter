import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/hub_catalog.dart';

class DisplayBoardScreen extends StatelessWidget {
  const DisplayBoardScreen({super.key});

  void _showPaperInfo(BuildContext context, DisplayPillarItem pillar, DisplayRowMeta row) {
    final route = '/display/${pillar.slug}/${row.key}';
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
                    gradient: LinearGradient(colors: pillar.gradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(row.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${row.name} — ${pillar.shortName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pillar.fullName} · ${row.desc}',
                        style: const TextStyle(fontSize: 12, color: UbColors.textMuted),
                      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROUTE: $route',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pillar.accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kertas Display KPI 16:9 / A4 untuk papan GL Management Board ini sedang disiapkan ke mode native Flutter.',
                    style: TextStyle(fontSize: 12.5, color: UbColors.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: pillar.gradient.first,
                  foregroundColor: UbColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
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
    final crossAxisCount = width >= 1100 ? 4 : (width >= 680 ? 2 : 1);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Ambient glows matching /display/page.tsx
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0284C7).withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded, size: 16, color: UbColors.textMuted),
                                SizedBox(width: 6),
                                Text('Beranda', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: UbColors.textMuted)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFE0F2FE), Color(0xFF7DD3FC)],
                          ).createShader(bounds),
                          child: const Text(
                            'GL Management Board',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Underbody · pilih pilar dan jenis kertas KPI yang ingin ditampilkan',
                          style: TextStyle(fontSize: 12.5, color: UbColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 268,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pillar = HubCatalog.displayPillars[index];
                        return _DisplayPillarCard(
                          pillar: pillar,
                          orderIndex: index + 1,
                          onSelectRow: (row) => _showPaperInfo(context, pillar, row),
                        );
                      },
                      childCount: HubCatalog.displayPillars.length,
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
}

class _DisplayPillarCard extends StatelessWidget {
  const _DisplayPillarCard({
    required this.pillar,
    required this.orderIndex,
    required this.onSelectRow,
  });

  final DisplayPillarItem pillar;
  final int orderIndex;
  final void Function(DisplayRowMeta row) onSelectRow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: pillar.gradient),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: pillar.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: pillar.gradient.first.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          pillar.chip,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pillar.shortName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: pillar.accentColor,
                              ),
                            ),
                            Text(
                              pillar.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: UbColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pillar.gradient.first.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$orderIndex',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: pillar.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.72,
                      ),
                      itemCount: HubCatalog.displayRows.length,
                      itemBuilder: (context, idx) {
                        final row = HubCatalog.displayRows[idx];
                        return InkWell(
                          onTap: () => onSelectRow(row),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: UbColors.surface.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: pillar.gradient),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Icon(row.icon, size: 15, color: Colors.white),
                                    ),
                                    const Icon(Icons.north_east_rounded, size: 14, color: UbColors.textMuted),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                    Text(
                                      row.desc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 9.5, color: UbColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
