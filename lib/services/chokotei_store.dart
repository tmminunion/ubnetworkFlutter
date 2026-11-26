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

  Future<List<ChokoteiIssue>> listManual(String ym) async {
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
}
