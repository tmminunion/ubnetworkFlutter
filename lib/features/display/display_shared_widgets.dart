// 1:1 Dart port of ubnetwork/app/display/PaperFrame.tsx, sub-shared.tsx, safety-main.tsx Block, & kaizen-report.tsx
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'display_paper_defaults.dart';

// =============================================================================
// 1. PAPER FRAME 16:9 (1600 x 900) — 1:1 `PaperFrame.tsx`
// =============================================================================

class DisplayPaperFrame extends StatelessWidget {
  const DisplayPaperFrame({
    super.key,
    required this.pillarChip,
    required this.pillarSlug,
    required this.pillarShort,
    required this.rowKey,
    required this.fy,
    this.customTitle,
    required this.child,
  });

  final String pillarChip;
  final String pillarSlug;
  final String pillarShort;
  final String rowKey;
  final int fy;
  final String? customTitle;
  final Widget child;

  Color get _themeBg => switch (rowKey) {
        'main' => const Color(0xFF2563EB),
        'sub' => const Color(0xFFFDE047),
        'proses' => const Color(0xFF64748B),
        'kaizen' => const Color(0xFFF97316),
        _ => const Color(0xFF2563EB),
      };

  Color get _themeFg => rowKey == 'sub' ? const Color(0xFF0F172A) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final letter = pillarChip.trim().isEmpty || pillarSlug == 'hoshin' ? 'H' : pillarChip.trim();
    final headerTitle = resolvePaperHeaderTitle(
      slug: pillarSlug,
      shortName: pillarShort,
      rowKey: rowKey,
      customTitle: customTitle,
    );

    return Container(
      width: kDisplayPaperW,
      height: kDisplayPaperH,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFF1E293B), fontFamily: 'sans-serif'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 92,
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _themeBg, width: 4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: letter.length > 1 ? 38 : 52,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PT. TMMIN',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Underbody Assy',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _themeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        headerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: _themeFg,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Center(
                    child: Text(
                      DisplayFyMath.fyLabel(fy),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2. EVA MARK (O / X) & TOOLBAR CONTROLS — 1:1 `sub-shared.tsx`
// =============================================================================

class EvaMarkWidget extends StatelessWidget {
  const EvaMarkWidget({
    super.key,
    required this.ok,
    this.size = 20,
  });

  final bool? ok;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (ok == null) return SizedBox(width: size, height: size);
    return CustomPaint(
      size: Size.square(size),
      painter: _EvaMarkPainter(ok: ok!),
    );
  }
}

class _EvaMarkPainter extends CustomPainter {
  const _EvaMarkPainter({required this.ok});

  final bool ok;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 22.0;
    if (ok) {
      final p = Paint()
        ..color = const Color(0xFF15803D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * s;
      canvas.drawCircle(Offset(11 * s, 11 * s), 7.8 * s, p);
    } else {
      final p = Paint()
        ..color = const Color(0xFFB91C1C)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0 * s;
      canvas.drawLine(Offset(5 * s, 5 * s), Offset(17 * s, 17 * s), p);
      canvas.drawLine(Offset(17 * s, 5 * s), Offset(5 * s, 17 * s), p);
    }
  }

  @override
  bool shouldRepaint(covariant _EvaMarkPainter oldDelegate) => oldDelegate.ok != ok;
}

class PaperMonthNav extends StatelessWidget {
  const PaperMonthNav({
    super.key,
    required this.ym,
    required this.onPrev,
    required this.onNext,
  });

  final String ym;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('MONTH', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        _PaperTinyBtn(label: '‹', onTap: onPrev),
        SizedBox(
          width: 68,
          child: Text(
            DisplayFyMath.labelOfYm(ym),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
        ),
        _PaperTinyBtn(label: '›', onTap: onNext),
      ],
    );
  }
}

class PaperTeamToggle extends StatelessWidget {
  const PaperTeamToggle({
    super.key,
    required this.team,
    required this.onChanged,
  });

