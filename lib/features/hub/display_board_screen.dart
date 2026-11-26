// 1:1 Dart port of ubnetwork/app/display/page.tsx (GL Management Board Index)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/hub_catalog.dart';
import '../display/display_paper_screen.dart';

class DisplayBoardScreen extends StatefulWidget {
  const DisplayBoardScreen({super.key});

  @override
  State<DisplayBoardScreen> createState() => _DisplayBoardScreenState();
}

class _DisplayBoardScreenState extends State<DisplayBoardScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 760 ? 4 : (width >= 540 ? 3 : 2);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Soft ambient sky & violet orbs + 44px grid (1:1 display/page.tsx)
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 380,
              height: 380,
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
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _SubtleGridPainter()),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back_rounded, size: 14, color: Color(0xFF94A3B8)),
                                      SizedBox(width: 5),
                                      Text(
                                        'Beranda',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Colors.white, Color(0xFFE0F2FE), Color(0xFF7DD3FC)],
                                ).createShader(bounds),
                                child: const Text(
                                  'GL Management Board',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Text(
                                'Underbody · pilih pilar dan jenis kertas KPI yang ingin ditampilkan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: UbColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (width >= 720)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Pintasan ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1))),
                                _kbdChip('1–${HubCatalog.displayPillars.length}'),
                                const Text(' pilar  ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                _kbdChip('Geser'),
                                const Text(' pindah kertas', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 238,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pillar = HubCatalog.displayPillars[index];
                        return _DisplayPillarCard(
                          pillar: pillar,
                          orderIndex: index + 1,
                          onSelectRow: (row) => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DisplayPaperScreen(
                                pillar: pillar,
                                initialRowKey: row.key,
                                restoreOrientationOnExit: false,
                              ),
                            ),
                          ),
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

  Widget _kbdChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFE2E8F0)),
        ),
      );
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -45,
            right: -45,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pillar.gradient.first.withValues(alpha: 0.14),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(gradient: LinearGradient(colors: pillar.gradient)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: pillar.gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              pillar.chip,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
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
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
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
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: pillar.gradient.first.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(7),
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
                      const SizedBox(height: 9),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildRowTile(HubCatalog.displayRows[0])),
                                  const SizedBox(width: 7),
                                  Expanded(child: _buildRowTile(HubCatalog.displayRows[1])),
                                ],
                              ),
                            ),
                            const SizedBox(height: 7),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildRowTile(HubCatalog.displayRows[2])),
                                  const SizedBox(width: 7),
                                  Expanded(child: _buildRowTile(HubCatalog.displayRows[3])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowTile(DisplayRowMeta row) {
    final shortLabel = row.key == 'kaizen' ? 'Kaizen' : row.name;
    return InkWell(
      onTap: () => onSelectRow(row),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: pillar.gradient),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(row.icon, size: 13, color: Colors.white),
                ),
                const Icon(Icons.north_east_rounded, size: 13, color: Color(0xFF64748B)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.1, color: Colors.white),
                ),
                Text(
                  row.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9.5, height: 1.15, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubtleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const step = 44.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
