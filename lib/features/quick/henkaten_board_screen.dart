import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';

class _HenkatenEntry {
  _HenkatenEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.detail,
    required this.shift,
    required this.pic,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String category; // MAN | MACHINE | MATERIAL | METHOD
  final String title;
  final String detail;
  final String shift;
  final String pic;
  String status; // OPEN | MONITOR | CLOSED
  final String createdAt;

  factory _HenkatenEntry.fromJson(Map<String, dynamic> j) => _HenkatenEntry(
        id: (j['id'] ?? '').toString(),
        category: (j['category'] ?? 'MAN').toString(),
        title: (j['title'] ?? '').toString(),
        detail: (j['detail'] ?? '').toString(),
        shift: (j['shift'] ?? 'WHITE').toString(),
        pic: (j['pic'] ?? '').toString(),
        status: (j['status'] ?? 'OPEN').toString(),
        createdAt: (j['createdAt'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'detail': detail,
        'shift': shift,
        'pic': pic,
        'status': status,
        'createdAt': createdAt,
      };
}

class HenkatenBoardScreen extends StatefulWidget {
  const HenkatenBoardScreen({super.key});

  @override
  State<HenkatenBoardScreen> createState() => _HenkatenBoardScreenState();
}

class _HenkatenBoardScreenState extends State<HenkatenBoardScreen> {
  static const String _kStoreKey = 'ubf_henkaten_4m_v1';
  static const String _toyotaHenkatenUrl =
      'http://mfg-connectivity.toyota.co.id/web#/henkaten-dashboard';

  List<_HenkatenEntry> _entries = [];
  String _filterCat = 'ALL';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStoreKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _entries = list
            .whereType<Map>()
            .map((e) => _HenkatenEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kStoreKey,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'MAN':
        return UbColors.cyan;
      case 'MACHINE':
        return UbColors.amber;
      case 'MATERIAL':
        return UbColors.emerald;
      case 'METHOD':
        return UbColors.purple;
      default:
        return UbColors.textMuted;
    }
  }

  void _copyPortalUrl() {
    Clipboard.setData(const ClipboardData(text: _toyotaHenkatenUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL Toyota Henkaten Dashboard disalin ke clipboard'),
        backgroundColor: UbColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openAddModal() async {
    final titleCtrl = TextEditingController();
    final detailCtrl = TextEditingController();
    final picCtrl = TextEditingController(
      text: AuthService.instance.currentUser?.name ?? '',
    );
    var cat = _filterCat == 'ALL' ? 'MAN' : _filterCat;
    var shift = AuthService.instance.currentUser?.shift == 'RED' ? 'RED' : 'WHITE';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            16,
            18,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tambah Catatan Henkaten 4M',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['MAN', 'MACHINE', 'MATERIAL', 'METHOD'].map((c) {
                    final active = cat == c;
                    return ChoiceChip(
                      label: Text(c),
                      selected: active,
                      selectedColor: _catColor(c).withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: active ? _catColor(c) : UbColors.textMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                      onSelected: (_) => setModalState(() => cat = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Judul Perubahan 4M',
                    hintText: 'Contoh: Operator MP Pengganti Pos 3',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: detailCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Detail & Tindakan Pengamanan',
                    hintText: 'Contoh: Coaching 5 menit + verifikasi 5 unit awal',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: picCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'PIC'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'RED', label: Text('RED')),
                        ButtonSegment(value: 'WHITE', label: Text('WHITE')),
                      ],
                      selected: {shift},
                      onSelectionChanged: (s) =>
                          setModalState(() => shift = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: UbColors.amber,
                    foregroundColor: UbColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text(
                    'Simpan Henkaten 4M',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true && titleCtrl.text.trim().isNotEmpty) {
      final now = DateTime.now().toUtc().add(const Duration(hours: 7));
      final stamp =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      setState(() {
        _entries.insert(
          0,
          _HenkatenEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            category: cat,
            title: titleCtrl.text.trim(),
            detail: detailCtrl.text.trim(),
            shift: shift,
            pic: picCtrl.text.trim().isEmpty ? 'Leader' : picCtrl.text.trim(),
            status: 'OPEN',
            createdAt: stamp,
          ),
        );
      });
      await _save();
    }
    titleCtrl.dispose();
    detailCtrl.dispose();
    picCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filterCat == 'ALL'
        ? _entries
        : _entries.where((e) => e.category == _filterCat).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.bg,
        title: const Text(
          'Henkaten Board 4M',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _copyPortalUrl,
            icon: const Icon(Icons.link_rounded, color: UbColors.cyan),
            tooltip: 'Salin URL Toyota Mfg Henkaten',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.amber,
        foregroundColor: UbColors.bg,
        onPressed: _openAddModal,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat 4M', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
              children: [
                // Portal Toyota Mfg Connectivity Card (1:1 Next.js Henkaten Shortcut)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        UbColors.amber.withValues(alpha: 0.16),
                        UbColors.surface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: UbColors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: UbColors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, color: UbColors.amber, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toyota Mfg Connectivity',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'mfg-connectivity.toyota.co.id/web#/henkaten-dashboard',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: UbColors.textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _copyPortalUrl,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: UbColors.amber,
                          side: BorderSide(color: UbColors.amber.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text('Salin', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // 4M Summary Strip
                Row(
                  children: ['MAN', 'MACHINE', 'MATERIAL', 'METHOD'].map((c) {
                    final cnt = _entries
                        .where((e) => e.category == c && e.status != 'CLOSED')
                        .length;
                    final col = _catColor(c);
                    final active = _filterCat == c;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                          () => _filterCat = active ? 'ALL' : c,
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          decoration: BoxDecoration(
                            color: active ? col.withValues(alpha: 0.2) : UbColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active ? col : UbColors.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$cnt',
                                style: TextStyle(
                                  color: col,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                if (shown.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: UbColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: UbColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.verified_rounded, color: UbColors.emerald, size: 36),
                        SizedBox(height: 8),
                        Text(
                          'Tidak ada perubahan 4M aktif',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap "Catat 4M" bila ada pergantian MP, mesin, material, atau metode.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: UbColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  ...shown.map((item) {
                    final col = _catColor(item.category);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: UbColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: col.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: col.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    color: col,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${item.shift} • ${item.createdAt}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: UbColors.textMuted,
                                  fontSize: 10.5,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () async {
                                  setState(() {
                                    item.status = item.status == 'OPEN'
                                        ? 'MONITOR'
                                        : (item.status == 'MONITOR' ? 'CLOSED' : 'OPEN');
                                  });
                                  await _save();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: item.status == 'CLOSED'
                                        ? UbColors.emerald.withValues(alpha: 0.2)
                                        : UbColors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      color: item.status == 'CLOSED'
                                          ? UbColors.emerald
                                          : UbColors.amber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  setState(() => _entries.removeWhere((e) => e.id == item.id));
                                  await _save();
                                },
                                icon: const Icon(Icons.delete_outline, size: 17, color: UbColors.textMuted),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          if (item.detail.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.detail,
                              style: const TextStyle(
                                color: UbColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'PIC: ${item.pic}',
                            style: const TextStyle(
                              color: UbColors.cyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
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
