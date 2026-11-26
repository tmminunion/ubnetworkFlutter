import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/display_monitor_models.dart';
import '../../services/local_store.dart';
import '../../services/productivity_ops_store.dart';
import '../../services/safety_findings_store.dart';

class MonitorTvScreen extends StatefulWidget {
  const MonitorTvScreen({super.key, this.initialDeckId = 'main'});

  final String initialDeckId;

  @override
  State<MonitorTvScreen> createState() => _MonitorTvScreenState();
}

class _MonitorTvScreenState extends State<MonitorTvScreen> {
  List<MonitorDeckModel> _decks = const [];
  String _deckId = 'main';
  int _slideIdx = 0;
  bool _paused = false;
  bool _fullscreen = false;
  bool _loading = true;
  String _clock = '--:--:--';
  Timer? _clockTimer;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _deckId = widget.initialDeckId;
    _tickClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());
    _load();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _tickClock() {
    final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final s = '${wib.hour.toString().padLeft(2, '0')}:${wib.minute.toString().padLeft(2, '0')}:${wib.second.toString().padLeft(2, '0')}';
    if (mounted) setState(() => _clock = s);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cfg = await LocalStore.instance.getSettings();
    final reps = await LocalStore.instance.listReports();
    final sf = await SafetyFindingsStore.instance.listFindings();
    final kz = await ProductivityOpsStore.instance.loadKaizenItems();
    final decks = DisplayMonitorCatalog.buildDecks(
      localChecksheets: reps.length,
      openSafetyFindings: sf.where((f) => f.status.toLowerCase() != 'closed').length,
      totalKaizen: kz.length,
      lineName: cfg.lineName,
    );
    if (!mounted) return;
    setState(() {
      _decks = decks;
      if (!_decks.any((d) => d.id == _deckId)) _deckId = decks.first.id;
      _slideIdx = 0;
      _loading = false;
    });
    _scheduleAutoPlay();
  }

  MonitorDeckModel? get _activeDeck {
    if (_decks.isEmpty) return null;
    return _decks.firstWhere((d) => d.id == _deckId, orElse: () => _decks.first);
  }

  void _scheduleAutoPlay() {
    _autoPlayTimer?.cancel();
    final deck = _activeDeck;
    if (_paused || deck == null || deck.slides.length < 2) return;
    final dur = deck.slides[_slideIdx % deck.slides.length].durationSec;
    _autoPlayTimer = Timer(Duration(seconds: dur), () {
      if (!mounted) return;
      _go(1);
    });
  }

  void _go(int delta) {
    final deck = _activeDeck;
    if (deck == null || deck.slides.isEmpty) return;
    setState(() {
      _slideIdx = (_slideIdx + delta + deck.slides.length) % deck.slides.length;
    });
    _scheduleAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final deck = _activeDeck;
    final slide = (deck != null && deck.slides.isNotEmpty) ? deck.slides[_slideIdx % deck.slides.length] : null;
    final accent = slide != null ? Color(slide.accentHex) : UbColors.cyan;

    return Scaffold(
      backgroundColor: _fullscreen ? Colors.black : UbColors.bg,
      appBar: _fullscreen
          ? null
          : AppBar(
              backgroundColor: UbColors.surface,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck?.title ?? 'UNDERBODY MONITOR', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                  Text('${slide?.name ?? 'Slide Show TV'} · $_clock WIB', style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: UbColors.textMuted)),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() => _paused = !_paused);
                    _scheduleAutoPlay();
                  },
                  icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: _paused ? UbColors.amber : UbColors.cyan),
                  tooltip: _paused ? 'Putar Otomatis' : 'Jeda',
                ),
                IconButton(
                  onPressed: () => setState(() => _fullscreen = true),
                  icon: const Icon(Icons.fullscreen_rounded),
                  tooltip: 'Layar Penuh',
                ),
              ],
            ),
      body: _loading || deck == null || slide == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (!_fullscreen)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _decks.map((d) {
                                final sel = d.id == _deckId;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(d.shortLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                                    selected: sel,
                                    onSelected: (_) {
                                      setState(() {
                                        _deckId = d.id;
                                        _slideIdx = 0;
                                      });
                                      _scheduleAutoPlay();
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                      // MAIN TV SLIDE CANVAS
                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if ((details.primaryVelocity ?? 0) < -200) _go(1);
                            if ((details.primaryVelocity ?? 0) > 200) _go(-1);
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: Container(
                              key: ValueKey('${deck.id}_${slide.id}'),
                              margin: EdgeInsets.all(_fullscreen ? 10 : 12),
                              padding: const EdgeInsets.all(20),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [accent.withValues(alpha: 0.22), UbColors.surface, const Color(0xFF070B14)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(color: accent.withValues(alpha: 0.6)),
                                          ),
                                          child: Text(slide.badge, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: accent)),
                                        ),
                                        const Spacer(),
                                        Text('$_clock WIB', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w800, color: UbColors.textMuted)),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(slide.headline, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
                                    const SizedBox(height: 6),
                                    Text(slide.subheadline, style: const TextStyle(fontSize: 13, color: UbColors.textMuted)),
                                    const SizedBox(height: 18),

                                    // METRIC TILES
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: slide.metrics
                                          .map(
                                            (m) => Container(
                                              width: 152,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: UbColors.bg.withValues(alpha: 0.78),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: accent.withValues(alpha: 0.4)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(m.label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: UbColors.textMuted)),
                                                  const SizedBox(height: 3),
                                                  Text(m.value, style: TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w900, color: accent)),
                                                  Text(m.unit, style: const TextStyle(fontSize: 10, color: UbColors.textMuted)),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    const SizedBox(height: 18),

                                    // BULLET HIGHLIGHTS
                                    ...slide.bullets.map(
                                      (b) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.check_circle_rounded, size: 16, color: accent),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(b, style: const TextStyle(fontSize: 13, height: 1.35))),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // SLIDE DOCK & CONTROLS
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(onPressed: () => _go(-1), icon: const Icon(Icons.chevron_left_rounded)),
                            for (var i = 0; i < deck.slides.length; i++)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _slideIdx ? 22 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _slideIdx ? accent : Colors.white24,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            IconButton(onPressed: () => _go(1), icon: const Icon(Icons.chevron_right_rounded)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_fullscreen)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        onPressed: () => setState(() => _fullscreen = false),
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
