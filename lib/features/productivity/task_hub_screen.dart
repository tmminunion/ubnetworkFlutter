import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/productivity_ops_models.dart';
import '../../services/productivity_ops_store.dart';

class TaskHubScreen extends StatefulWidget {
  const TaskHubScreen({super.key});

  @override
  State<TaskHubScreen> createState() => _TaskHubScreenState();
}

class _TaskHubScreenState extends State<TaskHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<TaskHubItem> _tasks = const [];
  bool _loading = true;
  String _shiftFilter = 'ALL'; // ALL | RED | WHITE
  String _search = '';

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
    final list = await ProductivityOpsStore.instance.loadTasks();
    if (!mounted) return;
    setState(() {
      _tasks = list;
      _loading = false;
    });
  }

  List<TaskHubItem> get _filtered {
    return _tasks.where((t) {
      if (_shiftFilter != 'ALL' && t.shift != _shiftFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return t.title.toLowerCase().contains(q) ||
            t.assignee.toLowerCase().contains(q) ||
            t.moduleName.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'Urgent':
        return UbColors.rose;
      case 'High':
        return UbColors.amber;
      case 'Low':
        return UbColors.emerald;
      default:
        return UbColors.cyan;
    }
  }

  Future<void> _updateStatus(TaskHubItem task, String newStatus) async {
    final next = _tasks.map((t) => t.id == task.id ? t.copyWith(status: newStatus) : t).toList();
    await ProductivityOpsStore.instance.saveTasks(next);
    if (!mounted) return;
    setState(() => _tasks = next);
    await ProductivityOpsStore.instance.syncUpdateTaskStatus(task.id, newStatus);
  }

  Future<void> _deleteTask(TaskHubItem task) async {
    final next = _tasks.where((t) => t.id != task.id).toList();
    await ProductivityOpsStore.instance.saveTasks(next);
    if (!mounted) return;
    setState(() => _tasks = next);
  }

  Future<void> _openTaskForm([TaskHubItem? existing]) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final modCtrl = TextEditingController(text: existing?.moduleName ?? 'Productivity');
    final picCtrl = TextEditingController(text: existing?.assignee ?? '');
    final estCtrl = TextEditingController(text: '${existing?.estimasiHari ?? 1}');
    var priority = existing?.priority ?? 'High';
    var status = existing?.status ?? 'To Do';
    var shift = existing?.shift ?? (_shiftFilter == 'ALL' ? 'RED' : _shiftFilter);

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
                  Text(
                    existing == null ? 'Buat Task Post-It Baru' : 'Edit Task Post-It',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Judul Task / Pekerjaan', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: modCtrl,
                          decoration: const InputDecoration(labelText: 'Modul / Area', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: picCtrl,
                          decoration: const InputDecoration(labelText: 'Assignee (PIC)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: priority,
                          decoration: const InputDecoration(labelText: 'Prioritas', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'Urgent', child: Text('Urgent (Merah)')),
                            DropdownMenuItem(value: 'High', child: Text('High (Kuning)')),
                            DropdownMenuItem(value: 'Medium', child: Text('Medium (Biru)')),
                            DropdownMenuItem(value: 'Low', child: Text('Low (Hijau)')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => priority = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'To Do', child: Text('To Do')),
                            DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                            DropdownMenuItem(value: 'In Review', child: Text('In Review')),
                            DropdownMenuItem(value: 'Done', child: Text('Done')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => status = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: shift,
                          decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'RED', child: Text('Shift RED')),
                            DropdownMenuItem(value: 'WHITE', child: Text('Shift WHITE')),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => shift = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: estCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Estimasi (Hari)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: UbColors.amber, foregroundColor: UbColors.bg),
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Simpan Task Post-It', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (saved == true) {
        final next = List<TaskHubItem>.from(_tasks);
        final nextId = next.fold<int>(0, (acc, e) => e.id > acc ? e.id : acc) + 1;
        final item = TaskHubItem(
          id: existing?.id ?? nextId,
          title: titleCtrl.text.trim(),
          moduleName: modCtrl.text.trim().isEmpty ? 'Umum' : modCtrl.text.trim(),
          status: status,
          priority: priority,
          assignee: picCtrl.text.trim().isEmpty ? 'Tim UB Assy' : picCtrl.text.trim(),
          shift: shift,
          estimasiHari: int.tryParse(estCtrl.text.trim()) ?? 1,
        );
        if (existing != null) {
          final idx = next.indexWhere((e) => e.id == existing.id);
          if (idx >= 0) next[idx] = item;
        } else {
          next.insert(0, item);
        }
        await ProductivityOpsStore.instance.saveTasks(next);
        if (mounted) setState(() => _tasks = next);
      }
    } finally {
      titleCtrl.dispose();
      modCtrl.dispose();
      picCtrl.dispose();
      estCtrl.dispose();
    }
  }

  void _openStatusPicker(TaskHubItem task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: UbColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pindahkan Status Task', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(task.title, style: const TextStyle(fontSize: 12, color: UbColors.textMuted)),
            const SizedBox(height: 12),
            for (final st in ['To Do', 'In Progress', 'In Review', 'Done'])
              ListTile(
                dense: true,
                title: Text(st, style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: task.status == st ? const Icon(Icons.check_circle_rounded, color: UbColors.cyan) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(task, st);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final doneCount = list.where((t) => t.status == 'Done').length;
    final progCount = list.where((t) => t.status == 'In Progress').length;
    final urgentCount = list.where((t) => t.priority == 'Urgent' && t.status != 'Done').length;
    final pct = list.isEmpty ? 0 : ((doneCount / list.length) * 100).round();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Manager Post-It Hub', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
            Text('Kanban Post-It & Linimasa Gantt Otomatis', style: TextStyle(fontSize: 11, color: UbColors.textMuted)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: UbColors.amber,
          labelColor: UbColors.amber,
          unselectedLabelColor: UbColors.textMuted,
          tabs: const [
            Tab(text: 'Board Post-It'),
            Tab(text: 'Linimasa Gantt'),
            Tab(text: 'Sticky Wall'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UbColors.amber,
        foregroundColor: UbColors.bg,
        onPressed: () => _openTaskForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Task Baru', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Overview + Filter
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _TaskStat(label: 'PROGRES', value: '$pct%', color: UbColors.cyan),
                          const SizedBox(width: 6),
                          _TaskStat(label: 'IN PROG', value: '$progCount', color: UbColors.amber),
                          const SizedBox(width: 6),
                          _TaskStat(label: 'DONE', value: '$doneCount', color: UbColors.emerald),
                          const SizedBox(width: 6),
                          _TaskStat(label: 'URGENT', value: '$urgentCount', color: UbColors.rose),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final sh in ['ALL', 'RED', 'WHITE'])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(sh, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                selected: _shiftFilter == sh,
                                onSelected: (_) => setState(() => _shiftFilter = sh),
                              ),
                            ),
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _search = v.trim()),
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Cari task / PIC...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 16),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildBoardTab(list),
                      _buildTimelineTab(list),
                      _buildWallTab(list),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBoardTab(List<TaskHubItem> list) {
    const cols = ['To Do', 'In Progress', 'In Review', 'Done'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 84),
      children: cols.map((col) {
        final items = list.where((t) => t.status == col).toList();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: UbColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(col.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: UbColors.cyan)),
                  Text('${items.length}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: UbColors.textMuted)),
                ],
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('Belum ada task di kolom ini.', style: TextStyle(fontSize: 11.5, color: UbColors.textMuted)),
                )
              else
                ...items.map((t) => _postItCard(t)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineTab(List<TaskHubItem> list) {
    final sched = TaskHubEngine.buildUrgencyTimeline(list);
    if (sched.slots.isEmpty) {
      return const Center(child: Text('Belum ada task untuk linimasa.', style: TextStyle(color: UbColors.textMuted)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 84),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Estimasi Total: ${sched.totalDays} Hari Kerja (Auto Multi-Pass: Urgent → High → Medium → Low)',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: UbColors.cyan),
          ),
        ),
        ...sched.slots.map((s) {
          final color = s.task.status == 'Done'
              ? UbColors.emerald
              : (s.task.status == 'In Progress' ? UbColors.cyan : _priorityColor(s.task.priority));
          final leftFrac = (s.startOffset / sched.totalDays).clamp(0.0, 0.85);
          final widthFrac = (s.duration / sched.totalDays).clamp(0.12, 1.0 - leftFrac);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: UbColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(s.task.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                    Text(
                      'H${s.startOffset + 1}–H${s.endDay}',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${s.task.moduleName} · ${s.task.assignee} · ${s.task.status}', style: const TextStyle(fontSize: 11, color: UbColors.textMuted)),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (_, c) => Container(
                    height: 22,
                    width: double.infinity,
                    decoration: BoxDecoration(color: UbColors.bg, borderRadius: BorderRadius.circular(8)),
                    child: Stack(
                      children: [
                        Positioned(
                          left: c.maxWidth * leftFrac,
                          width: c.maxWidth * widthFrac,
                          top: 2,
                          bottom: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${s.duration}h',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: UbColors.bg),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWallTab(List<TaskHubItem> list) {
    final width = MediaQuery.of(context).size.width;
    final cols = width >= 720 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 84),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 158,
      ),
      itemCount: list.length,
      itemBuilder: (_, idx) => _postItCard(list[idx], compact: true),
    );
  }

  Widget _postItCard(TaskHubItem t, {bool compact = false}) {
    final c = _priorityColor(t.priority);
    return InkWell(
      onTap: () => _openStatusPicker(t),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    t.priority.toUpperCase(),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: UbColors.bg),
                  ),
                ),
                const SizedBox(width: 6),
                Text(t.shift, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: UbColors.textMuted)),
                const Spacer(),
                InkWell(
                  onTap: () => _openTaskForm(t),
                  child: const Icon(Icons.edit_rounded, size: 15, color: UbColors.textMuted),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _deleteTask(t),
                  child: const Icon(Icons.delete_outline_rounded, size: 15, color: UbColors.rose),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              t.title,
              maxLines: compact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.25),
            ),
            if (compact) const Spacer() else const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${t.assignee} · ${t.estimasiHari}h',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: UbColors.textMuted),
                  ),
                ),
                Text(
                  t.status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskStat extends StatelessWidget {
  const _TaskStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: UbColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: UbColors.textMuted)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}
