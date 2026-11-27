import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chokotei_models.dart';
import 'local_store.dart';
import 'ub_web_api.dart';

class ChokoteiStore {
  ChokoteiStore._();
  static final ChokoteiStore instance = ChokoteiStore._();

  static String _manualKey(String ym) => 'ubf_chokotei_manual_v1_$ym';

  Future<({List<ChokoteiIssue> issues, bool fromServer})> fetchChokoteiList(
    String ym,
    String shift,
  ) async {
    final res = await UbWebApi.instance.getUb({
      'action': 'get_chokotei_list',
      'month': ym,
      'shift': shift,
    });
    if (res.ok && res.map['status'] == 'success' && res.map['data'] is List) {
      final issues = <ChokoteiIssue>[];
      for (final raw in (res.map['data'] as List).whereType<Map>()) {
        final rec = Map<String, dynamic>.from(raw);
        final subs = rec['sub_problems'];
        if (subs is List && subs.isNotEmpty) {
          for (var i = 0; i < subs.length; i++) {
            final sub = subs[i];
            if (sub is Map) {
              final m = Map<String, dynamic>.from(sub);
              issues.add(
                ChokoteiIssue(
                  id: '${rec['id']}',
                  tanggal: (rec['tanggal'] ?? '').toString(),
                  shift: (rec['shift'] ?? shift).toString().toUpperCase(),
                  timeRange: (rec['time_range'] ?? '').toString(),
                  machine: (m['machine_name'] ?? m['machine'] ?? rec['machine_name'] ?? rec['line_station'] ?? 'MST').toString(),
                  category: (m['category'] ?? rec['category'] ?? 'INT').toString().toUpperCase() == 'EXT' ? 'EXT' : 'INT',
                  problem: (m['problem'] ?? rec['problem'] ?? 'Line Delay / Stoppage').toString(),
                  countermeasure: (m['countermeasure'] ?? rec['countermeasure'] ?? '').toString(),
                  lossUnits: ChokoteiIssue.fromJson(m).lossUnits,
                  delayMin: ChokoteiIssue.fromJson(m).delayMin,
                  actionPlan: (rec['action_plan'] ?? '').toString(),
                  actionPic: (rec['action_pic'] ?? rec['pic_name'] ?? '').toString(),
                  actionStatus: (rec['action_status'] ?? 'open').toString(),
                ),
              );
            }
          }
        } else {
          issues.add(ChokoteiIssue.fromJson(rec));
        }
      }
      return (issues: issues, fromServer: true);
    }

    final localReports = await LocalStore.instance.listReports();
    final extracted = ChokoteiMath.extractFromLocalChecksheets(localReports, ym, shift);
    return (issues: extracted, fromServer: false);
  }

  Future<({bool synced, String message})> saveFollowup({
    required String issueId,
    required String actionStatus,
    required String actionPlan,
    required String actionPic,
  }) async {
    final numericId = int.tryParse(issueId);
    if (numericId == null) {
      return (synced: false, message: 'Status diperbarui secara lokal.');
    }
    final res = await UbWebApi.instance.postUb('save_chokotei_followup', {
      'issue_id': numericId,
      'action_status': actionStatus,
      'action_plan': actionPlan,
      'action_pic': actionPic,
    });
    if (res.ok && res.map['status'] == 'success') {
      return (synced: true, message: 'Kaizen Action Plan tersimpan ke MySQL!');
    }
    return (
      synced: false,
      message: res.statusCode > 0
          ? 'Gagal sync MySQL (HTTP ${res.statusCode}).'
          : 'Offline — perubahan tersimpan di tampilan.',
    );
  }

  /// 1:1 sync with Next.js `GET /api/chokotei-manual?month=YYYY-MM` (MongoDB Atlas)
  /// with offline-first local cache fallback.
  Future<({List<ChokoteiIssue> items, bool fromServer})> fetchManual(String ym) async {
    final res = await UbWebApi.instance.getJson('/api/chokotei-manual', query: {'month': ym});
    if (res.ok && res.map['items'] is List) {
      final remote = (res.map['items'] as List)
          .whereType<Map>()
          .map((m) => ChokoteiIssue.fromJson(Map<String, dynamic>.from(m), manual: true))
          .toList();
      if (res.map['configured'] == true || remote.isNotEmpty) {
        await saveManualList(ym, remote);
        return (items: remote, fromServer: true);
      }
    }
    final local = await _loadManualLocal(ym);
    return (items: local, fromServer: false);
  }

  Future<List<ChokoteiIssue>> listManual(String ym) async {
    final res = await fetchManual(ym);
    return res.items;
  }

  Future<List<ChokoteiIssue>> _loadManualLocal(String ym) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_manualKey(ym));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((m) => ChokoteiIssue.fromJson(Map<String, dynamic>.from(m), manual: true))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveManualList(String ym, List<ChokoteiIssue> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_manualKey(ym), jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  /// 1:1 Next.js mutation:
  /// - Existing (`[pm]\d+`): `PATCH /api/chokotei-manual/[id]`
  /// - New: `POST /api/chokotei-manual`
  Future<ChokoteiIssue> upsertManual(String ym, ChokoteiIssue item) async {
    final items = await _loadManualLocal(ym);
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.insert(0, item);
    }
    await saveManualList(ym, items);

    final payload = item.toManualServerPayload();
    final res = item.isManualServerId
        ? await UbWebApi.instance.patchJson('/api/chokotei-manual/${Uri.encodeComponent(item.id.trim())}', payload)
        : await UbWebApi.instance.postJson('/api/chokotei-manual', payload);

    if (res.ok && res.map['item'] is Map) {
      final synced = ChokoteiIssue.fromJson(Map<String, dynamic>.from(res.map['item'] as Map), manual: true);
      final repIdx = items.indexWhere((e) => e.id == item.id || e.id == synced.id);
      if (repIdx >= 0) {
        items[repIdx] = synced;
      } else {
        items.insert(0, synced);
      }
      await saveManualList(ym, items);
      return synced;
    }

    return item;
  }

  /// 1:1 Next.js `DELETE /api/chokotei-manual/[id]`
  Future<bool> deleteManual(String ym, String id) async {
    final items = await _loadManualLocal(ym);
    items.removeWhere((e) => e.id == id);
    await saveManualList(ym, items);

    if (!RegExp(r'^[pm]\d{1,9}$', caseSensitive: false).hasMatch(id.trim())) return true;
    final res = await UbWebApi.instance.deleteJson('/api/chokotei-manual/${Uri.encodeComponent(id.trim())}');
    return res.ok;
  }
}
