import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checksheet_models.dart';
import '../models/productivity_ops_models.dart';
import 'local_store.dart';
import 'ub_web_api.dart';

class ProductivityOpsStore {
  ProductivityOpsStore._();
  static final ProductivityOpsStore instance = ProductivityOpsStore._();

  static String _afterJobsKey(String shift) => 'ubf_after_jobs_v1_$shift';
  static String _afterHistoryKey(String shift) => 'ubf_after_hist_v1_$shift';
  static const String _tasksKey = 'ubf_task_hub_v1';
  static const String _templatesKey = 'ubf_shift_templates_v1';
  static const String _kaizenKey = 'ubf_prod_kaizen_v1';

  // ===========================================================================
  // 1. AFTER-PROD 5S — 1:1 with bungtemin.net/ub/api
  // ===========================================================================
  Future<({List<AfterProdMember> members, bool fromServer})> fetchAfterMembers(String shift) async {
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isNotEmpty) {
      try {
        final res = await http
            .get(Uri.parse('$base?action=get_members&shift=$shift'), headers: const {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final json = jsonDecode(res.body);
          if (json is Map && json['status'] == 'success' && json['data'] is List) {
            final list = (json['data'] as List)
                .whereType<Map>()
                .map((m) => AfterProdMember.fromJson(Map<String, dynamic>.from(m)))
                .where((m) => m.isEligibleFor5S)
                .toList();
            if (list.isNotEmpty) return (members: list, fromServer: true);
          }
        }
      } catch (_) {}
    }

    final fallback = UbMasterData.defaultMembers(shift)
        .asMap()
        .entries
        .map(
          (e) => AfterProdMember(
            id: e.key + 1,
            name: e.value.name,
            noreg: e.value.noreg,
            role: 'TM',
            shift: shift,
            line: 'Pos ${(e.key % 6) + 1}',
            statusKaryawan: e.key % 5 == 0 ? 'Vokasi' : (e.key % 3 == 0 ? 'Kontrak' : 'Tetap'),
          ),
        )
        .toList();
    return (members: fallback, fromServer: false);
  }

  Future<({List<AfterProdJob> jobs, bool fromServer})> fetchAfterJobs(String shift) async {
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isNotEmpty) {
      try {
        final res = await http
            .get(Uri.parse('$base?action=get_after_jobs&shift=$shift'), headers: const {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final json = jsonDecode(res.body);
          if (json is Map && json['status'] == 'success' && json['data'] is List) {
            final parsed = (json['data'] as List)
                .whereType<Map>()
                .map((m) => AfterProdJob.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            if (parsed.isNotEmpty) {
              await _saveAfterJobsCache(shift, parsed);
              return (jobs: parsed, fromServer: true);
            }
          }
        }
      } catch (_) {}
    }

    final cached = await _loadAfterJobsCache(shift);
    if (cached.isNotEmpty) return (jobs: cached, fromServer: false);

    final defaults = _defaultAfterJobs();
    await _saveAfterJobsCache(shift, defaults);
    return (jobs: defaults, fromServer: false);
  }

  Future<({bool synced, String message})> saveAfterJob(String shift, AfterProdJob job) async {
    final list = List<AfterProdJob>.from(await _loadAfterJobsCache(shift));
    final idx = list.indexWhere((e) => e.id == job.id && job.id > 0);
    if (idx >= 0) {
      list[idx] = job;
    } else {
      final nextId = list.fold<int>(0, (acc, e) => e.id > acc ? e.id : acc) + 1;
      list.add(job.copyWith(id: job.id > 0 ? job.id : nextId));
    }
    await _saveAfterJobsCache(shift, list);

    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isEmpty) return (synced: false, message: 'Pekerjaan tersimpan lokal.');
    try {
      final res = await http
          .post(
            Uri.parse('$base?action=save_after_job&shift=$shift'),
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(job.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (synced: true, message: 'Pekerjaan "${job.name}" tersimpan ke MySQL.');
      }
    } catch (_) {}
    return (synced: false, message: 'Pekerjaan "${job.name}" tersimpan lokal (offline).');
  }

  Future<({bool synced, String message})> deleteAfterJob(String shift, int jobId) async {
    final list = (await _loadAfterJobsCache(shift)).where((e) => e.id != jobId).toList();
    await _saveAfterJobsCache(shift, list);

    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isEmpty) return (synced: false, message: 'Pekerjaan dihapus lokal.');
    try {
      final res = await http
          .post(Uri.parse('$base?action=delete_after_job&id=$jobId&shift=$shift'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (synced: true, message: 'Pekerjaan dihapus dari MySQL.');
      }
    } catch (_) {}
    return (synced: false, message: 'Pekerjaan dihapus dari lokal.');
  }

  Future<({bool synced, String message})> saveAfterHistory(AfterProdHistoryRecord record) async {
    final hist = List<AfterProdHistoryRecord>.from(await loadAfterHistory(record.shift));
    hist.removeWhere((h) => h.date == record.date && h.shift == record.shift);
    hist.insert(0, record);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_afterHistoryKey(record.shift), jsonEncode(hist.take(30).map((e) => e.toJson()).toList()));

    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isEmpty) return (synced: false, message: 'Jadwal 5S tersimpan lokal.');
    try {
      final res = await http
          .post(
            Uri.parse('$base?action=save_after_tasks'),
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(record.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (synced: true, message: 'Jadwal 5S ${record.date} tersimpan ke MySQL!');
      }
    } catch (_) {}
    return (synced: false, message: 'Jadwal 5S ${record.date} tersimpan lokal (offline).');
  }

