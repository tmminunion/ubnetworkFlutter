import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checksheet_models.dart';
import '../models/roster_attendance_models.dart';
import 'local_store.dart';

class RosterAttendanceStore {
  RosterAttendanceStore._();
  static final RosterAttendanceStore instance = RosterAttendanceStore._();

  static String _rosterKey(String shift) => 'ubf_roster_v1_$shift';

  Future<({List<RosterMember> members, bool fromServer})> fetchRoster(String shift) async {
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();

    if (base.isNotEmpty) {
      try {
        final uri = Uri.parse('$base?action=get_members&shift=$shift&_t=${DateTime.now().millisecondsSinceEpoch}');
        final res = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 12));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final json = jsonDecode(res.body);
          if (json is Map && json['status'] == 'success' && json['data'] is List) {
            final parsed = (json['data'] as List)
                .whereType<Map>()
                .map((m) => RosterMember.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            if (parsed.isNotEmpty) {
              await _saveRosterCache(shift, parsed);
              return (members: parsed, fromServer: true);
            }
          }
        }
      } catch (_) {}
    }

    final cached = await _loadRosterCache(shift);
    if (cached.isNotEmpty) return (members: cached, fromServer: false);

    final fallback = UbMasterData.defaultMembers(shift)
        .asMap()
        .entries
        .map(
          (e) => RosterMember(
            id: e.key + 1,
            name: e.value.name,
            role: e.value.role,
            shift: shift,
            defaultPos: e.value.pos,
          ),
        )
        .toList();
    await _saveRosterCache(shift, fallback);
    return (members: fallback, fromServer: false);
  }

  Future<({bool synced, String message})> saveMember(RosterMember m) async {
    // 1. Offline-first update
    final current = await _loadRosterCache(m.shift);
    final list = List<RosterMember>.from(current);
    final idx = list.indexWhere((e) => e.id == m.id && m.id > 0);
    if (idx >= 0) {
      list[idx] = m;
    } else {
      final nextId = list.fold<int>(0, (acc, e) => e.id > acc ? e.id : acc) + 1;
      list.add(
        RosterMember(
          id: m.id > 0 ? m.id : nextId,
          name: m.name,
          noreg: m.noreg,
          phone: m.phone,
          idCard: m.idCard,
          rfidCode: m.rfidCode,
          role: m.role,
          shift: m.shift,
          defaultPos: m.defaultPos,
          statusKaryawan: m.statusKaryawan,
          isActive: m.isActive,
          notes: m.notes,
        ),
      );
    }
    await _saveRosterCache(m.shift, list);

    // 2. Push to MySQL bungtemin.net
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isEmpty) return (synced: false, message: 'Tersimpan di lokal.');
    try {
      final payload = {
        ...m.toJson(),
        'line_name': 'UB Assy',
      };
      final res = await http
          .post(
            Uri.parse('$base?action=save_member'),
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body);
        if (json is Map && json['status'] == 'success') {
          return (synced: true, message: 'Anggota "${m.name}" tersimpan ke MySQL!');
        }
      }
      return (synced: false, message: 'Tersimpan di lokal (MySQL HTTP ${res.statusCode}).');
    } catch (_) {
      return (synced: false, message: 'Tersimpan di lokal (offline).');
    }
  }

  Future<({bool synced, String message})> deleteMember(RosterMember m) async {
    final current = await _loadRosterCache(m.shift);
    final list = current.where((e) => e.id != m.id).toList();
    await _saveRosterCache(m.shift, list);

    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isEmpty || m.id <= 0) return (synced: false, message: 'Dihapus dari lokal.');
    try {
      final res = await http
          .post(
            Uri.parse('$base?action=delete_member'),
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'id': m.id}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (synced: true, message: 'Anggota ${m.name} dihapus dari MySQL.');
      }
    } catch (_) {}
    return (synced: false, message: 'Anggota ${m.name} dihapus dari lokal.');
  }

  Future<({
    List<MemberAttendanceRow> members,
    AttendanceSummaryKpi kpi,
    bool fromServer,
  })> fetchMonthlyAttendance(String ym, String shift) async {
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();

    if (base.isNotEmpty) {
      try {
        final uri = Uri.parse('$base?action=get_monthly_attendance&year_month=$ym&shift=$shift');
        final res = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 12));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final json = jsonDecode(res.body);
          if (json is Map && json['status'] == 'success' && json['members'] is List) {
            final members = (json['members'] as List)
                .whereType<Map>()
                .map((m) => MemberAttendanceRow.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            final rawKpi = json['kpi'] is Map ? Map<String, dynamic>.from(json['kpi'] as Map) : <String, dynamic>{};
            int ai(dynamic v) => v is num ? v.toInt() : (int.tryParse('${v ?? 0}') ?? 0);
            double ad(dynamic v) => v is num ? v.toDouble() : (double.tryParse('${v ?? 100}') ?? 100);
            final kpi = AttendanceSummaryKpi(
              avgAttendanceRate: ad(rawKpi['avgAttendanceRate']),
              totalHadir: ai(rawKpi['totalHadir']),
              totalSakit: ai(rawKpi['totalSakit']),
              totalIzin: ai(rawKpi['totalIzin']),
              totalCuti: ai(rawKpi['totalCuti']),
              totalDinas: ai(rawKpi['totalDinas']),
              totalAlpa: ai(rawKpi['totalAlpa']),
              totalAbsent: ai(rawKpi['totalAbsent']),
              perfectMembersCount: ai(rawKpi['perfectMembersCount']),
              totalMembers: ai(rawKpi['totalMembers']),
            );
            return (members: members, kpi: kpi, fromServer: true);
          }
        }
      } catch (_) {}
    }

    final localReports = await LocalStore.instance.listReports();
    final fb = RosterAttendanceMath.buildLocalAttendance(ym, shift, localReports);
    return (members: fb.members, kpi: fb.kpi, fromServer: false);
  }

  Future<List<RosterMember>> _loadRosterCache(String shift) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rosterKey(shift));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => RosterMember.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveRosterCache(String shift, List<RosterMember> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rosterKey(shift), jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