  final String team; // 'red' | 'white'
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isRed = team == 'red';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('REGU', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => onChanged('red'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: isRed ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'RED',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isRed ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => onChanged('white'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: !isRed ? Colors.white : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
              border: !isRed ? Border.all(color: const Color(0xFF0F172A), width: 1.2) : null,
            ),
            child: Text(
              'WHITE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: !isRed ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PaperFilterSeg extends StatelessWidget {
  const PaperFilterSeg({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          const SizedBox(width: 5),
        ],
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onChanged(options[i].$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: value == options[i].$1 ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                options[i].$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: value == options[i].$1 ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PaperPager extends StatelessWidget {
  const PaperPager({
    super.key,
    required this.page,
    required this.pages,
    required this.onPageChanged,
  });

  final int page;
  final int pages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final safePages = math.max(1, pages);
    final cur = page.clamp(1, safePages);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PaperTinyBtn(
          label: '‹',
          enabled: cur > 1,
          onTap: () => onPageChanged(cur - 1),
        ),
        const SizedBox(width: 6),
        Text(
          'Hal $cur/$safePages',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
        ),
        const SizedBox(width: 6),
        _PaperTinyBtn(
          label: '›',
          enabled: cur < safePages,
          onTap: () => onPageChanged(cur + 1),
        ),
      ],
    );
  }
}

class _PaperTinyBtn extends StatelessWidget {
  const _PaperTinyBtn({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
        ),
      ),
    );
  }
}

Widget buildPaperChip(String label, String value, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
    child: Text('$label $value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
  );
}

Widget buildPaperPhotoBox(String? rawUrl, {String placeholder = 'FOTO', BoxFit fit = BoxFit.contain}) {
  final u = (rawUrl ?? '').trim();
  if (u.isEmpty) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Text(
        placeholder,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2, color: Color(0xFFCBD5E1)),
      ),
    );
  }
  if (u.startsWith('data:image/')) {
    try {
      final comma = u.indexOf(',');
      if (comma > 0) {
        final bytes = base64Decode(u.substring(comma + 1));
        return Container(
          color: const Color(0xFFF1F5F9),
          child: Image.memory(bytes, fit: fit, errorBuilder: (_, __, ___) => _brokenPhoto(placeholder)),
        );
      }
    } catch (_) {
      return _brokenPhoto(placeholder);
    }
  }
  final resolved = u.startsWith('http://') || u.startsWith('https://')
      ? u
      : 'https://ubnetwork.vercel.app${u.startsWith('/') ? '' : '/'}$u';
  return Container(
    color: const Color(0xFFF1F5F9),
    child: Image.network(
      resolved,
      fit: fit,
      errorBuilder: (_, __, ___) => _brokenPhoto(placeholder),
    ),
  );
}

Widget _brokenPhoto(String placeholder) => Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Text(
        placeholder,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Color(0xFFCBD5E1)),
      ),
    );

// =============================================================================
// 3. SAFETY / QUALITY / ENV MAIN FY LINE-CHART BLOCK — 1:1 `safety-main.tsx`
// =============================================================================

class FyShiftLineSeries {
  const FyShiftLineSeries({
    required this.red,
    required this.white,
    required this.target,
    this.title,
    this.label,
  });

  final List<double?> red;
  final List<double?> white;
  final double target;
  final String? title;
  final String? label;
}

class FyLineBlockWidget extends StatelessWidget {
  const FyLineBlockWidget({
    super.key,
    required this.title,
    required this.balloonLabel,
    required this.axisLabel,
    required this.months,
    required this.series,
    this.lowerIsBetter = true,
  });