  Future<List<AfterProdHistoryRecord>> loadAfterHistory(String shift) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_afterHistoryKey(shift));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((m) => AfterProdHistoryRecord.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AfterProdJob>> _loadAfterJobsCache(String shift) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_afterJobsKey(shift));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => AfterProdJob.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAfterJobsCache(String shift, List<AfterProdJob> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_afterJobsKey(shift), jsonEncode(jobs.map((e) => e.toJson()).toList()));
  }

  List<AfterProdJob> _defaultAfterJobs() => const [
        AfterProdJob(id: 1, name: 'Sapu & Pel Area Pos 1–3', emoji: '🧹', scope: 'COMMON', requiredPeople: 2),
        AfterProdJob(id: 2, name: 'Bersihkan Jig & Tip Dresser', emoji: '🔧', scope: 'COMMON', requiredPeople: 2, allowedStatuses: ['Tetap', 'Kontrak']),
        AfterProdJob(id: 3, name: 'Buang Scrap & Spatter Robot', emoji: '♻️', scope: 'COMMON', requiredPeople: 2),
        AfterProdJob(id: 4, name: 'Rapikan Trolley & Part Kosong', emoji: '🛒', scope: 'COMMON', requiredPeople: 2),
        AfterProdJob(id: 5, name: 'Cek Kebocoran Angin & Matikan Panel', emoji: '⚡', scope: 'COMMON', requiredPeople: 1, allowedStatuses: ['Tetap']),
        AfterProdJob(id: 6, name: '5S Area Istirahat & Papan KPI', emoji: '📋', scope: 'COMMON', requiredPeople: 1, allowedStatuses: ['Vokasi', 'Kontrak', 'Tetap']),
      ];

  // ===========================================================================
  // 2. TASK MANAGER POST-IT HUB — 1:1 with Next.js /api/task
  // ===========================================================================
  Future<List<TaskHubItem>> loadTasks() async {
    final res = await UbWebApi.instance.getJson('/api/task', query: {'action': 'data'});
    if (res.ok) {
      final rawMods = res.map['modules'] ?? res.map['pekerjaans'];
      if (rawMods is List) {
        final remote = <TaskHubItem>[];
        for (final mod in rawMods) {
          if (mod is Map && mod['items'] is List) {
            final modName = '${mod['nama_pekerjaan'] ?? 'Umum'}';
            for (final it in mod['items'] as List) {
              if (it is Map) {
                final m = Map<String, dynamic>.from(it);
                m['pekerjaan_nama'] ??= modName;
                remote.add(TaskHubItem.fromJson(m));
              }
            }
          }
        }
        if (remote.isNotEmpty) {
          await saveTasks(remote);
          return remote;
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.whereType<Map>().map((m) => TaskHubItem.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {}
    }

    const seed = [
      TaskHubItem(
        id: 1,
        title: 'Pengambilan Data Cycle Time After Kaizen Pos 3',
        moduleName: 'Productivity',
        status: 'In Progress',
        priority: 'High',
        assignee: 'NUNU FATULAH',
        shift: 'RED',
        estimasiHari: 2,
      ),
      TaskHubItem(
        id: 2,
        title: 'Investigasi Sensor Clamp Jig Underbody RR',
        moduleName: 'Maintenance / Chokotei',
        status: 'To Do',
        priority: 'Urgent',
        assignee: 'TIM SHIFT RED',
        shift: 'RED',
        estimasiHari: 1,
      ),
      TaskHubItem(
        id: 3,
        title: 'Update Papan GL Board & Rekap KYT Bulanan',
        moduleName: 'Safety & 5S',
        status: 'In Review',
        priority: 'Medium',
        assignee: 'TL SHIFT WHITE',
        shift: 'WHITE',
        estimasiHari: 2,
      ),
      TaskHubItem(
        id: 4,
        title: 'Evaluasi Kaizen Bulanan Pengurangan Spatter',
        moduleName: 'Kaizen Report',
        status: 'Done',
        priority: 'Low',
        assignee: 'SGA UB ASSY',
        shift: 'WHITE',
        estimasiHari: 3,
      ),
    ];
    await saveTasks(seed);
    return seed;
  }

  Future<void> saveTasks(List<TaskHubItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tasksKey, jsonEncode(tasks.map((e) => e.toJson()).toList()));
  }

  Future<bool> syncUpdateTaskStatus(int taskId, String status) async {
    final res = await UbWebApi.instance.postJson(
      '/api/task',
      {'task_id': taskId, 'status': status},
      query: {'action': 'update_task_status'},
    );
    return res.ok;
  }

  // ===========================================================================
  // 3. MASTER SHIFT TEMPLATES — 1:1 with bungtemin.net/ub/api
  // ===========================================================================
  Future<({List<ShiftTemplateModel> templates, double masterTaktTime, bool fromServer})> fetchTemplates(
    double taktTime,
  ) async {
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isNotEmpty) {
      try {
        final res = await http
            .get(Uri.parse('$base?action=templates&takt_time=$taktTime'), headers: const {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final json = jsonDecode(res.body);
          if (json is Map && json['status'] == 'success' && json['data'] is List) {
            final parsed = (json['data'] as List)
                .whereType<Map>()
                .map((m) => ShiftTemplateModel.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            if (parsed.isNotEmpty) {
              await _saveTemplatesCache(parsed);
              return (templates: parsed, masterTaktTime: cfg.taktTime, fromServer: true);
            }
          }
        }
      } catch (_) {}
    }

    final cached = await _loadTemplatesCache();
    if (cached.isNotEmpty) return (templates: cached, masterTaktTime: cfg.taktTime, fromServer: false);

    final defaults = _defaultShiftTemplates(cfg.taktTime);
    await _saveTemplatesCache(defaults);
    return (templates: defaults, masterTaktTime: cfg.taktTime, fromServer: false);
  }

  Future<({bool synced, String message})> saveTemplate(ShiftTemplateModel tpl) async {
    final list = List<ShiftTemplateModel>.from(await _loadTemplatesCache());
    final idx = list.indexWhere((e) => e.code == tpl.code);
    if (idx >= 0) {
      list[idx] = tpl;
    } else {
      list.add(tpl);
    }
    await _saveTemplatesCache(list);

    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isEmpty) return (synced: false, message: 'Template "${tpl.name}" tersimpan lokal.');
    try {
      final res = await http
          .post(
            Uri.parse('$base?action=save_template'),
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(tpl.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (synced: true, message: 'Template "${tpl.name}" tersimpan ke MySQL!');
      }
    } catch (_) {}
    return (synced: false, message: 'Template "${tpl.name}" tersimpan lokal (offline).');
  }

  Future<List<ShiftTemplateModel>> _loadTemplatesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_templatesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => ShiftTemplateModel.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveTemplatesCache(List<ShiftTemplateModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_templatesKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  List<ShiftTemplateModel> _defaultShiftTemplates(double tt) => [
        ShiftTemplateModel(
          code: 'NORMAL_SENIN_KAMIS',
          name: 'Normal — Senin s/d Kamis (Day Shift)',
          category: 'normal',
          dayType: 'Senin - Kamis',
          defaultTaktTime: tt,
          regularHours: 7.5,
          description: 'Template standar produksi harian UB Assy (Reguler + OT 2 jam).',
          slots: const [
            ShiftTemplateSlot(slotNo: 1, startTime: '07:15', endTime: '08:15', durationMin: 60),
            ShiftTemplateSlot(slotNo: 2, startTime: '08:15', endTime: '09:15', durationMin: 60, breakAfterMin: 10, note: 'Break 10m'),
            ShiftTemplateSlot(slotNo: 3, startTime: '09:25', endTime: '10:25', durationMin: 60),
            ShiftTemplateSlot(slotNo: 4, startTime: '10:25', endTime: '11:25', durationMin: 60, breakAfterMin: 45, note: 'Ishoma 45m'),
            ShiftTemplateSlot(slotNo: 5, startTime: '12:10', endTime: '13:10', durationMin: 60),
            ShiftTemplateSlot(slotNo: 6, startTime: '13:10', endTime: '14:10', durationMin: 60, breakAfterMin: 10, note: 'Break 10m'),
            ShiftTemplateSlot(slotNo: 7, startTime: '14:20', endTime: '15:20', durationMin: 60),
            ShiftTemplateSlot(slotNo: 8, startTime: '15:20', endTime: '16:00', durationMin: 40, note: 'Akhir Reguler'),
            ShiftTemplateSlot(slotNo: 9, startTime: '16:15', endTime: '17:15', durationMin: 60, isOvertime: true, note: 'OT Jam 1'),
            ShiftTemplateSlot(slotNo: 10, startTime: '17:15', endTime: '18:15', durationMin: 60, isOvertime: true, note: 'OT Jam 2'),
          ],
        ),
        ShiftTemplateModel(
          code: 'NORMAL_JUMAT',
          name: 'Normal — Jumat (Day Shift)',
          category: 'normal',
          dayType: 'Jumat',
          defaultTaktTime: tt,
          regularHours: 7.5,
          description: 'Template produksi hari Jumat dengan jeda Sholat Jumat 75 menit.',
          slots: const [
            ShiftTemplateSlot(slotNo: 1, startTime: '07:15', endTime: '08:15', durationMin: 60),
            ShiftTemplateSlot(slotNo: 2, startTime: '08:15', endTime: '09:15', durationMin: 60, breakAfterMin: 10),
            ShiftTemplateSlot(slotNo: 3, startTime: '09:25', endTime: '10:25', durationMin: 60),
            ShiftTemplateSlot(slotNo: 4, startTime: '10:25', endTime: '11:30', durationMin: 65, breakAfterMin: 75, note: 'Jumat 75m'),
            ShiftTemplateSlot(slotNo: 5, startTime: '12:45', endTime: '13:45', durationMin: 60),
            ShiftTemplateSlot(slotNo: 6, startTime: '13:45', endTime: '14:45', durationMin: 60, breakAfterMin: 10),
            ShiftTemplateSlot(slotNo: 7, startTime: '14:55', endTime: '15:55', durationMin: 60),
            ShiftTemplateSlot(slotNo: 8, startTime: '15:55', endTime: '16:30', durationMin: 35, note: 'Akhir Reguler'),
            ShiftTemplateSlot(slotNo: 9, startTime: '16:45', endTime: '17:45', durationMin: 60, isOvertime: true, note: 'OT Jam 1'),
          ],
        ),
        ShiftTemplateModel(
          code: 'PUASA_RAMADHAN',
          name: 'Ramadhan / Puasa — Day Shift',
          category: 'puasa',
          dayType: 'Senin - Jumat (Puasa)',
          defaultTaktTime: tt,
          regularHours: 7.0,
          description: 'Penyesuaian jam kerja bulan Ramadhan dengan istirahat singkat & pulang lebih awal.',
          slots: const [
            ShiftTemplateSlot(slotNo: 1, startTime: '07:00', endTime: '08:00', durationMin: 60),
            ShiftTemplateSlot(slotNo: 2, startTime: '08:00', endTime: '09:00', durationMin: 60),
            ShiftTemplateSlot(slotNo: 3, startTime: '09:10', endTime: '10:10', durationMin: 60),
            ShiftTemplateSlot(slotNo: 4, startTime: '10:10', endTime: '11:10', durationMin: 60),
            ShiftTemplateSlot(slotNo: 5, startTime: '11:40', endTime: '12:40', durationMin: 60),
            ShiftTemplateSlot(slotNo: 6, startTime: '12:40', endTime: '13:40', durationMin: 60),
            ShiftTemplateSlot(slotNo: 7, startTime: '13:50', endTime: '14:50', durationMin: 60),
            ShiftTemplateSlot(slotNo: 8, startTime: '15:00', endTime: '16:00', durationMin: 60, isOvertime: true, note: 'OT Puasa'),
          ],
        ),
      ];

  // ===========================================================================
  // 4. KAIZEN REPORT PRODUCTIVITY — 1:1 with Next.js /api/kaizen-reports?area=P
  // ===========================================================================
  Future<List<ProdKaizenItem>> loadKaizenItems() async {
    final res = await UbWebApi.instance.getJson('/api/kaizen-reports', query: {'area': 'P'});
    if (res.ok) {
      final rawList = res.map['items'] is List
          ? res.map['items'] as List
          : (res.data is List ? res.list : null);
      if (rawList != null && rawList.isNotEmpty) {
        final remote = rawList
            .whereType<Map>()
            .map((m) {
              final j = Map<String, dynamic>.from(m);
              return ProdKaizenItem(
                id: '${j['id'] ?? j['_id'] ?? ''}',
                tag: '${j['tag'] ?? j['area'] ?? 'PRODUCTIVITY'}',
                month: '${j['month'] ?? (j['tanggal']?.toString().substring(0, 7) ?? ubTodayYmd().substring(0, 7))}',
                theme: '${j['theme'] ?? j['title'] ?? j['problem'] ?? ''}',
                lineProcess: '${j['line_process'] ?? j['machine'] ?? j['process'] ?? 'UB Assy'}',
                pic: '${j['pic'] ?? ''}',
                beforeValue: '${j['before_value'] ?? j['beforeValue'] ?? ''}',
                afterValue: '${j['after_value'] ?? j['afterValue'] ?? ''}',
                status: '${j['status'] ?? 'ON PROGRES'}'.toUpperCase(),
                rootCause: '${j['root_cause'] ?? j['beforeText'] ?? ''}',
                countermeasure: '${j['countermeasure'] ?? j['afterText'] ?? ''}',
                sourceChokoteiKey: '${j['chokoteiId'] ?? j['source_chokotei_key'] ?? ''}',
              );
            })
            .toList();
        await saveKaizenItems(remote);
        return remote;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kaizenKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.whereType<Map>().map((m) => ProdKaizenItem.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {}
    }

    final ym = ubTodayYmd().substring(0, 7);
    final seed = [
      ProdKaizenItem(
        id: 'kz_1',
        tag: 'CHOKOTEI',
        month: ym,
        theme: 'Reduksi Chokotei Sensor Clamp Jig RR dengan Bracket Pelindung Spatter',
        lineProcess: 'UB Assy — Robot 202',
        pic: 'TL Shift Red',
        beforeValue: '18 mnt/shift',
        afterValue: '2 mnt/shift',
        status: 'SUDAH',
        rootCause: 'Spatter las menempel pada permukaan sensor proximity clamp.',
        countermeasure: 'Pasang cover pelindung tembaga + jadwal pembersihan setiap istirahat.',
      ),
      ProdKaizenItem(
        id: 'kz_2',
        tag: 'CYCLE TIME',
        month: ym,
        theme: 'Relokasi Rack Part Sub-Assy Pos 3 untuk Hemat 4 Langkah Operator',
        lineProcess: 'UB Assy — Pos 3',
        pic: 'SGA White',
        beforeValue: '146 dtk',
        afterValue: '138 dtk',
        status: 'ON PROGRES',
        rootCause: 'Jarak pengambilan part 2.2 meter di belakang operator.',
        countermeasure: 'Buat flow rack miring dekat titik pasang.',
      ),
    ];
    await saveKaizenItems(seed);
    return seed;
  }

  Future<void> saveKaizenItems(List<ProdKaizenItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kaizenKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<bool> syncUpsertKaizen(ProdKaizenItem item, {required bool isEdit}) async {
    final payload = {
      ...item.toJson(),
      'area': 'P',
      'title': item.theme,
      'beforeText': item.rootCause,
      'afterText': item.countermeasure,
      'beforeValue': item.beforeValue,
      'afterValue': item.afterValue,
    };
    final res = isEdit
        ? await UbWebApi.instance.putJson('/api/kaizen-reports/${Uri.encodeComponent(item.id)}', payload)
        : await UbWebApi.instance.postJson('/api/kaizen-reports', payload);
    return res.ok;
  }

  Future<bool> syncDeleteKaizen(String id) async {
    final res = await UbWebApi.instance.deleteJson('/api/kaizen-reports/${Uri.encodeComponent(id)}');
    return res.ok;
  }
}
