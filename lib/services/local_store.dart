import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checksheet_models.dart';

class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static const _kSettings = 'ubf_settings_v1';
  static const _kReports = 'ubf_reports_v1';

  Future<UbSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettings);
    if (raw == null || raw.isEmpty) return UbSettings();
    try {
      return UbSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UbSettings();
    }
  }

  Future<void> saveSettings(UbSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettings, jsonEncode(s.toJson()));
  }

  Future<Map<String, ChecksheetReport>> _loadAllMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kReports);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, ChecksheetReport>{};
      decoded.forEach((k, v) {
        if (v is Map) {
          out[k] = ChecksheetReport.fromJson(Map<String, dynamic>.from(v));
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAllMap(Map<String, ChecksheetReport> map) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    map.forEach((k, v) => encoded[k] = v.toJson());
    await prefs.setString(_kReports, jsonEncode(encoded));
  }

  Future<List<ChecksheetReport>> listReports() async {
    final map = await _loadAllMap();
    final list = map.values.toList()
      ..sort((a, b) {
        final dc = b.tanggal.compareTo(a.tanggal);
        if (dc != 0) return dc;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return list;
  }

  Future<ChecksheetReport?> getReport(String id) async {
    final map = await _loadAllMap();
    return map[id];
  }

  Future<void> saveReport(ChecksheetReport rep) async {
    rep.updatedAt = DateTime.now().toIso8601String();
    final map = await _loadAllMap();
    map[rep.id] = rep;
    await _saveAllMap(map);
  }

  Future<({String finish, String label})?> findLatestPrevFinish(
    String targetDate,
    String targetShift,
    bool isNight,
  ) async {
    final all = await listReports();
    final cands = all.where((r) {
      final fin = r.noBodyFinish.replaceAll(RegExp(r'\D'), '');
      if (fin.isEmpty || r.tanggal.isEmpty) return false;
      if (r.tanggal.compareTo(targetDate) < 0) return true;
      if (r.tanggal == targetDate && r.shift != targetShift) {
        return isNight ? r.session != 'night' : false;
      }
      return false;
    }).toList();
    if (cands.isEmpty) return null;
    cands.sort((a, b) {
      final dc = b.tanggal.compareTo(a.tanggal);
      if (dc != 0) return dc;
      final an = a.session == 'night' ? 1 : 0;
      final bn = b.session == 'night' ? 1 : 0;
      if (an != bn) return bn.compareTo(an);
      return b.updatedAt.compareTo(a.updatedAt);
    });
    final top = cands.first;
    return (
      finish: top.noBodyFinish,
      label: '${top.shift} ${top.session == 'night' ? 'Malam' : 'Siang'} (${top.tanggal})',
    );
  }

  Future<({bool ok, String message})> syncReportToServer(ChecksheetReport rep) async {
    final cfg = await getSettings();
    final st = UbMasterData.computeStats(rep);

    final payload = {
      'date': rep.tanggal,
      'tanggal': rep.tanggal,
      'shift': rep.shift,
      'line': rep.lineName,
      'line_name': rep.lineName,
      'pic_name': rep.picName,
      'spv_name': rep.spvName,
      'takt_time': rep.taktTime,
      'template_code': rep.templateCode,
      'total_plan': st.totalPlan,
      'total_act': st.totalAct,
      'total_diff': st.diff,
      'efficiency': st.internalEfficiency,
      'eff_int': st.intEffPct,
      'eff_ext': st.extEffPct,
      'eff_total': st.totalEffPct,
      'total_delay_min': st.totalDelayMin,
      'int_delay_min': st.intDelayMin,
      'ext_delay_min': st.extDelayMin,
      'models_cbu': rep.cbuModels.map((m) => m.toJson()).toList(),
      'model_cbu_source': rep.cbuSource,
      'ckd_parts': rep.ckdParts.map((p) => p.toJson()).toList(),
      'no_body_start': rep.noBodyStart,
      'no_body_finish': rep.noBodyFinish,
      'jam_stop_produksi': rep.jamStopProduksi,
      'waktu_selesai_lini': st.estimatedFinishTime,
      'act_ot_hours': rep.actOtHours,
      'act_ot_units': rep.actOtUnits,
      'ccr_plan': st.effectiveCcrPlan,
      'members': rep.members.map((m) => m.toJson()).toList(),
      'hourly_records': rep.slots.map((s) => s.toJson()).toList(),
    };

    var anyOk = false;
    final notes = <String>[];

    // 1. Primary API (bungtemin.net/ub/api)
    if (cfg.serverApiUrl.trim().isNotEmpty) {
      try {
        final base = cfg.serverApiUrl.split('?').first;
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        if (cfg.apiKey.trim().isNotEmpty) {
          headers['x-ub-api-key'] = cfg.apiKey.trim();
        }
        final res = await http
            .post(
              Uri.parse('$base?action=save_report'),
              headers: headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 15));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          anyOk = true;
          notes.add('MySQL OK');
        } else {
          notes.add('MySQL HTTP ${res.statusCode}');
        }
      } catch (e) {
        notes.add('MySQL gagal');
      }
    }

    // 2. SharePoint Sync via NUDB
    if (cfg.enableSharepointSync && cfg.sharepointSyncUrl.trim().isNotEmpty) {
      try {
        final spPayload = {
          'listName': 'UB_Production_Reports',
          'syncKey': rep.id,
          'fields': {
            'Title': '${rep.tanggal} | ${rep.shift} | ${rep.lineName}',
            'SyncKey': rep.id,
            'Tanggal': rep.tanggal,
            'Shift': rep.shift,
            'LineName': rep.lineName,
            'TemplateCode': rep.templateCode,
            'TaktTime': rep.taktTime,
            'TotalPlan': st.totalPlan,
            'TotalAct': st.totalAct,
            'TotalDiff': st.diff,
            'CcrPlan': st.effectiveCcrPlan,
            'EfficiencyPct': double.tryParse(st.internalEfficiency) ?? 0,
            'IntDelayMin': st.intDelayMin,
            'ExtDelayMin': st.extDelayMin,
            'TotalDelayMin': st.totalDelayMin,
            'NoBodyStart': rep.noBodyStart,
            'NoBodyFinish': rep.noBodyFinish,
            'JamStopProduksi': rep.jamStopProduksi,
            'ActOtHours': rep.actOtHours,
            'ActOtUnits': rep.actOtUnits,
            'PicName': rep.picName,
            'SpvName': rep.spvName,
            'SyncedAt': DateTime.now().toIso8601String(),
          },
        };
        final res = await http
            .post(
              Uri.parse(cfg.sharepointSyncUrl.trim()),
              headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
              body: jsonEncode(spPayload),
            )
            .timeout(const Duration(seconds: 15));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          anyOk = true;
          notes.add('SharePoint OK');
        } else {
          notes.add('SP HTTP ${res.statusCode}');
        }
      } catch (_) {
        notes.add('SP gagal');
      }
    }

    rep.syncStatus = anyOk ? 'synced' : 'failed';
    if (anyOk) rep.lastSyncedAt = DateTime.now().toIso8601String();
    await saveReport(rep);
    return (
      ok: anyOk,
      message: anyOk ? 'Terkirim ke Server (${notes.join(' · ')})' : 'Gagal sync (${notes.join(' · ')}) — data aman di lokal',
    );
  }
}