  final String title;
  final String balloonLabel;
  final String axisLabel;
  final List<String> months;
  final FyShiftLineSeries series;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    bool? eval(double? v) {
      if (v == null) return null;
      return lowerIsBetter ? v <= series.target : v >= series.target;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 26,
            constraints: const BoxConstraints(minWidth: 460),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFF3F3B3B),
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
        Expanded(
          child: CustomPaint(
            painter: _FyLineChartPainter(
              series: series,
              balloonLabel: balloonLabel,
              axisLabel: axisLabel,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        // 12-Month Table with split R | W EVA row (150px left + 12 flex cols)
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF94A3B8)),
              left: BorderSide(color: Color(0xFF94A3B8)),
            ),
          ),
          child: Column(
            children: [
              _buildRow(
                left: 'MONTH',
                leftBg: const Color(0xFFF1F5F9),
                leftBold: true,
                cells: months,
                cellBg: const Color(0xFFF1F5F9),
                cellBold: true,
                height: 24,
              ),
              _buildRow(
                left: 'RED',
                leftBg: const Color(0xFFF87171),
                leftFg: Colors.white,
                leftBold: true,
                cells: List.generate(12, (i) => i < series.red.length ? DisplayFyMath.fmtNum(series.red[i]) : ''),
                height: 24,
              ),
              _buildRow(
                left: 'WHITE',
                leftBold: true,
                cells: List.generate(12, (i) => i < series.white.length ? DisplayFyMath.fmtNum(series.white[i]) : ''),
                height: 24,
              ),
              _buildRow(
                left: 'Target',
                leftBold: true,
                cells: List.filled(12, DisplayFyMath.fmtNum(series.target)),
                height: 24,
              ),
              // EVA R | W Row
              SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 150,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFF94A3B8)),
                          bottom: BorderSide(color: Color(0xFF94A3B8)),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text('EVA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          Spacer(),
                          Text('R | W', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                    for (var i = 0; i < 12; i++)
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFDE68A),
                            border: Border(
                              right: BorderSide(color: Color(0xFF94A3B8)),
                              bottom: BorderSide(color: Color(0xFF94A3B8)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Positioned(
                                      left: 3,
                                      top: 1,
                                      child: Text('R', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                                    ),
                                    EvaMarkWidget(ok: eval(i < series.red.length ? series.red[i] : null), size: 19),
                                  ],
                                ),
                              ),
                              Container(width: 1, color: const Color(0x66F59E0B)),
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Positioned(
                                      left: 3,
                                      top: 1,
                                      child: Text('W', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                                    ),
                                    EvaMarkWidget(ok: eval(i < series.white.length ? series.white[i] : null), size: 19),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildRow({
    required String left,
    required List<String> cells,
    required double height,
    Color leftBg = Colors.white,
    Color leftFg = const Color(0xFF0F172A),
    bool leftBold = false,
    Color cellBg = Colors.white,
    bool cellBold = false,
  }) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: leftBg,
              border: const Border(
                right: BorderSide(color: Color(0xFF94A3B8)),
                bottom: BorderSide(color: Color(0xFF94A3B8)),
              ),
            ),
            child: Text(
              left,
              style: TextStyle(
                fontSize: 16,
                fontWeight: leftBold ? FontWeight.w800 : FontWeight.w600,
                color: leftFg,
              ),
            ),
          ),
          for (final c in cells)
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cellBg,
                  border: const Border(
                    right: BorderSide(color: Color(0xFF94A3B8)),
                    bottom: BorderSide(color: Color(0xFF94A3B8)),
                  ),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: cellBold ? FontWeight.w700 : FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FyLineChartPainter extends CustomPainter {
  const _FyLineChartPainter({
    required this.series,
    required this.balloonLabel,
    required this.axisLabel,
  });

  final FyShiftLineSeries series;
  final String balloonLabel;
  final String axisLabel;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 150.0;
    const top = 10.0;
    final ph = math.max(40.0, size.height - top - 8.0);
    final pw = math.max(100.0, size.width - left);
    final colW = pw / 12.0;

    final all = <double>[
      ...series.red.whereType<double>(),
      ...series.white.whereType<double>(),
    ];
    var rawMax = math.max(0.0, series.target);
    for (final v in all) {
      if (v > rawMax) rawMax = v;
    }
    final fractional = [...all, series.target].any((v) => v != v.roundToDouble());
    final ax = DisplayFyMath.chartAxis(rawMax, fractional);
    final ymax = ax.ymax;
    final step = ax.step;

    double yOf(double v) => top + ph - (v.clamp(0.0, ymax) / ymax) * ph;
    double xOf(int i) => left + colW * i + colW / 2.0;

    // Plot area background & border
    final bgRect = Rect.fromLTWH(left, top, pw, ph);
    canvas.drawRect(bgRect, Paint()..color = Colors.white);
    canvas.drawRect(
      bgRect,
      Paint()
        ..color = const Color(0xFF9CA3AF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Ticks & horizontal lines
    final gridPaint = Paint()..color = const Color(0xFFE5E7EB)..strokeWidth = 1;
    for (var i = 0; i * step <= ymax + step / 1000.0; i++) {
      final t = double.parse((i * step).toStringAsFixed(6));
      final yy = yOf(t);
      canvas.drawLine(Offset(left, yy), Offset(size.width, yy), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: DisplayFyMath.fmtNum(t),
          style: const TextStyle(fontSize: 15, color: Color(0xFF374151)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - 8 - tp.width, yy - tp.height / 2));
    }

    // Rotated Y-axis label
    final axisTp = TextPainter(
      text: TextSpan(
        text: axisLabel,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(18, top + ph / 2);
    canvas.rotate(-math.pi / 2);
    axisTp.paint(canvas, Offset(-axisTp.width / 2, -axisTp.height / 2));
    canvas.restore();

    // Target dashed line
    if (series.target > 0) {
      _drawDashedHLine(canvas, left, size.width, yOf(series.target), const Color(0xFF16A34A), 2.0, 7, 5);
    }

    // Legend on left
    final legY1 = size.height - 38;
    final legY2 = size.height - 20;
    canvas.drawLine(Offset(38, legY1), Offset(68, legY1), Paint()..color = const Color(0xFFEF4444)..strokeWidth = 4);
    (TextPainter(
      text: const TextSpan(text: ': Red', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
      textDirection: TextDirection.ltr,
    )..layout())
        .paint(canvas, Offset(74, legY1 - 8));

    canvas.drawLine(Offset(38, legY2), Offset(68, legY2), Paint()..color = const Color(0xFF111827)..strokeWidth = 2.5);
    (TextPainter(
      text: const TextSpan(text: ': White', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
      textDirection: TextDirection.ltr,
    )..layout())
        .paint(canvas, Offset(74, legY2 - 8));

    // Red polyline + circles
    _drawSeriesSegments(canvas, series.red, xOf, yOf, const Color(0xFFEF4444), 4.5);
    for (var i = 0; i < 12 && i < series.red.length; i++) {
      final v = series.red[i];
      if (v != null) {
        canvas.drawCircle(Offset(xOf(i), yOf(v)), 5, Paint()..color = const Color(0xFFEF4444));
      }
    }

    // White polyline + X marks
    _drawSeriesSegments(canvas, series.white, xOf, yOf, const Color(0xFF111827), 2.5);
    final xMarkPaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 2.5;
    for (var i = 0; i < 12 && i < series.white.length; i++) {
      final v = series.white[i];
      if (v != null) {
        final cx = xOf(i);
        final cy = yOf(v);
        canvas.drawLine(Offset(cx - 5, cy - 5), Offset(cx + 5, cy + 5), xMarkPaint);
        canvas.drawLine(Offset(cx - 5, cy + 5), Offset(cx + 5, cy - 5), xMarkPaint);
      }
    }

    // Target callout box at top-right
    final lastX = xOf(11);
    final tipY = yOf(series.target);
    final ptrPaint = Paint()
      ..color = const Color(0xFF4B5563)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(lastX - 38, top + 36), Offset(lastX, tipY), ptrPaint);
    canvas.drawLine(Offset(lastX - 12, top + 36), Offset(lastX, tipY), ptrPaint);

    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 262, top + 6, 236, 30),
      const Radius.circular(6),
    );
    canvas.drawRRect(boxRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      boxRect,
      Paint()
        ..color = const Color(0xFF4B5563)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final tgtTp = TextPainter(
      text: TextSpan(
        text: 'TGT: ${DisplayFyMath.fmtNum(series.target)} $balloonLabel',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tgtTp.paint(canvas, Offset(size.width - 144 - tgtTp.width / 2, top + 21 - tgtTp.height / 2));
  }

  void _drawSeriesSegments(
    Canvas canvas,
    List<double?> vals,
    double Function(int) xOf,
    double Function(double) yOf,
    Color color,
    double strokeWidth,
  ) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    Path? cur;
    var count = 0;
    for (var i = 0; i < 12 && i < vals.length; i++) {
      final v = vals[i];
      if (v == null) {
        if (cur != null && count > 1) canvas.drawPath(cur, p);
        cur = null;
        count = 0;
      } else {
        final pt = Offset(xOf(i), yOf(v));
        if (cur == null) {
          cur = Path()..moveTo(pt.dx, pt.dy);
          count = 1;
        } else {
          cur.lineTo(pt.dx, pt.dy);
          count++;
        }
      }
    }
    if (cur != null && count > 1) canvas.drawPath(cur, p);
  }

  @override
  bool shouldRepaint(covariant _FyLineChartPainter oldDelegate) => true;
}

void drawDashedLine(
  Canvas canvas,
  Offset p1,
  Offset p2,
  Color color,
  double width,
  double dash,
  double gap,
) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = width;
  final dx = p2.dx - p1.dx;
  final dy = p2.dy - p1.dy;
  final dist = math.sqrt(dx * dx + dy * dy);
  if (dist <= 0) return;
  final ux = dx / dist;
  final uy = dy / dist;
  var pos = 0.0;
  while (pos < dist) {
    final end = math.min(pos + dash, dist);
    canvas.drawLine(
      Offset(p1.dx + ux * pos, p1.dy + uy * pos),
      Offset(p1.dx + ux * end, p1.dy + uy * end),
      paint,
    );
    pos += dash + gap;
  }
}

void _drawDashedHLine(Canvas canvas, double x1, double x2, double y, Color color, double w, double dash, double gap) {
  drawDashedLine(canvas, Offset(x1, y), Offset(x2, y), color, w, dash, gap);
}

// =============================================================================
// 4. SUB KPI 3-MONTH + 31-DAY CHART & GRID — 1:1 `quality-sub`, `productivity-sub`, `hr-dev-sub`, `env-sub`
// =============================================================================

class Sub3MonthDailyChart extends StatelessWidget {
  const Sub3MonthDailyChart({
    super.key,
    required this.monthVals,
    required this.dayVals,
    required this.weekend,
    required this.targets,
    required this.yLabel,
    this.isBar = false,
    this.barColor = const Color(0xFFF87171),
    this.lowerIsBetter = true,
    this.fractional = true,
    this.fixedMinY,
    this.fixedMaxY,
    this.fixedStep,
    this.targetSuffix = '',
  });

  final List<double?> monthVals; // length 3
  final List<double?> dayVals; // length 31
  final List<bool> weekend; // length 31
  final List<double> targets; // length 3 (targets[2] = current month & daily target)
  final String yLabel;
  final bool isBar;
  final Color barColor;
  final bool lowerIsBetter;
  final bool fractional;
  final double? fixedMinY;
  final double? fixedMaxY;
  final double? fixedStep;
  final String targetSuffix;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Sub3MonthDailyPainter(
        monthVals: monthVals,
        dayVals: dayVals,
        weekend: weekend,
        targets: targets,
        yLabel: yLabel,
        isBar: isBar,
        barColor: barColor,
        lowerIsBetter: lowerIsBetter,
        fractional: fractional,
        fixedMinY: fixedMinY,
        fixedMaxY: fixedMaxY,
        fixedStep: fixedStep,
        targetSuffix: targetSuffix,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _Sub3MonthDailyPainter extends CustomPainter {
  const _Sub3MonthDailyPainter({
    required this.monthVals,
    required this.dayVals,
    required this.weekend,
    required this.targets,
    required this.yLabel,
    required this.isBar,
    required this.barColor,
    required this.lowerIsBetter,
    required this.fractional,
    this.fixedMinY,
    this.fixedMaxY,
    this.fixedStep,
    required this.targetSuffix,
  });

  final List<double?> monthVals;
  final List<double?> dayVals;
  final List<bool> weekend;
  final List<double> targets;
  final String yLabel;
  final bool isBar;
  final Color barColor;
  final bool lowerIsBetter;
  final bool fractional;
  final double? fixedMinY;
  final double? fixedMaxY;
  final double? fixedStep;
  final String targetSuffix;

  @override
  void paint(Canvas canvas, Size size) {
    const labelW = 70.0;
    const mcolW = 52.0;
    const days = 31;
    const top = 10.0;
    final ph = math.max(40.0, size.height - top - 8.0);
    final base = top + ph;
    final dx0 = labelW + 3 * mcolW;
    final dcolW = math.max(8.0, (size.width - dx0) / days);

    final target = targets.length >= 3 ? targets[2] : (targets.isNotEmpty ? targets.last : 0.0);
    final vals = <double>[
      ...monthVals.whereType<double>(),
      ...dayVals.whereType<double>(),
    ];

    final ymin = fixedMinY ?? 0.0;
    double ymax;
    double step;
    if (fixedMaxY != null && fixedStep != null) {
      ymax = fixedMaxY!;
      step = fixedStep!;
    } else {
      var rawMax = math.max(target, 0.0);
      for (final t in targets) {
        if (t > rawMax) rawMax = t;
      }
      for (final v in vals) {
        if (v > rawMax) rawMax = v;
      }
      final ax = DisplayFyMath.chartAxis(math.max(rawMax, fractional ? 0.01 : 1.0), fractional);
      ymax = fixedMaxY != null ? math.max(fixedMaxY!, ax.ymax) : ax.ymax;
      step = (fixedMaxY != null && ymax == fixedMaxY) ? fixedMaxY! / 5.0 : ax.step;
    }

    double yOf(double v) {
      final clamped = v.clamp(ymin, ymax);
      return top + ph * (1.0 - (clamped - ymin) / math.max(1e-9, ymax - ymin));
    }

    // Plot boxes (3-month box + 31-day box)
    final mRect = Rect.fromLTWH(labelW, top, 3 * mcolW, ph);
    final dRect = Rect.fromLTWH(dx0, top, dcolW * days, ph);
    canvas.drawRect(mRect, Paint()..color = Colors.white);
    canvas.drawRect(dRect, Paint()..color = Colors.white);

    // Weekend shading
    final wkPaint = Paint()..color = const Color(0xFFF1F5F9);
    for (var i = 0; i < days && i < weekend.length; i++) {
      if (weekend[i]) {
        canvas.drawRect(Rect.fromLTWH(dx0 + dcolW * i, top, dcolW, ph), wkPaint);
      }
    }

    final borderPaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(mRect, borderPaint);
    canvas.drawRect(dRect, borderPaint);

    // Ticks
    final gridPaint = Paint()..color = const Color(0xFFE5E7EB)..strokeWidth = 1;
    for (var t = ymin; t <= ymax + step / 1000.0; t += step) {
      final yy = yOf(t);
      canvas.drawLine(Offset(labelW, yy), Offset(size.width, yy), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: DisplayFyMath.fmtNum(double.parse(t.toStringAsFixed(6))),
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF374151)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(labelW - 6 - tp.width, yy - tp.height / 2));
    }

    // Y-axis rotated label
    final yTp = TextPainter(
      text: TextSpan(
        text: yLabel,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF374151)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(14, top + ph / 2);
    canvas.rotate(-math.pi / 2);
    yTp.paint(canvas, Offset(-yTp.width / 2, -yTp.height / 2));
    canvas.restore();

    if (isBar) {
      final bPaint = Paint()..color = barColor.withValues(alpha: 0.92);
      for (var i = 0; i < 3 && i < monthVals.length; i++) {
        final v = monthVals[i];
        if (v != null) {
          final cx = labelW + mcolW * (i + 0.5);
          final bw = mcolW * 0.6;
          final yy = yOf(v);
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(cx - bw / 2, yy, bw, math.max(1, base - yy)), const Radius.circular(1.5)),
            bPaint,
          );
        }
      }
      for (var i = 0; i < days && i < dayVals.length; i++) {
        final v = dayVals[i];
        if (v != null) {
          final cx = dx0 + dcolW * (i + 0.5);
          final bw = dcolW * 0.64;
          final yy = yOf(v);
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(cx - bw / 2, yy, bw, math.max(1, base - yy)), const Radius.circular(1.5)),
            bPaint,
          );
        }
      }
    } else {
      // Dashed polyline + square markers
      void drawDashedSeries(List<Offset?> pts) {
        Offset? prev;
        for (final p in pts) {
          if (p != null && prev != null) {
            drawDashedLine(canvas, prev, p, const Color(0xFF111827), 2.0, 6, 3);
          }
          prev = p;
        }
      }

      final mPts = List<Offset?>.generate(
        3,
        (i) => i < monthVals.length && monthVals[i] != null
            ? Offset(labelW + mcolW * (i + 0.5), yOf(monthVals[i]!))
            : null,
      );
      final dPts = List<Offset?>.generate(
        days,
        (i) => i < dayVals.length && dayVals[i] != null
            ? Offset(dx0 + dcolW * (i + 0.5), yOf(dayVals[i]!))
            : null,
      );
      drawDashedSeries(mPts);
      drawDashedSeries(dPts);

      void drawSquareMarker(Offset p, double v, double tgt) {
        final ng = tgt > 0 && (lowerIsBetter ? v > tgt : v < tgt);
        final r = Rect.fromCenter(center: p, width: 7, height: 7);
        canvas.drawRect(r, Paint()..color = Colors.white);
        canvas.drawRect(
          r,
          Paint()
            ..color = ng ? const Color(0xFFEF4444) : const Color(0xFF111827)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }

      for (var i = 0; i < 3; i++) {
        if (mPts[i] != null && monthVals[i] != null) {
          drawSquareMarker(mPts[i]!, monthVals[i]!, i < targets.length ? targets[i] : target);
        }
      }
      for (var i = 0; i < days; i++) {
        if (dPts[i] != null && dayVals[i] != null) {
          drawSquareMarker(dPts[i]!, dayVals[i]!, target);
        }
      }
    }

    // Stepped / horizontal red dashed target line
    if (target > 0 || targets.any((t) => t > 0)) {
      for (var i = 0; i < 2 && i < targets.length; i++) {
        if (targets[i] > 0) {
          _drawDashedHLine(
            canvas,
            labelW + mcolW * i,
            labelW + mcolW * (i + 1),
            yOf(targets[i]),
            const Color(0xFFDC2626),
            2.5,
            10,
            6,
          );
        }
      }
      if (target > 0) {
        final ty = yOf(target);
        _drawDashedHLine(canvas, labelW + mcolW * 2, size.width, ty, const Color(0xFFDC2626), 2.5, 10, 6);
        final tp = TextPainter(
          text: TextSpan(
            text: 'TARGET ${DisplayFyMath.fmtNum(target)}$targetSuffix',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFFDC2626),
              backgroundColor: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(size.width - 6 - tp.width, (ty - tp.height - 3).clamp(0.0, base - tp.height)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Sub3MonthDailyPainter oldDelegate) => true;
}

class SubGridRowSpec {
  const SubGridRowSpec({
    required this.label,
    required this.monthCells,
    required this.dayCells,
    this.monthColors,
    this.dayColors,
    this.rowBg,
  });

  final String label;
  final List<String> monthCells; // 3
  final List<String> dayCells; // 31
  final List<Color?>? monthColors;
  final List<Color?>? dayColors;
  final Color? rowBg;
}

class Sub3MonthDailyGrid extends StatelessWidget {
  const Sub3MonthDailyGrid({
    super.key,
    required this.ym,
    required this.monthLabels,
    required this.weekend,
    required this.rows,
    required this.monthEva,
    required this.dayEva,
    this.monthHeaderLabel = 'DATA 3 MONTH',
    this.dailyHeaderSuffix = '',
    this.cellHeight = 20,
  });

  final String ym;
  final List<String> monthLabels; // 3
  final List<bool> weekend; // 31
  final List<SubGridRowSpec> rows;
  final List<bool?> monthEva; // 3
  final List<bool?> dayEva; // 31
  final String monthHeaderLabel;
  final String dailyHeaderSuffix;
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    final dim = DisplayFyMath.daysInMonth(ym);
    const borderSide = BorderSide(color: Color(0xFF94A3B8), width: 0.8);

    Widget box({
      required Widget child,
      double? width,
      double? height,
      Color? bg,
      Alignment alignment = Alignment.center,
      EdgeInsetsGeometry padding = EdgeInsets.zero,
    }) {
      return Container(
        width: width,
        height: height,
        padding: padding,
        alignment: alignment,
        decoration: BoxDecoration(
          color: bg ?? Colors.white,
          border: const Border(right: borderSide, bottom: borderSide),
        ),
        child: child,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: borderSide, left: borderSide),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group banner row
          SizedBox(
            height: 16,
            child: Row(
              children: [
                box(width: 70, height: 16, bg: const Color(0xFFF1F5F9), child: const SizedBox.shrink()),
                box(
                  width: 156,
                  height: 16,
                  bg: const Color(0xFF3F3B3B),
                  child: Text(
                    monthHeaderLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: box(
                    height: 16,
                    bg: const Color(0xFFF1F5F9),
                    child: Text(
                      'DATA HARIAN · ${DisplayFyMath.labelOfYm(ym).toUpperCase()}$dailyHeaderSuffix',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Date row
          SizedBox(
            height: cellHeight,
            child: Row(
              children: [
                box(
                  width: 70,
                  height: cellHeight,
                  bg: const Color(0xFFF1F5F9),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: const Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ),
                for (var i = 0; i < 3; i++)
                  box(
                    width: 52,
                    height: cellHeight,
                    bg: i == 2 ? const Color(0xFFFEF08A) : const Color(0xFFF1F5F9),
                    child: Text(
                      i < monthLabels.length ? monthLabels[i] : '',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ),
                for (var i = 0; i < 31; i++)
                  Expanded(
                    child: box(
                      height: cellHeight,
                      bg: i >= dim ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                      child: Text(
                        i >= dim ? '' : '${i + 1}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: (i < weekend.length && weekend[i]) ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Metric rows
          for (final r in rows)
            SizedBox(
              height: cellHeight,
              child: Row(
                children: [
                  box(
                    width: 70,
                    height: cellHeight,
                    bg: const Color(0xFFF1F5F9),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      r.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ),
                  for (var i = 0; i < 3; i++)
                    box(
                      width: 52,
                      height: cellHeight,
                      bg: r.rowBg ?? Colors.white,
                      child: Text(
                        i < r.monthCells.length ? r.monthCells[i] : '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: r.monthColors?[i] != null ? FontWeight.w800 : FontWeight.w500,
                          color: r.monthColors?[i] ?? const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  for (var i = 0; i < 31; i++)
                    Expanded(
                      child: box(
                        height: cellHeight,
                        bg: i >= dim
                            ? const Color(0xFFE2E8F0)
                            : (r.rowBg ?? ((i < weekend.length && weekend[i]) ? const Color(0xFFF1F5F9) : Colors.white)),
                        child: Text(
                          i >= dim || i >= r.dayCells.length ? '' : r.dayCells[i],
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: r.dayColors?[i] != null ? FontWeight.w800 : FontWeight.w500,
                            color: r.dayColors?[i] ?? const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // EVA Row
          SizedBox(
            height: cellHeight + 4,
            child: Row(
              children: [
                box(
                  width: 70,
                  height: cellHeight + 4,
                  bg: const Color(0xFFFEF3C7),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: const Text('EVA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ),
                for (var i = 0; i < 3; i++)
                  box(
                    width: 52,
                    height: cellHeight + 4,
                    bg: const Color(0xFFFEF3C7),
                    child: EvaMarkWidget(ok: i < monthEva.length ? monthEva[i] : null, size: 16),
                  ),
                for (var i = 0; i < 31; i++)
                  Expanded(
                    child: box(
                      height: cellHeight + 4,
                      bg: i >= dim ? const Color(0xFFE2E8F0) : const Color(0xFFFEF3C7),
                      child: i >= dim
                          ? const SizedBox.shrink()
                          : EvaMarkWidget(ok: i < dayEva.length ? dayEva[i] : null, size: 15),
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

// =============================================================================
// 5. KAIZEN REPORT SINGLE-PAGE BEFORE | AFTER SHEET — 1:1 `kaizen-report.tsx` & `safety-kaizen.tsx`
// =============================================================================

class KaizenSheetEntry {
  const KaizenSheetEntry({
    required this.id,
    required this.theme,
    required this.pic,
    required this.line,
    required this.process,
    required this.bulanLabel,
    required this.beforePhoto,
    required this.beforeCaption,
    required this.beforeSub,
    required this.beforeBoxLabel,
    required this.beforeBoxSub,
    required this.beforeBoxValue,
    required this.afterPhoto,
    required this.afterCaption,
    required this.afterSub,
    required this.afterBoxLabel,
    required this.afterBoxSub,
    required this.afterBoxValue,
    required this.result,
  });

  final String id;
  final String theme;
  final String pic;
  final String line;
  final String process;
  final String bulanLabel;
  final String beforePhoto;
  final String beforeCaption;
  final String beforeSub;
  final String beforeBoxLabel;
  final String beforeBoxSub;
  final String beforeBoxValue;
  final String afterPhoto;
  final String afterCaption;
  final String afterSub;
  final String afterBoxLabel;
  final String afterBoxSub;
  final String afterBoxValue;
  final String result;
}

class KaizenReportSheetWidget extends StatelessWidget {
  const KaizenReportSheetWidget({
    super.key,
    required this.chip,
    required this.pillarName,
    required this.entries,
    required this.page,
    required this.onPageChanged,
    required this.emptyTitle,
    required this.emptyHint,
    this.badgePrefix = 'Kaizen',
  });

  final String chip; // S, Q, P, C, HR, E
  final String pillarName;
  final List<KaizenSheetEntry> entries;
  final int page;
  final ValueChanged<int> onPageChanged;
  final String emptyTitle;
  final String emptyHint;
  final String badgePrefix;

  static const List<String> _cats = ['S', 'Q', 'P', 'C', 'HR', 'E'];

  @override
  Widget build(BuildContext context) {
    final pages = math.max(1, entries.length);
    final cur = page.clamp(1, pages);
    final f = entries.isNotEmpty ? entries[cur - 1] : null;
    final tag = formatKaizenTag(f?.id, chip);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Metadata + Category Circles + Pager
            Row(
              children: [
                if (tag.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Text(tag, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
                  ),
                _metaPair('NAMA:', f?.pic.isNotEmpty == true ? f!.pic : 'GL BOARD'),
                const SizedBox(width: 24),
                _metaPair('LINE:', f?.line.isNotEmpty == true ? f!.line : '-'),
                const SizedBox(width: 24),
                _metaPair('PROSES:', f?.process.isNotEmpty == true ? f!.process : '-'),
                const SizedBox(width: 24),
                _metaPair('BULAN:', f?.bulanLabel ?? '-'),
                const Spacer(),
                const Text('KATEGORI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                const SizedBox(width: 6),
                for (final k in _cats)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    height: 26,
                    constraints: const BoxConstraints(minWidth: 26),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isActiveCat(k) ? const Color(0xFF16A34A) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: _isActiveCat(k) ? null : Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      k,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isActiveCat(k) ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 8), color: const Color(0xFFCBD5E1)),
                buildPaperChip(badgePrefix, '${entries.length}', const Color(0xFFD1FAE5), const Color(0xFF047857)),
                const SizedBox(width: 8),
                PaperPager(page: cur, pages: pages, onPageChanged: onPageChanged),
              ],
            ),
            const SizedBox(height: 10),

            // THEMA Box
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF334155), width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'THEMA : ${f != null && f.theme.trim().isNotEmpty ? f.theme.toUpperCase() : '-'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.15, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 14),

            // BEFORE | AFTER Panels
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _KaizenSidePanel(
                      label: 'BEFORE',
                      photo: f?.beforePhoto,
                      caption: f?.beforeCaption ?? '',
                      sub: f?.beforeSub ?? '',
                      boxLabel: f?.beforeBoxLabel ?? 'INDIKATOR',
                      boxSub: f?.beforeBoxSub ?? '',
                      boxValue: f?.beforeBoxValue ?? '-',
                      isBefore: true,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _KaizenSidePanel(
                      label: 'AFTER',
                      photo: f?.afterPhoto,
                      caption: f?.afterCaption ?? '',
                      sub: f?.afterSub ?? '',
                      boxLabel: f?.afterBoxLabel ?? 'INDIKATOR',
                      boxSub: f?.afterBoxSub ?? '',
                      boxValue: f?.afterBoxValue ?? '-',
                      isBefore: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // RESULT Box
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF334155), width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  children: [
                    const TextSpan(text: 'RESULT', style: TextStyle(decoration: TextDecoration.underline)),
                    TextSpan(text: ' : ${f != null && f.result.trim().isNotEmpty ? f.result : '-'}'),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        if (entries.isEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.92),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emptyTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                  if (emptyHint.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(emptyHint, style: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool _isActiveCat(String k) {
    if (k == chip) return true;
    if (k == 'HR' && (chip == 'HR' || chip == 'H' || chip == 'M')) return true;
    if (k == 'E' && (chip == 'E' || chip == 'ENV')) return true;
    return false;
  }

  Widget _metaPair(String label, String value) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _KaizenSidePanel extends StatelessWidget {
  const _KaizenSidePanel({
    required this.label,
    required this.photo,
    required this.caption,
    required this.sub,
    required this.boxLabel,
    required this.boxSub,
    required this.boxValue,
    required this.isBefore,
  });

  final String label;
  final String? photo;
  final String caption;
  final String sub;
  final String boxLabel;
  final String boxSub;
  final String boxValue;
  final bool isBefore;

  @override
  Widget build(BuildContext context) {
    final boxBorder = isBefore ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7);
    final boxBg = isBefore ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    final boxFg = isBefore ? const Color(0xFFB91C1C) : const Color(0xFF047857);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF334155), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: buildPaperPhotoBox(photo, placeholder: 'FOTO')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          caption.isEmpty ? '-' : caption,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.2, color: Color(0xFF0F172A)),
                        ),
                        if (sub.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 190,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: boxBg,
                      border: Border.all(color: boxBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                boxLabel.isEmpty ? 'INDIKATOR' : boxLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: boxFg),
                              ),
                              if (boxSub.isNotEmpty)
                                Text(
                                  boxSub,
                                  style: TextStyle(fontSize: 10.5, color: boxFg.withValues(alpha: 0.8)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          boxValue.isEmpty ? '-' : boxValue,
                          style: TextStyle(
                            fontSize: boxValue.length > 6 ? 20 : 32,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            color: boxFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF334155), width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
