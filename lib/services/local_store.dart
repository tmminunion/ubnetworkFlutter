import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checksheet_models.dart';
import 'ub_web_api.dart';

class OnlineChecksheetLoadResult {
  const OnlineChecksheetLoadResult({
    required this.online,
    required this.foundInServer,
    required this.report,
    required this.templates,
    required this.message,
    this.prevCarry,
  });

  final bool online;
  final bool foundInServer;
  final ChecksheetReport report;
  final List<ShiftTemplate> templates;
  final String message;
  final ({String finish, String label})? prevCarry;
}

class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static const _kSettings = 'ubf_settings_v1';
  static const _kReports = 'ubf_reports_v1';
  static const _kServerTemplates = 'ubf_server_templates_v1';
  static const _kServerStructPrefix = 'ubf_server_struct_v1_';

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

  Future<List<ShiftTemplate>> getCachedTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kServerTemplates);
    if (raw == null || raw.isEmpty) return UbMasterData.masterTemplates;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final parsed = decoded
            .whereType<Map>()
            .map((e) => ShiftTemplate.fromJson(Map<String, dynamic>.from(e)))
            .where((t) => t.slots.isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (_) {}
    return UbMasterData.masterTemplates;
  }

  Future<void> _saveCachedTemplates(List<ShiftTemplate> list) async {
    if (list.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kServerTemplates, jsonEncode(list.map((t) => t.toJson()).toList()));
  }

  Future<({String gl, String tl, List<MemberAbsen> members})?> getCachedStructure(String shift) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kServerStructPrefix${shift.toUpperCase()}');
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final mems = (m['members'] as List?)
              ?.whereType<Map>()
              .map((e) => MemberAbsen.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      if (mems.isEmpty) return null;
      return (
        gl: (m['gl'] ?? '').toString(),
        tl: (m['tl'] ?? '').toString(),
        members: mems,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCachedStructure(
    String shift,
    ({String gl, String tl, List<MemberAbsen> members}) struct,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_kServerStructPrefix${shift.toUpperCase()}',
      jsonEncode({
        'gl': struct.gl,
        'tl': struct.tl,
        'members': struct.members.map((m) => m.toJson()).toList(),
      }),
    );
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
          final rep = ChecksheetReport.fromJson(Map<String, dynamic>.from(v));
          final normKey = UbMasterData.makeReportId(rep.tanggal, rep.shift, rep.lineName);
          rep.id = normKey;
          out[normKey] = rep;
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
    rep.id = UbMasterData.makeReportId(rep.tanggal, rep.shift, rep.lineName);
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

    final cbuToSave = rep.cbuSource == 'ratio'
        ? UbMasterData.calculateCbuByRatio(st.totalAct, rep.cbuModels)
        : rep.cbuModels;
    rep.cbuModels = cbuToSave;

    int qtyOf(String code) =>
        cbuToSave.where((m) => m.code == code).fold<int>(0, (a, m) => a + m.qty);

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
      'eff_int': st.intEffPct == '-' ? '100' : st.intEffPct,
      'eff_ext': st.extEffPct == '-' ? '100' : st.extEffPct,
      'eff_total': st.totalEffPct == '-' ? '100' : st.totalEffPct,
      'total_delay_min': st.totalDelayMin,
      'int_delay_min': st.intDelayMin,
      'ext_delay_min': st.extDelayMin,
      'models_cbu': cbuToSave.map((m) => m.toJson()).toList(),
      'model_cbu_source': rep.cbuSource,
      'model_innova': qtyOf('innova'),
      'model_fortuner': qtyOf('fortuner'),
      'model_zenix': qtyOf('zenix'),
      'model_ckd': rep.ckdParts.fold<int>(0, (a, p) => a + p.qty),
      'ckd_parts': rep.ckdParts.map((p) => p.toJson()).toList(),
      'no_body_start': rep.noBodyStart,
      'no_body_finish': rep.noBodyFinish,
      'jam_stop_produksi': rep.jamStopProduksi,
      'waktu_selesai_lini': st.estimatedFinishTime,
      'act_ot_hours': rep.actOtHours,
      'act_ot_units': rep.actOtUnits,
      'overtime_hours': rep.actOtHours > 0 ? rep.actOtHours : rep.overtimeHours,
      'ccr_plan': st.effectiveCcrPlan,
      'ot_plan_hours': st.otPlanHours,
      'ot_plan_units': st.otPlanUnits,
      'members': rep.members.map((m) => m.toJson()).toList(),
      'hourly_records': rep.slots.map((s) => s.toJson()).toList(),
    };

    var anyOk = false;
    final notes = <String>[];

    // 1. Primary 1:1 Next.js `/api/ub?action=save_report` (saves to MySQL + server-side SharePoint)
    final ubRes = await UbWebApi.instance.postUb('save_report', payload);
    if (ubRes.ok && (ubRes.map['status'] == 'success' || ubRes.map.isEmpty)) {
      anyOk = true;
      notes.add('MySQL OK');
    } else {
      notes.add(ubRes.error ?? 'MySQL HTTP ${ubRes.statusCode}');
    }

    // 2. Fallback SharePoint Sync via NUDB if direct SharePoint sync enabled and primary failed
    if (!anyOk && cfg.enableSharepointSync && cfg.sharepointSyncUrl.trim().isNotEmpty) {
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
            .timeout(const Duration(seconds: 12));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          anyOk = true;
          notes.add('SharePoint OK');
        }
      } catch (_) {}
    }

    rep.syncStatus = anyOk ? 'synced' : 'failed';
    if (anyOk) rep.lastSyncedAt = DateTime.now().toIso8601String();
    await saveReport(rep);
    return (
      ok: anyOk,
      message: anyOk
          ? 'Data Terkirim ke Server (${notes.join(' · ')})'
          : 'Gagal sync (${notes.join(' · ')}) — data aman di lokal',
    );
  }

  /// 1:1 Next.js Checksheet Loader:
  /// 1. Mengambil data hari ini (`get_report`), master settings (`get_settings`),
  ///    template aktif (`templates`), struktur regu (`get_members`), & body finish sebelumnya (`monthly_reports`) secara paralel.
  /// 2. Jika laporan tanggal+shift sudah ada di server (`found == true`), langsung merestorasi seluruh jam kerja, problem, absensi, CBU & CKD.
  /// 3. Jika belum ada di server (`found == false`), langsung menampilkan sesuai Template Harian (`pagi_normal` / `jumat_normal` / `malam_normal`)
  ///    lengkap dengan Takt Time server, roster Hadir aktual, rasio CBU/CKD master, dan carry-over No Body.
  Future<OnlineChecksheetLoadResult> loadOrCreateReportForDateShift({
    required String date,
    required String shift,
    String? sessionOverride,
    String? templateOverride,
    bool forceRefreshFromServer = false,
  }) async {
    final cfg = await getSettings();
    final normShift = shift.toUpperCase() == 'RED' ? 'RED' : 'WHITE';
    final line = cfg.lineName.trim().isEmpty ? 'UB Assy' : cfg.lineName.trim();
    final reportId = UbMasterData.makeReportId(date, normShift, line);

    final cachedTemplates = await getCachedTemplates();
    final cachedStruct = await getCachedStructure(normShift);
    final existingLocal = await getReport(reportId);

    final ym = date.length >= 7 ? date.substring(0, 7) : UbMasterData.wibToday().substring(0, 7);

    // Parallel burst via authenticated Next.js `/api/ub` gateway
    final responses = await Future.wait([
      UbWebApi.instance.getUb({
        'action': 'get_report',
        'date': date,
        'shift': normShift,
        'line': line,
      }),
      UbWebApi.instance.getUb({'action': 'get_settings'}),
      UbWebApi.instance.getUb({
        'action': 'templates',
        'takt_time': '${cfg.taktTime}',
      }),
      UbWebApi.instance.getUb({
        'action': 'get_members',
        'shift': normShift,
      }),
      UbWebApi.instance.getUb({
        'action': 'monthly_reports',
        'year_month': ym,
      }),
    ]);

    var repRes = responses[0];
    final setRes = responses[1];
    final tplRes = responses[2];
    final memRes = responses[3];
    final monRes = responses[4];

    final anyOnline = repRes.ok || setRes.ok || tplRes.ok || memRes.ok || monRes.ok;

    // 1. Parse Global Settings (`line_name`, `current_takt_time`, `models`, `ckd_parts`)
    var effectiveLine = line;
    var effectiveTakt = cfg.taktTime;
    List<CbuModelItem>? masterCbu;
    List<CkdPartItem>? masterCkd;
    if (setRes.ok && setRes.map['status'] == 'success' && setRes.map['data'] is Map) {
      final sd = Map<String, dynamic>.from(setRes.map['data'] as Map);
      final sLine = (sd['line_name'] ?? '').toString().trim();
      if (sLine.isNotEmpty) effectiveLine = sLine;
      final sTakt = (sd['current_takt_time'] as num?)?.toDouble();
      if (sTakt != null && sTakt > 0) effectiveTakt = sTakt;

      if (sd['models'] is List) {
        final parsedModels = (sd['models'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((m) => (m['code'] ?? '').toString() != 'ckd')
            .map((m) => CbuModelItem(
                  code: (m['code'] ?? '').toString(),
                  name: (m['name'] ?? m['code'] ?? '').toString().toUpperCase(),
                  qty: 0,
                  ratio: (m['ratio'] as num?)?.toDouble() ?? 1.0,
                ))
            .where((m) => m.code.isNotEmpty)
            .toList();
        if (parsedModels.isNotEmpty) masterCbu = parsedModels;
      }

      if (sd['ckd_parts'] is List) {
        final parsedCkd = (sd['ckd_parts'] as List)
            .whereType<Map>()
            .map((e) => CkdPartItem.fromJson(Map<String, dynamic>.from(e))..qty = 0)
            .where((p) => p.partNo.isNotEmpty)
            .toList();
        if (parsedCkd.isNotEmpty) masterCkd = parsedCkd;
      }

      if (cfg.taktTime != effectiveTakt || cfg.lineName != effectiveLine) {
        cfg
          ..taktTime = effectiveTakt
          ..lineName = effectiveLine;
        await saveSettings(cfg);
      }
    }

    // 2. Parse Master Shift Templates from Server
    var activeTemplates = cachedTemplates;
    if (tplRes.ok && tplRes.map['status'] == 'success' && tplRes.map['data'] is List) {
      final parsedTpls = (tplRes.map['data'] as List)
          .whereType<Map>()
          .map((e) => ShiftTemplate.fromJson(Map<String, dynamic>.from(e)))
          .where((t) => t.slots.isNotEmpty)
          .toList();
      if (parsedTpls.isNotEmpty) {
        activeTemplates = parsedTpls;
        await _saveCachedTemplates(parsedTpls);
      }
    }

    // 3. Parse Team Structure & Roster (`GL`, `TL`, `members`)
    var activeStruct = cachedStruct ??
        (
          gl: normShift == 'RED' ? 'KAMALUDIN' : 'DWI MULYONO',
          tl: normShift == 'RED' ? 'MASRURI / TRI RUSTIANTORO' : 'DADANG SURYADI / NUNU FATULAH',
          members: UbMasterData.defaultMembers(normShift),
        );
    if (memRes.ok && memRes.map['status'] == 'success' && memRes.map['data'] is List) {
      final rawMems = (memRes.map['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (rawMems.isNotEmpty) {
        final glRow = rawMems.cast<Map<String, dynamic>?>().firstWhere(
              (m) => (m?['role'] ?? '').toString().toUpperCase() == 'GL',
              orElse: () => null,
            );
        final tlRows = rawMems
            .where((m) => (m['role'] ?? '').toString().toUpperCase() == 'TL')
            .map((m) => (m['name'] ?? '').toString().trim())
            .where((n) => n.isNotEmpty)
            .toList();
        final glName = (glRow?['name'] ?? '').toString().trim().isNotEmpty
            ? (glRow!['name']).toString().trim()
            : activeStruct.gl;
        final tlNames = tlRows.isNotEmpty ? tlRows.join(' / ') : activeStruct.tl;
        final roster = <MemberAbsen>[];
        for (var i = 0; i < rawMems.length; i++) {
          final m = rawMems[i];
          final role = (m['role'] ?? 'TM').toString();
          final pos = (m['default_pos'] ?? 'Pos 1').toString();
          roster.add(MemberAbsen(
            id: (m['id'] as num?)?.toInt() ?? (i + 1),
            name: (m['name'] ?? '').toString(),
            noreg: (m['noreg'] ?? '').toString(),
            status: 'Hadir',
            note: '$role • $pos',
          ));
        }
        activeStruct = (gl: glName, tl: tlNames, members: roster);
        await _saveCachedStructure(normShift, activeStruct);
      }
    }

    // 4. Parse Monthly Reports (for Prev Body Finish + alternate line_name detection)
    final monthlyList = <Map<String, dynamic>>[];
    if (monRes.ok) {
      final raw = monRes.map['data'] is List
          ? monRes.map['data'] as List
          : (monRes.map['reports'] is List ? monRes.map['reports'] as List : const []);
      for (final item in raw) {
        if (item is Map) monthlyList.add(Map<String, dynamic>.from(item));
      }
    }

    // If `get_report` with `line` was not found, check if `monthly_reports` has an entry for `(date, normShift)` under a different `line_name`
    if (repRes.ok && repRes.map['found'] != true && monthlyList.isNotEmpty) {
      final altMatch = monthlyList.cast<Map<String, dynamic>?>().firstWhere(
            (m) =>
                (m?['tanggal'] ?? '').toString().split('T').first == date &&
                (m?['shift'] ?? '').toString().toUpperCase() == normShift,
            orElse: () => null,
          );
      final altLine = (altMatch?['line_name'] ?? '').toString().trim();
      if (altLine.isNotEmpty && altLine.toLowerCase() != line.toLowerCase()) {
        final retry = await UbWebApi.instance.getUb({
          'action': 'get_report',
          'date': date,
          'shift': normShift,
          'line': altLine,
        });
        if (retry.ok && retry.map['found'] == true) {
          repRes = retry;
        }
      }
    }

    // Helper for computing previous shift finish from `monthlyList` (1:1 Next.js `fetchPrevShiftFinish`)
    Future<({String finish, String label})?> resolvePrevCarry(bool isNight) async {
      if (monthlyList.isNotEmpty) {
        final normLine = effectiveLine.trim().toLowerCase();
        final cands = monthlyList.where((m) {
          final repDate = (m['tanggal'] ?? '').toString().split('T').first.trim();
          final repShift = (m['shift'] ?? '').toString().toUpperCase();
          final repLine = (m['line_name'] ?? '').toString().trim().toLowerCase();
          final fin = (m['no_body_finish'] ?? '').toString().trim();
          if (repDate.isEmpty || fin.replaceAll(RegExp(r'\D'), '').isEmpty) return false;
          if (normLine.isNotEmpty && repLine.isNotEmpty && repLine != normLine) return false;
          if (repDate.compareTo(date) < 0) return true;
          if (repDate == date && repShift != normShift) {
            final repNight = (m['template_code'] ?? '').toString().toLowerCase().contains('malam');
            return isNight ? !repNight : false;
          }
          return false;
        }).toList();

        if (cands.isNotEmpty) {
          cands.sort((a, b) {
            final da = (a['tanggal'] ?? '').toString().split('T').first;
            final db = (b['tanggal'] ?? '').toString().split('T').first;
            final dc = db.compareTo(da);
            if (dc != 0) return dc;
            final an = (a['template_code'] ?? '').toString().toLowerCase().contains('malam') ? 1 : 0;
            final bn = (b['template_code'] ?? '').toString().toLowerCase().contains('malam') ? 1 : 0;
            if (an != bn) return bn.compareTo(an);
            return (b['updated_at'] ?? '').toString().compareTo((a['updated_at'] ?? '').toString());
          });
          final top = cands.first;
          final fin = (top['no_body_finish'] ?? '').toString().trim();
          final sh = (top['shift'] ?? '').toString().toUpperCase();
          final dt = (top['tanggal'] ?? '').toString().split('T').first;
          final night = (top['template_code'] ?? '').toString().toLowerCase().contains('malam');
          return (finish: fin, label: '$sh ${night ? 'Malam' : 'Siang'} ($dt)');
        }
      }
      return findLatestPrevFinish(date, normShift, isNight);
    }

    // =========================================================================
    // CASE A: ONLINE & FOUND IN MYSQL -> RESTORE FULL SAVED CHECKSHEET (1:1 Next.js)
    // =========================================================================
    if (repRes.ok &&
        repRes.map['status'] == 'success' &&
        repRes.map['found'] == true &&
        repRes.map['laporan'] is Map) {
      final decoded = repRes.map;
      final lap = Map<String, dynamic>.from(decoded['laporan'] as Map);
      final isNightLap = (lap['template_code'] ?? '').toString().toLowerCase().contains('malam');
      final prevInfo = await resolvePrevCarry(isNightLap);

      final parsed = _parseFullServerResponse(
        decoded: decoded,
        lap: lap,
        fallbackDate: date,
        fallbackShift: normShift,
        effectiveLine: effectiveLine,
        effectiveTakt: effectiveTakt,
        cfg: cfg,
        struct: activeStruct,
        masterCbu: masterCbu,
        masterCkd: masterCkd,
        templates: activeTemplates,
        prevCarry: prevInfo,
      );

      // If user explicitly switched template/session in UI, apply on top of loaded report only when requested
      if (templateOverride != null && templateOverride != parsed.templateCode) {
        parsed.templateCode = templateOverride;
        parsed.session = templateOverride.toLowerCase().contains('malam') ? 'night' : 'day';
        parsed.workMode = templateOverride.toLowerCase().contains('puasa') ? 'puasa' : 'normal';
        parsed.slots = UbMasterData.buildSlotsFromTemplate(
          templateOverride,
          parsed.taktTime,
          parsed.overtimeHours,
          prevSlots: parsed.slots,
          otAwalMode: parsed.otAwal,
          customTemplates: activeTemplates,
        );
      }

      await saveReport(parsed);
      return OnlineChecksheetLoadResult(
        online: true,
        foundInServer: true,
        report: parsed,
        templates: activeTemplates,
        prevCarry: prevInfo,
        message: 'Data hari ini ($normShift) dimuat dari server',
      );
    }

    // =========================================================================
    // CASE B: ONLINE & NOT FOUND IN MYSQL -> TAMPILKAN SESUAI TEMPLATE HARIAN (1:1 Next.js)
    // =========================================================================
    if (anyOnline) {
      // Preserve local draft ONLY if user actually edited cells and hasn't synced yet
      if (!forceRefreshFromServer &&
          sessionOverride == null &&
          templateOverride == null &&
          existingLocal != null &&
          existingLocal.syncStatus != 'synced' &&
          existingLocal.hasUserEdits) {
        final prevInfo = await resolvePrevCarry(existingLocal.session == 'night');
        return OnlineChecksheetLoadResult(
          online: true,
          foundInServer: false,
          report: existingLocal,
          templates: activeTemplates,
          prevCarry: prevInfo,
          message: 'Melanjutkan draft lokal ($normShift)',
        );
      }

      final mp = repRes.map['monthly_plan'] is Map
          ? Map<String, dynamic>.from(repRes.map['monthly_plan'] as Map)
          : null;

      // Determine session & CCR/OT plan from monthly_plan or daily default
      String resolvedSession = sessionOverride ?? '';
      if (resolvedSession.isEmpty && templateOverride != null) {
        resolvedSession = templateOverride.toLowerCase().contains('malam') ? 'night' : 'day';
      }
      if (resolvedSession.isEmpty && mp != null) {
        final mpSess = (normShift == 'RED' ? mp['red_session'] : mp['white_session'])?.toString().toLowerCase() ?? '';
        if (mpSess == 'day' || mpSess == 'night') {
          resolvedSession = mpSess;
        }
      }
      if (resolvedSession.isEmpty) {
        resolvedSession = 'day';
      }

      int? planCcr;
      var planOtHours = 2;
      if (mp != null) {
        final rawPlan = normShift == 'RED'
            ? (mp['red_plan'] ?? mp['day_plan'])
            : (mp['white_plan'] ?? mp['day_plan']);
        final pVal = (rawPlan as num?)?.toInt() ?? int.tryParse('${rawPlan ?? 0}') ?? 0;
        if (pVal > 0) planCcr = pVal;

        final rawOt = normShift == 'RED' ? mp['red_ot_hours'] : mp['white_ot_hours'];
        final otVal = (rawOt as num?)?.toDouble() ?? double.tryParse('${rawOt ?? ''}') ?? -1;
        if (otVal >= 0) planOtHours = otVal.ceil().clamp(0, 3);
      }

      final prevInfo = await resolvePrevCarry(resolvedSession == 'night');
      final freshCfg = UbSettings.fromJson(cfg.toJson())
        ..lineName = effectiveLine
        ..taktTime = effectiveTakt;

      final freshTemplateReport = UbMasterData.createTemplateReport(
        date: date,
        shift: normShift,
        cfg: freshCfg,
        sessionOverride: resolvedSession,
        templateOverride: templateOverride,
        overtimeHours: planOtHours,
        picOverride: activeStruct.gl,
        spvOverride: activeStruct.tl,
        ccrOverride: planCcr,
        prevCarry: prevInfo,
        customCbuModels: masterCbu,
        customCkdParts: masterCkd,
        customMembers: activeStruct.members,
        customTemplates: activeTemplates,
      );

      return OnlineChecksheetLoadResult(
        online: true,
        foundInServer: false,
        report: freshTemplateReport,
        templates: activeTemplates,
        prevCarry: prevInfo,
        message: 'Belum ada laporan di server — menampilkan sesuai Template ${UbMasterData.getTemplate(freshTemplateReport.templateCode, customTemplates: activeTemplates).name}',
      );
    }

    // =========================================================================
    // CASE C: OFFLINE FALLBACK -> PAKAI CACHE LOKAL ATAU TEMPLATE LOKAL
    // =========================================================================
    final prevOffline = await findLatestPrevFinish(date, normShift, sessionOverride == 'night');
    if (existingLocal != null && sessionOverride == null && templateOverride == null) {
      return OnlineChecksheetLoadResult(
        online: false,
        foundInServer: false,
        report: existingLocal,
        templates: activeTemplates,
        prevCarry: prevOffline,
        message: 'Mode offline — menampilkan data lokal ($normShift)',
      );
    }

    final offlineDraft = UbMasterData.createTemplateReport(
      date: date,
      shift: normShift,
      cfg: cfg,
      sessionOverride: sessionOverride,
      templateOverride: templateOverride,
      picOverride: activeStruct.gl,
      spvOverride: activeStruct.tl,
      prevCarry: prevOffline,
      customMembers: activeStruct.members,
      customTemplates: activeTemplates,
    );
    return OnlineChecksheetLoadResult(
      online: false,
      foundInServer: false,
      report: offlineDraft,
      templates: activeTemplates,
      prevCarry: prevOffline,
      message: 'Mode offline — menampilkan sesuai Template Harian',
    );
  }

  ChecksheetReport _parseFullServerResponse({
    required Map<String, dynamic> decoded,
    required Map<String, dynamic> lap,
    required String fallbackDate,
    required String fallbackShift,
    required String effectiveLine,
    required double effectiveTakt,
    required UbSettings cfg,
    required ({String gl, String tl, List<MemberAbsen> members}) struct,
    required List<CbuModelItem>? masterCbu,
    required List<CkdPartItem>? masterCkd,
    required List<ShiftTemplate> templates,
    required ({String finish, String label})? prevCarry,
  }) {
    final dt = (lap['tanggal'] ?? fallbackDate).toString().split('T').first;
    final sh = (lap['shift'] ?? fallbackShift).toString().toUpperCase() == 'RED' ? 'RED' : 'WHITE';
    final line = (lap['line_name'] ?? effectiveLine).toString().trim().isNotEmpty
        ? (lap['line_name'] ?? effectiveLine).toString().trim()
        : 'UB Assy';
    final tpl = (lap['template_code'] ?? UbMasterData.defaultTemplateCode(dt)).toString();
    final tt = (lap['takt_time'] as num?)?.toDouble() ??
        double.tryParse('${lap['takt_time'] ?? ''}') ??
        effectiveTakt;

    List<Map<String, dynamic>> decodeMapList(dynamic raw) {
      if (raw is String && raw.trim().isNotEmpty) {
        try {
          raw = jsonDecode(raw);
        } catch (_) {}
      }
      if (raw is List) {
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    }

    // 1. PIC & SPV (replace legacy mock names with real team structure 1:1 Next.js)
    final rawPic = (lap['pic_name'] ?? '').toString().trim();
    final isMockPic = rawPic.isEmpty || rawPic.contains('HERU.P') || rawPic.contains('SLAMET.H');
    final picName = isMockPic ? struct.gl : rawPic;

    final rawSpv = (lap['spv_name'] ?? '').toString().trim();
    final isMockSpv = rawSpv.isEmpty || rawSpv.contains('SUHARTONO') || rawSpv.contains('DODDY.S');
    final spvName = isMockSpv ? struct.tl : rawSpv;

    // 2. CBU Models (`models_cbu`, `models_cbu_data`, or legacy `model_zenix`/`model_fortuner`/`model_innova`)
    final rawCbuMaps = decodeMapList(lap['models_cbu'] ?? lap['models_cbu_data']);
    List<CbuModelItem> cbuModels;
    if (rawCbuMaps.isNotEmpty) {
      cbuModels = rawCbuMaps.map((m) {
        final code = (m['code'] ?? '').toString();
        final masterHit = masterCbu?.where((x) => x.code == code);
        final ratio = (masterHit != null && masterHit.isNotEmpty)
            ? masterHit.first.ratio
            : ((m['ratio'] as num?)?.toDouble() ??
                (code == 'zenix' ? 1.0 : (code == 'fortuner' ? 0.6 : 0.1)));
        return CbuModelItem(
          code: code,
          name: (m['name'] ?? code.toUpperCase()).toString(),
          qty: (m['qty'] as num?)?.toInt() ?? int.tryParse('${m['qty'] ?? 0}') ?? 0,
          ratio: ratio,
        );
      }).toList();
    } else if (lap['model_zenix'] != null || lap['model_fortuner'] != null || lap['model_innova'] != null) {
      final baseModels = masterCbu ?? UbMasterData.defaultCbuModels();
      int legacyQty(String c) {
        final v = lap['model_$c'];
        return (v as num?)?.toInt() ?? int.tryParse('${v ?? 0}') ?? 0;
      }

      cbuModels = baseModels
          .map((m) => CbuModelItem(code: m.code, name: m.name, qty: legacyQty(m.code), ratio: m.ratio))
          .toList();
    } else {
      cbuModels = (masterCbu ?? UbMasterData.defaultCbuModels()).map((m) => m.copy()).toList();
    }

    // 3. CKD Parts (merge saved qty onto master CKD parts 1:1 Next.js)
    final savedCkd = decodeMapList(lap['ckd_parts'] ?? lap['ckd_parts_data'])
        .map(CkdPartItem.fromJson)
        .toList();
    final baseCkd = masterCkd ?? (savedCkd.isNotEmpty ? savedCkd : UbMasterData.defaultCkdParts());
    final ckdParts = baseCkd.map((mp) {
      final hit = savedCkd.where((s) => s.partNo == mp.partNo);
      return CkdPartItem(
        partNo: mp.partNo,
        partName: mp.partName,
        qty: hit.isNotEmpty ? hit.first.qty : 0,
      );
    }).toList();

    // 4. Manpower Attendance (`decoded['members']` top-level from `get_report`, fallback `lap['members']` / `lap['members_data']`)
    final rawMembers = decodeMapList(decoded['members'] ?? lap['members'] ?? lap['members_data']);
    final members = rawMembers.isNotEmpty
        ? rawMembers.map(MemberAbsen.fromJson).toList()
        : struct.members.map((m) => m.copy()).toList();

    // 5. Hourly Slots (`decoded['issues']` top-level from `get_report` 1:1 Next.js, fallback `lap['hourly_records']`)
    final rawIssues = decodeMapList(decoded['issues'] ?? lap['hourly_records']);
    List<HourlySlot> slots;
    var resolvedOtHours = 2;
    var resolvedOtAwal = 'none';

    if (rawIssues.isNotEmpty) {
      slots = rawIssues.map((iss) {
        final slotNo = (iss['slot_no'] ?? iss['no'] as num?)?.toInt() ??
            int.tryParse('${iss['slot_no'] ?? iss['no'] ?? 1}') ??
            1;
        final timeRange = (iss['time_range'] ?? iss['timeRange'] ?? '').toString();
        final isNightTpl = tpl.toLowerCase().contains('malam');
        final isEarlyOt = slotNo == 1 &&
            isNightTpl &&
            (timeRange.contains('20:00') || timeRange.contains('20:30'));
        final isOtSlot = slotNo >= 9 || isEarlyOt || iss['is_overtime'] == true || iss['isOvertime'] == true;

        final rawPlan = (iss['plan'] as num?)?.toInt() ?? int.tryParse('${iss['plan'] ?? 0}') ?? 0;
        final rawActObj = iss['act'];
        final parsedAct = (rawActObj == null || '$rawActObj'.trim().isEmpty)
            ? null
            : ((rawActObj as num?)?.toInt() ?? int.tryParse('$rawActObj'));

        final rawBlocked = iss['is_blocked'] ?? iss['isBlocked'];
        final isBlockedFromDb = rawBlocked == true ||
            rawBlocked == 1 ||
            '$rawBlocked' == '1' ||
            (slotNo >= 9 && rawPlan == 0 && (parsedAct == null || parsedAct == 0));

        final probStr = isBlockedFromDb ? '' : (iss['problem'] ?? '').toString();
        final rawSt = (iss['line_station'] ?? iss['lineStation'] ?? '').toString();
        final cleanSt = (rawSt == 'MST' && probStr.trim().isEmpty) ? '' : rawSt;

        final subRaw = decodeMapList(iss['problems'] ?? iss['sub_problems']);
        final subProbs = isBlockedFromDb
            ? <ChokoteiProblem>[]
            : (subRaw.isNotEmpty
                ? subRaw.map(ChokoteiProblem.fromJson).toList()
                : (probStr.trim().isNotEmpty
                    ? [
                        ChokoteiProblem(
                          id: 'p-${iss['id'] ?? slotNo}',
                          lineStation: cleanSt,
                          machineName: (iss['machine_name'] ?? cleanSt).toString(),
                          problem: probStr,
                          countermeasure: (iss['countermeasure'] ?? '').toString(),
                          lossUnits: (iss['loss_units'] as num?)?.toInt() ??
                              (parsedAct != null ? math.max(0, rawPlan - parsedAct) : 0),
                          delayMin: (iss['delay_min'] ?? iss['delayMin'] as num?)?.toDouble() ?? 0,
                          category: ((iss['category'] ?? 'INT').toString().toUpperCase() == 'EXT') ? 'EXT' : 'INT',
                        ),
                      ]
                    : <ChokoteiProblem>[]));

        if (slotNo == 1 && isNightTpl && !isBlockedFromDb) {
          resolvedOtAwal = timeRange.contains('20:30') ? '30m' : '1h';
        }

        return HourlySlot(
          no: slotNo,
          timeRange: timeRange,
          plan: isBlockedFromDb ? 0 : rawPlan,
          act: isBlockedFromDb ? null : parsedAct,
          isOvertime: isOtSlot,
          isEarlyOvertime: isEarlyOt,
          isBlocked: isBlockedFromDb,
          lineStation: isBlockedFromDb ? '-' : cleanSt,
          problem: probStr,
          countermeasure: isBlockedFromDb ? '' : (iss['countermeasure'] ?? '').toString(),
          delayMin: isBlockedFromDb
              ? 0
              : ((iss['delay_min'] ?? iss['delayMin'] as num?)?.toDouble() ??
                  double.tryParse('${iss['delay_min'] ?? 0}') ??
                  0),
          delayCategory: ((iss['category'] ?? iss['delayCategory'] ?? 'INT').toString().toUpperCase() == 'EXT')
              ? 'EXT'
              : 'INT',
          lossUnits: isBlockedFromDb
              ? 0
              : ((iss['loss_units'] as num?)?.toInt() ??
                  (parsedAct != null ? math.max(0, rawPlan - parsedAct) : 0)),
          problems: subProbs,
        );
      }).toList()
        ..sort((a, b) => a.no.compareTo(b.no));

      resolvedOtHours = slots.where((r) => r.isOvertime && !r.isBlocked && !r.isEarlyOvertime).length;
    } else {
      slots = UbMasterData.buildSlotsFromTemplate(tpl, tt, 2, customTemplates: templates);
    }

    // 6. Monthly Plan CCR & No Body Start/Finish auto-carry
    final mp = decoded['monthly_plan'] is Map
        ? Map<String, dynamic>.from(decoded['monthly_plan'] as Map)
        : null;
    final mpCcr = mp != null
        ? ((sh == 'RED' ? (mp['red_plan'] ?? mp['day_plan']) : (mp['white_plan'] ?? mp['day_plan'])) as num?)
                ?.toInt() ??
            0
        : 0;
    final ccrPlan = ((lap['ccr_plan'] as num?)?.toInt() ?? 0) > 0
        ? (lap['ccr_plan'] as num).toInt()
        : (mpCcr > 0 ? mpCcr : (sh == 'RED' ? cfg.ccrTargetRed : cfg.ccrTargetWhite));

    var noBodyStart = (lap['no_body_start'] ?? '').toString().trim();
    var noBodyFinish = (lap['no_body_finish'] ?? '').toString().trim();
    if (noBodyStart.isEmpty && prevCarry != null) {
      noBodyStart = UbMasterData.addNumberPreservePad(prevCarry.finish, 1);
    }
    if (noBodyFinish.isEmpty && noBodyStart.isNotEmpty && ccrPlan > 0) {
      noBodyFinish = UbMasterData.addNumberPreservePad(noBodyStart, ccrPlan - 1);
    }

    final actOtH = (lap['act_ot_hours'] ?? lap['overtime_hours'] as num?)?.toDouble() ??
        double.tryParse('${lap['act_ot_hours'] ?? lap['overtime_hours'] ?? 0}') ??
        0;
    final actOtU = (lap['act_ot_units'] as num?)?.toInt() ??
        int.tryParse('${lap['act_ot_units'] ?? 0}') ??
        0;

    return ChecksheetReport(
      id: UbMasterData.makeReportId(dt, sh, line),
      tanggal: dt,
      shift: sh,
      session: tpl.toLowerCase().contains('malam') ? 'night' : 'day',
      workMode: tpl.toLowerCase().contains('puasa') ? 'puasa' : 'normal',
      templateCode: tpl,
      overtimeHours: resolvedOtHours,
      otAwal: resolvedOtAwal,
      lineName: line,
      taktTime: tt,
      ccrPlan: ccrPlan,
      picName: picName,
      spvName: spvName,
      noBodyStart: noBodyStart,
      noBodyFinish: noBodyFinish,
      jamStopProduksi: (lap['jam_stop_produksi'] ?? '').toString(),
      actOtHours: actOtH,
      actOtUnits: actOtU,
      cbuSource: (lap['model_cbu_source'] ?? 'ratio').toString(),
      cbuModels: cbuModels,
      ckdParts: ckdParts,
      members: members,
      slots: slots,
      syncStatus: 'synced',
      updatedAt: (lap['updated_at'] ?? DateTime.now().toIso8601String()).toString(),
      lastSyncedAt: (lap['updated_at'] ?? DateTime.now().toIso8601String()).toString(),
    );
  }
}
