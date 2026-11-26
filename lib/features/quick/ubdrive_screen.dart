import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';

class _DriveItem {
  _DriveItem({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    this.modified,
    this.childCount,
    this.webUrl,
  });

  final String id;
  final String name;
  final String type; // folder | file
  final int size;
  final String? modified;
  final int? childCount;
  final String? webUrl;

  factory _DriveItem.fromJson(Map<String, dynamic> j) => _DriveItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        type: (j['type'] ?? 'file').toString(),
        size: (j['size'] as num?)?.toInt() ?? 0,
        modified: j['modified']?.toString(),
        childCount: (j['childCount'] as num?)?.toInt(),
        webUrl: j['webUrl']?.toString(),
      );
}

class UbdriveScreen extends StatefulWidget {
  const UbdriveScreen({super.key});

  @override
  State<UbdriveScreen> createState() => _UbdriveScreenState();
}

class _UbdriveScreenState extends State<UbdriveScreen> {
  final List<String> _path = [];
  List<_DriveItem> _items = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _query = '';
  final _searchCtrl = TextEditingController();

  String get _pathStr => _path.join('/');

  @override
  void initState() {
    super.initState();
    _fetchList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (jsonBody) h['Content-Type'] = 'application/json';
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('ubf_gate_cookie_v1') ?? '';
    if (cookie.isNotEmpty) {
      h['Cookie'] = cookie.split(';').first;
    }
    return h;
  }

  Future<void> _fetchList() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(
        '${AuthService.gateBaseUrl}/api/drive/list?path=${Uri.encodeQueryComponent(_pathStr)}',
      );
      final res = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 14));
      final json = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && json is Map && json['success'] == true) {
        final raw = (json['items'] as List?) ?? [];
        _items = raw
            .whereType<Map>()
            .map((e) => _DriveItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _error = (json is Map ? json['error'] : null)?.toString() ?? 'Gagal memuat UBdrive (HTTP ${res.statusCode})';
      }
    } catch (_) {
      _error = 'Tidak bisa menghubungi server UBdrive (periksa koneksi internet)';
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UbColors.surface,
        title: const Text('Folder Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Nama folder...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buat')),
        ],
      ),
    );
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || name.isEmpty) return;

    setState(() => _busy = true);
    try {
      final res = await http
          .post(
            Uri.parse('${AuthService.gateBaseUrl}/api/drive/folder'),
            headers: await _headers(jsonBody: true),
            body: jsonEncode({'path': _pathStr, 'name': name}),
          )
          .timeout(const Duration(seconds: 12));
      final json = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && json is Map && json['success'] == true) {
        await _fetchList();
      } else {
        _toast((json is Map ? json['error'] : null)?.toString() ?? 'Gagal membuat folder', isErr: true);
      }
    } catch (_) {
      _toast('Gagal menghubungi server UBdrive', isErr: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteItem(_DriveItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UbColors.surface,
        title: const Text('Hapus Item?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text(
          'Hapus ${item.type == 'folder' ? 'folder' : 'file'} "${item.name}"? (Masuk Recycle Bin SharePoint)',
          style: const TextStyle(color: UbColors.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: UbColors.rose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final res = await http
          .delete(
            Uri.parse('${AuthService.gateBaseUrl}/api/drive/item?id=${Uri.encodeQueryComponent(item.id)}'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 12));
      final json = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && json is Map && json['success'] == true) {
        await _fetchList();
      } else {
        _toast((json is Map ? json['error'] : null)?.toString() ?? 'Gagal menghapus item', isErr: true);
      }
    } catch (_) {
      _toast('Gagal menghubungi server UBdrive', isErr: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg, {bool isErr = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isErr ? UbColors.rose : UbColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _fmtSize(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconFor(_DriveItem item) {
    if (item.type == 'folder') return Icons.folder_rounded;
    final n = item.name.toLowerCase();
    if (n.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (n.endsWith('.ppt') || n.endsWith('.pptx')) return Icons.slideshow_rounded;
    if (n.endsWith('.xls') || n.endsWith('.xlsx')) return Icons.table_chart_rounded;
    if (n.endsWith('.doc') || n.endsWith('.docx')) return Icons.description_rounded;
    if (n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png') || n.endsWith('.webp')) {
      return Icons.image_rounded;
    }
    if (n.endsWith('.mp4') || n.endsWith('.mov')) return Icons.movie_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _colorFor(_DriveItem item) {
    if (item.type == 'folder') return UbColors.amber;
    final n = item.name.toLowerCase();
    if (n.endsWith('.pdf')) return UbColors.rose;
    if (n.endsWith('.ppt') || n.endsWith('.pptx')) return const Color(0xFFF97316);
    if (n.endsWith('.xls') || n.endsWith('.xlsx')) return UbColors.emerald;
    if (n.endsWith('.doc') || n.endsWith('.docx')) return UbColors.cyan;
    return UbColors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final shown = _items
        .where((i) => _query.trim().isEmpty || i.name.toLowerCase().contains(_query.trim().toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.bg,
        title: const Text(
          'UBdrive (SharePoint)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _createFolder,
            icon: const Icon(Icons.create_new_folder_rounded, color: UbColors.cyan),
            tooltip: 'Folder Baru',
          ),
          IconButton(
            onPressed: _loading ? null : _fetchList,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb & Search
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.home_rounded, size: 15, color: UbColors.cyan),
                        label: const Text('03. Drive'),
                        onPressed: () {
                          _path.clear();
                          _fetchList();
                        },
                      ),
                      for (var idx = 0; idx < _path.length; idx++) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.chevron_right_rounded, size: 16, color: UbColors.textMuted),
                        ),
                        ActionChip(
                          label: Text(_path[idx]),
                          onPressed: () {
                            _path.removeRange(idx + 1, _path.length);
                            _fetchList();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Cari file atau folder di UBdrive...',
                    prefixIcon: Icon(Icons.search_rounded, size: 19),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_rounded, size: 42, color: UbColors.rose),
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _fetchList,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : shown.isEmpty
                        ? const Center(
                            child: Text(
                              'Folder kosong',
                              style: TextStyle(color: UbColors.textMuted, fontWeight: FontWeight.w700),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchList,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                              itemCount: shown.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final item = shown[i];
                                final col = _colorFor(item);
                                return InkWell(
                                  onTap: () {
                                    if (item.type == 'folder') {
                                      _path.add(item.name);
                                      _query = '';
                                      _searchCtrl.clear();
                                      _fetchList();
                                    } else {
                                      final url =
                                          '${AuthService.gateBaseUrl}/api/drive/file?id=${Uri.encodeQueryComponent(item.id)}&download=1';
                                      Clipboard.setData(ClipboardData(text: url));
                                      _toast('Link unduhan "${item.name}" disalin ke clipboard');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: UbColors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: UbColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: col.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(11),
                                          ),
                                          child: Icon(_iconFor(item), color: col, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.type == 'folder'
                                                    ? '${item.childCount ?? 0} item'
                                                    : _fmtSize(item.size),
                                                style: const TextStyle(
                                                  color: UbColors.textMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (item.type != 'folder')
                                          IconButton(
                                            onPressed: () {
                                              final url =
                                                  '${AuthService.gateBaseUrl}/api/drive/file?id=${Uri.encodeQueryComponent(item.id)}&download=1';
                                              Clipboard.setData(ClipboardData(text: url));
                                              _toast('Link unduhan disalin');
                                            },
                                            icon: const Icon(Icons.download_rounded, size: 19, color: UbColors.cyan),
                                          ),
                                        IconButton(
                                          onPressed: _busy ? null : () => _deleteItem(item),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: UbColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
