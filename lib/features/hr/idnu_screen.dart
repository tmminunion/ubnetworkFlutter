import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/cost_env_models.dart';
import '../../models/hr_morale_models.dart';
import '../../services/hr_morale_store.dart';

class IdnuScreen extends StatefulWidget {
  const IdnuScreen({super.key});

  @override
  State<IdnuScreen> createState() => _IdnuScreenState();
}

class _IdnuScreenState extends State<IdnuScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<IdnuIdeaItem> _items = const [];
  String _areaFilter = 'ALL';
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await HrMoraleStore.instance.loadIdnuItems();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _openSubmitModal(IdnuIdeaItem item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final beforeCtrl = TextEditingController(text: item.beforeText);
    final afterCtrl = TextEditingController(text: item.afterText);
    var isDraft = item.isDraft;

    try {
      final ok = await showModalBottomSheet<bool>(
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
                  Text('Kirim Ide ke Portal Innovation (${item.uid})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  TextField(controller: titleCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Judul Ide', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: beforeCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Kondisi Sebelum (Before)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: afterCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Kondisi Sesudah (After)', border: OutlineInputBorder(), isDense: true)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isDraft,
                    title: const Text('Simpan sebagai DRAFT terlebih dulu', style: TextStyle(fontSize: 13)),
                    onChanged: (v) => setM(() => isDraft = v),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.cyan, foregroundColor: UbColors.bg),
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.send_rounded, size: 17),
                    label: Text(isDraft ? 'Simpan Draft Ide' : 'Submit ke Approve LH', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (ok == true) {
        final txId = item.transactionId.isNotEmpty
            ? item.transactionId
            : '${isDraft ? 'DF' : 'ID'}${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        final next = _items
            .map(
              (e) => e.uid == item.uid
                  ? e.copyWith(
                      title: titleCtrl.text.trim(),
                      beforeText: beforeCtrl.text.trim(),
                      afterText: afterCtrl.text.trim(),
                      status: 'sudah',
                      portalStatus: isDraft ? 'Draft' : 'Menunggu LH',
                      transactionId: txId,
                      isDraft: isDraft,
                    )
                  : e,
            )
            .toList();
        await HrMoraleStore.instance.saveIdnuItems(next);
        if (mounted) {
          setState(() => _items = next);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ide tersimpan sebagai ${isDraft ? 'DRAFT' : 'SUBMIT'} ($txId)!')),
          );
        }
      }
    } finally {
      titleCtrl.dispose();
      beforeCtrl.dispose();
      afterCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final outstanding = _items.where((e) => e.status == 'sudah' && e.portalStatus != 'Paid').toList();
    final paid = _items.where((e) => e.portalStatus == 'Paid').toList();
    final totalReward = paid.fold<int>(0, (acc, e) => acc + e.reward);

    final filteredKaizen = _items.where((e) {
      if (_areaFilter != 'ALL' && e.area != _areaFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return e.title.toLowerCase().contains(q) || e.pic.toLowerCase().contains(q) || e.uid.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Idea · Innovation Portal', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('Kaizen SQPCHR → Approve LH & Paid', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: UbColors.cyan,
          labelColor: UbColors.cyan,
          unselectedLabelColor: UbColors.textMuted,
          tabs: [
            Tab(text: 'Kaizen (${_items.length})'),
            Tab(text: 'Approve LH (${outstanding.length})'),
            Tab(text: 'Paid (${paid.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // TAB 1: KAIZEN SQPCHR -> IDE
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final a in ['ALL', 'S', 'Q', 'P', 'C', 'H', 'E'])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(a, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                selected: _areaFilter == a,
                                onSelected: (_) => setState(() => _areaFilter = a),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => setState(() => _search = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Cari judul Kaizen, PIC, ID...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 17),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...filteredKaizen.map((it) {
                      final sent = it.status == 'sudah';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Chip(label: Text(it.area, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)), visualDensity: VisualDensity.compact),
                                  const SizedBox(width: 6),
                                  Text(it.uid, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted)),
                                  const Spacer(),
                                  Text(
                                    sent ? '${it.transactionId} · ${it.portalStatus}' : 'Belum Dikirim',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: sent ? UbColors.emerald : UbColors.amber),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(it.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                              const SizedBox(height: 4),
                              Text('Before: ${it.beforeText}', style: const TextStyle(fontSize: 11.5, color: UbColors.rose)),
                              Text('After: ${it.afterText}', style: const TextStyle(fontSize: 11.5, color: UbColors.emerald)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('PIC: ${it.pic} · ${it.process}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                                  const Spacer(),
                                  FilledButton.tonal(
                                    onPressed: () => _openSubmitModal(it),
                                    child: Text(sent ? 'Update Ide' : 'Proses Ide', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                // TAB 2: OUTSTANDING (APPROVE LH / DRAFT)
                outstanding.isEmpty
                    ? const Center(child: Text('Belum ada ide outstanding.', style: TextStyle(color: UbColors.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: outstanding.length,
                        itemBuilder: (_, idx) {
                          final it = outstanding[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(it.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              subtitle: Text('${it.transactionId} · ${it.date} · PIC ${it.pic}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                              trailing: Chip(label: Text(it.portalStatus, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
                            ),
                          );
                        },
                      ),

                // TAB 3: REKAP PAID
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: UbColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: UbColors.emerald.withValues(alpha: 0.4))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Reward Dibayar (Paid)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(formatRupiah(totalReward), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 16, color: UbColors.emerald)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...paid.map(
                      (it) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(it.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          subtitle: Text('${it.transactionId} · ${it.pic}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                          trailing: Text(formatRupiah(it.reward), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: UbColors.emerald)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
