import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cost_env_models.dart';
import 'ub_web_api.dart';

class CostEnvStore {
  CostEnvStore._();
  static final CostEnvStore instance = CostEnvStore._();

  static String _costDailyKey(String ym) => 'ubf_cost_daily_v1_$ym';
  static String _costFindingsKey(String ym) => 'ubf_cost_findings_v1_$ym';
  static String _envEnergyKey(String ym) => 'ubf_env_energy_v1_$ym';
  static String _airCheckKey(String date, String shift) => 'ubf_air_cs_v1_${date}_$shift';
  static const String _airFindingsKey = 'ubf_air_findings_v1';
  static String _envFindingsKey(String ym) => 'ubf_env_findings_v1_$ym';

  // ===========================================================================
  // 1. COST DAILY — 1:1 with /api/cost/daily (GET / PATCH / PUT)
  // ===========================================================================
  Future<CostDailyMonth> loadCostDaily(String ym) async {
    final res = await UbWebApi.instance.getJson('/api/cost/daily', query: {'month': ym});
    if (res.ok && res.map['data'] is Map) {
      final parsed = CostDailyMonth.fromJson(ym, Map<String, dynamic>.from(res.map['data'] as Map));
      if (parsed.items.isNotEmpty) {
        await _saveCostDailyLocal(parsed);
        return parsed;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_costDailyKey(ym));
    if (raw != null && raw.isNotEmpty) {
      try {
        return CostDailyMonth.fromJson(ym, Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {}
    }

    final items = _defaultCostItems();
    final red = {for (final it in items) it.id: List<double?>.filled(31, null)};
    final white = {for (final it in items) it.id: List<double?>.filled(31, null)};
    final blank = CostDailyMonth(ym: ym, items: items, red: red, white: white);
    await _saveCostDailyLocal(blank);
    return blank;
  }

  Future<void> _saveCostDailyLocal(CostDailyMonth month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_costDailyKey(month.ym), jsonEncode(month.toJson()));
  }

  Future<void> saveCostDaily(CostDailyMonth month) async {
    await _saveCostDailyLocal(month);
    // Sync item list & targets 1:1 with PUT /api/cost/daily
    await UbWebApi.instance.putJson('/api/cost/daily', {
      'month': month.ym,
      'items': month.items.map((e) => e.toJson()).toList(),
    });
  }

  Future<bool> patchCostCell({
    required String ym,
    required String team,
    required String itemId,
    required int day,
    required double? value,
  }) async {
    final res = await UbWebApi.instance.patchJson('/api/cost/daily', {
      'month': ym,
      'team': team,
      'itemId': itemId,
      'day': day,
      'value': value,
    });
    return res.ok;
  }

  List<CostItem> _defaultCostItems() => const [
        CostItem(id: 'tip_cap', name: 'Tip Cap Welding 16mm', targetRed: 40, targetWhite: 40),
        CostItem(id: 'gloves', name: 'Sarung Tangan Las / Cotton', targetRed: 60, targetWhite: 60),
        CostItem(id: 'majun', name: 'Kain Majun (Kg)', targetRed: 25, targetWhite: 25),
        CostItem(id: 'anti_spatter', name: 'Anti Spatter Spray (Btl)', targetRed: 15, targetWhite: 15),
        CostItem(id: 'grinding_disc', name: 'Batu Gerinda 4"', targetRed: 30, targetWhite: 30),
        CostItem(id: 'tape_5s', name: 'Isolasi & Marking Tape 5S', targetRed: 12, targetWhite: 12),
      ];

  // ===========================================================================
  // 2. COST FINDINGS — 1:1 with /api/cost/findings (GET / POST / PUT / DELETE)
  // ===========================================================================
  Future<List<CostFinding>> loadCostFindings(String ym) async {
    final res = await UbWebApi.instance.getJson('/api/cost/findings', query: {'month': ym});
    if (res.ok && res.map['items'] is List) {
      final list = (res.map['items'] as List)
          .whereType<Map>()
          .map((m) => CostFinding.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      await _saveCostFindingsLocal(ym, list);
      return list;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_costFindingsKey(ym));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => CostFinding.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCostFindingsLocal(String ym, List<CostFinding> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_costFindingsKey(ym), jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> saveCostFindings(String ym, List<CostFinding> list) async {
    await _saveCostFindingsLocal(ym, list);
  }

  Future<bool> syncUpsertCostFinding(CostFinding item, {required bool isEdit}) async {
    final res = isEdit
        ? await UbWebApi.instance.putJson('/api/cost/findings/${Uri.encodeComponent(item.id)}', item.toJson())
        : await UbWebApi.instance.postJson('/api/cost/findings', item.toJson());
    return res.ok;
  }

  Future<bool> syncDeleteCostFinding(String id) async {
    final res = await UbWebApi.instance.deleteJson('/api/cost/findings/${Uri.encodeComponent(id)}');
    return res.ok;
  }

  // ===========================================================================
  // 3. ENV ENERGY DAILY (kWh) — 1:1 with /api/env/energy (GET / PUT / PATCH)
  // ===========================================================================
  Future<EnvEnergyMonth> loadEnvEnergy(String ym) async {
    final res = await UbWebApi.instance.getJson('/api/env/energy', query: {'month': ym});
    if (res.ok && res.map['data'] is Map) {
      final parsed = EnvEnergyMonth.fromJson(ym, Map<String, dynamic>.from(res.map['data'] as Map));
      await _saveEnvEnergyLocal(parsed);
      return parsed;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_envEnergyKey(ym));
    if (raw != null && raw.isNotEmpty) {
      try {
        return EnvEnergyMonth.fromJson(ym, Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {}
    }
    final empty = EnvEnergyMonth.empty(ym);
    await _saveEnvEnergyLocal(empty);
    return empty;
  }

  Future<void> _saveEnvEnergyLocal(EnvEnergyMonth data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_envEnergyKey(data.ym), jsonEncode(data.toJson()));
  }

  Future<void> saveEnvEnergy(EnvEnergyMonth data) async {
    await _saveEnvEnergyLocal(data);
    await UbWebApi.instance.putJson('/api/env/energy', {
      'month': data.ym,
      'data': {
        'red': data.red,
        'white': data.white,
        'target': data.target,
      },
    });
  }

  // ===========================================================================
  // 4. ENV AIR LEAKAGE (#lub & #klub) — 1:1 with /api/env/air-leakage
  // ===========================================================================
  Future<({String inspector, List<AirCheckPoint> points})> loadAirChecksheet(String date, String shift) async {
    final res = await UbWebApi.instance.getJson(
      '/api/env/air-leakage',
      query: {'type': 'checksheet', 'date': date, 'shift': shift},
    );
    if (res.ok && res.map['item'] is Map) {
      final it = Map<String, dynamic>.from(res.map['item'] as Map);
      final pts = (it['items'] is List ? it['items'] as List : const [])
          .whereType<Map>()
          .map((e) => AirCheckPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (pts.isNotEmpty) {
        final insp = '${it['inspector'] ?? ''}';
        await _saveAirChecksheetLocal(date, shift, insp, pts);
        return (inspector: insp, points: pts);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_airCheckKey(date, shift));
    if (raw != null && raw.isNotEmpty) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final pts = (m['points'] is List ? m['points'] as List : const [])
            .whereType<Map>()
            .map((e) => AirCheckPoint.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (pts.isNotEmpty) {
          return (inspector: '${m['inspector'] ?? ''}', points: pts);
        }
      } catch (_) {}
    }
    return (inspector: '', points: _defaultAirCheckPoints());
  }

  Future<void> _saveAirChecksheetLocal(String date, String shift, String inspector, List<AirCheckPoint> points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _airCheckKey(date, shift),
      jsonEncode({'inspector': inspector, 'points': points.map((e) => e.toJson()).toList()}),
    );
  }

  Future<void> saveAirChecksheet(String date, String shift, String inspector, List<AirCheckPoint> points) async {
    await _saveAirChecksheetLocal(date, shift, inspector, points);
    await UbWebApi.instance.postJson(
      '/api/env/air-leakage',
      {
        'date': date,
        'shift': shift,
        'inspector': inspector,
        'items': points.map((e) => e.toJson()).toList(),
        'notes': '',
      },
      query: {'type': 'checksheet'},
    );
  }

  List<AirCheckPoint> _defaultAirCheckPoints() => const [
        AirCheckPoint(code: 'AL-01', point: 'Regulator & FRL Main Line', area: 'UB Assy Pos 1'),
        AirCheckPoint(code: 'AL-02', point: 'Solenoid Valve Clamp Jig FR', area: 'UB Assy Pos 2'),
        AirCheckPoint(code: 'AL-03', point: 'Selang Pneumatic Gun Spot', area: 'UB Assy Pos 3'),
        AirCheckPoint(code: 'AL-04', point: 'Fitting Elbow & Coupler Robot', area: 'Robot 201–204'),
        AirCheckPoint(code: 'AL-05', point: 'Cylinder Clamp Jig Underbody RR', area: 'UB Assy Pos 5'),
        AirCheckPoint(code: 'AL-06', point: 'Air Blow Gun & Manifold Outlet', area: 'Area Inspection'),
      ];

  Future<List<AirLeakageFinding>> loadAirFindings({String? month}) async {
    final ym = month ?? costEnvTodayYmd().substring(0, 7);
    final res = await UbWebApi.instance.getJson(
      '/api/env/air-leakage',
      query: {'type': 'findings', 'month': ym},
    );
    if (res.ok && res.map['items'] is List) {
      final list = (res.map['items'] as List)
          .whereType<Map>()
          .map((m) => AirLeakageFinding.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      await _saveAirFindingsLocal(list);
      return list;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_airFindingsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => AirLeakageFinding.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAirFindingsLocal(List<AirLeakageFinding> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_airFindingsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> saveAirFindings(List<AirLeakageFinding> list) async {
    await _saveAirFindingsLocal(list);
  }

  Future<bool> syncUpsertAirFinding(AirLeakageFinding item, {required bool isEdit}) async {
    final res = isEdit
        ? await UbWebApi.instance.patchJson('/api/env/air-leakage/${Uri.encodeComponent(item.id)}', item.toJson())
        : await UbWebApi.instance.postJson('/api/env/air-leakage', item.toJson(), query: {'type': 'findings'});
    return res.ok;
  }

  Future<bool> syncDeleteAirFinding(String id) async {
    final res = await UbWebApi.instance.deleteJson('/api/env/air-leakage/${Uri.encodeComponent(id)}');
    return res.ok;
  }

  // ===========================================================================
  // 5. ENV TEMUAN & KAIZEN — 1:1 with /api/env/findings
  // ===========================================================================
  Future<List<EnvFindingItem>> loadEnvFindings(String ym) async {
    final res = await UbWebApi.instance.getJson('/api/env/findings', query: {'month': ym});
    if (res.ok && res.map['items'] is List) {
      final list = (res.map['items'] as List)
          .whereType<Map>()
          .map((m) => EnvFindingItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      await _saveEnvFindingsLocal(ym, list);
      return list;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_envFindingsKey(ym));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => EnvFindingItem.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveEnvFindingsLocal(String ym, List<EnvFindingItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_envFindingsKey(ym), jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> saveEnvFindings(String ym, List<EnvFindingItem> list) async {
    await _saveEnvFindingsLocal(ym, list);
  }

  Future<bool> syncUpsertEnvFinding(EnvFindingItem item, {required bool isEdit}) async {
    final res = isEdit
        ? await UbWebApi.instance.putJson('/api/env/findings/${Uri.encodeComponent(item.id)}', item.toJson())
        : await UbWebApi.instance.postJson('/api/env/findings', item.toJson());
    return res.ok;
  }

  Future<bool> syncDeleteEnvFinding(String id) async {
    final res = await UbWebApi.instance.deleteJson('/api/env/findings/${Uri.encodeComponent(id)}');
    return res.ok;
  }
}
