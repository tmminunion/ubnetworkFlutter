import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';

class _PostItNote {
  _PostItNote({
    required this.id,
    required this.task,
    required this.assignee,
    required this.priority,
    required this.status,
    required this.project,
    required this.estimasi,
  });

  final String id;
  final String task;
  final String assignee;
  final String priority; // Low | Medium | High | Urgent
  String status; // To Do | In Progress | Done
  final String project;
  final String estimasi;

  factory _PostItNote.fromJson(Map<String, dynamic> j) => _PostItNote(
        id: (j['id'] ?? '').toString(),
        task: (j['task'] ?? '').toString(),
        assignee: (j['assignee'] ?? '').toString(),
        priority: (j['priority'] ?? 'High').toString(),
        status: (j['status'] ?? 'To Do').toString(),
        project: (j['project'] ?? 'UBnetwork').toString(),
        estimasi: (j['estimasi'] ?? '2').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'task': task,
        'assignee': assignee,
        'priority': priority,
        'status': status,
        'project': project,
        'estimasi': estimasi,
      };
}

class PostitBoardScreen extends StatefulWidget {
  const PostitBoardScreen({super.key});

  @override
  State<PostitBoardScreen> createState() => _PostitBoardScreenState();
}

class _PostitBoardScreenState extends State<PostitBoardScreen> {
  static const String _kStoreKey = 'ubf_postit_board_v1';

  final _taskCtrl = TextEditingController(text: 'Pengambilan Data Cycle Time After');
  final _assigneeCtrl = TextEditingController(
    text: AuthService.instance.currentUser?.name ?? 'NUNU FATULAH',
  );
  final _projectCtrl = TextEditingController(text: 'Bungtemin Task Hub');
  final _estimasiCtrl = TextEditingController(text: '2');

  String _priority = 'High';
  String _status = 'To Do';
  List<_PostItNote> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _taskCtrl.dispose();
    _assigneeCtrl.dispose();
    _projectCtrl.dispose();
    _estimasiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStoreKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _notes = list
            .whereType<Map>()
            .map((e) => _PostItNote.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kStoreKey,
      jsonEncode(_notes.map((e) => e.toJson()).toList()),
    );
  }

  void _applyPreset(String task, String prio, String st) {
    setState(() {
      _taskCtrl.text = task;
      _priority = prio;
      _status = st;
    });
  }

  String _buildEdgeUrl() {
    final q = Uri(
      queryParameters: {
        'task': _taskCtrl.text.trim(),
        'assignee': _assigneeCtrl.text.trim(),
        'priority': _priority,
        'status': _status,
        'project': _projectCtrl.text.trim(),
        'estimasi': _estimasiCtrl.text.trim(),
      },
    ).query;
    return 'https://ubnetwork.vercel.app/api/postit?$q';
  }

  Color _prioBg(String p) {
    switch (p) {
      case 'Urgent':
        return const Color(0xFFFEE2E2);
      case 'High':
        return const Color(0xFFFEF3C7);
      case 'Medium':
        return const Color(0xFFE0F2FE);
      default:
        return const Color(0xFFD1FAE5);
    }
  }

  Color _prioAccent(String p) {
    switch (p) {
      case 'Urgent':
        return const Color(0xFFDC2626);
      case 'High':
        return const Color(0xFFD97706);
      case 'Medium':
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFF059669);
    }
  }

  Future<void> _pinNote() async {
    if (_taskCtrl.text.trim().isEmpty) return;
    setState(() {
      _notes.insert(
        0,
        _PostItNote(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          task: _taskCtrl.text.trim(),
          assignee: _assigneeCtrl.text.trim().isEmpty ? 'TIM UB' : _assigneeCtrl.text.trim(),
          priority: _priority,
          status: _status,
          project: _projectCtrl.text.trim(),
          estimasi: _estimasiCtrl.text.trim().isEmpty ? '1' : _estimasiCtrl.text.trim(),
        ),
      );
    });
    await _saveNotes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post-It ditempel ke papan shopfloor!'),
        backgroundColor: UbColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.bg,
        title: const Text(
          'Post-It Board',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _buildEdgeUrl()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link Post-It Edge API disalin'),
                  backgroundColor: UbColors.cyan,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: UbColors.amber),
            tooltip: 'Salin Link Post-It API',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
        children: [
          // Live Sticky Note Preview (1:1 Post-It Generator)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF08A),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _prioBg(_priority),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _priority.toUpperCase(),
                        style: TextStyle(
                          color: _prioAccent(_priority),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _status,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Est: ${_estimasiCtrl.text}j',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF334155),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _taskCtrl.text.isEmpty ? 'Judul Catatan...' : _taskCtrl.text,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PIC: ${_assigneeCtrl.text}',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _projectCtrl.text,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Preset Cepat
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ActionChip(
                label: const Text('⏱️ Cycle Time'),
                onPressed: () => _applyPreset(
                  'Pengambilan Data Cycle Time After',
                  'High',
                  'To Do',
                ),
              ),
              ActionChip(
                label: const Text('🚨 Urgent Bug'),
                onPressed: () => _applyPreset(
                  'Investigasi Masalah Kebocoran Oli',
                  'Urgent',
                  'In Progress',
                ),
              ),
              ActionChip(
                label: const Text('✓ Kaizen Done'),
                onPressed: () => _applyPreset(
                  'Evaluasi Kaizen Bulanan Bidang 3',
                  'Low',
                  'Done',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: UbColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: UbColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _taskCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Judul Task / Catatan'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _assigneeCtrl,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Assignee / PIC'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _estimasiCtrl,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Jam'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _priority,
                        dropdownColor: UbColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: ['Low', 'Medium', 'High', 'Urgent']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _priority = v ?? 'High'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        dropdownColor: UbColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['To Do', 'In Progress', 'Done']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _status = v ?? 'To Do'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15),
                    foregroundColor: UbColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: _pinNote,
                  icon: const Icon(Icons.push_pin_rounded, size: 18),
                  label: const Text(
                    'Tempel ke Papan Post-It',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          if (_notes.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Papan Post-It Tersimpan (${_notes.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ..._notes.map((n) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _prioBg(n.priority),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.task,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${n.assignee} • ${n.priority} • ${n.status} (${n.estimasi}j)',
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          setState(() {
                            n.status = n.status == 'To Do'
                                ? 'In Progress'
                                : (n.status == 'In Progress' ? 'Done' : 'To Do');
                          });
                          await _saveNotes();
                        },
                        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF059669)),
                      ),
                      IconButton(
                        onPressed: () async {
                          setState(() => _notes.removeWhere((e) => e.id == n.id));
                          await _saveNotes();
                        },
                        icon: const Icon(Icons.delete_outline, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
