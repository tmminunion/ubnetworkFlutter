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

  /// Ambil laporan checksheet secara ONLINE dari MySQL server (1:1 Ubnetwork Next.js `get_report`).
  Future<({bool online, bool found, ChecksheetReport? report, String message})> fetchOnlineReport({
    required String date,
    required String shift,
    required String lineName,
  }) async {
    final cfg = await getSettings();
    final base = cfg.serverApiUrl.trim().split('?').first;
    if (base.isEmpty) {
      return (online: false, found: false, report: null, message: 'URL Server API belum diatur.');
    }

    try {
      final headers = <String, String>{'Accept': 'application/json'};
      if (cfg.apiKey.trim().isNotEmpty) {
        headers['x-ub-api-key'] = cfg.apiKey.trim();
      }
      final uri = Uri.parse(
        '$base?action=get_report&date=${Uri.encodeQueryComponent(date)}&shift=${Uri.encodeQueryComponent(shift)}&line=${Uri.encodeQueryComponent(lineName)}',
      );
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return (
          online: false,
          found: false,
          report: null,
          message: 'Server HTTP ${res.statusCode}',
        );
      }

      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['status'] == 'success' && decoded['found'] == true && decoded['laporan'] is Map) {
        final lap = Map<String, dynamic>.from(decoded['laporan'] as Map);
        final rep = _parseServerLaporan(lap, fallbackDate: date, fallbackShift: shift, cfg: cfg);
        await saveReport(rep);
        return (
          online: true,
          found: true,
          report: rep,
          message: 'Data shift $shift ($date) dimuat dari server',
        );
      }

      return (
        online: true,
        found: false,
        report: null,
        message: 'Belum ada laporan di server untuk $shift ($date)',
      );
    } catch (_) {
      return (
        online: false,
        found: false,
        report: null,
        message: 'Tidak dapat terhubung ke server (Offline)',
      );
    }
  }

  /// Ambil nomor body finish terakhir secara ONLINE dari `monthly_reports` (1:1 Next.js).
  Future<({String finish, String label})?> fetchOnlinePrevFinish({
    required String targetDate,
    required String targetShift,
    required String lineName,
  }) async {
    final cfg = await getSettings();
    final base = cfg.serverApiUrl.trim().split('?').first;
    if (base.isEmpty) return findLatestPrevFinish(targetDate, targetShift, false);

    try {
      final ym = targetDate.length >= 7 ? targetDate.substring(0, 7) : UbMasterData.wibToday().substring(0, 7);
      final headers = <String, String>{'Accept': 'application/json'};
      if (cfg.apiKey.trim().isNotEmpty) {
        headers['x-ub-api-key'] = cfg.apiKey.trim();
      }
      final uri = Uri.parse('$base?action=monthly_reports&year_month=${Uri.encodeQueryComponent(ym)}');
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return findLatestPrevFinish(targetDate, targetShift, false);
      }

      final decoded = jsonDecode(res.body);
      final rawList = (decoded is Map)
          ? (decoded['data'] is List ? decoded['data'] : (decoded['reports'] is List ? decoded['reports'] : []))
          : [];
      final normLine = lineName.trim().toLowerCase();
      final cands = <Map<String, dynamic>>[];

      for (final item in rawList) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final repDate = (m['tanggal'] ?? '').toString().padRight(10).substring(0, 10).trim();
        final repShift = (m['shift'] ?? '').toString().toUpperCase();
        final repLine = (m['line_name'] ?? '').toString().trim().toLowerCase();
        final fin = (m['no_body_finish'] ?? '').toString().trim();
        if (repDate.isEmpty || fin.replaceAll(RegExp(r'\D'), '').isEmpty) continue;
        if (normLine.isNotEmpty && repLine.isNotEmpty && repLine != normLine) continue;
        if (repDate.compareTo(targetDate) < 0 || (repDate == targetDate && repShift != targetShift)) {
          cands.add(m);
        }
      }

      if (cands.isEmpty) return findLatestPrevFinish(targetDate, targetShift, false);
      cands.sort((a, b) {
        final da = (a['tanggal'] ?? '').toString();
        final db = (b['tanggal'] ?? '').toString();
        final dc = db.compareTo(da);
        if (dc != 0) return dc;
        return (b['updated_at'] ?? '').toString().compareTo((a['updated_at'] ?? '').toString());
      });

      final top = cands.first;
      final fin = (top['no_body_finish'] ?? '').toString().trim();
      final sh = (top['shift'] ?? '').toString().toUpperCase();
      final dt = (top['tanggal'] ?? '').toString();
      final isNight = (top['template_code'] ?? '').toString().toLowerCase().contains('malam');
      return (
        finish: fin,
        label: '$sh ${isNight ? 'Malam' : 'Siang'} ($dt)',
      );
    } catch (_) {
      return findLatestPrevFinish(targetDate, targetShift, false);
    }
  }

  ChecksheetReport _parseServerLaporan(
    Map<String, dynamic> lap, {
    required String fallbackDate,
    required String fallbackShift,
    required UbSettings cfg,
  }) {
    final dt = (lap['tanggal'] ?? fallbackDate).toString().split('T').first;
    final sh = (lap['shift'] ?? fallbackShift).toString().toUpperCase() == 'RED' ? 'RED' : 'WHITE';
    final line = (lap['line_name'] ?? cfg.lineName).toString();
    final tpl = (lap['template_code'] ?? 'pagi_normal').toString();
    final tt = (lap['takt_time'] as num?)?.toDouble() ?? cfg.taktTime;

    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fn) {
      if (raw is String && raw.trim().isNotEmpty) {
        try {
          raw = jsonDecode(raw);
        } catch (_) {}
      }
      if (raw is List) {
        return raw.whereType<Map>().map((e) => fn(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    }

    final cbu = parseList(lap['models_cbu'], CbuModelItem.fromJson);
    final ckd = parseList(lap['ckd_parts'], CkdPartItem.fromJson);
    final mems = parseList(lap['members'], MemberAbsen.fromJson);
    final slots = parseList(lap['hourly_records'], HourlySlot.fromJson);

    return ChecksheetReport(
      id: UbMasterData.makeReportId(dt, sh, line),
      tanggal: dt,
      shift: sh,
      session: tpl.toLowerCase().contains('malam') ? 'night' : 'day',
      workMode: tpl.toLowerCase().contains('puasa') ? 'puasa' : 'normal',
      templateCode: tpl,
      overtimeHours: 2,
      lineName: line,
      taktTime: tt,
      ccrPlan: (lap['ccr_plan'] as num?)?.toInt() ?? (sh == 'RED' ? cfg.ccrTargetRed : cfg.ccrTargetWhite),
      picName: (lap['pic_name'] ?? (sh == 'RED' ? 'KAMALUDIN' : 'DWI MULYONO')).toString(),
      spvName: (lap['spv_name'] ?? '').toString(),
      noBodyStart: (lap['no_body_start'] ?? '').toString(),
      noBodyFinish: (lap['no_body_finish'] ?? '').toString(),
      jamStopProduksi: (lap['jam_stop_produksi'] ?? '').toString(),
      actOtHours: (lap['act_ot_hours'] as num?)?.toDouble() ?? 0,
      actOtUnits: (lap['act_ot_units'] as num?)?.toInt() ?? 0,
      cbuSource: (lap['model_cbu_source'] ?? 'ratio').toString(),
      cbuModels: cbu.isEmpty ? UbMasterData.defaultCbuModels() : cbu,
      ckdParts: ckd.isEmpty ? UbMasterData.defaultCkdParts() : ckd,
      members: mems.isEmpty ? UbMasterData.defaultMembers(sh) : mems,
      slots: slots.isEmpty ? UbMasterData.buildSlotsFromTemplate(tpl, tt, 2) : slots,
      syncStatus: 'synced',
      updatedAt: (lap['updated_at'] ?? DateTime.now().toIso8601String()).toString(),
      lastSyncedAt: (lap['updated_at'] ?? DateTime.now().toIso8601String()).toString(),
    );
  }
}
